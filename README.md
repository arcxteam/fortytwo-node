# Fortytwo Node Operator For Inference With CPU Mode

![banner](fortytwo.gif)

This repository contains installation instructions and helper scripts for setting up the FortyTwo Network console application on Linux systems

## 1. Get Realtime Node by Telegram Bot

Use tool-bot monitoring FortyTwo node operator in performs swarm model inference! Get a detail dashboard ranking, received token, daily report & tracking any transaction FOR 42Tokens in participant network

> **Got bot here...** https://greyscope.xyz/x/fortytwo

Key Bot Features:
 - Get real-time performs using etherscan APIs
 - Get binding wallet maximum 2 EOA wallet address
 - Get amount balances in MONAD, FOR 42Token and recent activity
 - Get dashboard insights : Rank, Name, Win Rate, Rounds Won, Activity and Rewards
 - Get notifications received FOR 42Token transactions
 - Get notifications summary FOR daily accumulated token

## 2. Installing Setup Node

### Update Services & Depedency

```bash
sudo apt update && sudo apt upgrade -y \
sudo apt install -y \
automake autoconf build-essential clang curl \
gcc git htop iptables jq libatomic1 libblas3 libclang-dev \
libgbm1 liblapack3 liblapack-dev libleveldb-dev libomp-dev \
libopenblas-dev libgomp1 libopenmpi-dev libssl-dev lz4 make nano \
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
- Back to main root ~/ `Ctrl + A + D`

```
# back to screen
screen -r fortytwo
```

> Note; After installation, the FortyTwo console application will be ready to use. **If you can't get received 42T after a few minutes or hourly..check logs if get like here**

- INFO Request 41d89c4b5b394015179749b91b525a75d6327cb049f5aa3239caa2dd3dae569d <mark>has too short deadline to fit. Required speed: 0.001164882414882415. Max: 0.001</mark>
- INFO Remaining join duration for Inference Join state: 4982 ms
- INFO Request d06dc0566a9fac84ab6539b7554f6605c593962fe2365cbc84918efbf06a4b11 <mark>has too short deadline to fit. Required speed: 0.001233404909875498. Max: 0.001</mark>

#### Solutions
- Ur server need faster for complete any Task Inference
- Need activate on AVX2 or use another low LLModel visit the Huggingface
- List LLModel check here https://github.com/arcxteam/fortytwo-node/blob/main/llmodel.py

---

## Error Cause & Custom LLModel
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
   rm linux.sh
   wget https://github.com/arcxteam/fortytwo-node/linux.sh
   chmod +x linux.sh && ./linux.sh
   ```

3. **Another my Custom Model No.23**
   - Costum model by import `select 1`
   - Need use `LLM_HF_REPO` and `LLM_HF_MODEL_NAME`
   - Visit `Huggingface`
   - Check file repo model need suppport parameter key is `GGUF`
   - Select low LLModel as medium 1GB-3GB use `Q5_K_M` or `Q4_K_M` or `Q3_K_M`
   
   Example my custom LLModel

   ```bash
   LLM_HF_REPO="prithivMLmods/palmyra-mini-thinking-AIO-GGUF"
   LLM_HF_MODEL_NAME="palmyra-mini-thinking-b.Q5_K_M.gguf"
   NODE_NAME="⬢ MATH EQUATIONS & REASONING: Palmyra-Mini-Thinking-B 1.78B Q5"
   ```

### Notes
- Official docs require NVIDIA GPU; CPU support may be limited/slower.
- If fails again, edit script: Remove `+="-cuda124"` in download sections.
