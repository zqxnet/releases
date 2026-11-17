# zqx CLI reference

`zqx` is the command-line client of a ZQX node. It sends each command to the local `zqxd` daemon. The daemon does the work: it talks to the controller and to the peers.

## Find the daemon

`zqx` finds the daemon in this order:

1. The `--socket <path>` option.
2. The `ZQX_SOCKET` environment variable.
3. `$HOME/.zqx/zqxd.sock`, if it exists. A daemon that runs as your user listens here.
4. `/var/run/zqx/zqxd.sock`, if it exists. A daemon that runs as root listens here: the macOS package and the Linux service.
5. `$HOME/.zqx/zqxd.sock`. When no daemon runs, `zqx` starts one there.

`zqx` never uses a directory that all users can write to, such as `/tmp`.

On Windows, `zqx` and the service use a protected named pipe. Refer to the [installation guide](installation.md#windows). Usually you do not need `--socket`.

### Who can use the daemon

- **Read:** all local users can read a service's status with no `sudo`: `status`, `peers`, `ip`, `ping`, `netcheck`, `dns status`.
- **Change:** `up`, `down`, `share`, `forward` and profile commands need root, or the operator group: `zqx` on Linux, `admin` on macOS, Administrators on Windows.
- **When a change is refused,** `zqx` tells you the command that an administrator runs to add you to the group.

## Commands

| Command | What it does |
| --- | --- |
| [`zqx up`](#zqx-up) | Connect to a controller and join the fabric |
| [`zqx down`](#zqx-down) | Disconnect from the fabric |
| [`zqx status`](#zqx-status) | Show the state of this node |
| [`zqx peers`](#zqx-peers) | List the peers |
| [`zqx ping`](#zqx-ping) | Ping a peer over the fabric |
| [`zqx netcheck`](#zqx-netcheck) | Check UDP, STUN, the relay and the NAT mapping |
| [`zqx ip`](#zqx-ip) | Show the fabric IP of this node |
| [`zqx tag`](#zqx-tag) | Show the tags of this node |
| [`zqx share`](#zqx-share) | Publish a local port as a service on the fabric |
| [`zqx forward`](#zqx-forward) | Forward a local TCP port to a service on the fabric |
| [`zqx apps`](#zqx-apps) | List the services on the fabric |
| [`zqx test-access`](#zqx-test-access) | Test an access request against the local rules |
| [`zqx dns`](#zqx-dns) | Show fabric DNS, or resolve a name |
| [`zqx service`](#zqx-service) | Install, start, stop or remove the background service |
| [`zqx daemon`](#zqx-daemon) | Run the daemon in the foreground |

**Options for all commands:** `-s, --socket <path>` (the daemon's socket), `-h, --help`, `-V, --version`.

**JSON output:** `zqx status`, `zqx peers`, `zqx apps`, `zqx tag` and `zqx test-access` accept `--json`.

**Exit status:** `0` when the command succeeds, `1` when it fails. `zqx ping` exits with `1` when no ping gets a reply.

### `zqx up`

Connect to a controller and join the fabric. The daemon keeps the settings. After a restart, it connects again automatically.

```bash
zqx up --server console.zqxnet.com --auth-key <key>
```

| Option | Environment | Meaning |
| --- | --- | --- |
| `--server <address>` | `ZQX_SERVER` | The controller. `console.zqxnet.com` is the hosted controller. |
| `--auth-key <key>` (alias `--auth-token`) | `ZQX_AUTH_TOKEN` | The pre-auth key from the console. A key of the form `<key>.<coordinator node ID>` also pins the controller. |
| `--hostname <name>` | `ZQX_NAME` | The node name. The default is the host name. |
| `--identity <identity>` | `ZQX_IDENTITY` | The identity claim (for example `alice@corp`). |
| `--ephemeral[=true\|false]` | `ZQX_EPHEMERAL` | Mark the device as short-lived (for example a CI runner or a container). The daemon keeps this setting. It accepts `true`, `false`, `1`, `0`, `yes` and `no`. The controller removes an ephemeral device when it leaves (`zqx down`), or when it stays offline longer than the xnet's timeout (10 minutes by default; set it in the console under **Keys & settings**). |

**Device approval:** if the xnet needs approval for new devices, the device waits with no access until an Owner or Admin approves it.

- `zqx up` prints "Waiting for an administrator to approve this device in the console", then waits. On approval it prints the fabric address, and exits with status 0. On rejection, or when the wait runs out, it prints why, and exits with status 1.
- Ctrl-C stops waiting in the terminal. The device keeps waiting, and connects by itself once approved.
- `zqx status` shows "Waiting for approval", and when the wait ends.
- A rejected device, or one not approved in time, needs a new key. A key marked pre-approved skips approval.

### `zqx down`

Disconnect from the fabric. The node keeps its identity. `zqx up` connects it again.

On an ephemeral device, `zqx down` leaves the fabric for good: the controller removes the device at once, and joining again needs a new key. A daemon with no saved state (`--state mem:`) also leaves when it stops.

### `zqx status`

Show the state of this node, then the peers that it uses.

```text
=== zqx Node Status ===
Backend State:       Running
Node ID:             4f2a91c07e5d38b6a1c29e047d5f8b3a6e1c92d40b7a5e18
Name:                dana-laptop
Overlay IP:          100.64.0.12
Controller:          203.0.113.10:443
Transport:           QUIC (UDP)
Key Exchange:        X25519MLKEM768 (hybrid post-quantum)
Virtual Adapter:     Active (utun11)
State Protection:    Sealed (System keychain)

Fabric Peers:
  * db-1                 -> 100.64.0.20     online, direct
```

- `State Problem:` and `DNS Problem:` lines show a problem and its fix, when there is one.
- In a large xnet, the peer list shows only the peers in use, and a count of the others.

### `zqx peers`

List the peers. There is one row for each peer: node ID, name, endpoint, fabric IP, tags, services and status.

**The status column:**
- The controller's view, and this device's own view of the connection. Examples: "online, direct", "online, relay", "offline, last seen 5m ago", "connected (relay), no controller session for 5m".
- `ephemeral` marks a short-lived device.
- In a large xnet (more peers than `ZQX_ON_DEMAND_PEERS`, default 2,000), this device holds details only for the peers that it uses. The other peers show the status "not in use". This device gets their details and status when it connects to them.

With `--json`, a peer that is not in use has `"listed": true` and an empty `id`.

### `zqx ping`

Ping a peer over the fabric. The output shows the round-trip time and the path: direct, or through the relay.

```bash
zqx ping <name, fabric IP or node ID>
```

| Option | Meaning |
| --- | --- |
| `-c, --count <n>` | The number of pings (default 4) |
| `--until-direct` | Stop when the connection is direct |
| `-v, --verbose` | Show the time for each hop through the relay |

```text
pong from node2 (100.64.0.3) via 203.0.113.7:24310 in 16ms [X25519MLKEM768]
no reply: no reply from node2 within 2.5 s
pong from node2 (100.64.0.3) via 203.0.113.7:24310 in 14ms [X25519MLKEM768]
3 sent, 2 received
```

- The peer's `zqxd` (or `zqxnet` app) answers each ping. `zqx ping` counts a reply only when that answer arrives. Thus the times and the losses are real.
- `zqx ping` works to all peers, with or without a virtual adapter. It also works from a device without one.
- It exits with status `1` when no ping gets a reply. You can use it as a health check: `zqx ping -c 1 db-1 || exit 1`.

**The OS `ping`:**
- From a device with the virtual adapter, `ping <peer>` reaches all peers.
- A peer with the adapter replies from its operating system.
- A peer without it replies from its daemon, if the access rules permit ICMP from you (`proto:icmp` or `proto:any`).
- A device without the adapter has no route to the fabric. Use `zqx ping` there.

### `zqx netcheck`

Check the network: UDP, TLS over TCP 443, the STUN server and the relay. The report includes the NAT mapping of the peer port, measured from the peer socket.

```text
  * UDP:               true
  * TCP 443 (TLS):     true (649ms)
  * NAT Mapping:       Port-changing (peer port 24310 appears as 51877)
  * Public Endpoint:   198.51.100.23:51877
  * STUN Server:       203.0.113.10:443 (210ms)
```

### `zqx ip`

Show the fabric IP of this node, for example `100.64.0.3`.

### `zqx tag`

Show the tags of this node.

```bash
zqx tag
zqx tag --json
```

The controller assigns the tags: from the pre-auth key that admitted the device, or in the console. A device cannot set its own tags. To change them, edit the device in the console.

### `zqx share`

Publish a local port as a named service on the fabric.

```bash
zqx share 8080 --name web
```

| Option | Meaning |
| --- | --- |
| `-n, --name <name>` | The service name (default `app-<port>`) |
| `--host <host>` | The target host (default `127.0.0.1`) |
| `--proto <tcp\|udp>` | The protocol (default `tcp`) |
| `--tags <tags>` | Service tags, separated by commas |

Peers see a shared service when this device joins again.

### `zqx forward`

Forward a local TCP port to a service on the fabric.

```bash
zqx forward 28080 web 8080    # 127.0.0.1:28080 goes to port 8080 of "web"
```

### `zqx apps`

List the services that the peers publish: service, gateway, endpoint, target and protocol.

### `zqx test-access`

Test an access request against the access rules of this node. The command shows the result (`PERMITTED` or `DENIED`) and the reason.

```bash
zqx test-access --identity alice@corp --target 127.0.0.1 --port 5432
```

| Option | Meaning |
| --- | --- |
| `-i, --identity <identity>` | The caller identity |
| `-t, --target <host>` | The target host or IP |
| `-p, --port <port>` | The target port |
| `--proto <tcp\|udp>` | The protocol (default `tcp`) |
| `--caller-tags <tags>` | The caller's tags, separated by commas |
| `--target-tags <tags>` | The target's tags, separated by commas |

### `zqx dns`

| Command | What it does |
| --- | --- |
| `zqx dns status` | Show the xnet domain, the resolver and the names that it knows |
| `zqx dns resolve <name>` | Resolve a name through the daemon (for example `db-1` or `db-1.acme.zqxnode.com`) |

### `zqx service`

Manage the background service. The actions are different on each platform.

| Action | Windows (service `ZQXD`) | Linux (systemd unit `zqxd`) |
| --- | --- | --- |
| `install` | Registers and starts the service | Shows how to make the unit. Refer to the [installation guide](installation.md#run-zqxd-as-a-systemd-service). |
| `start`, `stop`, `status` | Starts, stops or shows the service | Runs `systemctl start`, `stop` or `status` |
| `uninstall` | Stops and removes the service | Not available |

- On Windows, run `install` and `uninstall` from an elevated PowerShell.
- On macOS, `zqx service` does not work. Use `launchctl` with `system/com.zqxnet.zqxd`, or the package's `zqx-uninstall`.

### `zqx daemon`

Run the daemon in the foreground (all-in-one distribution). The options are the same as `zqxd`. The most used options are in the table.

| Option | Environment | Meaning |
| --- | --- | --- |
| `-s, --server <address>` | `ZQX_SERVER` | The controller |
| `--auth-token <key>` | `ZQX_AUTH_TOKEN` | The pre-auth key |
| `-l, --listen <address>` | `ZQX_LISTEN` | The UDP address for peer connections. Without it, the daemon selects a random port from 20000 to 32767 and keeps it. |
| `--state <path\|auto\|mem:>` | `ZQX_STATE` | The state file. `auto` is the system default. `mem:` keeps the state in memory only. |
| `--tun <true\|false>` | | Use the virtual adapter |
| `--socks-port <port>` | | The local SOCKS5 proxy (default 1080, `0` disables it) |
| `--coordinator-key <node ID>` | `ZQX_COORDINATOR_KEY` | Pin the controller's key |

## Controller pinning

Each node has a persistent hybrid identity in its state file:
- a classical key (Ed25519, or ECDSA P-256);
- an ML-DSA-65 key.

The node ID (48 hex characters) is a hash of both public keys. Thus a connection to a node by its ID pins both keys. Each connection proves both keys: the TLS handshake signs with the classical key, then each side signs the session with its ML-DSA-65 key.

Nodes also pin the controller's key, in one of these ways:

| How | Example |
| :--- | :--- |
| Option or environment | `zqxd --server coord.example.com:443 --coordinator-key <coordinator node ID>` (`ZQX_COORDINATOR_KEY`) |
| Pre-auth key suffix | `zqx up --auth-key <key>.<coordinator node ID>` |
| First use | With neither, the node pins the first controller that it reaches, and saves it in the state file. |

The node refuses a controller with a different key. The controller shows its node ID at startup (`Coordinator node ID: …`).

## Sealed state

The state file holds the node keys, the pre-auth key and the controller pins. A key that only this machine can unseal encrypts it. This is on by default, with no setup.

| Platform | Sealed with |
| :--- | :--- |
| Linux | `systemd-creds`: the TPM 2.0 and the host credential key when the TPM works (this needs the `libtss2` libraries), or the host key only (`/var/lib/systemd/credential.secret`, root only) |
| macOS | The System keychain (the root LaunchDaemon), through Apple's `security` tool. Thus later ZQX builds can read it after an upgrade. |
| Windows | A non-exportable key in the TPM (Platform Crypto Provider), or DPAPI with the machine key |

- `zqxd` unseals the key one time, when it starts.
- A copy of the state file is not usable on a different machine.
- `zqx status` shows the protection (for example `State Protection: Sealed (System keychain)`).
- A plain state file from an earlier release becomes sealed when `zqxd` starts. The node keeps its identity.

`ZQX_STATE_SEAL` sets the behaviour:

| Value | Behaviour |
| :--- | :--- |
| `auto` (default) | Seal where a TPM or a keystore is available. If not, keep a plain file that only the owner can read. |
| `require` | Do not start without a TPM or a keystore. |
| `off` | Keep a plain file that only the owner can read. |

A `zqxd` that a user runs (not root, SYSTEM or the LaunchDaemon) keeps a plain file. So do containers without `systemd-creds`.

**If `zqxd` cannot unseal the state:** this can occur after a TPM reset, a keychain reset, a disk moved to a different machine, or a new OS installation.
1. `zqxd` keeps the file as `<state>.unsealable-<unix time>`. Each time it uses a new name, so it overwrites nothing.
2. It starts with a new identity.
3. `zqx status` (`State Problem:`) and the tray tell you.
4. Join again with `zqx up --auth-key <key>`, or from the tray. The message goes away when the controller admits the node.

An upgrade keeps the sealed state and the identity of the node. There is one exception: a Mac that upgrades from v0.5.3 or earlier. Only the build that wrote its state key can read it, so the Mac joins again one time, with a new identity.

## Fabric names

Devices have the name `<device>.<xnet domain>`, for example `dana-laptop.acme-labs.zqxnode.com`. The short name `<device>` also works. Services have the name `<service>.<device>.<xnet domain>`.

**With the virtual adapter:**
- The operating system sends names in the xnet's domain, and only those names, to the fabric resolver `100.100.100.53`.
- `zqxd` answers on the adapter itself. Thus it opens no DNS socket, and nothing else on the machine can collide with it.
- It answers A records and reverse lookups for fabric addresses. For other record types, it answers "no data".

The resolver settings on each platform:

| Platform | Settings |
| :--- | :--- |
| macOS | `/etc/resolver/<domain>`, and a supplemental DNS entry (`scutil`) that also makes short names work |
| Linux | `resolvectl dns`, `domain` and `default-route false` on the adapter (systemd-resolved) |
| Windows | An NRPT rule for `.<domain>`, and the DNS suffix of the adapter. The machine-wide suffix list does not change. |

- The settings follow the xnet's domain. `zqxd` removes them when the adapter stops.
- `zqxd` removes settings from earlier releases (`.zqx`, `.internal`, `127.0.0.1:5353`).
- A few seconds after a change, `zqxd` checks that the OS resolves the device's own name. If it does not, `zqx status` shows `DNS Problem:` with the fix. `zqx dns status` and the menu bar show it too.

**Without the virtual adapter** (`--tun false`, containers, the `zqxnet` SDK), fabric names resolve only in ZQX: through the SOCKS proxy and the SDK.

## Related documents

- [Installation guide](installation.md)
