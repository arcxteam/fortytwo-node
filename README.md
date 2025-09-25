# FortyTwo Network Node

This repository contains installation instructions and helper scripts for setting up the FortyTwo Network console application on Linux systems.

## 🚀 Installation Depedency & Update

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

### Cloning - Download and install the FortyTwo
```bash
git clone https://github.com/arcxteam/fortytwo-node.git
```

### Create a screen session
```bash
screen -S fortytwo
```

```bash
cd fortytwo-node
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

3. **Custom Model no.23**
   ```bash
   LLM_HF_REPO="prithivMLmods/palmyra-mini-thinking-AIO-GGUF"
   LLM_HF_MODEL_NAME="palmyra-mini-thinking-b.Q5_K_M.gguf"
   NODE_NAME="⬢ MATH EQUATIONS & REASONING: Palmyra-Mini-Thinking-B 1.78B Q5"
   ```

### Notes
- Official docs require NVIDIA GPU; CPU support may be limited/slower.
- If fails again, edit script: Remove `+="-cuda124"` in download sections.
