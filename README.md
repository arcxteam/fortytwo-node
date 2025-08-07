apt-get update && apt-get install -y curl unzip screen

# FortyTwo Network Node

This repository contains installation instructions and helper scripts for setting up the FortyTwo Network console application on Linux systems.

## 🚀 Quick Installation

Run the following commands to set up the FortyTwo console application:

### Cloning - Download and install the FortyTwo
```bash
git clone https://github.com/arcxteam/fortytwo-node.git
```

### Create a screen session
```
screen -S fortytwo
```
```
cd fortytwo-node
chmod +x install.sh && ./install.sh
```

<img width="1475" height="230" alt="image-08-07-2025_03_17_PM" src="https://github.com/user-attachments/assets/ae265d85-4825-4ec8-9761-02750c89b394" />


<img width="1530" height="800" alt="Desktop-screenshot-08-07-2025_02_53_PM" src="https://github.com/user-attachments/assets/ca9e6b1f-16a9-4315-98a8-269ec9eef1f6" />

After installation, the FortyTwo console application will be ready to use. You can detach from the screen session using `Ctrl+A+D` and reattach later using:

```
screen -r fortytwo
```
