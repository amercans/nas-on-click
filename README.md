# nas-on-click

Click-to-mount NAS shares for macOS. You get one icon for each share. A double-click mounts the share and opens it in Finder:
- directly when the Mac is on the office network,
- through [Cloudflare WARP](https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/) when it is anywhere else.

Shares are never mounted in the background. That is why the *"Server connections interrupted"* dialog never shows up after sleep, network changes or Power Nap.

Built for and tested with a Synology NAS over SMB, but it works with any SMB server.

## Why

The usual ways of keeping a NAS mounted on a laptop break in one of three places:

- **Login items and auto-mount scripts** mount the share again on every wake and network change. Whenever the server is unreachable, macOS shows the interrupted-connections dialog.
- **Power Nap's dark wakes** mount shares while the lid is closed. When the Mac goes back to sleep, nobody unmounts them.
- **Scripts that send the NAS password** to any host that answers on the office IP. On a café network, that host could be anything.

nas-on-click mounts a share only when someone asks for it. It also unmounts shares on time and only talks to the NAS when it is sure where it is.

## How it works

```
 double-click "Projects" icon
          │
          ▼
 tiny launcher app ──writes──▶ ~/.nas-on-click/requests/Projects
          │
          └─ launchctl kickstart ──▶ agent.sh (LaunchAgent)
                                        │
             in the office?  ───────────┤  gateway IP + gateway MAC (ARP cache) + subnet
             WARP connected? ───────────┤  enrolled in your team + NAS port reachable
                                        ▼
                         mount (password from the login Keychain)
                                        ▼
                                 open in Finder
```

- **Never mounts by itself.** launchd also runs the agent on network changes and once a minute. Those runs only unmount shares whose route has disappeared, and they show no dialog.
- **Unmounts before sleep.** A small helper listens to IOKit power notifications, which also arrive for the sleep that follows a dark wake. Before the Mac sleeps it unmounts every share, and never forcibly. A share with an open file stays mounted.
- **WARP first, office second.** When WARP is connected and enrolled in the team from your config, the share is always mounted through the tunnel. The direct office route is a fallback, used only when three things match:
  - the default gateway address,
  - the gateway's MAC address, read from the ARP cache (no packets are sent, so no Local Network prompt),
  - the Mac's own subnet.

  This keeps the password away from look-alike networks for anyone who isn't holding your config (see the limitations below).
- **A rejected password is never sent again.** The agent asks the user for the new password instead, so the NAS auto-block does not lock the account.
- **Safe uninstall.** `uninstall.sh` refuses to delete anything while a share is still mounted.

## Requirements

- macOS 12 or later, Apple silicon or Intel.
- An SMB server, such as a Synology NAS.
- Optional, for access from outside the office: a Cloudflare Zero Trust team whose WARP clients can reach the NAS, for example through a Cloudflare Tunnel with a private network route.
- To build: Xcode Command Line Tools (`swiftc`).

## Quick start

```sh
git clone https://github.com/amercans/nas-on-click.git
cd nas-on-click
cp config.example my-office.conf      # fill in your own values
tools/make-package.sh --config my-office.conf
```

This produces `dist/package/<INSTALLER_NAME>.app` and a zip of it. Hand it out and ask people to open it. The installer:

1. asks for the NAS user name and password, checks them and stores them in the login Keychain;
2. if remote access is configured, installs Cloudflare WARP. The package's Cloudflare signature is checked before installing. It then enrols the Mac in your team (one browser sign-in);
3. creates one icon per share the user can access, inside a folder that is also linked on the Desktop.

The installer is ad-hoc signed, not notarized. A copy downloaded through a browser has to be allowed once under **System Settings → Privacy & Security → Open Anyway**. A copy taken from a USB stick or a file share opens directly. Updates installed by nas-on-click itself never need this step.

## Configuration

The config file is parsed, never executed. It only accepts known keys, and every value is checked. `config.example` documents each key. Summary:

| Key | Purpose |
|---|---|
| `APP_NAME`, `ORG_NAME`, `SUPPORT_CONTACT`, `LANGUAGE` | Names in dialogs, who to contact, `en` or `tr` |
| `DATA_DIR`, `BUNDLE_ID`, `FOLDER_NAME`, `KEYCHAIN_SERVICE` | Local layout on each Mac |
| `OFFICE_HOST`, `OFFICE_GATEWAY`, `OFFICE_GATEWAY_MAC`, `OFFICE_SUBNET_PREFIX` | Direct access in the office |
| `REMOTE_HOST`, `WARP_TEAM`, `LOGIN_ACCOUNT` | Access through Cloudflare WARP (optional) |
| `EXCLUDE_SHARES`, `USERNAME_UPPERCASE` | Which shares get no icon; user-name quirk of some NAS setups |
| `UPDATE_URL` | Where signed releases are published (empty = no update checks) |
| `INSTALLER_NAME` | Name of the installer app |
| `LEGACY_LABELS`, `LEGACY_BUNDLE_PREFIXES` | Clean-up of an older in-house setup |

