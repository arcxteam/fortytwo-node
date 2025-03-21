#!/bin/bash

# Script for installing and setting up LayerEdge Light Node with systemd service
# Based on: https://docs.layeredge.io/introduction/developer-guide/run-a-node/light-node-setup-guide
# Usage: sudo ./layeredge_install.sh <private_key> or bash layeredge_install.sh <private_key>

set -e

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Check if private key argument is provided
if [ -z "$1" ]; then
  echo -e "${RED}Error: Private key argument is missing.${NC}"
  echo -e "Usage: sudo ./layeredge_install.sh <private_key> or bash layeredge_install.sh <private_key>"
  exit 1
fi

PRIVATE_KEY="$1"

# Print banner
echo -e "${GREEN}================== WELCOME TO VOTING DAPPs =======================${NC}"
echo -e "${YELLOW}
 ██████╗██╗   ██╗ █████╗ ███╗   ██╗███╗   ██╗ ██████╗ ██████╗ ███████╗
██╔════╝██║   ██║██╔══██╗████╗  ██║████╗  ██║██╔═══██╗██╔══██╗██╔════╝
██║     ██║   ██║███████║██╔██╗ ██║██╔██╗ ██║██║   ██║██║  ██║█████╗  
██║     ██║   ██║██╔══██║██║╚██╗██║██║╚██╗██║██║   ██║██║  ██║██╔══╝  
╚██████╗╚██████╔╝██║  ██║██║ ╚████║██║ ╚████║╚██████╔╝██████╔╝███████╗
 ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝
${NC}"
echo -e "${GREEN}=========================================================================${NC}"
echo -e "${MAGENTA}         Welcome to Voting Onchain Testnet & Mainnet Interactive   ${NC}"
echo -e "${YELLOW}           - CUANNODE By Greyscope&Co, Credit By Arcxteam -     ${NC}"
echo -e "${GREEN}=========================================================================${NC}"

# Check if script is run as root, and if not, restart with sudo
if [ "$EUID" -ne 0 ]; then
  echo -e "${YELLOW}Script must be run as root. Restarting with sudo...${NC}"
  exec sudo "$0" "$@"
  exit $?
fi

# Function to check and install dependencies
install_dependencies() {
  echo -e "${YELLOW}Checking and installing dependencies...${NC}"
  
  # Update package lists
  apt update
  
  # Install required packages
  apt install -y curl wget jq build-essential git screen

  # Check if Go is installed and has correct version (1.18+)
  if ! command -v go &> /dev/null; then
    echo -e "${YELLOW}Go not installed. Installing Go...${NC}"
    wget https://go.dev/dl/go1.22.2.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /root/.bashrc
    rm go1.22.2.linux-amd64.tar.gz
  else
    # Check Go version
    GO_VERSION=$(go version | grep -oP 'go\K[0-9]+\.[0-9]+' || echo "0.0")
    GO_MAJOR=$(echo $GO_VERSION | cut -d. -f1)
    GO_MINOR=$(echo $GO_VERSION | cut -d. -f2)
    
    if [ "$GO_MAJOR" -lt 1 ] || ([ "$GO_MAJOR" -eq 1 ] && [ "$GO_MINOR" -lt 18 ]); then
      echo -e "${YELLOW}Go version $GO_VERSION is below required version 1.18. Upgrading Go...${NC}"
      wget https://go.dev/dl/go1.22.2.linux-amd64.tar.gz
      rm -rf /usr/local/go
      tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz
      export PATH=$PATH:/usr/local/go/bin
      rm go1.22.2.linux-amd64.tar.gz
    else
      echo -e "${GREEN}Go version $GO_VERSION is already installed and meets minimum requirement (1.18+)${NC}"
    fi
  fi
  
  # Check if Rust is installed and has correct version (1.81+)
  if ! command -v rustc &> /dev/null; then
    echo -e "${YELLOW}Rust not installed. Installing Rust...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    echo 'source $HOME/.cargo/env' >> /root/.bashrc
  else
    # Check Rust version
    RUST_VERSION=$(rustc --version | grep -oP '\d+\.\d+\.\d+' || echo "0.0.0")
    RUST_MAJOR=$(echo $RUST_VERSION | cut -d. -f1)
    RUST_MINOR=$(echo $RUST_VERSION | cut -d. -f2)
    
    if [ "$RUST_MAJOR" -lt 1 ] || ([ "$RUST_MAJOR" -eq 1 ] && [ "$RUST_MINOR" -lt 81 ]); then
      echo -e "${YELLOW}Rust version $RUST_VERSION is below required version 1.81. Updating Rust...${NC}"
      rustup update stable
    else
      echo -e "${GREEN}Rust version $RUST_VERSION is already installed and meets minimum requirement (1.81+)${NC}"
    fi
  fi
  
  # Install Risc0 Toolchain if not already installed
  if ! command -v rzup &> /dev/null; then
    echo -e "${YELLOW}Installing Risc0 Toolchain...${NC}"
    curl -L https://risczero.com/install | bash -
    source ~/.bashrc
    
    # Check if rzup is now available
    if command -v rzup &> /dev/null; then
      echo -e "${YELLOW}Running rzup install...${NC}"
      rzup install
    else
      echo -e "${YELLOW}Warning: rzup command not found after installation.${NC}"
      echo -e "${YELLOW}You may need to run the following manually after installation:${NC}"
      echo -e "${GREEN}source ~/.bashrc && rzup install${NC}"
    fi
  else
    echo -e "${GREEN}Risc0 Toolchain already installed${NC}"
  fi
  
  # Set up environment variables for this session
  export PATH=$PATH:/usr/local/go/bin:$HOME/.cargo/bin
  
  # Verify installations
  GO_VERSION=$(go version 2>/dev/null || echo "Go not in PATH")
  RUST_VERSION=$(rustc --version 2>/dev/null || echo "Rust not in PATH")
  
  echo -e "${GREEN}Go status: ${GO_VERSION}${NC}"
  echo -e "${GREEN}Rust status: ${RUST_VERSION}${NC}"
  
  echo -e "${GREEN}Dependencies check completed${NC}"
}

