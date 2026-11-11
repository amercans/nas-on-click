# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the
project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

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
