# Zapret for Discord and YouTube (Fedora Linux Port)

This project is a port of the popular Windows `zapret-discord-youtube` DPI bypass repository, specifically adapted to work on Fedora Linux. It uses the original lists and `.bin` payloads, but replaces the Windows `winws.exe` and `WinDivert` setup with the Linux native `nfqws` and `iptables` (NFQUEUE).

> [!WARNING]
> This version is specifically built for **Fedora Linux**.

## ⚙️ Installation

1. **Clone the repository:**
   You can clone this repository anywhere you like. For example:
   ```bash
   git clone https://github.com/flowseal/zapret-discord-youtube.git
   cd zapret-discord-youtube
   ```

2. **Install dependencies and compile nfqws:**
   Run the installation script as root. This will use `dnf` to install the required development tools and libraries (`gcc`, `make`, `libnetfilter_queue-devel`, etc.), then clone the main `zapret` repository to compile the `nfqws` binary for Linux.
   ```bash
   sudo ./install.sh
   ```

## 🚀 Usage

You can run the bypass either manually or as a background service.

### Manual Run
Run the start script as root. It will automatically configure `iptables` rules to intercept traffic on the necessary ports and route it through `nfqws`.
```bash
sudo ./start.sh
```
To stop the bypass, simply press `Ctrl+C`. The script will automatically clean up the `iptables` rules upon exit.

### Run as a Systemd Service (Background / Auto-start)
If you want the bypass to run automatically in the background and start on boot, you can use the included setup script. This script will automatically create the systemd service file pointing to wherever you cloned the repository.

1. **Install and start the service:**
   ```bash
   sudo ./install_service.sh
   ```

2. **Check the status:**
   ```bash
   sudo systemctl status zapret-discord-youtube.service
   ```

## 🗒️ Customizing Lists

Just like the Windows version, you can modify the text files in the `lists/` directory to customize what gets bypassed.
- **`list-general-user.txt`**: Add your own domains here.
- **`list-exclude-user.txt`**: Exclude specific domains.
- **`ipset-exclude-user.txt`**: Exclude specific IPs.

*(Note: These user files are automatically created when you run `start.sh` for the first time if they don't already exist.)*

## ⚖️ Licensing
Distributed under the MIT License. Based on the original zapret project by bol-van.
