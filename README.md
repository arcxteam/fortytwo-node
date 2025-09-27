# Fortytwo Node Operator FOR Inference with CPU Mode

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
sudo apt update && sudo apt upgrade -y &&
sudo apt install -y \
automake autoconf build-essential clang curl \
gcc git htop iptables jq libatomic1 libblas3 libclang-dev \
libgbm1 liblapack3 liblapack-dev libleveldb-dev libomp-dev \
libopenblas-dev libgomp1 libopenmpi-dev libssl-dev lz4 make nano \
ncdu ninja-build nvme-cli pkg-config \
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
wget https://raw.githubusercontent.com/arcxteam/fortytwo-node/refs/heads/main/.p2p_known_peers.json
```

### Redirect Installation Script or Cloning Repo
```bash
wget https://raw.githubusercontent.com/arcxteam/fortytwo-node/refs/heads/main/linux.sh
```

### Create a screen & Running Operator
```bash
screen -S fortytwo
```
```bash
chmod +x linux.sh && ./linux.sh
```
- Test with default **MODEL NO.22** `Qwen3 1.7B Q4` but **I'm recommended use custom model**
- Back to main root ~/ `Ctrl + A + D`

```
# back to screen log
screen -r fortytwo
```

> Note; After installation, the FortyTwo console application be ready run. **If not yet received 42T after a few minutes or hourly.. check your logs, if get like here**

- INFO Request 41d89c4b5b394015179749b91b525a75d6327cb049f5aa3239caa2dd3dae569d <mark>has too short deadline to fit. Required speed: 0.001164882414882415. Max: 0.001</mark>
- INFO Remaining join duration for Inference Join state: 4982 ms
- INFO Request d06dc0566a9fac84ab6539b7554f6605c593962fe2365cbc84918efbf06a4b11 <mark>has too short deadline to fit. Required speed: 0.001233404909875498. Max: 0.001</mark>

#### Solutions
- The VPServer need faster for complete any Task Inference, RAM 2GB-8GB so cool
- Need check activate on AVX2/AVX or use another low-parameter LLModel visit [Huggingface](https://huggingface.co/models?pipeline_tag=text-generation&num_parameters=min:0,max:6B&library=gguf&apps=llama.cpp&other=text-generation-inference&sort=trending)
- A list custom-parameter GGUF LLModels for Text, Code & Math https://arcxteam.github.io/fortytwo-node/llmodel.html

---

## Error Cause & Custom LLModel
The script downloaded `FortytwoCapsule-linux-amd64-cuda124` (GPU version), which requires CUDA libraries `libcuda.so.1`. On CPU-only servers without NVIDIA drivers, this library is missing, causing the load failure.

### Why It Happened
- Got it <mark>libcuda.so.1</mark> redownload capsule & got like this <mark>rust_backtrace=1/full/0</mark> try another model this issue by fortytwo capsule `llm_model.rs:315` `llama.cpp`
- Script detects no `nvidia-smi` and selects CPU binary (correct)
- But download URL appends `-cuda124` for GPU, even in "CPU" branch—likely a script bug (non-existent CPU file defaults to GPU)

### Fix
1. **Manual Download Capsule & Replace**:
   ```bash
   cd ~/Fortytwo/fortytwo-console-app-main/FortytwoNode
   rm -f FortytwoCapsule # remove&redownload
   wget "https://fortytwo-network-public.s3.us-east-2.amazonaws.com/capsule/v$(curl -s https://fortytwo-network-public.s3.us-east-2.amazonaws.com/capsule/latest)/FortytwoCapsule-linux-amd64" -O FortytwoCapsule
   chmod +x FortytwoCapsule
   ```

2. **Rerun Script**:
   ```bash
   cd ~/Fortytwo/fortytwo-console-app-main
   rm linux.sh
   wget https://raw.githubusercontent.com/arcxteam/fortytwo-node/refs/heads/main/linux.sh
   chmod +x linux.sh && ./linux.sh
   ```

3. **Another Custom Model GGUF**
   - Costum model by import plz `select 1`
   - Need use `LLM_HF_REPO` and `LLM_HF_MODEL_NAME`
   - Visit [Huggingface](https://huggingface.co/models?pipeline_tag=text-generation&num_parameters=min:0,max:6B&library=gguf&apps=llama.cpp&other=text-generation-inference&sort=trending)
   - Check repo file model need a parameter key is `GGUF` & `llama.cpp`
   - Select low LLModel medium at 1GB-3GB file and use token `0.5B-3B` with quantity param `Q3_K_M` or `Q4_K_M` or `Q5_K_M`
   - A list custom-parameter GGUF LLModels for Text, Code & Math https://arcxteam.github.io/fortytwo-node/llmodel.html

   Example my custom LLModel

   ```bash
   LLM_HF_REPO="unsloth/DeepSeek-R1-Distill-Qwen-1.5B-GGUF"
   LLM_HF_MODEL_NAME="DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf"
   NODE_NAME="⬢ MATH EQUATIONS & REASONING: DeepSeek-R1-Distill-Qwen-1.5B Q4"
   ```
     <img width="919" height="210" alt="image" src="https://github.com/user-attachments/assets/449fa513-7a5c-43f0-8dfb-3a1c30d9d4f6" />
  
### Notes
- Official docs require NVIDIA GPU; CPU support may be limited/slower.
- If fails again, edit script: Remove `+="-cuda124"` in download sections.
