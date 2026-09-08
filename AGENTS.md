# AGENTS.md

Conventions for coding agents (and humans) working in this repository.

## What this project is

`declutter` is a disk cleanup CLI for developer machines, written in pure bash.
No build step, no dependencies, no package manager. Run it straight from a clone:
`./declutter`.

## Hard constraints

1. **bash 3.2 compatible.** macOS still ships bash 3.2 at `/bin/bash`, and CI runs
   the suite with it. No associative arrays (`declare -A`), no `mapfile`, no
   `${var,,}`, no `&>>`. Parallel indexed arrays are the pattern here (see
   `lib/registry.sh`).
2. **No dependencies.** Only tools present in a base macOS/Ubuntu install: `du`,
   `df`, `find`, `awk`, `sort`, `sed`, `tput`. Never add a runtime, and never call
   out to the network from the tool itself.
3. **The safety model is not negotiable.** Nothing is deleted without confirmation.
   Red items are advisory only and no flag may delete them — `--level red` is
   rejected deliberately. Every code path that deletes must honour `DRY_RUN`.
4. **Both languages, always.** User-facing strings are bilingual. Catalog strings
   live in `lib/i18n.sh`; item descriptions use the inline helper
   `$(L "english" "tiếng Việt")` in `modules/*.sh`. Code comments and the log file
   are English only.
5. **The draw loop must not fork.** `lib/ui.sh` builds each frame into one string
   and writes it once. Never put `$(...)` inside a per-row, per-frame expression —
   that is what made the list flicker. Format sizes once in `build_order`, and use
   `pad`/`padl` (which write to `$PAD_OUT`) rather than command substitution.

## Layout

| Path | Role |
|---|---|
| `declutter` | CLI: argument parsing, orchestration |
| `lib/core.sh` | sizing, `human()`, padding, logging, sudo detection |
| `lib/i18n.sh` | language detection, string catalog, `usage()` |
| `lib/registry.sh` | `add()`, group validation, module loading |
| `lib/actions.sh` | the deletions (`rm`/`rmchild`/`findrm`/`agerm`/`cmd`/`note`) |
| `lib/ui.sh` | `build_order()`, `--report` list, interactive picker |
| `lib/report.sh` | `--json` output |
| `lib/runner.sh` | runs the selection, reports reclaimed space |
| `lib/projects.sh` | `--projects` scan (lists only, never deletes) |
| `modules/*.sh` | item definitions, split by tool and by OS |
| `completions/` | bash and zsh completion |
| `tests/run.sh` | the suite, inside a fake `$HOME` |

## Adding a cleanup item

One line in the right file under `modules/`:

```bash
add green ai-cli rm "" "$(L "Short description" "Mô tả ngắn")" "$H/.something/cache"
```

Signature: `add LEVEL GROUP ACTION EXTRA "description" [path...]`.

| Action | Behaviour |
|---|---|
| `rm` | delete the paths |
| `rmchild` | delete the contents, keep the directory |
| `findrm` | `EXTRA="maxdepth\|pattern"` |
| `agerm` | `EXTRA="days\|pattern"` — only entries older than N days |
| `cmd` | `EXTRA` is a shell command; paths are used only to measure size |
| `note` | report only, never deletes |

Choosing the tier: green only if losing it costs nothing but time. If it loses
history or forces a long rebuild, it is yellow. If it might be real data, or only
the user can know whether it is still needed, it is red — and then use `note`.

New groups must be added to `KNOWN_GROUPS` in `lib/registry.sh`, to the `--only`
list in both `usage_en`/`usage_vi`, and to both completion files.

## Testing

```bash
./tests/run.sh          # everything, in a fake $HOME
/bin/bash tests/run.sh  # on macOS: exercise bash 3.2 specifically
```

CI is **manual-only** (`workflow_dispatch`) — nothing runs on push or on a pull
request. Dispatch it with `gh workflow run ci`, and never assume a green tick
appeared on its own; the local suite is your feedback loop.

The suite exports `DECLUTTER_SKIP_CMD=1` because `cmd` items (`docker builder
prune`, `apt clean`, `brew cleanup`) are **not** contained by the fake `$HOME` —
they act on the real daemon and the real system. If you add a `cmd` item, the
tests will not exercise it; verify it by hand.

Two traps worth knowing:

- The suite runs with `set -o pipefail`. Never pipe `declutter` into `grep -q`:
  grep exits at the first match, declutter dies of SIGPIPE, and the pipeline reads
  as a failure even though the text was there. Write the output to a file first.
- `DECLUTTER_LANG=en` is exported so assertions on output text do not depend on
  the host locale. When you test locale detection itself, `env -u` the higher
  precedence variables — the order is `LC_ALL` > `LC_MESSAGES` > `LANG`, and CI
  runners set `LC_ALL`, so merely setting `LANG` proves nothing.

Any change that touches deletion behaviour needs a matching assertion: what must
go, and what must survive.

## Docs to keep in sync

`README.md` and `README.vi.md` are parallel documents — a change to one belongs in
the other. `docs/GUIDE.md` / `docs/GUIDE.vi.md` likewise. `llms.txt` carries the
flag list and the JSON contract; update it when either changes.
