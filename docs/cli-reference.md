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
| [`zqx login`](#zqx-login) | Log this node in with your ZQX account, in a browser |
| [`zqx logout`](#zqx-logout) | Log out the person on this node: the node stays in its xnet |
| [`zqx reset`](#zqx-reset) | Leave the xnet: a login or a new key adds the node again, as a new node |
| [`zqx down`](#zqx-down) | Disconnect from the fabric |
| [`zqx status`](#zqx-status) | Show the state of this node |
| [`zqx peers`](#zqx-peers) | List the peers |
| [`zqx ping`](#zqx-ping) | Ping a peer over the fabric |
| [`zqx netcheck`](#zqx-netcheck) | Check UDP, STUN, the relay and the NAT mapping |
| [`zqx ip`](#zqx-ip) | Show the fabric IP of this node |
| [`zqx labels`](#zqx-labels) | Show the labels of this node |
| [`zqx share`](#zqx-share) | Publish a local port as a service on the fabric |
| [`zqx forward`](#zqx-forward) | Forward a local TCP port to a service on the fabric |
| [`zqx apps`](#zqx-apps) | List the services on the fabric |
| [`zqx test-access`](#zqx-test-access) | Test an access request against the local rules |
| [`zqx dns`](#zqx-dns) | Show fabric DNS, or resolve a name |
| [`zqx service`](#zqx-service) | Install, start, stop or remove the background service |
| [`zqx daemon`](#zqx-daemon) | Run the daemon in the foreground |

**Options for all commands:** `-s, --socket <path>` (the daemon's socket), `-h, --help`, `-V, --version`.

**JSON output:** `zqx status`, `zqx peers`, `zqx apps`, `zqx labels` and `zqx test-access` accept `--json`.

**Exit status:** `0` when the command succeeds, `1` when it fails. `zqx ping` exits with `1` when no ping gets a reply.

### `zqx up`

Connect to a controller and join the fabric. The daemon keeps the settings. After a restart, it connects again automatically.

**With your account:** run `zqx up` with no key. The node prints a link, and opens your browser on a desktop. Log in; on the node itself that is all. The node then joins your xnet, as you (refer to [`zqx login`](#zqx-login)).

**With a key** (servers, containers, CI): copy the command from the console (**Add node**):

```bash
zqx up --auth-key <key>
```

The node asks ZQX (`fabric.zqxnet.com`) where your xnet's controllers are, and connects to them. A self-hosted controller takes its own address: `zqx up --server <controller address> --auth-key <key>`.

| Option | Environment | Meaning |
| --- | --- | --- |
| `--server <address>` | `ZQX_SERVER` | The controller. The default with a key is `fabric.zqxnet.com`: ZQX directs the node to its xnet's controllers. A self-hosted controller takes its own address. `console.zqxnet.com` is the website, not a server: it is refused. |
| `--auth-key <key>` (alias `--auth-token`) | `ZQX_AUTH_TOKEN` | The pre-auth key from the console. A key of the form `<key>.<controller node ID>` also pins the controller. |
| `--hostname <name>` | `ZQX_NAME` | Fix the node's name. Without it, the name follows the OS hostname, also when the hostname changes (checked each minute; the node then starts a new controller session with the new name). `--hostname auto` lets the name follow the hostname again. A name that an admin gives the node in the console wins over both, until the admin chooses **Use the node's hostname**. Two nodes with one name in an xnet: the later one gets `-2`, `-3` and so on. |
| `--ephemeral[=true\|false]` | `ZQX_EPHEMERAL` | Mark the node as short-lived (for example a CI runner or a container). The daemon keeps this setting. It accepts `true`, `false`, `1`, `0`, `yes` and `no`. The controller removes an ephemeral node when it leaves (`zqx down`), or when it stays offline longer than the xnet's timeout (10 minutes by default; set it in the console under **Keys & settings**). |
| `--accept-dns[=true\|false]` | `ZQX_ACCEPT_DNS` | Use fabric names and the xnet's DNS settings through this machine's DNS. On by default. `--accept-dns=false` leaves the machine's DNS as it is, for example on a server with its own resolver. The daemon keeps this setting. The console shows the nodes that turned it off. |

**Node approval:** if the xnet needs approval for new nodes, the node waits with no access until an Owner or Admin approves it.

- `zqx up` prints "Waiting for an administrator to approve this node in the console", then waits. On approval it prints the fabric address, and exits with status 0. On rejection, or when the wait runs out, it prints why, and exits with status 1.
- Ctrl-C stops waiting in the terminal. The node keeps waiting, and connects by itself once approved.
- `zqx status` shows "Waiting for approval", and when the wait ends.
- A rejected node, or one not approved in time, needs a new key. A key marked pre-approved skips approval.

### `zqx login`

Log this node in with your ZQX account, with no key. `zqx up` does the same when the node has no key and has not joined an xnet.

```bash
zqx login
```

1. The node prints a link. On a desktop it also opens your browser.
2. Log in with your identity provider.
3. **On the node itself**, that is all: the browser returns to ZQX on the node, as in other desktop apps, and the page says you are logged in. The node prints `Connected to <xnet> as <email>.`

- **A choice:** a new node asks which xnet to join only when you can add nodes to more than one. It also shows invitations and your company's xnet when you have them.
- **From another computer** (over SSH, or the printed link opened elsewhere), the browser can't return to the node. The page asks you to check the node and click **Log in** (or **Connect** for a new node), and warns you to continue only if you started the login. Click **Not my node** if you did not start it. In an xnet with two or more members, an Owner or an Admin then approves the node in the console.
- The node opens no browser when it runs as root (`sudo`), over SSH, with no desktop, or as a Windows service. Open the printed link instead.
- The link works for 10 minutes. Press Ctrl-C to cancel.
- **A node that joined with a key, with no person:** `zqx login` adds the person. The node keeps its fabric IP and labels, and logs in to its own xnet only: you must be a member of it.
- A node with a person refuses. Run [`zqx logout`](#zqx-logout) first. **Exception:** from 14 days before the login expires, the same person can log in again (see [Login expiry](#login-expiry)).

### Login expiry

A person's login on a node lasts the xnet's login lifetime: 180 days by default, from 1 to 365 days, or off (**Keys & settings**, **Login lifetime**). Labels never expire.

- **From 14 days before,** `zqx status` shows "Log in again before `<date>` to keep your access on this node." The tray and the menu bar show it, with **Log in again…**, and the tray gives a notice at 14, 3 and 1 days.
- **Log in again before the date** with `zqx login` or **Log in again…**. The node stays connected, and keeps its fabric IP, name and labels.
- **At the expiry,** the node is logged out, as by `zqx logout`. It stays in its xnet, connected, and keeps only the access of its labels. `zqx status` shows "Your login on this node expired." Run `zqx login` to log in again.
- A stream that needed the person is refused with "This node must log in again." Each node checks this by itself, also when the controller cannot be reached.
- An Owner or Admin can turn login expiry off for one node, extend a login by one day, or log a node out, in the console.

### Node expiry

An xnet can turn on node expiry (off by default; **Keys & settings**). Every node must then be renewed by an Owner or Admin in the console within the period: 30 to 365 days.

- From 14 days before, `zqx status` shows "This node expires on `<date>`. Ask an administrator to renew it." The tray and the menu bar show it too.
- After the date, the node has no access until it is renewed. It stays in its xnet, with its name and fabric IP.
- `zqx login` does not renew a node. Ask an Owner or Admin to renew it.

### Nodes with no identity

A node with no label and no person has no identity: nothing says what it is, or who answers for it.

- It loses access after the xnet's identify time: 72 hours by default, from 1 hour to 30 days (**Keys & settings**, **Identify nodes**). The limit cannot be turned off.
- The time starts when the node has neither: when it joins with a key that has no labels, when its last label goes, or when its person logs out or leaves the xnet.
- After that time, no node can reach it, and it reaches none. It stays in the xnet, with its name and fabric IP.
- A label, or a person who logs in (`zqx login`), gives the access back at once.
- `zqx status`, the tray, the menu bar and the console show the time left.

### `zqx logout`

Log out the person on this node. The node stays in its xnet, with the same fabric IP, name and labels.

```bash
zqx logout
```

- Access rules that name the person (`src:user:<email>`, `src:autogroup:member`) no longer match the node. Rules on its labels still do.
- The controller must confirm. If it does not answer, nothing changes: try again when the node is online.
- To log in again, as the same or another person, run `zqx login`.

### `zqx reset`

Leave the xnet for good. A login or a new key adds the node again, as a new node with a new fabric IP.

```bash
zqx reset
```

- The command asks first; `--yes` (`-y`) skips the question.
- The controller removes the node from the xnet. The console no longer lists it.
- The node gets a new identity.
- **The controller does not answer** (no network, the controller is down): the node is reset on itself anyway. It keeps its old key for 30 days, only to finish the reset when the controller answers. Remove the node in the console to finish it at once.
- The ZQX service starts again with the new identity. This takes a few seconds.
- `zqx down` is not a reset: a node that goes down keeps its place in the xnet.

**Who can log in, log out and reset** (`zqx login`, `zqx logout`, `zqx reset`, and the apps' **Log in**, **Log out** and **Reset**):
- An administrator, root or the operator group, as for each other change.
- **On macOS and Windows, also the person at the computer's screen** (the console user; on Windows the active console session, not a Remote Desktop session), for a login and a logout. A reset needs an administrator.
- On Linux, only root and the operator group.
- To turn the right for the person at the screen off, start the service with `ZQX_SIGN_IN_RIGHT=off`.

### `zqx down`

Disconnect from the fabric. The node keeps its identity. `zqx up` connects it again.

On an ephemeral node, `zqx down` leaves the fabric for good: the controller removes the node at once, and joining again needs a new key. A daemon with no saved state (`--state mem:`) also leaves when it stops.

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

- `Controller:` is the controller that this node reached. A node that joined through `fabric.zqxnet.com` shows the controller of its xnet, not `fabric.zqxnet.com`.
- A node that the controller refused shows why, for example "This key was used already", and what to do: make a new key in the console, then run `zqx up --auth-key <key>`.
- `Controller Key:` is the controller node ID that this node pins. Before the first connection it shows `not pinned yet`. Refer to [Controller pinning](#controller-pinning).
- `Recovery Key:` is the controller recovery key that this node pins, when it has one.
- `Controller Set:` shows the controllers of this node's xnet, when the controller sends a set: its epoch and serial, and each controller with its role and address. Refer to [Controller sets](#controller-sets).
- `State Problem:` and `DNS Problem:` lines show a problem and its fix, when there is one.
- `Login:` shows `Logged in as <email>` or `Not logged in`. A node is connected, or connected and logged in.
- `Identity:` shows on a node with no label and no person: when it loses access, and the fix. After that time it shows `needs identity`: no node can reach it, and it reaches none. A label (from an admin) or [`zqx login`](#zqx-login) gives the access back at once. Refer to [Nodes with no identity](#nodes-with-no-identity).
- In a large xnet, the peer list shows only the peers in use, and a count of the others.
- `Controller Session: none for 3h 10m; reconnecting` shows when this node has lost its controller session and is trying again. The time says how old the peer presence is: the peer list shows the presence from when the session ended.

### `zqx peers`

List the peers. There is one row for each peer: node ID, name, endpoint, fabric IP, labels, services and status.

**The status column:**
- The controller's view, and this node's own view of the connection. Examples: "online, direct", "online, relay", "offline, last seen 5m ago", "connected (relay), no controller session for 5m".
- "online, idle": the peer is online, and this node has no connection to it now. A connection starts when something uses the peer, and usually goes direct in under a second.
- "direct (LAN)": the direct path uses the peer's local network address. Two nodes on one network find it even when their router cannot send traffic back into its own network. Each node tells its LAN addresses only to the peer, inside the encrypted connection: the controller never sees them. `ZQX_LAN_CANDIDATES=off` stops a node from sending them.
- "direct, not answering": the direct path has not answered its probes for more than 3 s. After 7 s the connection moves back to the relay, or closes if the peer has gone. A direct path that is not probed shows as "direct".
- "last known online; reconnecting to the controller": this node has no controller session now. The presence is from the last update, and can be out of date. A peer that this node is connected to shows "connected (direct)" or "connected (relay)", which is current.
- `ephemeral` marks a short-lived node.
- In a large xnet (more peers than `ZQX_ON_DEMAND_PEERS`, default 2,000), this node holds details only for the peers that it uses. The other peers show the status "not in use". This node gets their details and status when it connects to them.

With `--json`, a peer that is not in use has `"listed": true` and an empty `id`.

**`-v`, `--verbose`:** for each connected peer, the path probes that find and check the direct path. Use it when a pair stays on the relay.

```text
             probes sent:     41 direct, last 203.0.113.7:24310 2s ago; 40 through relays
             pings received:  0
             answers:         0 direct; 40 through relays
```

- **probes sent:** pings to the peer's addresses, and through each relay path.
- **pings received:** pings from the peer that arrived directly. With none, the peer's pings do not reach this node.
- **answers:** answers to this node's pings. With none, its pings, or the answers, do not get through.
- **refused** (shown only when not zero): probes under a key that does not match this connection, probes with a clock difference over 30 s, and answers that came too late.
- `zqx status` shows `Unknown Probes:` when pings arrived under a key that no connection has (for example, a peer that still uses its connection from before a restart).
- `--json` gives the same counters in `probes`.
- A relayed pair that hears nothing on the direct path for 2 minutes stops its direct probes for 3 minutes, then looks again. Thus a router entry that went wrong (a peer's restart can do that) expires, and the next probe makes a new one. The daemon's log says when it pauses.

**`--stats`:** for each connected peer, one line for each open connection, with its statistics since it opened. Use it when a transfer to a peer is slow.

```text
             dialed direct 203.0.113.7:47001: rtt 301.5 ms, window 664.7 KB, sent 37550 packets, lost 33 (0.09%), congestion events 33, mtu 1452, tx 47.0 MB, rx 1.2 MB
             lane direct 203.0.113.7:47001: rtt 301.6 ms, window 120.0 KB, sent 8211 packets, lost 7 (0.09%), congestion events 6, mtu 1452, tx 10.3 MB, rx 0.4 MB
```

| Field | What it says |
| --- | --- |
| `dialed`, `accepted`, `lane` | Who opened the connection: this node, the peer, or a lane (an extra connection for more cores) |
| `direct <address>`, `relay` | The path, and the peer's address on a direct path |
| `rtt` | The smoothed round trip. On a quiet connection it includes up to 25 ms that the peer waits before it acknowledges, so it can be above `zqx ping` on a fast path. Far above `zqx ping` during a transfer, it shows a queue on the way |
| `window` | The congestion window: how much data can be in flight. A transfer is at most window ÷ round trip |
| `lost`, `congestion events` | Packets lost on the path, and how often the sender reduced its window |
| `mtu` | The packet size in use |
| `tx`, `rx` | Bytes sent and received on the connection |

`--json` gives the same values in `connections` (the round trip as `rtt_us`, in microseconds).

### `zqx ping`

Ping a peer over the fabric. The output shows the round-trip time and the path: direct, or through the relay.

```bash
zqx ping <name, fabric IP or node ID>
```

| Option | Meaning |
| --- | --- |
| `-c, --count <n>` | The number of pings (default 4) |
| `--until-direct` | Stop when the connection is direct |

```text
pong from node2 (100.64.0.3) via 203.0.113.7:24310 in 16ms [X25519MLKEM768]
no reply: no reply from node2 within 2.5 s
pong from node2 (100.64.0.3) via 203.0.113.7:24310 in 14ms [X25519MLKEM768]
3 sent, 2 received
```

- The peer's `zqxd` (or `zqxnode` app) answers each ping. `zqx ping` counts a reply only when that answer arrives. Thus the times and the losses are real.
- The time is the measured round trip of each ping, through the relay too.
- `zqx ping` works to all peers, with or without a virtual adapter. It also works from a node without one.
- It exits with status `1` when no ping gets a reply. You can use it as a health check: `zqx ping -c 1 db-1 || exit 1`.

**The OS `ping`:**
- From a node with the virtual adapter, `ping <peer>` reaches all peers.
- A peer with the adapter replies from its operating system.
- A peer without it replies from its daemon, if the access rules permit ICMP from you (`proto:icmp` or `proto:any`).
- A node without the adapter has no route to the fabric. Use `zqx ping` there.

### `zqx netcheck`

Check the network: UDP, TLS over TCP 443, the STUN server and the relay. The report includes the NAT mapping of the peer port, measured from the peer socket, and the node's IPv6 address as a STUN server sees it.

```text
  * UDP:               true
  * TCP 443 (TLS):     true (649ms)
  * NAT Mapping:       Port-changing (peer port 24310 appears as 51877)
  * Public Endpoint:   198.51.100.23:51877
  * IPv6:              [2001:db8:10::23]:24310
  * STUN Server:       203.0.113.10:443 (210ms)
```

- **IPv6:** "no answer" when the node has no IPv6 route, or no STUN server has an IPv6 address. On an IPv6-only network the public endpoint is the IPv6 one.
- The node dials every address of a name, IPv6 and IPv4, and uses the first that answers: a family that does not work costs about a quarter of a second.

### `zqx ip`

Show the fabric IP of this node, for example `100.64.0.3`.

### `zqx labels`

Show the labels of this node.

```bash
zqx labels
zqx labels --json
```

- A label is a fact about a node: `namespace:key` or `namespace:key=value`. Examples: `ops:env=prod`, `ops:gpu`, `zqx:relay`.
- An admin sets the labels: on the key that admitted the node, or on the node in the console. A node cannot set its own labels.
- Access rules select nodes by their labels. Refer to [Labels](#labels).
- **A node's identity** comes from the controller, never from the node: its node ID, its labels, and the person logged in on it, if any. In access rules, `src:user:alice@example.com` selects Alice's nodes, `src:autogroup:member` selects each node with a person, and `src:node:<node ID>` one node. Join selectors with `+`: `src:ops:role=laptop+user:alice@example.com` is Alice on a laptop. A rule names at most one person and at most one `node:` on each side; `dst:node:<node ID>+ops:env=prod` is that one node, while it has the label.

### Labels

| Part | Characters | Length |
| --- | --- | --- |
| Namespace | `a-z`, `0-9`, `-`. Starts with a letter. | 2 to 32 |
| Key | `a-z`, `0-9`, `-`, `_`, `.`. Starts and ends with a letter or a digit. | 1 to 63 |
| Value (optional) | The same as a key | 1 to 63 |

- Labels are lower case. A label has 160 characters at most, and a node has 32 labels at most.
- A node has one value for each key in a namespace: one `ops:env`, not two.
- Namespaces that start with `zqx` are reserved. `zqx` holds ZQX's services, for example `zqx:relay`. `zqx-<name>` holds the services of a provider that ZQX registers. An admin cannot set a provider's labels.
- Words of the access rules are not namespaces: `group`, `autogroup`, `team`, `node`, `user`, `tag`, `label`, `svc`, `system`, `fabric`, `xnet`, `internet`, `self`, `any`, `all`, `none`, `identity`, `target`, `src`, `dst`, `port` and `proto`.
- In an access rule, `ops:env` selects every node with the key `ops:env`. `ops:env=prod` selects only the nodes with that value.

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
| `--labels <labels>` | Service labels, separated by commas, in your own namespaces (for example `app:tier=gold`) |

Peers see a shared service when this node joins again.

**What a service's labels cover:** a rule that names a service's labels permits only streams that reach that service: by its name (`web`, `web.internal`) or by its exact host and port (`127.0.0.1:8080`). `localhost`, `127.0.0.1` and `::1` count as one host. A stream to another port on the same host, or to another host on the same port, is checked with this node's own labels.

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
zqx test-access --caller alice@example.com --target 127.0.0.1 --port 5432
```

| Option | Meaning |
| --- | --- |
| `-c, --caller <caller>` | The caller: a person's email, `node:<node ID>`, or a label |
| `-t, --target <host>` | The target host or IP |
| `-p, --port <port>` | The target port |
| `--proto <tcp\|udp>` | The protocol (default `tcp`) |
| `--caller-labels <labels>` | The caller's labels, separated by commas |
| `--target-labels <labels>` | The target's labels, separated by commas |

A label given as the caller or the target (for example `--target ops:role=db`) stands for a node with that label.

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

Nodes have the name `<node>.<xnet domain>`, for example `dana-laptop.acme-labs.zqxnode.com`. The short name `<node>` also works. Services have the name `<service>.<node>.<xnet domain>`.

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
- A few seconds after a change, `zqxd` checks that the OS resolves the node's own name. If it does not, `zqx status` shows `DNS Problem:` with the fix. `zqx dns status` and the menu bar show it too.

**Without the virtual adapter** (`--tun false`, containers, the `zqxnode` SDK), fabric names resolve only in ZQX: through the SOCKS proxy and the SDK.

## DNS settings of the xnet

An Owner or Admin sets these in the console, on the **Names & DNS** page. With no settings, each node keeps its own DNS for all names outside the xnet.

| Setting | What it does |
| --- | --- |
| Nameservers | The xnet's nameservers, in order: an address (plain DNS), a DNS over HTTPS URL, a DNS over TLS server, or a node of the xnet |
| Use for all names | The nameservers replace each node's own DNS. When no nameserver answers, nodes use their own DNS. |
| Strict | With "use for all names": nodes never use their own DNS. Names stop resolving when no nameserver answers. |
| Split DNS | A domain and its nameservers (for example `corp.example.com` to `10.0.0.53`), or "node's own DNS" to keep a domain on each node's local network |
| Search domains | Tried after the xnet's domain for names with no dots |

How nodes use them:
- `zqxd` asks the nameservers one at a time, in order. A nameserver that does not answer goes to the end of the list for 30 seconds.
- A split DNS domain never goes to the node's own DNS, also when its nameservers do not answer. Thus private names stay private.
- A nameserver on a node of the xnet is reached over the fabric. The access rules must let nodes reach it on port 53. The console tells you which nodes the rules keep from it.
- `zqxd` answers only queries from its own machine. It is never a resolver for other nodes.
- Each node reports the nameservers that do not answer. `zqx dns status`, `zqx status` and the console show them.
- Without the virtual adapter, the SOCKS proxy resolves split DNS names whose address is a node of the xnet.

## Related documents

- [Installation guide](installation.md)
