# zqx CLI Reference

The `zqx` command-line tool is used to interact with and manage your zqx fabric network node. It communicates with the `zqxd` daemon via a local Unix socket.

## Overview

`zqx` provides commands to:
- View node status and peer information
- Test connectivity with ping
- Measure network throughput with speedtest
- Monitor the fabric network

The tool automatically detects the control socket location, so you typically don't need to specify connection details.

## Socket Detection

The `zqx` tool automatically finds the `zqxd` control socket using the following priority:

1. **`ZQX_SOCKET` environment variable** (highest priority)
2. **`~/.zqx/zqxd.sock`** (user home directory)
3. **`/var/run/zqx/zqxd.sock`** (system-wide location)
4. **`/tmp/zqxd.sock`** (temporary location, common in containers)

The socket path can be manually specified with `--socket`, but this is typically not needed.

## Commands

### `zqx status`

Display the current status of your zqx node and all connected peers.

**Usage:**
```bash
zqx status
```

**Output:**
```
NAME                 IP                   STATUS             ID
----                 --                   ------             --
mynode               100.64.0.2           online (self)      a1b2c3d4
node2                100.64.0.3           online             e5f6g7h8
node3                100.64.0.4           offline            i9j0k1l2
```

**Fields:**
- **NAME**: Node name
- **IP**: Fabric network IP address (from 100.64.0.0/10 range)
- **STATUS**: Connection status (`online` or `offline`). Your own node shows `online (self)`
- **ID**: Short node identifier (first 8 characters of full ID)

**JSON Output:**
```bash
zqx status --json
```

Returns structured JSON data with node and peer information.

---

### `zqx peers`

List all peers in the fabric network. This is similar to `zqx status` but focuses on peer information.

**Usage:**
```bash
zqx peers
```

**Output:**
Same format as `zqx status`, showing all peers in the network.

**JSON Output:**
```bash
zqx peers --json
```

---

### `zqx ping [target]`

Send ICMP-like ping packets to a peer to test connectivity and measure round-trip time (RTT).

**Usage:**
```bash
zqx ping <target>
```

**Arguments:**
- `<target>`: Peer to ping, specified by:
  - Node name (e.g., `node2`)
  - IP address (e.g., `100.64.0.3`)
  - IPv4 or IPv6 format

**Options:**
- `-c, --count <number>`: Number of ping packets to send (default: 4)

**Examples:**
```bash
# Ping a peer by name
zqx ping node2

# Ping a peer by IP address
zqx ping 100.64.0.3

# Send 10 ping packets
zqx ping node2 --count 10

# Short form
zqx ping node2 -c 10
```

**Output:**
```
PING node2 (100.64.0.3)
RTT: 1.234ms
RTT: 1.189ms
RTT: 1.201ms
RTT: 1.198ms

--- node2 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss
Average RTT: 1.206ms
```

**How it works:**
- Sends custom ping packets over QUIC tunnels (not ICMP)
- Each packet includes a sequence number and timestamp
- The peer responds with a pong packet
- RTT is calculated from the round-trip time
- Results show individual RTT values and statistics

**JSON Output:**
```bash
zqx ping node2 --json
```

Returns structured JSON with RTT measurements and packet loss statistics.

---

### `zqx speedtest [target]`

Measure network throughput (bandwidth) to a peer over the QUIC tunnel.

**Usage:**
```bash
zqx speedtest <target>
```

**Arguments:**
- `<target>`: Peer to test, specified by:
  - Node name (e.g., `node2`)
  - IP address (e.g., `100.64.0.3`)

**Options:**
- `-d, --duration <seconds>`: Test duration in seconds (default: 10)
- `-D, --direction <direction>`: Test direction: `upload`, `download`, or `both` (default: `both`)

**Examples:**
```bash
# Test both upload and download for 10 seconds (default)
zqx speedtest node2

# Test upload only for 5 seconds
zqx speedtest node2 -d 5 -D upload

# Test download only for 15 seconds
zqx speedtest node2 --duration 15 --direction download

# Short form
zqx speedtest node2 -d 3 -D both
```

**Output:**
```
Speed test to node2 (100.64.0.3)
Duration: 10 seconds
Upload:   1973.66 Mbps (246.71 MB/s)
Download: 0.00 Mbps (0.00 MB/s)
Total:    1973.66 Mbps (246.71 MB/s)
```

**Fields:**
- **Upload**: Bandwidth when sending data to the peer (your upload speed)
- **Download**: Bandwidth when receiving data from the peer (your download speed)
- **Total**: Combined bandwidth (when testing both directions)