# Function to clone and setup Light Node
setup_light_node() {
  echo -e "${YELLOW}Setting up LayerEdge Light Node...${NC}"
  
  # Clone the Light Node repository
  cd /root
  if [ ! -d "/root/light-node/.git" ]; then
    echo -e "${YELLOW}Cloning Light Node repository...${NC}"
    git clone https://github.com/Layer-Edge/light-node.git
  else
    echo -e "${YELLOW}Light Node repository already exists, pulling latest changes...${NC}"
    cd /root/light-node
    git pull
  fi
  
  cd /root/light-node
  
  # Check repo structure
  if [ ! -d "risc0-merkle-service" ]; then
    echo -e "${RED}Error: Directory structure seems incorrect. risc0-merkle-service directory not found.${NC}"
    echo -e "${YELLOW}This might be a different repository structure than expected.${NC}"
    echo -e "${YELLOW}Trying alternative repository name...${NC}"
    
    cd /root
    git clone https://github.com/Layer-Edge/light-node-release.git light-node-temp
    
    if [ -d "/root/light-node-temp/risc0-merkle-service" ]; then
      echo -e "${GREEN}Found correct repository structure in alternative repo!${NC}"
      rm -rf /root/light-node
      mv /root/light-node-temp /root/light-node
    else
      rm -rf /root/light-node-temp
      echo -e "${RED}Error: Could not find the correct repository structure.${NC}"
      echo -e "${YELLOW}Please verify the repository manually.${NC}"
      exit 1
    fi
  fi
  
  cd /root/light-node
  
  # Setup .env file
  echo -e "${YELLOW}Creating .env file...${NC}"
  cat > .env << EOF
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
# Alternatively:
ZK_PROVER_URL=https://layeredge.mintair.xyz/
API_REQUEST_TIMEOUT=100
POINTS_API=https://light-node.layeredge.io
PRIVATE_KEY='${PRIVATE_KEY}'
EOF
  
  echo -e "${GREEN}.env file created successfully${NC}"
}

# Function to check and setup Merkle Service
setup_merkle_service() {
  echo -e "${YELLOW}Setting up Risc0 Merkle Service...${NC}"
  
  cd /root/light-node/risc0-merkle-service
  
  # Check if there's a run_merkle_tree.sh script
  if [ -f "run_merkle_tree.sh" ]; then
    echo -e "${YELLOW}Found run_merkle_tree.sh script, making it executable...${NC}"
    chmod +x run_merkle_tree.sh
  else
    # Build Merkle Service with Cargo
    echo -e "${YELLOW}Building Merkle Service with Cargo...${NC}"
    source $HOME/.cargo/env
    cargo build
  fi
  
  echo -e "${GREEN}Merkle Service setup completed${NC}"
}

