# Architecture

This document explains how nas-on-click is put together, what it promises, what it
protects against and why some choices were made the way they were.

## Components

| Part | Language | Role |
|---|---|---|
| `src/install.sh` | bash | First install (interactive) and `--update` refresh (non-interactive, with rollback) |
| `src/agent.sh` | bash | LaunchAgent: serves clicks, drops dead mounts, unmounts before sleep, update checks |
| `src/uninstall.sh` | bash | Removal; refuses to delete anything while a share is mounted |
| `src/lib/config.sh` | bash | Config parser and validator (never executes the file) |
| `src/lib/common.sh` | bash | Route detection, mount table parsing, dialogs, locks, helpers |
| `src/lib/update.sh` | bash | Download, verification and installation of signed updates |
| `src/lib/smb-shares.exp` | expect | Lists shares, typing the password into `smbutil` through a pseudo-terminal |
| `src/app/*.swift` | Swift | One binary, `nas-on-click`, in several roles (below) |
| `src/helpers/sleepwatch.swift` | Swift | Sleep watcher (IOKit power notifications) |

The `nas-on-click` binary has one role per app bundle (`NOCRole` in `Info.plist`) and a few
commands:

- **launcher**: one bundle per share in the NAS folder. A double-click writes a request
  file and kickstarts the agent.
- **installer**: the setup app that is handed out. It starts `install.sh` in its own
  session and quits.
- **helper**: lives inside the installed app folder, so that dialogs and the progress window
  carry the app's name and icon.
- **`mount`**: mounts with NetFS, password on stdin, system UI disabled.
- **`ui` / `progress`**: native dialogs and the setup progress window.
- **`verify-manifest`**: Ed25519 verification of update manifests.

## Flows

**Click.**
1. The launcher writes a request file: `~/<DATA_DIR>/requests/<share>`.
2. It runs `launchctl kickstart` on the agent.
3. The agent picks a route: WARP if it is connected to the configured team and the NAS answers on port 445; otherwise the office route if the office check passes.
4. It mounts the share (`security find-generic-password -g | nas-on-click mount`) and opens it in Finder.

**Saving a password.** The command `add-generic-password … -X <hex>` is written to `security -i` on stdin. The item is created by `/usr/bin/security` itself, so the agent's later reads never trigger a Keychain prompt, and the password never appears in an argument list.

**Clean-up.** launchd also starts the agent once a minute and on every network change. Those runs only unmount shares whose route is gone, after re-checking 15 seconds later. They never mount anything.

**Sleep.** `sleepwatch` receives `kIOMessageSystemWillSleep`. This message also arrives for the sleep that follows a dark wake. `sleepwatch` then runs `agent.sh sleep`, which unmounts every share in parallel, never forcibly, within the time macOS allows, and only then acknowledges the sleep.

**Update.**
1. After a share has been opened, and at most once a day, the agent fetches `manifest.json` and `manifest.sig`.
2. It verifies the signature against `app/update-keys`, then checks the product name and that the version is newer.
3. It asks the user.
4. It downloads the package and checks its exact size and SHA-256.
5. It runs the new `install.sh --update`, which swaps the `app` folder and rebuilds the launchers.
6. If anything fails after the swap, the previous version is put back and refreshed.

## Invariants

- Nothing is mounted unless the user clicked within the last three minutes.
- A share is force-unmounted only when its route cannot come back soon: it is mounted from the office address and the Mac has no address on the office subnet, or the Mac has no network at all (both after a 5-second grace period). A WARP mount is never forced while the Mac is online, and no unmount before sleep is ever forced.
- A password the NAS rejected is never sent again. The user is asked for a new one, so the NAS auto-block cannot lock the account through repeated retries. The stored password counts as rejected on an authentication error, and also after two failed mounts in a row whatever the error code, so a server that reports rejection differently still cannot cause a stream of retries. A new password is stored only after the NAS accepted it.
- The NAS password never appears in a process's arguments or environment. It only passes through pipes: Keychain → `security -g` → stdin of the helper or of the expect script.
- Uninstall deletes nothing while a share is still mounted. Every `rm -r` uses `-x`, so it never crosses into another file system.
- The config file is parsed and never executed. Unknown keys and forbidden characters are rejected.
- An update is installed only if it is signed with a trusted key, is newer than the installed version, matches its manifest exactly, and the user agreed.

