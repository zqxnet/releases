# ZQX Installation & Deployment Guide

This guide covers installing and deploying ZQX across Windows, macOS, and Linux.

---

## Windows Installation

### Option 1: Standalone Setup Wizard (Recommended)
Download the native setup executable from the [Releases Page](https://github.com/zqxnet/releases/releases/latest):
- File: `zqx-setup-x86_64.exe`

**Features:**
- Installs binaries (`zqx.exe`, `zqxd.exe`, `zqx-tray.exe`, `zqx-stir.exe`) and Wintun driver to `C:\Program Files\ZQX`.
- Adds `C:\Program Files\ZQX` to the system `PATH`.
- Registers and starts the Windows Service `ZQXD` with auto-restart on failure.
- Configures persistent state directory at `C:\ProgramData\ZQX`.
- Places Start Menu and Desktop shortcuts and launches the notification tray app `zqx-tray.exe`.

### Unattended Enterprise Silent Install
For deployment via Microsoft Intune, SCCM, or Group Policy:
```cmd
zqx-setup-x86_64.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
```

### Option 2: Portable Archive
Download `zqx-windows-x86_64.zip`, extract to any directory, and execute the automated PowerShell installer:
```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

---

## macOS Installation

### Option 1: Apple Installer Package (Recommended for Enterprise)
Download `zqx-macos-arm64.pkg` from the [Releases Page](https://github.com/zqxnet/releases/releases/latest).

- Double-click the `.pkg` file to run the Apple Installer wizard.
- Installs `ZQX.app` into `/Applications/`.
- Automatically symlinks CLI binaries (`zqx`, `zqxd`, `zqx-stir`) to `/usr/local/bin/`.
- Sets up system PATH support in `/etc/paths.d/zqx`.
- Launches the SwiftUI Menu Bar app.

**Command-line installation:**
```bash
sudo installer -pkg zqx-macos-arm64.pkg -target /
```

### Option 2: Drag-and-Drop Disk Image
Download `zqx-macos-arm64.dmg`:
- Open `zqx-macos-arm64.dmg`.
- Drag `ZQX.app` into the `Applications` folder.

### Option 3: Standalone CLI Binaries
Download `zqx-macos-arm64.tar.gz`, extract, and move binaries:
```bash
tar -xzf zqx-macos-arm64.tar.gz
sudo mv zqx zqxd zqx-stir /usr/local/bin/
```

### Uninstallation on macOS
```bash
sudo /Library/Application\ Support/ZQX/uninstall.sh
```

---

## Linux Installation

Download `zqx-linux-amd64.tar.gz` from the [Releases Page](https://github.com/zqxnet/releases/releases/latest):

```bash
tar -xzf zqx-linux-amd64.tar.gz
sudo mv zqx zqxd zqx-stir /usr/local/bin/
```

### Running as a Systemd Service
Create `/etc/systemd/system/zqxd.service`:

```ini
[Unit]
Description=ZQX Zero-Trust Fabric Network Daemon
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/zqxd --state auto
Restart=always
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now zqxd
```