# Function to build Light Node
build_light_node() {
  echo -e "${YELLOW}Building LayerEdge Light Node...${NC}"
  
  cd /root/light-node
  
  # Set correct Go environment
  export PATH=$PATH:/usr/local/go/bin
  
  # First check if an executable already exists
  if [ -f "light-node" ]; then
    echo -e "${GREEN}Found pre-built light-node executable${NC}"
  elif [ -f "main" ]; then
    echo -e "${GREEN}Found pre-built main executable${NC}"
  else
    # Build Light Node using go build
    echo -e "${YELLOW}Building Light Node with Go...${NC}"
    
    # Check if go.mod exists
    if [ -f "go.mod" ]; then
      go build
      
      # Check if build was successful
      if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to build Light Node with 'go build'.${NC}"
        echo -e "${YELLOW}Trying alternative build command 'go build -o light-node main.go'...${NC}"
        go build -o light-node main.go
      fi
    else
      echo -e "${RED}Error: go.mod not found. Cannot build the Light Node.${NC}"
      exit 1
    fi
  fi
  
  # Verify the executable exists after build
  if [ -f "light-node" ]; then
    echo -e "${GREEN}light-node executable found${NC}"
  elif [ -f "main" ]; then
    echo -e "${GREEN}main executable found${NC}"
  else
    echo -e "${RED}Error: No executable found after build. Build may have failed.${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}Light Node build completed${NC}"
}

# Function to create systemd service for Merkle Service
create_merkle_service() {
  echo -e "${YELLOW}Creating systemd service for Risc0 Merkle Service...${NC}"
  
  # Check the content of run_merkle_tree.sh if it exists
  if [ -f "/root/light-node/risc0-merkle-service/run_merkle_tree.sh" ]; then
    echo -e "${YELLOW}Checking run_merkle_tree.sh content...${NC}"
    chmod +x /root/light-node/risc0-merkle-service/run_merkle_tree.sh
    
    # Try running script directly to see if it works
    echo -e "${YELLOW}Testing run_merkle_tree.sh (output suppressed)...${NC}"
    cd /root/light-node/risc0-merkle-service
    if timeout 5 ./run_merkle_tree.sh > /dev/null 2>&1; then
      echo -e "${GREEN}run_merkle_tree.sh appears to be working.${NC}"
      MERKLE_EXEC_CMD="/bin/bash /root/light-node/risc0-merkle-service/run_merkle_tree.sh"
    else
      echo -e "${YELLOW}run_merkle_tree.sh test failed, using cargo run directly instead.${NC}"
      MERKLE_EXEC_CMD="/root/.cargo/bin/cargo run"
    fi
  else
    echo -e "${YELLOW}run_merkle_tree.sh not found, using cargo run...${NC}"
    MERKLE_EXEC_CMD="/root/.cargo/bin/cargo run"
  fi
  
  # Create systemd service file
  cat > /etc/systemd/system/layeredge-merkle.service << EOF
[Unit]
Description=LayerEdge Risc0 Merkle Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/light-node/risc0-merkle-service
ExecStart=${MERKLE_EXEC_CMD}
Restart=always
RestartSec=15
StandardOutput=journal
StandardError=journal
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/go/bin:/root/.cargo/bin
Environment=RUST_BACKTRACE=1

[Install]
WantedBy=multi-user.target
EOF

  # Reload systemd to pick up the new service
  systemctl daemon-reload
  
  # Enable the service to start on boot
  systemctl enable layeredge-merkle.service
  
  # Start the service
  systemctl start layeredge-merkle.service
  
  # Check if service started successfully
  if systemctl is-active --quiet layeredge-merkle.service; then
    echo -e "${GREEN}Merkle Service systemd service created and started successfully!${NC}"
  else
    echo -e "${YELLOW}Merkle Service failed to start with run_merkle_tree.sh, trying with cargo run...${NC}"
    
    # Modify service to use cargo run directly
    cat > /etc/systemd/system/layeredge-merkle.service << EOF
[Unit]
Description=LayerEdge Risc0 Merkle Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/light-node/risc0-merkle-service
ExecStart=/root/.cargo/bin/cargo run
Restart=always
RestartSec=15
StandardOutput=journal
StandardError=journal
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/go/bin:/root/.cargo/bin
Environment=RUST_BACKTRACE=1

[Install]
WantedBy=multi-user.target
EOF

    # Reload and restart
    systemctl daemon-reload
    systemctl restart layeredge-merkle.service
    
    if systemctl is-active --quiet layeredge-merkle.service; then
      echo -e "${GREEN}Merkle Service started successfully with cargo run!${NC}"
    else
      echo -e "${RED}Warning: Merkle Service failed to start. Light Node may not function correctly.${NC}"
      echo -e "${YELLOW}You can check the logs with: journalctl -u layeredge-merkle.service${NC}"
    fi
  fi
  
  # Wait for Merkle Service to initialize
  echo -e "${YELLOW}Waiting for Merkle Service to initialize (30 seconds)...${NC}"
  sleep 30
}

