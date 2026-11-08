<div align="center">
  <img src="assets/zqx-logo.svg" alt="ZQX Logo" width="360">
  <br>
  <br>
  <p><strong>Zero Trust. Quantum Safe. Universal eXchange.</strong></p>
</div>

[ZQX](https://zqxnet.com) is a zero-trust fabric overlay network that connects your devices, servers, and cloud workloads securely from anywhere, with hybrid post-quantum cryptography by default.

This repository hosts **official ZQX binary installers, portable packages, and user documentation**. To manage your network, users, and access control policies, sign in to the ZQX Console at [**console.zqxnet.com**](https://console.zqxnet.com).

---

## Downloads & Installation

Pre-built signed installers and packages for Windows, macOS, and Linux are available on the [**Releases Page**](https://github.com/zqxnet/releases/releases/latest):

| Platform | Download | Description |
| :--- | :--- | :--- |
| **Windows (Installer)** | [**`zqx-setup-x86_64.exe`**](https://github.com/zqxnet/releases/releases/latest/download/zqx-setup-x86_64.exe) | Standalone Windows Setup Wizard & Silent Enterprise Installer (System Tray, Service, CLI, Wintun) |
| **Windows (Portable)** | [**`zqx-windows-x86_64.zip`**](https://github.com/zqxnet/releases/releases/latest/download/zqx-windows-x86_64.zip) | Portable zip archive: System Tray App (`zqx-tray.exe`), Windows Service, CLI, & Wintun L3 Driver |
| **macOS (Installer)** | [**`zqx-macos-arm64.pkg`**](https://github.com/zqxnet/releases/releases/latest/download/zqx-macos-arm64.pkg) | Apple Installer Package: installs `ZQX.app` and symlinks CLI to `/usr/local/bin` |
| **macOS (Disk Image)** | [**`zqx-macos-arm64.dmg`**](https://github.com/zqxnet/releases/releases/latest/download/zqx-macos-arm64.dmg) | Drag-and-drop Disk Image for easy installation into `/Applications` |
| **macOS (App Bundle)** | [**`zqx-macos-arm64-app.zip`**](https://github.com/zqxnet/releases/releases/latest/download/zqx-macos-arm64-app.zip) | Portable SwiftUI Menu Bar application bundle (`ZQX.app`) |
| **macOS (CLI)** | [**`zqx-macos-arm64.tar.gz`**](https://github.com/zqxnet/releases/releases/latest/download/zqx-macos-arm64.tar.gz) | Headless command-line binaries (`zqx`, `zqxd`, `zqx-stir`) |
| **Linux** | [**`zqx-linux-amd64.tar.gz`**](https://github.com/zqxnet/releases/releases/latest/download/zqx-linux-amd64.tar.gz) | Standalone x86_64 binaries (`zqx`, `zqxd`, `zqx-stir`) |

See the [**Installation & Deployment Guide**](docs/installation.md) and [**CLI Reference**](docs/cli-reference.md) for enterprise rollout and systemd setup.

---

## Quickstart

### 1. Connect to your ZQX network

Connect interactively using your browser:

```bash
zqx up
```

Or enroll a headless server or CI/CD worker using a pre-authentication key:

```bash
zqx up --auth-key zqx_key_...
```

### 2. Check status & peers

```bash
zqx status
zqx peers
zqx ping <peer-name-or-ip>
zqx netcheck
```

---

## Plans & Licensing

ZQX software is proprietary and available under free and commercial plans metered primarily by **users**—with unlimited personal devices:

| Plan | Users | Coordination Plane | Key Features |
| :--- | :--- | :--- | :--- |
| **Personal** | **Free up to 10 users** | ZQX Hosted Cloud (`console.zqxnet.com`) | Hybrid Post-Quantum Crypto (`X25519 + ML-KEM-768` & `ML-DSA-65`), MagicDNS, unlimited user devices |
| **Starter** | Per user / month | ZQX Hosted Cloud | Team SSO, granular ACL policies, MagicDNS |
| **Premium** | Per user / month | ZQX Hosted Cloud | Category-5 Strict PQC (`ML-KEM-1024` / `ML-DSA-87`), SIEM audit log streaming, cross-xnet sharing |
| **Enterprise** | Per user + **per coordinator** | **Self-Hosted Coordinators** + Hosted Cloud | Sovereign / on-prem / air-gapped coordination servers (14-day built-in evaluation mode), 100G throughput, custom SLA |

See [LICENSE](LICENSE) for full End-User License Agreement terms. For Enterprise coordinator licensing, contact [sales@zqxnet.com](mailto:sales@zqxnet.com).
