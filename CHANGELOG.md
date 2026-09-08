# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versions follow [Semantic Versioning](https://semver.org/).

## [1.1.0] — 2026-09-08

### Added

- **English interface and docs.** The whole UI is bilingual: it follows `$LANG`,
  and `--lang en|vi` (or `DECLUTTER_LANG`) overrides it. Strings live in
  `lib/i18n.sh`; item descriptions use the inline `L "english" "tiếng Việt"`
  helper.
- **`--json`.** The same list as one JSON object — `version`, `platform`, `lang`,
  `level`, `free_kb`, `items[]` (each with `level`, `group`, `action`, `desc`,
  `size_kb`, `size_human`, `paths[]`, `selectable`, `preselected`) and `totals`.
  The shape is stable from this release on.
- **Group name validation.** `--only`/`--skip` now reject a misspelled group with
  the list of valid ones, instead of silently matching nothing.
- **Shell completion** for bash and zsh, under `completions/`.
- **`install.sh --uninstall`**, which removes the symlink and the share directory
  and leaves `~/.declutter.log` alone.
- `AGENTS.md` (repository conventions), `llms.txt`, `CONTRIBUTING.md`,
  `SECURITY.md`, this changelog, and a GitHub Pages landing page at `docs/index.html`.
- English README and manual guide are now canonical (`README.md`,
  `docs/GUIDE.md`); the Vietnamese originals moved to `README.vi.md` and
  `docs/GUIDE.vi.md`.

### Fixed

- **Red advisories never appeared.** Items using the `note` action with no
  measurable size were dropped from the list, so the Docker-volume warning, the
  "needs sudo" notice, the `node_modules`/`target`/`.venv` pointers, the Timeshift
  and APFS-snapshot notes and the Ollama/LM Studio entries never reached the user.
  `note` items now survive at 0 KB.
- `ai-model` was missing from the group list in `--help`.
- Module loading no longer relies on a convoluted per-filename OS gate; sourcing a
  module only defines functions, and the platform gate lives on the hook name
  (`register_linux_*`, `register_mac_*`).

### Changed

- Code comments, log lines, the test suite and CI step names are now English.
  Vietnamese lives in the `*.vi.md` docs and in the runtime string catalog.
- The test suite grew from 52 to 68 assertions, covering the JSON contract, both
  languages, group validation, red-advisory visibility and the installer round
  trip.

## [1.0.0]

- First release: interactive checkbox list with real sizes, three safety tiers,
  `--report`, `--yes`, `--dry-run`, `--projects`, `--only`/`--skip`, `--deep`,
  logging to `~/.declutter.log`, Ubuntu and macOS support from one pure-bash
  script, and a test suite running in a fake `$HOME`.
