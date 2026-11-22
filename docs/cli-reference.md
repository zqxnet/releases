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

Copy the command from the console (**Add device**):

```bash
zqx up --auth-key <key>
```

The device asks ZQX (`fabric.zqxnet.com`) where your xnet's controllers are, and connects to them. A self-hosted controller takes its own address: `zqx up --server <controller address> --auth-key <key>`.

| Option | Environment | Meaning |
| --- | --- | --- |
| `--server <address>` | `ZQX_SERVER` | The controller. The default with a key is `fabric.zqxnet.com`: ZQX directs the device to its xnet's controllers. A self-hosted controller takes its own address. |
| `--auth-key <key>` (alias `--auth-token`) | `ZQX_AUTH_TOKEN` | The pre-auth key from the console. A key of the form `<key>.<controller node ID>` also pins the controller. |
| `--hostname <name>` | `ZQX_NAME` | The node name. The default is the host name. |
| `--identity <identity>` | `ZQX_IDENTITY` | The identity claim (for example `alice@corp`). |
| `--ephemeral[=true\|false]` | `ZQX_EPHEMERAL` | Mark the device as short-lived (for example a CI runner or a container). The daemon keeps this setting. It accepts `true`, `false`, `1`, `0`, `yes` and `no`. The controller removes an ephemeral device when it leaves (`zqx down`), or when it stays offline longer than the xnet's timeout (10 minutes by default; set it in the console under **Keys & settings**). |
| `--accept-dns[=true\|false]` | `ZQX_ACCEPT_DNS` | Use fabric names and the xnet's DNS settings through this machine's DNS. On by default. `--accept-dns=false` leaves the machine's DNS as it is, for example on a server with its own resolver. The daemon keeps this setting. The console shows the devices that turned it off. |

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
Controller Key:      9c41e0b27d6f53a8c1b04e92f7a3d65e08b1c4f29a7e3d50 (pinned)
Recovery Key:        5e8a2c71f04b93d6e1a7c2b80f4d9e36 (pinned)
Controller Set:      epoch 1, serial 1
                     Primary 9c41e0b27d6f53a8c1b04e92f7a3d65e08b1c4f29a7e3d50 at 203.0.113.10:443
Transport:           QUIC (UDP)
Key Exchange:        X25519MLKEM768 (hybrid post-quantum)
Virtual Adapter:     Active (utun11)
State Protection:    Sealed (System keychain)

Fabric Peers:
  * db-1                 -> 100.64.0.20     online, direct
