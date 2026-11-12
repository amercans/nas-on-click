# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the
project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.2.0] - 2026-11-12

### Added
- Interface in German, French, Spanish and Russian, besides English and Turkish.
  `LANGUAGE=auto` (new default) follows the Mac's system language.
- Release notes per language (`notes_i18n` in the manifest); older versions keep showing
  the English note.
- Opening the setup app on a Mac where it is already installed offers Repair or Uninstall,
  so removing it no longer needs the Terminal.

## [1.1.1] - 2026-11-12

### Fixed
- Passwords containing non-ASCII letters were read back hex-encoded by `security -w`;
  they are now read with `-g`, whose output is unambiguous, and decoded.
- When the Mac leaves the office network, office mounts are force-unmounted after a
  5-second grace period instead of after 15 s, before macOS shows its "server
  connections interrupted" dialog.
- After a fresh install, the first click showed a Keychain prompt ("security wants to
  access …"). The password item is now created by `/usr/bin/security` itself (through
  `security -i` on stdin, hex-encoded), so reading it never prompts.

## [1.1.0] - 2026-11-11

### Security
- The NAS password no longer appears in any process's arguments: mounting uses NetFS
  with the password on stdin, the Keychain is written through the Security framework,
  and setup lists shares by typing into `smbutil`'s prompt through a pseudo-terminal.
- System login dialogs are disabled while mounting, so no second Keychain item can be
  created by accident.
- The WARP installer's leaf certificate is matched exactly.
- Release packages are built by GitHub Actions with a build provenance attestation,
  which the maintainer verifies before signing the manifest.

### Changed
- Dialogs, the setup app and a new setup progress window are native macOS windows with
  the app's name and icon (no more AppleScript windows); notifications were dropped.
- Locks use `lockf(1)`: the kernel releases them when a process ends.
- An expired ARP entry no longer makes the agent drop an office mount.
- A click that arrives just as a run ends is served immediately.

### Added
- ARCHITECTURE.md: components, flows, invariants, state files, threat model, design decisions.
- Behaviour tests for the agent, installer and uninstaller with shimmed system tools.
- OpenSSF Scorecard, leak scan in CI, CODEOWNERS and a pull request template.

## [1.0.1] - 2026-11-11

### Added
- The final setup message suggests dragging the NAS folder into Finder's Favorites.

### Fixed
- Uninstall now removes the NAS folder even when Finder has left its hidden view
  settings file in it.

## [1.0.0] - 2026-11-11

### Added
- One launcher icon per share; a double-click mounts the share and opens it in Finder.
- Route selection: direct in the office (gateway IP + MAC + subnet), otherwise
  through Cloudflare WARP when enrolled in the configured team.
- Background clean-up of mounts whose route is gone, without dialogs.
- Unmount before sleep, including the sleep after a dark wake (IOKit).
- Installer with Keychain storage, signed WARP install and team enrolment.
- Signed self-update (Ed25519 manifest, version and checksum checks, user consent,
  automatic rollback).
- English and Turkish interface.
