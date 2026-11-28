# Run your own controller

The controller admits your nodes and tells them about each other. ZQX runs one for you. You can also run your own, free, on a machine you choose, and manage it from the ZQX console.

## What you get

| | Your own controller |
| --- | --- |
| Price | Free on every plan below Enterprise |
| Controllers | 1 |
| Xnets on it | 2 (your xnet on ZQX is separate) |
| Nodes in its xnets | No limit |
| Secondary (failover) | None: when the machine stops, its xnets stop accepting changes. Nodes that are connected keep working |
| Relay | Its own, on the same port |
| Licence | 90 days, renewed automatically while it is connected to ZQX |

Your nodes' traffic never goes through ZQX. The controller connects to ZQX so that you can manage it from the console.

## What you need

- A Linux machine (x86-64) with Docker, or a Kubernetes cluster with x86-64 nodes.
- Outbound HTTPS (TCP 443) to `fabric.zqxnet.com` (the controller's link to ZQX) and to `ghcr.io` (the controller image).
- Your nodes must reach the machine on UDP and TCP port 443.
  - In a private network, nodes in that network reach it. You do not need a public address or a port forward.
  - For nodes in other networks, give the machine a public address or a port forward, and set `ZQX_PUBLIC_ADDR` (refer to [The address that nodes use](#the-address-that-nodes-use)).

ZQX never connects to the machine. The controller connects out.

## Install

1. In the console (`https://console.zqxnet.com`), open **Controllers** and click **Add your own controller**. The console makes a connection token.
2. Under **Start it with**, choose **Docker**, **Compose** or **Kubernetes**, then click its **Copy** button.
3. On the machine, start the controller with what you copied:
   - **Docker:** run the command. If your user is not in the `docker` group, run `sudo -s` first.
   - **Compose:** save the file as `compose.yaml`, then run `docker compose up -d`.
   - **Kubernetes:** save the file as `zqx-controller.yaml`, then run `kubectl apply -f zqx-controller.yaml`.
4. Wait for the console. It shows **connected**, with the controller's name and the address that your nodes use.

To use your own configuration, set `ZQX_SAAS_TOKEN` to the token. Refer to [Settings](#settings).

**The connection token:**
- It works once, for 24 hours.
- Keep it like a password until it is used. After that it does nothing: the controller keeps its licence in its volume.
- The console shows it once. **Make a new token** replaces it, and **Revoke token** stops it.

**The name:** the controller takes the machine's host name. To give another name, use **Rename…** in the controller's actions on the Controllers page, or set `ZQX_CONTROLLER_NAME`.

**To check on the machine:**

```bash
docker logs zqx-controller
```

The log shows the address that the controller found, for example "Nodes reach this controller at 10.0.0.5:443: found on this machine."

## The address that nodes use

The controller finds the address itself, from the machine's route to the internet:

| The machine has | Nodes reach it at |
| --- | --- |
| A public address of its own | That public address |
| A private address only | Its private address. Only nodes in that network reach it |

**To give another address** (a DNS name, a port forward or a load balancer):
- **In the console:** on the Controllers page, open the controller's actions, click **Change address…**, choose **An address you set**, and enter it, for example `ctrl.example.com` or `203.0.113.24:8443`. Connected nodes get it within a minute. **The one the controller finds** goes back to the found address.
- **On the controller:** set `ZQX_PUBLIC_ADDR`, for example `ZQX_PUBLIC_ADDR=ctrl.example.com`, then start the controller again. The console can't change an address set this way.

**IPv6:** the controller listens on IPv6 and IPv4. The address it finds is the IPv4 one when the machine has IPv4. For nodes on IPv6-only networks, give a DNS name with both an IPv4 (A) and an IPv6 (AAAA) record: nodes then try both and use the first that answers. An IP address reaches one family only.

## Settings

The examples in the console set these values. Set them in your own configuration in the same way.

| Setting | Value | Why |
| --- | --- | --- |
| `ZQX_SAAS_TOKEN` | The connection token | Joins the controller to your account, once |
| `ZQX_SAAS_MANAGEMENT` | `full` | Lets the console create and change the xnets on it |
| `ZQX_RELAY` | `true` | Its own relay, for nodes that cannot connect directly |
| `ZQX_PUBLIC_ADDR` | Optional | The address that nodes use, when the found one is not right |
| `ZQX_CONTROLLER_NAME` | Optional | The name in the console, in place of the host name |

Keep the state in a volume at `/var/lib/zqx`, and use the host network (`--network host`, `network_mode: host` or `hostNetwork: true`), so that the controller sees the machine's addresses.

## Create its xnets

1. In the console, click **New xnet on it** (Controllers), or open the xnet menu at the top and click **New xnet…**.
2. Enter a name, choose **On your controller**, and click **Create xnet**.
3. Add nodes to the new xnet as to any xnet: **Nodes**, **Add a node**.

## Update

The console says when your controller needs an update, for example "Update home-lab", and shows the image of the new version. Until you update it, ZQX does not accept its connection, and you cannot change its xnets from the console. Nodes that are connected keep working.

Start the controller again with the new image. Its keys, its xnets and its licence stay in its volume, so it needs no new token.

- **Docker:** remove the container, then run the same command with the new image.

  ```bash
  docker rm -f zqx-controller
  ```

- **Compose:** change the `image:` line, then run `docker compose up -d`.
- **Kubernetes:** change the `image:` line, then run `kubectl apply -f zqx-controller.yaml`.

Optional: remove the old images.

```bash
docker image prune -a --filter "label=org.opencontainers.image.title=ZQX controller"
```

## The licence

- The controller gets it from ZQX when it connects with the token, and keeps it in its volume.
- It lasts 90 days. ZQX renews it while the controller is connected, from 30 days before it expires.
- The controller's log warns from 14 days before it expires.
- After it expires, the controller admits no new nodes and no new xnets. Nodes that joined stay connected. Connect the controller to ZQX again to renew it.
- The console's **Plan & licences** page shows the licence, when it expires and whether it renews. From 30 days before it expires, while the controller is not connected, the page shows a warning with the date.

**The recovery key:** the controller keeps a recovery key in its volume, and nodes pin it. Optional: keep a copy apart.

```bash
docker exec zqx-controller zqx-control recovery-key export --out /var/lib/zqx/recovery-copy.key
```

Then copy that file from the volume to a safe place, and delete it from the volume.

## Remove

1. In the console, on the Controllers page, open the controller's actions and click **Remove controller…**.
2. Read what goes with it: each xnet on the controller, with its nodes, keys, access rules and members. You cannot undo it.
3. Choose your Google account again, then type the controller's name, and click **Remove controller**.
   - The xnets on it are deleted, and its licence is revoked. Your plan's controller is free for another.
   - A controller that is connected stops admitting nodes at once. A controller that is not connected is removed in ZQX: its nodes on the machine keep their state until you remove the machine.
4. On the machine, remove the controller and its state. This deletes the controller's keys and data. The console shows these commands too.
   - **Docker:**

     ```bash
     docker rm -f zqx-controller
     ```

     ```bash
     docker volume rm zqx-controller
     ```

   - **Compose:** run `docker compose down -v`.
   - **Kubernetes:** run `kubectl delete -f zqx-controller.yaml`, then delete its volume claim: `kubectl delete pvc state-zqx-controller-0`.
5. Optional: remove the image.

   ```bash
   docker image prune -a --filter "label=org.opencontainers.image.title=ZQX controller"
   ```

If a removed controller starts again, ZQX refuses it, and its log says what to run. To use it again, add it with a new connection token.

## Ports

| Port | Direction | For |
| --- | --- | --- |
| UDP 443 | Inbound, from your nodes | Your nodes (QUIC), and the controller's relay |
| TCP 443 | Inbound, from your nodes | Your nodes on networks that block UDP |
| TCP 443 | Outbound | The connection to `fabric.zqxnet.com`, and the image from `ghcr.io` |

## Problems

| What you see | What to do |
| --- | --- |
| The console still says it is waiting | Check the outbound HTTPS connection to `fabric.zqxnet.com`, and `docker logs zqx-controller` |
| "This connection token was used already", "expired" or "was revoked" | In the console, click **Add your own controller** again for a new token, and start the controller with it |
| The log says "ZQX now needs" a version | Update the controller (above) |
| Nodes cannot join | Run `zqx status` on the node: it shows why the controller refused it, for example a key for one node that was used already. Check that UDP and TCP port 443 reach the machine from the nodes. For nodes outside its network, use **Change address…** or set `ZQX_PUBLIC_ADDR` |
| "Your plan includes one controller, and … is connected" | Remove that controller (**Remove controller…**), or stop it, then make a new token |
| The console shows the controller as **Disconnected** | Check that the machine runs it (`docker ps`) and its outbound HTTPS connection. If the machine is gone, use **Remove controller…** |
| The log says "This controller was removed from your ZQX account" | Remove it from the machine (above), or add it again with a new connection token |
| "Your controller holds 2 xnets" | Delete an xnet on it, or upgrade the plan |

## Licence

The controller is ZQX software under the [ZQX Proprietary Software EULA](https://github.com/zqxnet/releases/blob/main/LICENSE). The image holds the EULA and the third-party notices in `/usr/share/doc/zqx/`. Each release also has the image as a file (`zqx-control-image-linux-amd64.tar.gz`, with its `.sha256`), for a machine that loads images from files.