```

- `Controller Key:` is the controller node ID that this node pins. Before the first connection it shows `not pinned yet`. Refer to [Controller pinning](#controller-pinning).
- `Recovery Key:` is the controller recovery key that this node pins, when it has one.
- `Controller Set:` shows the controllers of this node's xnet, when the controller sends a set: its epoch and serial, and each controller with its role and address. Refer to [Controller sets](#controller-sets).
- `State Problem:` and `DNS Problem:` lines show a problem and its fix, when there is one.
- In a large xnet, the peer list shows only the peers in use, and a count of the others.
- `Controller Session: none for 3h 10m; reconnecting` shows when this node has lost its controller session and is trying again. The time says how old the peer presence is: the peer list shows the presence from when the session ended.

### `zqx peers`

List the peers. There is one row for each peer: node ID, name, endpoint, fabric IP, tags, services and status.

**The status column:**
- The controller's view, and this device's own view of the connection. Examples: "online, direct", "online, relay", "offline, last seen 5m ago", "connected (relay), no controller session for 5m".
- "online, idle": the peer is online, and this device has no connection to it now. A connection starts when something uses the peer, and usually goes direct in under a second.
- "direct (LAN)": the direct path uses the peer's local network address. Two devices on one network find it even when their router cannot send traffic back into its own network. Each device tells its LAN addresses only to the peer, inside the encrypted connection: the controller never sees them. `ZQX_LAN_CANDIDATES=off` stops a device from sending them.
- "direct, not answering": the direct path has not answered its probes for more than 3 s. After 7 s the connection moves back to the relay, or closes if the peer has gone. A direct path that is not probed shows as "direct".
- "last known online; reconnecting to the controller": this device has no controller session now. The presence is from the last update, and can be out of date. A peer that this device is connected to shows "connected (direct)" or "connected (relay)", which is current.
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

- The peer's `zqxd` (or `zqxnode` app) answers each ping. `zqx ping` counts a reply only when that answer arrives. Thus the times and the losses are real.
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
| `zqx dns status` | Show the xnet domain, the resolver, the xnet's DNS settings, this machine's own nameservers, nameservers that do not answer, and the names that it knows |
| `zqx dns resolve <name>` | Resolve a name through the daemon: a fabric name (for example `db-1` or `db-1.acme.zqxnode.com`), or another name as the xnet's DNS settings say |

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
| `--controller-key <node ID>` | `ZQX_CONTROLLER_KEY` | Pin the controller's key |

## Controller pinning

Each node has a persistent hybrid identity in its state file:
- a classical key (Ed25519, or ECDSA P-256);
- an ML-DSA-65 key.

The node ID (48 hex characters) is a hash of both public keys. Thus a connection to a node by its ID pins both keys. Each connection proves both keys: the TLS handshake signs with the classical key. Then each side sends an Exported Authenticator (RFC 9261) with its ML-DSA-65 certificate, signed with that key and bound to the session.

Nodes also pin the controller's key, in one of these ways:

| How | Example |
| :--- | :--- |
| Option or environment | `zqxd --server controller.example.com:443 --controller-key <controller node ID>` (`ZQX_CONTROLLER_KEY`) |
| Pre-auth key suffix | `zqx up --auth-key <key>.<controller node ID>` |
| First use | With neither, the node pins the first controller that it reaches, and saves it in the state file. |

The node refuses a controller with a different key. The controller shows its node ID at startup (`Controller node ID: …`). `zqx status` shows the key that the node pins (`Controller Key:`), so you can compare the two.

### Controller sets

An xnet can have a primary controller and a secondary controller. The controller sends the node a signed controller set, and the node keeps it in its state file. You do not have to do anything.

- The first set must name the pinned controller (as primary or secondary), and be signed by its primary. A node that joined through the secondary then pins the primary.
- A later set must follow the set that the node holds. The primary of the set signs it. A new primary is signed by a controller of the set that the node holds.
- The node trusts each controller in the set, and refuses all others.
- The node connects to the primary first, then to the secondary, then to the address that it joined with.
- The node refuses a set that is older than a set it saw before.

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
- The operating system sends names in the xnet's domain to the fabric resolver `100.100.100.53`. With DNS settings (below), it also sends the names that the settings claim.
- `zqxd` answers on the adapter itself. Thus it opens no DNS socket, and nothing else on the machine can collide with it.
- It answers A records and reverse lookups for fabric addresses. For other record types, it answers "no data".

The resolver settings on each platform:

| Platform | Settings |
| :--- | :--- |
| macOS | `/etc/resolver/<domain>` for each domain, and a supplemental DNS entry (`scutil`) with the match domains and the search list. "Use for all names" adds the empty match domain. |
| Linux (systemd-resolved) | `resolvectl dns`, `domain` (search domains, and `~<domain>` for split DNS domains) and `default-route` on the adapter. "Use for all names" adds `~.` and `default-route true`. |
| Linux (resolvconf) | A `resolvconf` record for the adapter, with `nameserver 100.100.100.53` and the search list |
| Linux (no DNS manager) | `zqxd` writes `/etc/resolv.conf` one time, and keeps the old file as `/etc/resolv.conf.zqx-backup`. Names that the settings leave to the machine go to the old file's nameservers. `zqx down` puts the old file back. If another program replaces the file, `zqxd` does not write it again: `zqx status` shows the problem and the fix. |
| Windows | An NRPT rule for `.<domain>` and for each split DNS domain (`.` for "use for all names"), and the DNS suffix of the adapter. With search domains, `zqxd` adds them to the machine-wide suffix list, records them in `C:\ProgramData\ZQX\dns-suffixes.txt`, and removes only those. |

- The settings follow the xnet's domain. `zqxd` removes them when the adapter stops.
- `zqxd` removes settings from earlier releases (`.zqx`, `.internal`, `127.0.0.1:5353`).
- A few seconds after a change, `zqxd` checks that the OS resolves the device's own name. If it does not, `zqx status` shows `DNS Problem:` with the fix. `zqx dns status` and the menu bar show it too.

**Without the virtual adapter** (`--tun false`, containers, the `zqxnode` SDK), fabric names resolve only in ZQX: through the SOCKS proxy and the SDK.

## DNS settings of the xnet

An Owner or Admin sets these in the console, on the **Names & DNS** page. With no settings, each device keeps its own DNS for all names outside the xnet.

| Setting | What it does |
| --- | --- |
| Nameservers | The xnet's nameservers, in order: an address (plain DNS), a DNS over HTTPS URL, a DNS over TLS server, or a device of the xnet |
| Use for all names | The nameservers replace each device's own DNS. When no nameserver answers, devices use their own DNS. |
| Strict | With "use for all names": devices never use their own DNS. Names stop resolving when no nameserver answers. |
| Split DNS | A domain and its nameservers (for example `corp.example.com` to `10.0.0.53`), or "device's own DNS" to keep a domain on each device's local network |
| Search domains | Tried after the xnet's domain for names with no dots |

How devices use them:
- `zqxd` asks the nameservers one at a time, in order. A nameserver that does not answer goes to the end of the list for 30 seconds.
- A split DNS domain never goes to the device's own DNS, also when its nameservers do not answer. Thus private names stay private.
- A nameserver on a device of the xnet is reached over the fabric. The access rules must let devices reach it on port 53. The console tells you which devices the rules keep from it.
- `zqxd` answers only queries from its own machine. It is never a resolver for other devices.
- Each device reports the nameservers that do not answer. `zqx dns status`, `zqx status` and the console show them.
- Without the virtual adapter, the SOCKS proxy resolves split DNS names whose address is a device of the xnet.

## Related documents

- [Installation guide](installation.md)
