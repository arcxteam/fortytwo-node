# Fortytwo Node Operator For Inference With CPU Mode

This repository contains installation instructions and helper scripts for setting up the FortyTwo Network console application on Linux systems.

## Get Realtime Node by Telegram Bot

Tool monitoring FortyTwo node operator in performs swarm model inference! Get a detail dashboard ranking, received token, daily report & tracking any transaction FOR 42Tokens in participant network

> Get bot here... https://greyscope.xyz/x/fortytwo 

Key Bot Features:
▪ Get real-time performs using etherscan APIs
▪ Get binding wallet maxi 2 EOA wallet address
▪ Get amount balances in MONAD, FOR 42Token and recent activity
▪ Get dashboard insights : Rank, Name, Win Rate, Rounds Won, Activity and Rewards
▪ Get notifications received FOR 42Token transactions
▪ Get notifications summary FOR daily accumulated token

Enjoy!! FOR swarm inferences

## Guides Install

### Update Services & Depedency

```bash
sudo apt update && sudo apt upgrade -y \
sudo apt install -y \
automake autoconf bsdmainutils build-essential clang curl \
gcc git htop iptables jq libatomic1 libblas3 libclang-dev \
libgbm1 liblapack3 liblapack-dev libleveldb-dev libomp-dev \
libopenblas-dev libopenmpi-dev libssl-dev lz4 make nano \
ncdu ninja-build nvme-cli ocl-icd-opencl-dev pkg-config \
python3-pip screen tar tmux unzip wget
```

### Create Folder
```bash
mkdir -p ~/Fortytwo && cd ~/Fortytwo
```

### Download Execute by Officially
```bash
curl -L -o fortytwo-console-app.zip https://github.com/Fortytwo-Network/fortytwo-console-app/archive/refs/heads/main.zip
unzip fortytwo-console-app.zip
cd fortytwo-console-app-main
# will delete official script linux.sh
rm linux.sh
```

### Use P2P a Peers Network (optional)
```bash
wget https://github.com/arcxteam/fortytwo-node/.p2p_known_peers.json
```

### Redirect installation script or Cloning repo
```bash
wget https://github.com/arcxteam/fortytwo-node/linux.sh
```

### Create a screen & Running Operator
```bash
screen -S fortytwo
```

```bash
chmod +x linux.sh && ./linux.sh
```

<img width="1475" height="230" alt="image-08-07-2025_03_17_PM" src="https://github.com/user-attachments/assets/ae265d85-4825-4ec8-9761-02750c89b394" />


<img width="1530" height="800" alt="Desktop-screenshot-08-07-2025_02_53_PM" src="https://github.com/user-attachments/assets/ca9e6b1f-16a9-4315-98a8-269ec9eef1f6" />

After installation, the FortyTwo console application will be ready to use.

```
screen -ls
screen -r fortytwo
```


### Error Cause
The script downloaded `FortytwoCapsule-linux-amd64-cuda124` (GPU version), which requires CUDA libraries (`libcuda.so.1`). On CPU-only servers without NVIDIA drivers, this library is missing, causing the load failure.

### Why It Happened
- Script detects no `nvidia-smi` and selects CPU binary (correct).
- But download URL appends `-cuda124` for GPU, even in "CPU" branch—likely a script bug (non-existent CPU file defaults to GPU).

### Fix
1. **Manual Download & Replace**:
   ```bash
   cd ~/Fortytwo/fortytwo-console-app-main/FortytwoNode
   rm -f FortytwoCapsule  # Remove broken binary
   wget "https://fortytwo-network-public.s3.us-east-2.amazonaws.com/capsule/v$(curl -s https://fortytwo-network-public.s3.us-east-2.amazonaws.com/capsule/latest)/FortytwoCapsule-linux-amd64" -O FortytwoCapsule
   chmod +x FortytwoCapsule
   ```

2. **Rerun Script**:
   ```bash
   cd ~/Fortytwo/fortytwo-console-app-main
   chmod +x linux.sh && ./linux.sh
   ```

3. **Another my Custom Model no.23**
   ```bash
   LLM_HF_REPO="prithivMLmods/palmyra-mini-thinking-AIO-GGUF"
   LLM_HF_MODEL_NAME="palmyra-mini-thinking-b.Q5_K_M.gguf"
   NODE_NAME="⬢ MATH EQUATIONS & REASONING: Palmyra-Mini-Thinking-B 1.78B Q5"
   ```

### Notes
- Official docs require NVIDIA GPU; CPU support may be limited/slower.
- If fails again, edit script: Remove `+="-cuda124"` in download sections.
