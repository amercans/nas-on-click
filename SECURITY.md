# Security policy

## Reporting a vulnerability

Please do not open a public issue. Use GitHub's private reporting instead:
**Security → Report a vulnerability** on this repository
(<https://github.com/amercans/nas-on-click/security/advisories/new>).

Include what you found, how to reproduce it and which version you tested
(`~/<DATA_DIR>/app/VERSION`). You can expect an acknowledgement within a week.

## Scope

Of most interest:

- anything that lets an update be installed without a valid signature or without
  the user's consent;
- ways to make an installed copy send the NAS password to a host other than the
  configured NAS;
- config or share names that lead to command execution or to files outside the
  data folder being written or deleted.

The threat model and known limitations are in [ARCHITECTURE.md](ARCHITECTURE.md#threat-model)
and under "Security model" in the README.

## Supported versions

Only the latest release receives fixes.