## Updates

Installed copies update themselves, but only with the user's consent and only from releases signed by you.

- **When it checks:** at most once a day, right after the user opens a share. It never checks on a timer of its own.
- **What it downloads:** `manifest.json` and `manifest.sig` from `UPDATE_URL`.
- **What it checks:**
  - the Ed25519 signature, against the keys shipped with the installed version (`keys/update-keys.txt`);
  - that the manifest is for this product;
  - that the version is newer than the installed one;
  - that the package has exactly the size and SHA-256 listed in the manifest.
- **How it installs:** only after the user agrees. If the install fails, the previous version is restored.

Publishing works the same way whoever runs it:

```sh
swift tools/signer.swift keygen     # once: creates the key in your login Keychain, prints the public key
swift tools/signer.swift backup ~/Desktop/signing-key.txt   # once: keep this file offline
tools/release.sh 1.1.0 "Short note shown to users"
```

**For a fork:**
1. Put your own public key in `keys/update-keys.txt`.
2. Point `UPDATE_URL` at your repository's `releases/latest/download`.

A release signed with an existing key may add a new key to `keys/update-keys.txt`, so you can rotate keys without reinstalling every Mac.

Updates replace the scripts, helpers and launchers. They do not touch:
- the config file,
- the Keychain item,
- the WARP enrolment,
- shares that are currently mounted.

## Security model

- **Credentials.** The NAS password is stored in the user's login Keychain. Mount errors are discarded. The installer logs `smbutil`'s error line, which states the reason ("authentication rejected"), not the password.
- **What updates need to succeed.** An attacker needs your signing key *and* the ability to publish where `UPDATE_URL` points. Even then, nothing is installed without the user's consent. Turn on [immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases) for the repository.
- **Known limitations:**
  - **Password in command-line arguments.** While a share is being mounted, checked or saved, the password briefly appears in the arguments of `smbutil`, `mount_smbfs` or `security` (and in the AppleScript environment). Other processes of the same user and root can see it during that time.
  - **Same-user access to the Keychain item.** The NAS password item trusts the `security` tool, so other programs running as the same user can read it.
  - **The office check is not an authentication boundary.** The gateway address, gateway MAC and subnet are in every installer and visible on the office network. Someone with that knowledge can imitate the office on another network. A Mac without a connected WARP would then send its NAS sign-in there: an NTLMv2 exchange, not the plain password, but one that can be attacked offline. Use strong NAS passwords, or leave the office values empty to always use WARP.
  - **No notarization.** The installer, helpers and launchers are ad-hoc signed.
  - **No expiry on update metadata.** An attacker who controls the network can withhold updates, but cannot install anything.
  - **No key revocation.** A leaked signing key stays trusted by every copy that has not yet installed a release removing it. The signing tool keeps the key behind a confirmation prompt (`swift tools/signer.swift protect`); keep the backup offline.

Please report vulnerabilities privately: see [SECURITY.md](SECURITY.md).

## Uninstall

```sh
~/<DATA_DIR>/app/uninstall.sh
```

This removes the background jobs, the launchers, the Keychain item and the data folder. Cloudflare WARP is left installed, and so is the system-wide WARP settings file `/Library/Application Support/Cloudflare/mdm.xml` that setup writes when it installs WARP; the script prints how to remove both.

## Troubleshooting

- **Setup:** `~/<DATA_DIR>/install.log`
- **Everyday use:** `~/<DATA_DIR>/agent.log` — mounts, unmounts, update checks.
- **Clicking an icon does nothing:** check *System Settings → General → Login Items* and allow the background item.

## Development

```sh
tools/build.sh                         # universal helpers + payload in dist/payload
tests/run.sh                           # config, signature and update-flow tests
git config core.hooksPath tools/hooks  # run tools/leak-scan.sh before every push
```

`tools/leak-scan.sh` rejects the following, anywhere in the files or the git history:
- IP and MAC addresses outside the documentation ranges,
- e-mail addresses,
- private keys,
- every pattern in your own list, kept outside the repository (`~/.config/nas-on-click/forbidden-patterns.txt`).

## Prior art

The update design follows ideas from [The Update Framework](https://theupdateframework.io/) and from the EdDSA-signed updates used by [Sparkle](https://sparkle-project.org/). No code is taken from either.

## Trademarks

Synology, Cloudflare, WARP, Apple and macOS are trademarks of their respective owners. This project is not affiliated with or endorsed by any of them.

## License

[MIT](LICENSE). Provided as is. Try it with a test share before rolling it out.