## State files (`~/<DATA_DIR>/`)

| Path | Meaning |
|---|---|
| `config` | Deployment config (copied from the setup app) |
| `app/` | Installed version: scripts, `bin/`, `Helper.app`, `update-keys`, `VERSION` |
| `app.prev/` | The version replaced by the last update (kept for rollback) |
| `user` | NAS user name (the password is in the login Keychain) |
| `shares` | Shares the user may open, one per line |
| `requests/` | One empty file per pending click |
| `password-rejected` | Present after the NAS rejected the stored password |
| `mount-failures` | Consecutive failed mounts with the stored password |
| `last-sleep` | Time of the last sleep (detects a lid closed while mounting) |
| `last-update-check` | Time of the last update check |
| `agent.lock`, `update.lock`, `install.lock` | flock files (held by `lockf(1)`, freed by the kernel) |
| `agent.log`, `install.log` | Logs |

## Threat model

| Threat | Mitigation | Residual risk |
|---|---|---|
| Malicious or tampered update | Ed25519-signed manifest naming the product, version, file, size and SHA-256. The signature is checked before parsing. Newer-only. User consent required. Immutable GitHub releases. The package is built by GitHub Actions with a build-provenance attestation, which is verified before signing. | A stolen signing key plus control of the release location. The key sits behind a Keychain confirmation prompt; keep the backup offline. |
| Downgrade or replay of an old release | The version must be newer than the installed one. | None known. |
| Update withheld (freeze) | — | An attacker who controls the network can keep updates from arriving. Manifests carry no expiry, because enforcing one would mean re-signing every week. |
| Password sent to a look-alike network | WARP is tried first. The office route needs the gateway IP, the gateway MAC (ARP cache, no packets sent) and the subnet to match. | These values are not secret. Someone who knows them can imitate the office for a Mac whose WARP is off. Such a Mac would then send an NTLMv2 exchange, never the plain password. |
| Password visible to other processes | Pipes only. Never in process arguments, which on macOS any local user can list. Never in environment variables. | The Keychain item trusts `/usr/bin/security`, so other code running as the same user can read it. |
| Crafted config or share names | Strict config parser. Share and request names containing `/` or `..`, or starting with `.`, are rejected. XML escaping in `Info.plist`. Placeholders are filled with `noc_fmt`, never with `printf`. | — |
| Fake WARP installer | `pkgutil` signature check, with the leaf certificate matched exactly (Cloudflare's Developer ID). The check runs again as root after the file has been copied into a root-owned folder. | — |
| Root step tampered with | The root command is built inline and passed to the authorisation prompt. No script from the user-writable folder runs as root. | — |

## Design decisions

- **Shell for the orchestration.**
  - Every tool it drives already exists on macOS: `launchctl`, `diskutil`, `security`, `warp-cli`, `smbutil`.
  - The logic is mostly sequencing.
  - Reviewers can read it without a toolchain.
  - The parts that need APIs are in Swift: NetFS, the Keychain, AppKit, IOKit, CryptoKit.
- **WARP before the office route.** The office check uses values that ship inside every installer, so it cannot be an authentication boundary. Going through the tunnel costs some speed in the office in exchange for not trusting the LAN.
- **Ad-hoc signing, no notarization.** Notarization needs a paid Apple Developer ID. Without one:
  - a browser download needs "Open Anyway" once,
  - Keychain access lists cannot be pinned to a code signature that survives updates, so the item trusts `/usr/bin/security` instead,
  - macOS will not let the app post notifications, so setup shows a progress window instead.

  Copies installed by nas-on-click's own updater are not quarantined.
- **The Keychain item is created by `/usr/bin/security`.** Keychain items carry a partition list naming which code may read them without asking. An item created from an ad-hoc signed helper would make every later read by `security` show a password prompt. Creating it with `security -i`, password hex-encoded on stdin, avoids both the prompt and any exposure in process arguments.
- **expect for share listing.** `smbutil` reads passwords from the terminal only. A pseudo-terminal keeps the password off the command line without depending on private frameworks.
- **One signing key.** For a small project, one key kept in the Keychain with an offline backup is enough. `keys/update-keys.txt` accepts several keys, and a signed release can add or remove keys.
