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
cd fortytwo-node
chmod +x install.sh && ./install.sh
```

After installation, the FortyTwo console application will be ready to use. You can detach from the screen session using `Ctrl+A+D` and reattach later using:

```
screen -r fortytwo
```
