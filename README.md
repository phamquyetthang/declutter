# declutter — free up disk space on a dev machine (macOS & Ubuntu)

**English** · [Tiếng Việt](README.vi.md)

[![ci](https://github.com/quytstudio/declutter/actions/workflows/ci.yml/badge.svg)](https://github.com/quytstudio/declutter/actions/workflows/ci.yml)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![platform: macOS | Ubuntu](https://img.shields.io/badge/platform-macOS%20%7C%20Ubuntu-lightgrey.svg)](#requirements)
[![pure bash](https://img.shields.io/badge/pure-bash%203.2%2B-89e051.svg)](#requirements)

**A disk cleanup CLI for developers.** It scans your machine, shows a checkbox
list with real sizes, pre-ticks only what is provably safe, and deletes nothing
until you press Enter.

Unlike a general-purpose cleaner, `declutter` targets the junk **AI coding tools**
leave behind — Claude Code / Codex / Gemini CLI transcripts, the WebStorage of AI
chat panels in VS Code and Cursor, HuggingFace caches, Ollama models — the
fastest-growing directories on a developer's machine today, and the ones
`apt clean` and `brew cleanup` never touch.

> Pure bash, zero dependencies, runs on bash 3.2 (the version macOS still ships).

```
declutter  —  linux  —  14.1G free on /
o = safe (pre-ticked)   ! = your call   x = manual only, not selectable
──────────────────────────────────────────────────────────────────────────
  [x] o     3.0G  Code: WebStorage (AI webview panels)           ai-ide
> [x] o     1.3G  npx cache                                      pkg-node
  [x] o     430M  Cargo registry cache (re-fetched on build)     pkg-rust
  [ ] !     250M  Claude Code: transcripts older than 60d (bre…  ai-cli
  [ ] !      42M  Code: Copilot Chat history                     ai-ide
    -  x     2.2G  Installed extensions (remove: code --uninst…  ai-ide
──────────────────────────────────────────────────────────────────────────
  Selected: 12 items — 1.8G
  [↑↓/jk] move   [space] toggle   [a] invert all   [o] safe only
  [n] clear   [enter] CLEAN   [q] quit
```

## Install

One command, same on Linux and macOS:

```bash
curl -fsSL https://raw.githubusercontent.com/quytstudio/declutter/main/install.sh | bash
```

Installs into `~/.local/bin` (override with `PREFIX=...`). If the machine has no
`git` — common on a fresh Mac, which needs Xcode Command Line Tools — the
installer falls back to downloading a tarball with `curl`. When it finishes it
prints the exact `export PATH=...` line for the rc file of the shell you actually
use (`~/.zshrc` on macOS, `~/.bashrc` on Linux).

Or clone and run it in place — no install needed:

```bash
git clone https://github.com/quytstudio/declutter.git
cd declutter && ./declutter
```

To remove it: `./install.sh --uninstall` (your `~/.declutter.log` is left alone).

## Usage

```bash
declutter                  # scan → pick → Enter. Deletes NOTHING by default.
declutter --report         # print the list and exit
declutter --json           # same list as JSON, for scripts and agents
declutter --yes            # skip the list, clean the safe tier straight away
declutter --yes -l yellow  # include the "your call" tier
declutter --dry-run --yes  # rehearse: log what WOULD go, touch nothing
declutter --projects       # list heavy node_modules/target/.venv directories
declutter --only ai-ide    # clean IDE caches only
declutter --lang vi        # Vietnamese interface (auto-detected from $LANG)
```

## Three safety tiers

| Tier | Meaning | Default |
|---|---|---|
| `o` **safe** | Caches that provably regenerate. Losing them only makes the next build or install slower. | **Pre-ticked** |
| `!` **your call** | You lose history (transcripts, Copilot Chat), or a rebuild takes a long time (Gradle caches, Go modcache). | Unticked, you turn it on |
| `x` **manual only** | Real data, or something only you know you still need: `node_modules`, Ollama models, Docker volumes, Xcode Archives, the Maven repo. | **Not selectable.** Size is shown so you can deal with it yourself |

`--level red` is refused on purpose: no flag makes this tool delete a red item
for you.

## What it cleans

Grouped, filterable with `--only a,b` / `--skip a,b`:

| Group | What is in it |
|---|---|
| `ai-cli` | Claude Code (`shell-snapshots`, `statsig`, old transcripts), Codex CLI, Gemini CLI, Cursor telemetry, Aider tags cache |
| `ai-ide` | VS Code / Cursor / Windsurf / VSCodium: `Cache`, `CachedExtensionVSIXs`, `GPUCache`, `WebStorage`, `globalStorage/github.copilot-chat`; JetBrains caches |
| `ai-ml` | CUDA/Triton JIT, PyTorch hub, HuggingFace hub, Whisper/CLIP/Keras |
| `ai-model` | Ollama and LM Studio weights — **reported only**, never deleted |
| `pkg-node` | npm, yarn, pnpm, bun, npx, Electron builder |
| `pkg-python` | pip, uv, Poetry, conda, `__pycache__` (with `--deep`) |
| `pkg-rust` | Cargo registry cache and sources |
| `pkg-go` | Go build cache, test cache, module cache |
| `pkg-java` | Gradle caches, daemon logs, wrapper dists; the Maven repo is report-only |
| `docker` | Build cache, dangling images, stopped containers |
| `browser` | Chrome / Chromium / Edge / Firefox page caches — cache directories only |
| `os` (Ubuntu) | apt cache, journal, old snap revisions, flatpak, `/var/crash`, Trash |
| `os` (macOS) | Homebrew, user logs, Trash |
| `xcode` | DerivedData, SwiftPM cache, unavailable simulators, iOS DeviceSupport |

## What it never touches

`~/.ssh` · `~/.gnupg` · `~/.aws` · `.env` files · login tokens ·
`~/.claude/settings.json`, `skills`, `agents`, `memory` ·
VS Code's `User/settings.json`, `keybindings.json`, `snippets`, `User/History` ·
browser profiles (only `~/.cache` and `~/Library/Caches` are in scope) ·
Docker volumes · Xcode Archives · the Maven repo · Timeshift / Time Machine
snapshots · `node_modules` and `target/` (listed via `--projects`, never removed).

## Safety

- **Nothing is deleted by default.** You press Enter, or you pass `--yes`.
- `--dry-run` logs every exact path it would remove and touches no disk.
- Every action is appended to `~/.declutter.log`.
- An item that does not exist never appears — the list is always what is really
  on your machine.
- `/tmp/claude-*` is only cleared for entries older than a day, so a running
  session is never killed.

## JSON output, for scripts and AI agents

`declutter --json` prints the same list as a single JSON object, so an agent or a
script can decide what to clean without driving the TUI:

```bash
# the five biggest safe items, largest first
declutter --json | jq -r '.items[] | select(.level=="green")
  | "\(.size_human)\t\(.desc)"' | head -5

# total reclaimable at the safe tier
declutter --json | jq '.totals.preselected_human'
```

Each item carries `level`, `group`, `action`, `desc`, `size_kb`, `size_human`,
`paths[]`, `selectable` (false for red) and `preselected`. The shape is stable
from 1.1.0 onward.

## FAQ

### Is it safe to run?

Yes, in the sense that matters: it deletes nothing until you say so, and the
pre-ticked tier is caches only. The tests assert that a green run leaves
`~/.ssh`, `~/.claude/settings.json`, VS Code settings, `workspaceStorage`, the
Maven repo and every transcript untouched. Run `declutter --dry-run --yes` first
if you want to read the exact list of paths before anything happens.

### Will it delete my Claude Code chat history?

Not at the default tier. Transcripts (`~/.claude/projects/*.jsonl`) sit in the
`!` tier, are never pre-ticked, and only entries older than `--days N` (60 by
default) are ever considered. Deleting them means losing `--resume` for those
sessions. `~/.claude/settings.json`, `skills`, `agents` and `memory` are in the
never-touch list.

### How much space does it actually free?

On a working developer machine, typically 5–40 GB. The usual biggest wins are
VS Code / Cursor `WebStorage` and caches, `~/.npm/_npx`, the Cargo registry
cache, Xcode `DerivedData` on macOS, and the Docker build cache. Run
`declutter --report` to see your own numbers before deciding.

### Does it work on macOS?

Yes — macOS and Ubuntu/Debian are the two supported platforms, from the same
script. It runs on the bash 3.2 that macOS ships, and CI tests every commit on
`macos-latest` with `/bin/bash` specifically for that reason. Xcode, Homebrew,
simulator and iOS DeviceSupport cleanup are macOS-only groups.

### How is this different from CleanMyMac, BleachBit or `brew cleanup`?

Those clean the *operating system*. `declutter` cleans the *developer toolchain*,
and in particular the AI-tool directories none of them know about: AI chat
webview storage, model caches, CLI transcripts. It is also a 2,000-line bash
script with no daemon, no telemetry, no subscription — you can read everything it
will ever delete before you run it.

### Can I add my own cleanup item?

Yes, one line in a file under `modules/`. See [Adding a cleanup item](#adding-a-cleanup-item).

### How do I uninstall it?

`./install.sh --uninstall`, or delete `~/.local/bin/declutter` and
`~/.local/share/declutter` by hand.

### Does it phone home?

No. There is no network call anywhere in the tool. `install.sh` is the only thing
that downloads, and only from GitHub.

## Requirements

- macOS (bash 3.2+, the stock one is fine) or Ubuntu/Debian
- `bash`, `du`, `df`, `find`, `awk`, `sort` — all part of a base install
- No package manager, no runtime, no root. `sudo` is used only for the
  Ubuntu system items, and only if it is already available without a password
  prompt.

## Development

```bash
./tests/run.sh     # 68 assertions inside a fake $HOME, your real machine untouched
```

The tests set `DECLUTTER_SKIP_CMD=1` because command-style items
(`docker builder prune`, `apt clean`, `brew cleanup`) are **not** contained by
the fake `$HOME` — they act on the real daemon and the real system.

### Adding a cleanup item

One `add` line in a file under `modules/`:

```bash
add green ai-cli rm "" "$(L "Short description" "Mô tả ngắn")" "$H/.something/cache"
```

`L "english" "tiếng Việt"` is the bilingual helper; see `lib/i18n.sh`.

| Action | What it does |
|---|---|
| `rm` | delete the paths |
| `rmchild` | delete the contents, keep the directory (Trash) |
| `findrm` | `EXTRA="maxdepth\|pattern"` |
| `agerm` | `EXTRA="days\|pattern"` — only entries older than N days |
| `cmd` | run a command; paths are only used to measure size |
| `note` | report only, never deletes |

## Architecture

```
declutter          # CLI: argument parsing, orchestration
lib/core.sh        # sizing, formatting, logging, sudo
lib/i18n.sh        # bilingual strings (English + Vietnamese)
lib/registry.sh    # add() + module loading
lib/actions.sh     # the deletions (honours --dry-run)
lib/ui.sh          # the interactive checkbox list
lib/report.sh      # --json output
lib/runner.sh      # runs the selection, reports space reclaimed
lib/projects.sh    # scans for node_modules/target/.venv
modules/*.sh       # item definitions, split by tool and by OS
completions/       # bash + zsh completion
tests/run.sh       # the suite, inside a fake $HOME
```

## Documentation

[docs/GUIDE.md](docs/GUIDE.md) — the complete manual disk-cleanup reference for
macOS and Ubuntu, every command labelled with its safety tier. Use it when you
would rather run the commands yourself than use the tool.
([Tiếng Việt](docs/GUIDE.vi.md))

## License

MIT © [phamquyetthang](https://github.com/phamquyetthang)
