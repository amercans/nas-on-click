# Setting up the NAS side

nas-on-click only handles the Macs. "Office" here means the network where the NAS sits; for a NAS at home, read "home" and set `LOCATION=home`. This page covers what has to be in place on the NAS and the network around it, and the settings that keep the whole setup working after power cuts, router restarts and lost laptops.

The examples use documentation addresses (`192.0.2.x` in the office, `198.51.100.x` for the remote route). Replace them with your own.

## 1. Give the NAS a fixed address

Every installed Mac stores the NAS address. If the router gives the NAS a new address after a restart, every Mac loses access at once.

- **Best:** a DHCP reservation for the NAS's MAC address on the router.
- **No access to the router:** set a manual address on the NAS itself (on Synology: *Control Panel → Network → Network Interface → Edit*). Choose one outside the router's DHCP pool. If you cannot find out where the pool ends, use an address near the top of the subnet and check that nothing answers on it first.
- **Or use a name for the remote route.** `REMOTE_HOST` accepts a host name, for example one your VPN's DNS hands out. `OFFICE_HOST` must stay an IP address (see [ARCHITECTURE.md](../ARCHITECTURE.md)).

`OFFICE_HOST` and `REMOTE_HOST` must be different, because the agent tells the two routes apart by address. A NAS with two network ports can use one address per port. With a single port, use the address the VPN gives the NAS (for example its Tailscale address), or a name that resolves to it. A name that resolves to the office address is refused.

## 2. SMB settings worth checking

- **Turn the Guest account off.** With Guest on, some NAS systems sign an unknown user name in as a guest instead of rejecting it, so a typing mistake can still list shares. Setup would then store a user name that does not exist.
- **Minimum protocol SMB 2 or newer.** SMB 1 has no place on a network that also carries a VPN.
- **Keep the auto-block on.** nas-on-click never sends a password the NAS has rejected a second time. It asks the user for the new one instead, so the auto-block only catches real guessing.
- **Share permissions decide the icons.** Setup lists the shares the user can open and creates one icon each. Use `EXCLUDE_SHARES` for system shares such as `docker` or `homes`.

## 3. Office detection values

The office route needs four values. Read them on a Mac connected to the office network:

```sh
route -n get default | grep gateway     # OFFICE_GATEWAY
arp -n 192.0.2.1                        # OFFICE_GATEWAY_MAC (use the gateway from above)
ipconfig getifaddr en0                  # OFFICE_SUBNET_PREFIX: keep the part up to the last dot
```

These values are not secret, and nas-on-click does not treat them as a password. They only keep the office route from being chosen by accident on another network.

## 4. Remote access

### Option A: Cloudflare Tunnel and WARP

This is the path the installer automates on the Mac side: it installs WARP, checks its signature and enrols the Mac in your team.

On the network side:

1. **Run a tunnel connector next to the NAS.** `cloudflared` can run as a container on the NAS itself (host networking) or on any always-on machine in the office.
2. **Add a private network route** for the NAS address only (`198.51.100.20/32`), not the whole office subnet.
3. **Use a split-tunnel device profile in include mode** that sends only that `/32` through WARP. The rest of each Mac's traffic stays as it was, and the browser and video calls are not slowed down.
4. **Restrict enrolment** to your identity provider and your domain.
5. **Add Gateway network policies:** allow your users to reach the NAS address on port 445 (and the admin port if they need it), then block every other port on that address.
6. **Logging:** decide what you need. If DNS and HTTP logs are not needed for the NAS, turn them off for privacy.

Set `REMOTE_HOST` to the NAS address from step 2 and `WARP_TEAM` to your team name.

### Option B: any other VPN

If the Macs already reach the NAS over Tailscale, WireGuard, IPsec or a similar VPN, leave `WARP_TEAM` empty. Setup then installs nothing extra. The remote route is used only when macOS sends traffic for `REMOTE_HOST` through a tunnel interface.

Check it on a Mac that is connected to the VPN:

```sh
route -n get nas.example.internal | grep interface   # should print utun…, ipsec…, ppp… or wg…
```

Set `REMOTE_HOST` to the address or fully qualified name the VPN gives the NAS. A name must resolve to a private address (`10.x`, `172.16–31.x`, `192.168.x` or `100.64–127.x`). If the VPN routes all traffic, or its own DNS does not resolve the name, prefer an IP address (see the security model in the README).

## 5. Keep it running

- **Power.** Put the NAS on a UPS and let the NAS know about it, so it shuts down cleanly before the battery runs out. That means a USB cable from the UPS to the NAS, or, for a building-wide UPS with a network card, the NAS's network-UPS (SNMP) setting. A UPS that the NAS cannot talk to only delays the hard power-off.
- **Tunnel redundancy.** A second `cloudflared` connector for the same tunnel, on another always-on machine, keeps remote access up when the first one crashes or restarts. It does not help when the NAS itself is down.
- **Snapshots.** Deleting a file in a mounted share deletes it on the NAS. Scheduled, read-only snapshots (on Synology: *Snapshot Replication*, with immutable snapshots where available) make that, and ransomware on a connected Mac, recoverable.
- **Disk health.** Schedule data scrubbing and S.M.A.R.T. tests. Neither is on by default on every NAS.

## Checklist

- [ ] The NAS address cannot change (reservation, manual address or host name).
- [ ] Guest account off, SMB 2 or newer, auto-block on.
- [ ] Office values read on an office Mac and written to the config.
- [ ] Remote route works from outside the office: WARP connected, or `route -n get` shows a tunnel interface.
- [ ] The NAS knows about its UPS.
- [ ] Snapshots and scrubbing are scheduled.
- [ ] A test share opens and closes cleanly before rollout.
