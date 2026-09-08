# Contributing

Thanks for considering it. This is a small pure-bash project, so contributing is
mostly: clone, edit, run the tests.

```bash
git clone https://github.com/quytstudio/declutter.git
cd declutter
./declutter --report     # see it work, deletes nothing
./tests/run.sh           # the suite, in a fake $HOME
```

There is no build step and nothing to install.

## The rules that matter

1. **bash 3.2 compatible.** macOS ships bash 3.2 and CI runs the suite with it.
   No `declare -A`, no `mapfile`, no `${var,,}`. Use parallel indexed arrays.
2. **No dependencies.** Only what a base macOS/Ubuntu install has: `du`, `df`,
   `find`, `awk`, `sort`, `tput`. The tool never touches the network.
3. **Nothing is deleted without confirmation**, and every deleting path honours
   `--dry-run`. Red items stay advisory: no flag may ever delete one.
4. **Both languages.** User-facing text is bilingual —
   `$(L "english" "tiếng Việt")` for item descriptions, `lib/i18n.sh` for
   everything else. Code comments and the log file are English.

`AGENTS.md` has the full picture: layout, the `add()` signature, the actions, and
the two testing traps that will otherwise cost you an hour.

## Adding a cleanup item

Most contributions are one line in a file under `modules/`:

```bash
add green ai-cli rm "" "$(L "Short description" "Mô tả ngắn")" "$H/.something/cache"
```

Then add an assertion to `tests/run.sh`: create the directory in the fake `$HOME`,
and assert it goes (or survives) at the right tier.

**Picking the tier** is the part worth thinking about:

- **green** — losing it costs time and nothing else. A cache that provably
  regenerates.
- **yellow** — you lose history, or the rebuild is genuinely long.
- **red** — it might be real data, or only the user can know whether it is still
  needed. Use the `note` action: it reports the size and never deletes.

When in doubt, go one tier stricter. A tool that under-cleans is an inconvenience;
one that deletes something irreplaceable is a bug nobody forgives.

## Pull requests

- One topic per PR.
- `./tests/run.sh` green. On macOS, also `/bin/bash tests/run.sh`.
- CI does **not** run automatically on a push or a PR — it is manual-only
  (`workflow_dispatch`). A maintainer dispatches it from the Actions tab, or with
  `gh workflow run ci`. So run the suite locally before you open the PR.
- Update `README.md` **and** `README.vi.md` if behaviour changed, plus `llms.txt`
  if you added or changed a flag.
- Add an entry to `CHANGELOG.md` under a new "Unreleased" heading.

## Reporting a problem

Open an issue with your OS and version, `bash --version`, the output of
`declutter --version`, and the relevant lines from `~/.declutter.log`. If
something was deleted that should not have been, say so first — that is the
highest-priority class of bug in this project.
