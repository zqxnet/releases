![ZQX](assets/zqx-logo.svg)

**Zero Trust. Quantum Safe. Universal eXchange.**

[ZQX](https://zqxnet.com) is a zero-trust fabric network. It connects your devices, servers and cloud workloads securely, from all locations.

- Each connection uses pinned mutual TLS 1.3 with the hybrid post-quantum `X25519MLKEM768` key exchange (X25519 and FIPS 203 ML-KEM-768).
- Devices connect directly when they can, and through a ZQX relay when they cannot.
- Access rules decide who can reach what. A request that no rule permits is refused.

This repository has the official ZQX installers, packages and user guides. To manage your network, users and access rules, sign in to the ZQX console at [console.zqxnet.com](https://console.zqxnet.com).

## Downloads

The installers and packages for Windows, macOS and Linux are on the [releases page](https://github.com/zqxnet/releases/releases/latest).

| Platform | Download | Contents |
| :--- | :--- | :--- |
| **Windows (installer)** | [`zqx-setup-x86_64.exe`](https://github.com/zqxnet/releases/releases/latest/download/zqx-setup-x86_64.exe) | Setup wizard and silent installer: tray app, service, CLI, Wintun |
| **Windows on ARM (installer)** | [`zqx-setup-arm64.exe`](https://github.com/zqxnet/releases/releases/latest/download/zqx-setup-arm64.exe) | The same installer, for ARM64 devices |
| **Windows (portable)** | [`zqx-windows-x86_64.zip`](https://github.com/zqxnet/releases/releases/latest/download/zqx-windows-x86_64.zip) | Zip archive: tray app (`zqx-tray.exe`), service, CLI, Wintun driver |
| **macOS (installer)** | [`zqx-macos-arm64.pkg`](https://github.com/zqxnet/releases/releases/latest/download/zqx-macos-arm64.pkg) | Installer package: `ZQX.app`, the `zqxd` LaunchDaemon (virtual adapter) and the CLI in `/usr/local/bin` |
| **macOS (disk image)** | [`zqx-macos-arm64.dmg`](https://github.com/zqxnet/releases/releases/latest/download/zqx-macos-arm64.dmg) | Disk image: drag `ZQX.app` into `/Applications` |
| **macOS (app)** | [`zqx-macos-arm64-app.zip`](https://github.com/zqxnet/releases/releases/latest/download/zqx-macos-arm64-app.zip) | The menu bar app bundle (`ZQX.app`) |
| **macOS (CLI)** | [`zqx-macos-arm64.tar.gz`](https://github.com/zqxnet/releases/releases/latest/download/zqx-macos-arm64.tar.gz) | Command-line binaries (`zqx`, `zqxd`, `zqx-stir`) |
| **Linux** | [`zqx-linux-amd64.tar.gz`](https://github.com/zqxnet/releases/releases/latest/download/zqx-linux-amd64.tar.gz) | x86_64 binaries (`zqx`, `zqxd`, `zqx-stir`) |

For the installation steps, refer to the [installation guide](docs/installation.md). For the commands, refer to the [CLI reference](docs/cli-reference.md).

## Quick start

### 1. Add a device to your network

1. In the console, click **Add device**.
2. Copy the command, and run it on the device. It looks like this:

   ```bash
   zqx up --server console.zqxnet.com --auth-key zqx_key_...
   ```

On Windows, you can also copy the command and select **Connect** from the ZQX tray icon.

### 2. Check the device and its peers

```bash
zqx status                      # this device
zqx peers                       # the other devices
zqx ping <peer name or IP>      # a ping over the network
zqx netcheck                    # UDP, the relay and the NAT
```

## Plans and licence

ZQX is proprietary software, with free and paid plans. The price is per **user**, with no limit on personal devices.

| Plan | Users | Coordinator | Main features |
| :--- | :--- | :--- | :--- |
| **Personal** | **Free, up to 10 users** | ZQX hosted (`console.zqxnet.com`) | Fabric DNS, no limit on user devices |
| **Starter** | Per user, per month | ZQX hosted | Team SSO, detailed access rules, Fabric DNS |
| **Premium** | Per user, per month | ZQX hosted | SIEM audit log streaming, sharing across xnets |
| **Enterprise** | Per user and **per coordinator** | **Self-hosted coordinators** and ZQX hosted | Sovereign, on-premises and air-gapped coordinators (14-day evaluation mode), 100G throughput, custom SLA |

For the full terms, refer to the [End-User License Agreement](LICENSE). For Enterprise coordinator licences, write to [sales@zqxnet.com](mailto:sales@zqxnet.com).