# Function to create systemd service for Light Node
create_light_node_service() {
  echo -e "${YELLOW}Creating systemd service for LayerEdge Light Node...${NC}"
  
  # Determine executable name
  LIGHT_NODE_EXECUTABLE="light-node"
  if [ ! -f "/root/light-node/light-node" ] && [ -f "/root/light-node/main" ]; then
    LIGHT_NODE_EXECUTABLE="main"
  fi
  
  # Create systemd service file
  cat > /etc/systemd/system/layeredge.service << EOF
[Unit]
Description=LayerEdge Light Node Service
After=layeredge-merkle.service
Requires=layeredge-merkle.service

[Service]
Type=simple
User=root
WorkingDirectory=/root/light-node
ExecStart=/root/light-node/${LIGHT_NODE_EXECUTABLE}
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/go/bin

[Install]
WantedBy=multi-user.target
EOF

  # Reload systemd to pick up the new service
  systemctl daemon-reload
  
  # Enable the service to start on boot
  systemctl enable layeredge.service
  
  # Start the service
  systemctl start layeredge.service
  
  echo -e "${GREEN}Light Node systemd service created and started successfully!${NC}"
}

# Main installation process
main() {
  echo -e "${YELLOW}Starting LayerEdge Light Node installation...${NC}"
  
  # Install dependencies
  install_dependencies
  
  # Setup Light Node
  setup_light_node
  
  # Setup Merkle Service
  setup_merkle_service
  
  # Build Light Node
  build_light_node
  
  # Create systemd service for Merkle Service
  create_merkle_service
  
  # Create systemd service for Light Node
  create_light_node_service
  
  # Display status and commands
  echo -e "${GREEN}====================================================================${NC}"
  echo -e "${GREEN} LayerEdge Light Node has been installed and started successfully!${NC}"
  echo -e "${GREEN}====================================================================${NC}"
  echo -e "${YELLOW}Merkle Service Status:${NC}"
  systemctl status layeredge-merkle.service --no-pager
  
  echo -e "${YELLOW}Light Node Status:${NC}"
  systemctl status layeredge.service --no-pager
  
  echo -e "${GREEN}====================================================================${NC}"
  echo -e "${YELLOW}Verification Process:${NC}"
  echo -e "The Light Node will automatically run the verification process from verifier.go"
  echo -e "This process will verify Merkle proofs and submit them to earn points"
  echo -e "No additional action is needed - the verification runs automatically as part of the node"
  echo -e "${GREEN}====================================================================${NC}"
  
  echo -e "${YELLOW}You can manage the services with the following commands:${NC}"
  echo -e "${YELLOW}For Merkle Service:${NC}"
  echo -e "Check status: ${GREEN}sudo systemctl status layeredge-merkle.service${NC}"
  echo -e "View logs: ${GREEN}sudo journalctl -u layeredge-merkle.service -f -n 100${NC}"
  echo -e "Stop service: ${GREEN}sudo systemctl stop layeredge-merkle.service${NC}"
  echo -e "Start service: ${GREEN}sudo systemctl start layeredge-merkle.service${NC}"
  echo -e "Restart service: ${GREEN}sudo systemctl restart layeredge-merkle.service${NC}"
  
  echo -e "${YELLOW}For Light Node:${NC}"
  echo -e "Check status: ${GREEN}sudo systemctl status layeredge.service${NC}"
  echo -e "View logs: ${GREEN}sudo journalctl -u layeredge.service -f -n 100${NC}"
  echo -e "Stop service: ${GREEN}sudo systemctl stop layeredge.service${NC}"
  echo -e "Start service: ${GREEN}sudo systemctl start layeredge.service${NC}"
  echo -e "Restart service: ${GREEN}sudo systemctl restart layeredge.service${NC}"
  echo -e "${GREEN}====================================================================${NC}"
}

# Run the main installation
main