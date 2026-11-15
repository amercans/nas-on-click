# Contributing

Bug reports and pull requests are welcome.

- Keep changes small and focused; explain the problem the change solves.
- Run `tools/build.sh` and `tests/run.sh`, and make sure `shellcheck -x -S warning`
  is clean (CI runs both).
- Never include real addresses, user names, share names or company names in code,
  tests, examples or commit messages. Use the documentation ranges
  (`192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24`, MAC `00:00:5e:00:53:xx`)
  and `example.com`.
- User-facing text lives in `src/lang/*.sh` (en, tr, de, fr, es, ru); add every new string to
  all of them (the test suite checks that the files define the same keys). Improvements to
  the translations by native speakers are very welcome.
- Behaviour changes that affect users belong in `CHANGELOG.md` under "Unreleased".

By contributing you agree that your contribution is licensed under the MIT License.
