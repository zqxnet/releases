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

- A Linux machine (x86-64) with Docker. A server, a virtual machine or a cloud instance.
- A public IP address or DNS name for the machine.
- Inbound UDP and TCP port 443 open to the internet, for your nodes.
- Outbound HTTPS (TCP 443) to `console.zqxnet.com`, and to `github.com` for the download of the controller image (about 35 MB).
- `curl` and `sha256sum` (most Linux systems have both).

## Install

1. In the console (`https://console.zqxnet.com`), open **Controllers** and click **Add your own controller**.
2. Enter a name (lower-case letters, digits and hyphens, for example `home-lab`) and the machine's public address (for example `203.0.113.24`). Add `:port` if your nodes reach it on a port other than 443.
3. Click **Get the install command**, then **Copy**.
4. Run the command on the machine. If your user is not in the `docker` group, run `sudo -s` first, then the command.

The command downloads the controller image from the ZQX releases page, checks its SHA-256, loads it into Docker, and starts the controller. If the check fails, it stops before anything starts.

The command holds your controller's licence. Keep it like a password. You can get it again in the console.

The console shows **Connected** when the controller is up. To check on the machine:

```bash
docker logs zqx-controller
```

## Create its xnets

1. In the console, click **New xnet on it** (Controllers), or open the xnet menu at the top and click **New xnet…**.
2. Enter a name, choose **On your controller**, and click **Create xnet**.
3. Add nodes to the new xnet as to any xnet: **Nodes**, **Add a node**.

## Update

The console says when your controller needs an update, for example "Update home-lab". Until you update it, ZQX does not accept its connection, and you cannot change its xnets from the console. Nodes that are connected keep working.

1. In the console, click **Show install command**, then **Get the install command**, then **Copy**.
2. On the machine, remove the old container. Its keys and xnets stay in the `zqx-controller` volume.

   ```bash
   docker rm -f zqx-controller
   ```

3. Run the new command.
4. Optional: remove the old image. Replace `<old version>` with the version it ran, for example `0.21.0`.

   ```bash
   docker image rm zqx-control:<old version>
   ```

## The licence

- It lasts 90 days. ZQX renews it while the controller is connected, from 30 days before it expires.
- The controller's log warns from 14 days before it expires.
- After it expires, the controller admits no new nodes and no new xnets. Nodes that joined stay connected. Connect the controller to ZQX again to renew it.

## Remove

1. In the console, delete the xnets on the controller (**Keys & settings**, **Delete xnet**).
2. On the machine, remove the container and its volume. This deletes the controller's keys and data, and you cannot undo it.

   ```bash
   docker rm -f zqx-controller
   ```

   ```bash
   docker volume rm zqx-controller
   ```

3. Optional: remove the image. Replace `<version>` with the version it ran.

   ```bash
   docker image rm zqx-control:<version>
   ```

## Ports

| Port | Direction | For |
| --- | --- | --- |
| UDP 443 | Inbound | Your nodes (QUIC), and the controller's relay |
| TCP 443 | Inbound | Your nodes on networks that block UDP |
| TCP 443 | Outbound | The connection to `console.zqxnet.com` |

## Problems

| What you see | What to do |
| --- | --- |
| The console shows **Not connected** | Check the outbound HTTPS connection to `console.zqxnet.com`, and `docker logs zqx-controller` |
| The log says "ZQX now needs" a version | Update the controller (above) |
| Nodes cannot join | Check that UDP and TCP port 443 reach the machine from the internet, and that the public address in the install command is right |
| "Your plan includes one self-hosted controller, and it is connected" | Your licence is in use on another machine. Stop that controller first |
| "Your controller holds 2 xnets" | Delete an xnet on it, or upgrade the plan |

## Licence

The controller is ZQX software under the [ZQX Proprietary Software EULA](https://github.com/zqxnet/releases/blob/main/LICENSE). The image holds the EULA and the third-party notices in `/usr/share/doc/zqx/`.