**How it works:**
- **Upload test**: Opens QUIC streams and sends 1MB data chunks continuously for the specified duration
- **Download test**: Currently not implemented (returns 0.00 Mbps)
- Measures actual bytes transferred over the QUIC tunnel
- Calculates throughput in both Mbps (megabits per second) and MB/s (megabytes per second)

**Note:** The speedtest runs synchronously and may take longer than the specified duration due to network overhead. The HTTP client timeout is set to 10 minutes for speedtest operations.

**JSON Output:**
```bash
zqx speedtest node2 --json
```

Returns structured JSON with speed measurements.

---

## Global Options

### `--json`

Output results in JSON format instead of human-readable text.

**Usage:**
```bash
zqx status --json
zqx ping node2 --json
zqx speedtest node2 --json
```

Useful for scripting and programmatic access to zqx data.

### `--socket <path>`

Manually specify the path to the `zqxd` control socket. This option is hidden from help output as it's rarely needed.

**Usage:**
```bash
zqx status --socket /custom/path/zqxd.sock
```

**Note:** The socket path is automatically detected in most cases. Only use this option if:
- The socket is in a non-standard location
- You're debugging socket connection issues
- You need to connect to a different `zqxd` instance

---

## Exit Codes

- `0`: Success
- `1`: Error (command failed, peer not found, etc.)

---

## Examples

### Basic Usage

```bash
# Check if zqxd is running and see status
zqx status

# List all peers
zqx peers

# Ping a peer to test connectivity
zqx ping node2

# Test network speed
zqx speedtest node2
```

### Advanced Usage

```bash
# Send 20 ping packets
zqx ping node2 -c 20

# Test upload speed for 30 seconds
zqx speedtest node2 -d 30 -D upload

# Get JSON output for scripting
zqx status --json | jq '.peers[] | select(.connected == true)'

# Use custom socket location
ZQX_SOCKET=/tmp/custom.sock zqx status
```

### Troubleshooting

```bash
# Check if zqxd is running
zqx status
# If this fails, zqxd may not be running or socket not found

# Test connectivity to a specific peer
zqx ping node2

# Measure actual throughput
zqx speedtest node2 -d 5
```

---

## Coordinator Pinning (`zqxd`)

Every node has a persistent hybrid identity in its state file: a classical key (Ed25519, or ECDSA P-256) and an ML-DSA-65 key. Its node ID (48 hex characters) is a hash of both public keys, so dialing a node by its ID pins both. Every connection proves both keys: the TLS handshake signs with the classical key, and each side then signs the session with its ML-DSA-65 key. Nodes also pin the coordinator's key:

| How | Example |
| :--- | :--- |
| Flag or environment | `zqxd --server coord.example.com:443 --coordinator-key <coordinator node ID>` (`ZQX_COORDINATOR_KEY`) |
| Auth key suffix | `zqxd --auth-key <key>.<coordinator node ID>` |
| First use | With neither, the first coordinator reached is pinned and saved in the state file. |

A coordinator presenting a different key is refused. The coordinator prints its node ID at startup (`Coordinator node ID: …`).

---

## Sealed State (`zqxd`)

The state file (node keys, auth token, coordinator pins) is encrypted with a key that only this machine can unseal. It's on by default and needs no setup:

| Platform | Sealed with |
| :--- | :--- |
| Linux | `systemd-creds`: the TPM 2.0 plus the host credential key when the TPM works (needs the `libtss2` libraries), else the host key alone (`/var/lib/systemd/credential.secret`, root only) |
| macOS | The System keychain (the root LaunchDaemon) |
| Windows | A non-exportable key in the TPM (Platform Crypto Provider), else DPAPI with the machine key |

The key is unsealed once when `zqxd` starts. A copy of the state file is useless on another machine. `zqx status` shows the protection in use (`State Protection: Sealed (TPM 2.0 and host key (systemd-creds))`). A plain state file from an earlier release is sealed on first start, and the node keeps its identity.

`ZQX_STATE_SEAL` sets the behaviour:

| Value | Behaviour |
| :--- | :--- |
| `auto` (default) | Seal wherever a TPM or keystore is available; otherwise keep the plain, owner-only file |
| `require` | Refuse to start without one |
| `off` | Plain, owner-only file |

A user-run `zqxd` (not root, SYSTEM or the LaunchDaemon) and containers without `systemd-creds` keep a plain file.

**If the state can't be unsealed** (TPM cleared, keychain reset, disk moved to another machine, OS reinstalled), `zqxd` keeps the file as `<state>.unsealable`, starts with a new identity and says so in `zqx status` (`State Problem:`) and the tray. Join again with `zqx up --auth-key <key>`, or from the tray.

---

## See Also

- [README.md](../README.md) - Project overview and architecture
- [zqxd documentation](../README.md#start-the-zqx-daemon-zqxd) - Daemon documentation

