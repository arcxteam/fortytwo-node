#!/bin/bash

# Script for installing and setting up LayerEdge Light Node with systemd service
# Based on: https://docs.layeredge.io/introduction/developer-guide/run-a-node/light-node-setup-guide
# Usage: bash layeredge_install.sh <private_key>

set -e

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Check if private key argument is provided
if [ -z "$1" ]; then
  echo -e "${RED}Error: Private key argument is missing.${NC}"
  echo -e "Usage: bash layeredge_install.sh <private_key>"
  exit 1
fi

PRIVATE_KEY="$1"

# Print banner
echo -e "${GREEN}====================================================================${NC}"
echo -e "${GREEN}           LayerEdge Light Node Installation Script                 ${NC}"
echo -e "${GREEN}====================================================================${NC}"

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root or using sudo${NC}"
  exit 1
fi

# Function to check and install dependencies
install_dependencies() {
  echo -e "${YELLOW}Checking and installing dependencies...${NC}"
  
  # Update package lists
  apt update
  
  # Install required packages
  apt install -y curl wget jq build-essential git screen

  # Check if Go is installed (Go 1.18+ required)
  if ! command -v go &> /dev/null; then
    echo -e "${YELLOW}Installing Go...${NC}"
    wget https://golang.org/dl/go1.20.0.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.20.0.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /root/.bashrc
    rm go1.20.0.linux-amd64.tar.gz
  else
    # Check Go version
    GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    GO_MAJOR=$(echo $GO_VERSION | cut -d. -f1)
    GO_MINOR=$(echo $GO_VERSION | cut -d. -f2)
    
    if [ "$GO_MAJOR" -lt 1 ] || ([ "$GO_MAJOR" -eq 1 ] && [ "$GO_MINOR" -lt 18 ]); then
      echo -e "${YELLOW}Upgrading Go to version 1.20...${NC}"
      wget https://golang.org/dl/go1.20.0.linux-amd64.tar.gz
      rm -rf /usr/local/go
      tar -C /usr/local -xzf go1.20.0.linux-amd64.tar.gz
      export PATH=$PATH:/usr/local/go/bin
      rm go1.20.0.linux-amd64.tar.gz
    fi
  fi
  
  # Check if Rust is installed
  if ! command -v rustc &> /dev/null; then
    echo -e "${YELLOW}Installing Rust...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    echo 'source $HOME/.cargo/env' >> /root/.bashrc
  fi
  
  # Install Risc0 Toolchain
  echo -e "${YELLOW}Installing Risc0 Toolchain...${NC}"
  curl -L https://risczero.com/install | bash
  source ~/.bashrc
  
  # Use rzup command if available, or warn if not
  if command -v rzup &> /dev/null; then
    rzup install
  else
    echo -e "${YELLOW}Warning: rzup command not found. You may need to restart your terminal and run 'rzup install' manually.${NC}"
    echo -e "${YELLOW}Continuing with installation...${NC}"
  fi
  
  # Verify installations
  export PATH=$PATH:/usr/local/go/bin
  GO_VERSION=$(go version)
  echo -e "${GREEN}Go version: ${GO_VERSION} installed successfully${NC}"
  
  RUST_VERSION=$(rustc --version)
  echo -e "${GREEN}Rust version: ${RUST_VERSION} installed successfully${NC}"
  
  echo -e "${GREEN}Dependencies installed successfully${NC}"
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
    exit 1
  fi
  
  if [ ! -f "main.go" ]; then
    echo -e "${RED}Warning: main.go not found in the repository root.${NC}"
    echo -e "${YELLOW}Build process might not work as expected.${NC}"
  fi
  
  # Setup .env file
  echo -e "${YELLOW}Creating .env file...${NC}"
  cat > .env << EOF
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
# Alternatively:
# ZK_PROVER_URL=https://layeredge.mintair.xyz/
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
  
  # Determine the best way to run the Merkle service
  if [ -f "/root/light-node/risc0-merkle-service/run_merkle_tree.sh" ]; then
    MERKLE_EXEC_CMD="/bin/bash /root/light-node/risc0-merkle-service/run_merkle_tree.sh"
  else
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
RestartSec=10
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
  
  echo -e "${GREEN}Merkle Service systemd service created and started successfully!${NC}"
  
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