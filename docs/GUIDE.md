# Disk cleanup reference for developers — Ubuntu & macOS

[English](GUIDE.md) · [Tiếng Việt](GUIDE.vi.md)

Every terminal command worth knowing to **find out what is eating your disk** and
then reclaim it: **AI tool junk** (transcripts, IDE caches, model weights), system
caches, package manager caches, dev environments (Node/Python/Rust/Go/Java/Docker)
and the OS-specific junk directories.

The AI section comes **first (§A)** because it is the fastest-growing group today
and no OS cleanup tool touches it.

> **The golden rule:** *measure first, delete second.* Run **§0 Diagnostics**
> before anything else, so you know where the gigabytes actually are. Deleting
> blindly usually reclaims a few hundred megabytes while the real culprit is one
> 40 GB `node_modules` / `DerivedData` / Docker volume.

**The safety labels used throughout this document:**

| Label | Meaning |
|---|---|
| 🟢 Safe | Deletes regenerable cache only. Run it freely. |
| 🟡 Your call | Losing the cache makes the next build or install slow, or logs you out of something. |
| 🔴 Careful | May lose real data / needs the app closed / cannot be undone. |

**Convention:** *every* command that deletes something carries a label — either at
the start of the bullet, or as a comment at the end of the line inside a code
block. A command with **no delete label** is **read-only** (`du`, `df`,
`find … -print`, `ls`, `*list`) and safe to run. When a command both measures and
deletes, the label describes the deleting half.

---

## ⚠️ macOS users read this first: zsh globs differ from bash

macOS defaults to **zsh**. When a `*` pattern **matches nothing**, zsh **errors
out and cancels the whole command**, where bash keeps the literal string and
carries on:

```
zsh: no matches found: /Users/thang/.aider*
```

That means **one** missing path stops the entire loop from running a single line —
even with `2>/dev/null`, because the failure happens while zsh expands the glob,
**before** the command is invoked, so the redirect cannot help.

Every **deleting** command in this document has been rewritten to be **glob-free**
(`find … -exec` instead of `rm -rf dir/*`) so it behaves identically in both
shells. Some **listing** commands still need `*` (e.g. `du -sh ~/.claude/*`). If
you hit `no matches found`:

```bash
setopt +o nomatch     # 🟢 shell behaviour only, gone when you close the terminal
```

To disable it permanently, add `unsetopt nomatch` to `~/.zshrc`. To check which
shell you are in: `echo $SHELL`.

The other macOS (BSD) ↔ Ubuntu (GNU) differences are already handled below: `du`
has no `--max-depth` (use `-d`), `find` has no `-printf`, `find` does have
`-mindepth`. `sort -rh` works on **both**, so it is used freely.

---

## §0. Diagnostics: where is the space?

> 🟢 **All of §0 is read-only** — nothing in this section deletes anything. The
> single exception: inside `ncdu` you can press `d` to delete — that is your own
> keystroke, and it is 🔴 (immediate, no trash).

### 0.1 Disk overview (both OSes)

```bash
df -h            # free space per partition
df -h /          # the system volume only
```

### 0.2 Which directories are heaviest

```bash
# Top 20 heaviest directories here
du -sh -- * .[!.]* 2>/dev/null | sort -rh | head -20

# Scan the whole home directory
du -sh ~/* ~/.[!.]* 2>/dev/null | sort -rh | head -25
```

Ubuntu — whole-system scan (`-x` = do not cross filesystems):

```bash
sudo du -xh / --max-depth=1 2>/dev/null | sort -rh | head -20
```

macOS — BSD `du` has no `--max-depth`, use `-d`:

```bash
sudo du -xh -d 1 / 2>/dev/null | sort -rh | head -20
sudo du -xh -d 1 ~/Library 2>/dev/null | sort -rh | head -20
```

### 0.3 Interactive tools (recommended — far faster than `du`)

```bash
# Ubuntu
sudo apt install ncdu
ncdu -x /                       # browse the tree, press 'd' to delete

# macOS
brew install ncdu
ncdu -x /                       # or: brew install dust && dust -d 2 ~
```

GUI options: Ubuntu has **Disk Usage Analyzer** (`baobab`); macOS has
* → About This Mac → Storage → Manage*, or the **GrandPerspective** app.

### 0.4 Finding individual large files

```bash
# Files > 500 MB in home
find ~ -type f -size +500M -exec ls -lh {} \; 2>/dev/null | awk '{print $5, $9}'

# The 20 largest files on the machine (Ubuntu)
sudo find / -xdev -type f -printf '%s %p\n' 2>/dev/null | sort -rn | head -20

# macOS (BSD find has no -printf)
sudo find / -xdev -type f -size +500M 2>/dev/null -exec ls -lh {} + | awk '{print $5, $9}'
```

---

# PART A — AI TOOLS (clean these first)

This is the **newest and fastest-growing** junk on a dev machine, and almost no OS
cleanup tool touches it: conversation transcripts, IDE webview caches, downloaded
extension VSIXs, and **model weights measured in tens of gigabytes**.

**One command to measure it all — run this first:**

```bash
# 🟢 read-only. No globs at all → correct in both bash and zsh (macOS).
for p in ~/.claude ~/.codex ~/.gemini ~/.cursor ~/.windsurf ~/.continue \
         ~/.aider.tags.cache.v3 ~/.aider.chat.history.md \
         ~/.ollama ~/.lmstudio ~/.copilot ~/.anthropic \
         ~/.cache/huggingface ~/.cache/torch ~/.cache/whisper ~/.cache/lm-studio \
         ~/.keras ~/.triton ~/.nv ~/.cache/claude-cli-nodejs \
         ~/.vscode/extensions ~/.cursor/extensions \
         ~/.config/Code ~/.config/Cursor ~/.config/Windsurf \
         ~/Library/Application\ Support/Code \
         ~/Library/Application\ Support/Cursor \
         ~/Library/Application\ Support/Windsurf \
         ~/Library/Caches/JetBrains; do
  [ -e "$p" ] && du -sh "$p" 2>/dev/null
done | sort -rh
```

> Real numbers from one Ubuntu dev machine with heavy AI tool use, to give you a
> sense of scale: `~/.config/Code` **5.0 G**, `~/.vscode/extensions` **1.6 G**,
> `~/.cursor` **638 M**, `~/.claude` **369 M**, `~/.codex` **150 M**,
> `~/.gemini` **104 M** — over **7 GB** that `apt clean` cannot touch a byte of.

---

## A1. Terminal coding assistants (Claude Code, Codex, Gemini CLI, Aider)

The bulk of it is **conversation transcripts** (JSONL/SQLite) accumulating per
project.

**Claude Code** — see what is heavy:

```bash
du -sh ~/.claude/* 2>/dev/null | sort -rh | head
```

You will usually see: `projects/` (transcripts, the heaviest), `plugins/`,
`file-history/`, `shell-snapshots/`, `todos/`, `statsig/`, `backups/`.

* 🟡 **Delete transcripts older than 30 days** — the trade-off: you can no longer
  `--resume`/`--continue` those sessions:
    ```bash
    du -sh ~/.claude/projects/* 2>/dev/null | sort -rh | head      # look first
    find ~/.claude/projects -name '*.jsonl' -mtime +30 -print      # check the list
    # only once you agree, change -print to -delete
    ```
* 🟢 **Junk that provably regenerates:**
    ```bash
    # glob-free → works in zsh; these directories rebuild themselves on next run
    rm -rf ~/.claude/shell-snapshots ~/.claude/statsig ~/.cache/claude-cli-nodejs
    find /tmp -maxdepth 1 -name 'claude-*' -exec rm -rf {} + 2>/dev/null
    ```
* 🟡 **File-edit history & backups** (used to undo older changes):
    ```bash
    du -sh ~/.claude/file-history ~/.claude/backups
    find ~/.claude/file-history -mtime +30 -delete
    ```
* 🔴 **Do not delete**: `~/.claude/settings.json`, `~/.claude.json`,
  `~/.claude/CLAUDE.md`, `~/.claude/skills`, `~/.claude/agents`,
  `~/.claude/memory` — configuration and memory you wrote yourself, not
  regenerable.

**Codex CLI:**

```bash
du -sh ~/.codex/* 2>/dev/null | sort -rh
rm -rf ~/.codex/cache                                  # 🟢
find ~/.codex/sessions -mtime +30 -delete              # 🟡 loses session history
ls -lh ~/.codex/logs*.sqlite                           # 🟡 log files can be tens of MB
```

**Gemini CLI / Antigravity:**

```bash
du -sh ~/.gemini/* 2>/dev/null | sort -rh
rm -rf ~/.gemini/tmp ~/.gemini/cache 2>/dev/null       # 🟢
```

**Aider** — its junk lives **inside each repo**, not in home:

```bash
# 🟢 read-only — find Aider caches and chat history scattered across repos
find ~ -name '.aider.tags.cache.v*' -type d -prune 2>/dev/null \
  | xargs -I{} du -sh {} 2>/dev/null | sort -rh | head
find ~ \( -name '.aider.chat.history.md' -o -name '.aider.input.history' \) 2>/dev/null

# 🟢 tags cache — Aider rebuilds it on the next run
find ~ -name '.aider.tags.cache.v*' -type d -prune -exec rm -rf {} + 2>/dev/null
# 🔴 chat history is data you produced — review it, then delete file by file
```

**The rule for this whole group:** transcripts are data **you** created. If a
conversation matters, export or copy it before any bulk delete.

## A2. AI-enabled IDEs (VS Code + Copilot, Cursor, Windsurf)

This is usually the **heaviest directory in a dev machine's home** — mostly the
webview storage of AI chat panels plus downloaded extensions.

Paths per OS:

| Component | Ubuntu | macOS |
|---|---|---|
| VS Code | `~/.config/Code` | `~/Library/Application Support/Code` |
| Cursor | `~/.config/Cursor` | `~/Library/Application Support/Cursor` |
| Windsurf | `~/.config/Windsurf` | `~/Library/Application Support/Windsurf` |
| Extensions | `~/.vscode/extensions`, `~/.cursor/extensions` | same as Ubuntu (they live in `~`) |

**Quit the IDE before running any of the commands below.**

```bash
BASE=~/.config/Code          # macOS: BASE=~/Library/Application\ Support/Code
du -sh "$BASE"/* 2>/dev/null | sort -rh | head -8
```

* 🟢 **Pure cache — delete freely:**
    ```bash
    rm -rf "$BASE"/Cache "$BASE"/CachedData "$BASE"/CachedExtensionVSIXs \
           "$BASE"/Code\ Cache "$BASE"/GPUCache "$BASE"/logs
    ```
    `CachedExtensionVSIXs` holds the `.vsix` files downloaded to install
    extensions — useless once installed (**654 MB** on the measured machine).
* 🟡 **`WebStorage` — the single biggest offender, the storage behind the AI chat
  webviews** (**3.1 GB** measured). Deleting it loses the display state of some
  panels; it never touches code:
    ```bash
    du -sh "$BASE"/WebStorage
    rm -rf "$BASE"/WebStorage
    ```
* 🟡 **`User/globalStorage` — extension data, including Copilot Chat history:**
    ```bash
    du -sh "$BASE"/User/globalStorage/* 2>/dev/null | sort -rh | head
    rm -rf "$BASE"/User/globalStorage/github.copilot-chat     # loses Copilot chat history
    ```
* 🟡 **`User/workspaceStorage` — per-folder state for everything you ever opened**
  (**241 MB** measured). Most entries point at projects deleted long ago:
    ```bash
    du -sh "$BASE"/User/workspaceStorage | tail -1
    find "$BASE"/User/workspaceStorage -maxdepth 1 -mtime +180 -print   # check first
    ```
* 🟡 **Extensions — uninstall what you don't use instead of nuking the folder:**
    ```bash
    du -sh ~/.vscode/extensions/* 2>/dev/null | sort -rh | head -15
    code --list-extensions
    code --uninstall-extension <publisher.name>
    ```
    Wiping `~/.vscode/extensions` outright also works (🟡) — VS Code reinstalls
    them if you have Settings Sync on, but everything has to download again.
* 🔴 **Do not delete**: `User/settings.json`, `User/keybindings.json`,
  `User/snippets`, `User/History` (the local history of files you edited — it can
  save uncommitted code).

Cursor/Windsurf add their own directories in home:

```bash
du -sh ~/.cursor/* 2>/dev/null | sort -rh          # extensions, projects, ai-tracking…
rm -rf ~/.cursor/ai-tracking 2>/dev/null           # 🟢 local telemetry
```

## A3. Local models (Ollama, LM Studio, llama.cpp, GGUF)

This group is measured **in tens of gigabytes, not megabytes**. If you have it
installed, it is almost certainly the heaviest thing in this entire document.

**Ollama:**

```bash
ollama list                                   # models and their sizes
du -sh ~/.ollama/models 2>/dev/null           # macOS: same path
ollama rm llama3:70b                          # 🔴 gone; getting it back is a ~40GB pull
ollama ps                                     # which models are loaded in RAM
```

If you run Ollama in Docker, the models live in a volume:
`docker volume ls | grep ollama`, then `docker volume rm <name>` (🔴).

**LM Studio:**

```bash
du -sh ~/.lmstudio/models ~/.cache/lm-studio 2>/dev/null
# macOS: ~/.lmstudio, ~/Library/Application Support/LM Studio
```

**Stray GGUF/safetensors files** (downloaded by hand, forgotten in Downloads):

```bash
find ~ -type f \( -name '*.gguf' -o -name '*.safetensors' -o -name '*.ckpt' -o -name '*.pt' \) \
  -size +200M 2>/dev/null -exec ls -lh {} + | awk '{print $5, $9}' | sort -rh
```

## A4. ML library caches (HuggingFace, PyTorch, MediaPipe, Whisper, CUDA)

Models downloaded automatically when code runs — easy to forget, because nobody
deliberately downloaded them.

```bash
du -sh ~/.cache/huggingface ~/.cache/torch ~/.cache/whisper \
       ~/.keras ~/.cache/clip ~/.triton ~/.nv 2>/dev/null | sort -rh
```

* 🟡 **HuggingFace** — it ships a selective deletion tool, better than `rm -rf`:
    ```bash
    huggingface-cli scan-cache          # table of models, sizes, last use
    huggingface-cli delete-cache        # pick revisions to drop (interactive)
    # or bluntly:
    rm -rf ~/.cache/huggingface/hub
    ```
    *(Set `HF_HOME=/other/disk/hf` in `~/.bashrc`/`~/.zshrc` to move the cache to
    a roomier disk instead of cleaning it periodically.)*
* 🟢 **PyTorch / Keras / Whisper / CLIP:**
    ```bash
    rm -rf ~/.cache/torch/hub ~/.cache/torch/checkpoints
    rm -rf ~/.cache/whisper ~/.cache/clip
    du -sh ~/.keras/models 2>/dev/null
    ```
* 🟢 **GPU JIT caches** (regenerate themselves, only the first run is slower):
    ```bash
    rm -rf ~/.nv/ComputeCache ~/.triton/cache
    ```
* 🟡 **Virtualenvs containing `torch`/`mediapipe`/`onnxruntime`** — 2–6 GB each,
  and usually duplicated across several projects:
    ```bash
    find ~ -maxdepth 5 -type d \( -name '.venv' -o -name 'venv' \) -prune 2>/dev/null \
      | xargs -I{} du -sh {} 2>/dev/null | sort -rh | head -10
    ```
    Deletable, because `pip install -r requirements.txt` rebuilds them — but
    **check whether the project is still in use** first. See also §D2.

## A5. AI-generated images and video

Output from Stable Diffusion, ComfyUI, Automatic1111… is **real data** (🔴) — only
clean the models and caches, and review output directories by hand:

```bash
du -sh ~/stable-diffusion-webui/models ~/ComfyUI/models 2>/dev/null
du -sh ~/stable-diffusion-webui/outputs ~/ComfyUI/output 2>/dev/null
```

## A6. One-shot AI combo (🟢 — cache only, transcripts untouched)

Quit your IDE first:

```bash
# 🟢 THE WHOLE BLOCK deletes only regenerable cache: no transcripts
# (~/.claude/projects, ~/.codex/sessions), no settings, no models.
CODE=~/.config/Code   # macOS: CODE=~/Library/Application\ Support/Code
rm -rf "$CODE"/Cache "$CODE"/CachedData "$CODE"/CachedExtensionVSIXs "$CODE"/GPUCache "$CODE"/logs \
  && rm -rf ~/.claude/shell-snapshots ~/.claude/statsig ~/.cache/claude-cli-nodejs \
  && rm -rf ~/.codex/cache ~/.gemini/tmp ~/.cursor/ai-tracking \
  && find /tmp -maxdepth 1 -name 'claude-*' -exec rm -rf {} + 2>/dev/null \
  && rm -rf ~/.nv/ComputeCache ~/.triton/cache ~/.cache/torch/hub \
  && df -h /
```

---

# PART B — UBUNTU / DEBIAN

## B1. System cleanup (the basics)

* 🟢 **Drop dependencies nothing needs any more** (old kernels included):
    ```bash
    sudo apt autoremove -y
    ```
* 🔴 **Also purge those packages' config files** (heavier handed, clears old
  kernels completely):
    ```bash
    sudo apt autoremove --purge -y
    ```
* 🟢 **Delete every downloaded `.deb` in the package cache:**
    ```bash
    sudo apt clean
    ```
* 🟢 **Delete only stale/superseded `.deb` files** (gentler than `clean`):
    ```bash
    sudo apt autoclean
    ```
* 🟢 **Vacuum the system journal** — keep 3 days, or cap it by size:
    ```bash
    journalctl --disk-usage            # how much the logs take
    sudo journalctl --vacuum-time=3d
    sudo journalctl --vacuum-size=200M
    ```
* 🟢 **Old rotated logs in `/var/log`:**
    ```bash
    sudo find /var/log -type f -regex '.*\.\(gz\|old\|[0-9]+\)$' -delete
    ```
* 🟢 **Empty the trash:**
    ```bash
    find ~/.local/share/Trash -mindepth 1 -delete 2>/dev/null   # glob-free, zsh-safe
    ```
* 🟢 **Old crash reports (`/var/crash`) — often several GB:**
    ```bash
    sudo rm -rf /var/crash/*
    ```
* 🟡 **Check which kernel you are on before removing old ones:**
    ```bash
    uname -r                                  # the running kernel — NEVER remove this one
    dpkg -l 'linux-image-*' | grep '^ii'      # installed kernels
    ```

## B2. Snap, Flatpak, orphaned configs

* 🟢 **Remove old Snap revisions (usually several GB):**
    ```bash
    LANG=C snap list --all | awk '/disabled/{print $1, $3}' \
      | while read -r snapname revision; do
          sudo snap remove "$snapname" --revision="$revision"
        done
    ```
* 🟡 **Cap snap at 2 retained revisions (stops the junk at the source):**
    ```bash
    sudo snap set system refresh.retain=2
    ```
* 🟢 **Flatpak — remove runtimes nothing uses:**
    ```bash
    flatpak uninstall --unused -y
    flatpak repair --user
    ```
* 🟡 **Purge leftover config of removed software (residual `rc` configs):**
    ```bash
    dpkg -l | awk '/^rc/ { print $2 }' | sudo xargs --no-run-if-empty dpkg --purge
    ```
* 🔴 **Wipe the whole user cache** — safe data-wise, but it will **log you out of
  some apps / lose thumbnails / make the next app launch slow**. Quit everything
  first:
    ```bash
    rm -rf ~/.cache/*
    # Gentler — thumbnails only:
    rm -rf ~/.cache/thumbnails
    ```

## B3. Timeshift / snapshots (if installed)

🔴 Snapshots are system backups — deleting them removes your ability to roll back.

```bash
sudo timeshift --list                                       # 🟢 read-only
sudo timeshift --delete --snapshot '2025-01-01_00-00-00'    # 🔴 that restore point is gone for good
```

## B4. One-shot Ubuntu combo (🟢)

```bash
# 🟢 the whole block: only regenerable packages/caches/logs. Trash is 🟡 — check
# `ls ~/.local/share/Trash/files` first if you use it as temporary storage.
sudo apt autoremove -y && sudo apt autoclean && sudo apt clean \
  && sudo journalctl --vacuum-time=3d \
  && find ~/.local/share/Trash -mindepth 1 -delete 2>/dev/null \
  && rm -rf ~/.cache/thumbnails \
  && df -h /
```

---

# PART C — macOS

macOS has no `apt`/`snap`/`journalctl`. Quick translation table:

| What you want | Ubuntu | macOS |
|---|---|---|
| System package manager | `apt` | `brew` |
| Package cache | `sudo apt clean` | `brew cleanup -s --prune=all` |
| Remove orphaned dependencies | `apt autoremove` | `brew autoremove` |
| System logs | `journalctl --vacuum-*` | `sudo rm -rf /private/var/log/*.gz` |
| Trash | `~/.local/share/Trash` | `~/.Trash` |
| User cache | `~/.cache` | `~/Library/Caches` |
| System snapshots | Timeshift | APFS local snapshots (`tmutil`) |

## C1. Homebrew

* 🟢 **Clear old versions and the download cache (typically 5–20 GB):**
    ```bash
    brew cleanup -s --prune=all
    rm -rf "$(brew --cache)"
    ```
* 🟡 **Remove formulae that only exist as dependencies of something you removed:**
    ```bash
    brew autoremove
    ```
* **See what is heavy, to decide what to remove by hand:**
    ```bash
    brew list --formula
    brew list --cask
    du -sh "$(brew --prefix)"/Cellar/* 2>/dev/null | sort -rh | head -20
    brew doctor
    ```

## C2. Xcode & iOS development — the biggest junk source on a Mac dev machine

* 🟢 **DerivedData (build cache — often 20–80 GB):**
    ```bash
    du -sh ~/Library/Developer/Xcode/DerivedData
    rm -rf ~/Library/Developer/Xcode/DerivedData      # Xcode recreates the directory
    ```
* 🟡 **iOS DeviceSupport — symbols for old iOS versions, ~3–6 GB each:**
    ```bash
    du -sh ~/Library/Developer/Xcode/iOS\ DeviceSupport/*
    rm -rf ~/Library/Developer/Xcode/iOS\ DeviceSupport/*     # keep only the iOS you test on
    ```
* 🟢 **Simulator junk (unavailable runtimes and devices):**
    ```bash
    xcrun simctl delete unavailable
    xcrun simctl shutdown all && xcrun simctl erase all       # 🟡 wipes all simulator data
    rm -rf ~/Library/Developer/CoreSimulator/Caches/*
    du -sh ~/Library/Developer/CoreSimulator/Devices          # check first
    ```
* 🔴 **Archives (`.xcarchive` files for App Store submissions — needed to
  symbolicate crash reports):**
    ```bash
    du -sh ~/Library/Developer/Xcode/Archives
    # Archives older than 90 days (-mindepth 2 keeps the root directory safe):
    find ~/Library/Developer/Xcode/Archives -mindepth 2 -maxdepth 2 -type d -mtime +90 -print
    # read that list, and only then swap -print for: -exec rm -rf {} +
    ```
* 🟢 **Other Xcode / SwiftPM caches:**
    ```bash
    rm -rf ~/Library/Caches/org.swift.swiftpm
    rm -rf ~/Library/Developer/Xcode/UserData/IB\ Support
    rm -rf ~/Library/Developer/Xcode/iOS\ Device\ Logs/*
    ```

## C3. macOS system caches & logs

* 🟡 **User caches** — quit every app before running this:
    ```bash
    du -sh ~/Library/Caches/* | sort -rh | head -20     # look first
    rm -rf ~/Library/Caches/*
    ```
* 🟡 **User logs:**
    ```bash
    rm -rf ~/Library/Logs/*
    ```
* 🔴 **System-level caches** (needs `sudo`; some apps may need reopening):
    ```bash
    sudo rm -rf /Library/Caches/*
    sudo rm -rf /private/var/log/*.gz /private/var/log/asl/*.asl
    ```
* 🟢 **Trash (external drives included):**
    ```bash
    find ~/.Trash -mindepth 1 -delete 2>/dev/null              # glob-free → zsh-safe
    sudo find /Volumes -maxdepth 2 -name '.Trashes' -exec rm -rf {} + 2>/dev/null
    ```
* 🟢 **Release held RAM/disk cache (safe, the machine stutters for a few seconds):**
    ```bash
    sudo purge
    ```

## C4. APFS local snapshots & "purgeable space"

This is the classic reason Finder claims 5 GB free while `du` accounts for far
less data: Time Machine keeps local snapshots on the disk itself.

```bash
tmutil listlocalsnapshots /                       # list the snapshots
```

* 🟡 **Force the system to thin snapshots until 20 GB is free** (`4` = the most
  urgent priority):
    ```bash
    sudo tmutil thinlocalsnapshots / 21474836480 4
    ```
* 🔴 **Delete one specific snapshot outright:**
    ```bash
    sudo tmutil deletelocalsnapshots 2025-01-01-000000
    ```

## C5. Other macOS-specific junk

* 🔴 **iPhone/iPad backups (very large, and real data):**
    ```bash
    du -sh ~/Library/Application\ Support/MobileSync/Backup/*
    ```
* 🟡 **Downloaded Mail attachments:**
    ```bash
    du -sh ~/Library/Containers/com.apple.mail/Data/Library/Mail\ Downloads 2>/dev/null
    ```
* 🟡 **Docker Desktop — the virtual disk file (see also §D6):**
    ```bash
    du -sh ~/Library/Containers/com.docker.docker/Data/vms 2>/dev/null
    ```
* 🟢 **Old installers/DMGs in Downloads:**
    ```bash
    find ~/Downloads -type f \( -name '*.dmg' -o -name '*.pkg' -o -name '*.zip' \) \
      -mtime +30 -exec ls -lh {} + | awk '{print $5, $9}'
    ```
* 🟡 **Partially downloaded iOS/macOS software updates:**
    ```bash
    sudo rm -rf /Library/Updates/*
    ```

## C6. One-shot macOS combo (🟢)

```bash
# 🟢 the whole block: brew cache, DerivedData, simulator junk, trash.
# 🟡 only ~/.Trash — make sure nothing in there still matters.
brew cleanup -s --prune=all \
  && rm -rf "$(brew --cache)" ~/Library/Developer/Xcode/DerivedData \
  && find ~/.Trash -mindepth 1 -delete 2>/dev/null \
  && xcrun simctl delete unavailable \
  && sudo purge \
  && df -h /
```

---

# PART D — DEV ENVIRONMENTS (both OSes)

On a developer machine this part usually reclaims **more than the OS sections do**.
Every line that deletes something is labelled inside the code block.

## D1. Node.js — NVM, npm, yarn, pnpm, bun

**Node versions via NVM:**

```bash
nvm ls                              # 🟢 read-only — an N/A line means not installed, no space used
du -sh ~/.nvm/versions/node/* | sort -rh   # 🟢 read-only
nvm uninstall 14.17.0               # 🟡 removes one Node; projects pinned to it break
nvm current && cat .nvmrc 2>/dev/null      # 🟢 check what you are on BEFORE removing anything
```

*(Installed via Homebrew on macOS? Use `brew uninstall node@18` — also 🟡. With
`fnm`/`volta`, remove from `~/.local/share/fnm` / `~/.volta/tools` the same way.)*

**Package manager caches:**

```bash
du -sh ~/.npm ~/.cache/yarn ~/Library/Caches/Yarn ~/.bun/install/cache 2>/dev/null  # 🟢 read-only
pnpm store path && du -sh "$(pnpm store path)"   # 🟢 read-only

npm cache clean --force            # 🟢 ~/.npm — re-downloaded on next install
yarn cache clean                   # 🟢 yarn classic
yarn cache clean --all             # 🟢 yarn berry
pnpm store prune                   # 🟢 only packages no project references
bun pm cache rm                    # 🟢
rm -rf ~/.npm/_npx                 # 🟢 the npx cache
```

> ⚠️ These are only 🟢 while you are **online**. If you are about to work offline
> or you are on a slow connection, losing the cache means `npm install` stops
> working → treat it as 🟡 instead.

**`node_modules` — culprit number one.**

```bash
# 🟢 read-only — every node_modules with its size, heaviest first
find ~ -name node_modules -type d -prune 2>/dev/null \
  | xargs -I{} du -sh {} 2>/dev/null | sort -rh | head -20

# 🟢 read-only — which projects you have not touched in 90 days
find ~/projects -name node_modules -type d -prune -mtime +90 -print

# 🔴 ACTUAL DELETE — only after reading the list above carefully.
# The risk: a project on an old lockfile, or with a package pulled from the
# registry, will not reinstall identically. Never touch a repo mid-task.
# find ~/projects -name node_modules -type d -prune -mtime +90 -exec rm -rf {} +
```

```bash
npx npkill        # 🟡 interactive — you pick the directories, and they go immediately
```

**Electron / build output:**

```bash
du -sh ~/.cache/electron ~/.electron ~/.cache/electron-builder 2>/dev/null   # 🟢 read-only
rm -rf ~/.cache/electron ~/.electron ~/.cache/electron-builder    # 🟡 next Electron build re-downloads ~200MB per version
rm -rf ~/Library/Caches/electron ~/Library/Caches/electron-builder   # 🟡 macOS, same thing
```

## D2. Python

```bash
du -sh ~/.cache/pip ~/.cache/uv ~/.cache/pypoetry 2>/dev/null   # 🟢 read-only

pip cache purge                       # 🟢 wheel cache — re-downloadable
uv cache clean                        # 🟢 if you use uv
conda clean --all -y                  # 🟡 drops package tarballs + index; envs stay intact
rm -rf ~/.cache/pypoetry              # 🟢 Poetry (Ubuntu)
rm -rf ~/Library/Caches/pypoetry      # 🟢 Poetry (macOS)
```

```bash
# 🟢 bytecode regenerates on the next run — completely safe
find ~ -type d -name __pycache__ -prune -exec rm -rf {} + 2>/dev/null
find ~ -type f -name '*.pyc' -delete 2>/dev/null
```

```bash
# 🟢 read-only — find heavy virtualenvs (ones with torch/mediapipe are 2–6 GB, see §A4)
find ~ -maxdepth 4 -type d \( -name '.venv' -o -name 'venv' \) -prune 2>/dev/null \
  | xargs -I{} du -sh {} 2>/dev/null | sort -rh | head

# 🔴 delete one specific venv — rebuildable from requirements.txt/pyproject.toml,
# BUT only while that file exists and its pins still install. Check first:
# ls <project>/requirements.txt <project>/pyproject.toml && rm -rf <project>/.venv
```

## D3. Rust

`target/` is a black hole — a few GB per project is normal.

```bash
du -sh ~/.cargo/registry ~/.cargo/git        # 🟢 read-only
# 🟢 read-only — find every target/ directory
find ~ -type d -name target -prune 2>/dev/null \
  | xargs -I{} du -sh {} 2>/dev/null | sort -rh | head -20

cargo clean                                  # 🟡 per project — the next build is a full rebuild (slow)
rm -rf ~/.cargo/registry/cache ~/.cargo/registry/src   # 🟢 re-fetched when you build
```

```bash
cargo install cargo-sweep                    # 🟢 installs the tool only
cargo sweep --time 30 --dry-run --recursive ~/projects   # 🟢 preview what would go
cargo sweep --time 30 --recursive ~/projects             # 🟡 removes artifacts >30 days old in every target/
```

```bash
rustup toolchain list                        # 🟢 read-only
rustup toolchain uninstall nightly-2023-01-01   # 🟡 projects pinning it (rust-toolchain.toml) re-download
```

## D4. Go

```bash
du -sh "$(go env GOMODCACHE)" "$(go env GOCACHE)"   # 🟢 read-only

go clean -cache        # 🟢 build cache — next build is slower, nothing is lost
go clean -testcache    # 🟢 cached test results
go clean -modcache     # 🟡 module cache — every dependency re-downloads, breaks you offline
```

## D5. Java / Android / Gradle / Maven

```bash
du -sh ~/.gradle ~/.m2/repository 2>/dev/null   # 🟢 read-only
du -sh ~/Android/Sdk ~/Library/Android/sdk 2>/dev/null   # 🟢 read-only
du -sh ~/.android/avd/* 2>/dev/null             # 🟢 read-only — a few GB per emulator

./gradlew --stop                       # 🟢 stops the daemon only — REQUIRED before deleting
# 🟢 incremental build cache only (find instead of a glob, for zsh)
find ~/.gradle/caches -maxdepth 1 -name 'build-cache-*' -exec rm -rf {} + 2>/dev/null
rm -rf ~/.gradle/daemon                # 🟢 daemon logs
rm -rf ~/.gradle/caches                # 🟡 next build re-downloads every dependency (very slow)
rm -rf ~/.gradle/wrapper/dists         # 🟡 every project re-downloads its Gradle version
rm -rf ~/.m2/repository                # 🟡 Maven — same, and it also loses your local `mvn install` artifacts
```

> 🔴 `~/.m2/repository` can hold **internal artifacts you built and installed
> yourself** that no repository can re-fetch. Check first:
> `find ~/.m2/repository -name '*.jar' -newer ~/.m2/settings.xml`.

```bash
# 🔴 deleting an emulator (AVD) — also loses the data inside that virtual device
# avdmanager list avd            # 🟢 look first
# avdmanager delete avd -n <name>
```

## D6. Docker

```bash
docker system df                       # 🟢 ALWAYS run this before pruning
docker system df -v                    # 🟢 per image/volume detail

docker builder prune -af               # 🟢 build cache only — rebuilds are slower, nothing lost
docker image prune                     # 🟢 dangling images only (<none>)
docker container prune                 # 🟡 removes stopped containers — loses data written in container layers
docker system prune                    # 🟡 stopped containers + unused networks + orphan images + build cache
docker image prune -a                  # 🟡 every image with no container → you have to pull again
docker system prune -a --volumes       # 🔴 VOLUMES TOO — loses every project's database/local state
```

```bash
docker volume ls                       # 🟢 look first
docker volume rm <name>                # 🔴 the data in that volume is gone
```

On macOS the space only truly returns to the disk once Docker Desktop shrinks the
virtual disk: **Docker Desktop → Settings → Resources → Advanced → Disk image
size** (🟡), or **Troubleshoot → Reset to factory defaults** (🔴 loses every image
and volume).

## D7. Git

```bash
git count-objects -vH                  # 🟢 read-only — how bloated the repo is
# 🟢 read-only — find heavy repos
find ~ -name '.git' -type d -prune 2>/dev/null \
  | xargs -I{} du -sh {} 2>/dev/null | sort -rh | head -15

git gc                                 # 🟢 safe repack, keeps everything still referenced
git gc --aggressive --prune=now        # 🟡 hard repack + drops orphaned objects NOW:
                                       #    the old reflog goes, so you cannot `git reset` back
```

> 🔴 Do not run `--prune=now` right after a bad `reset --hard` / `rebase` when you
> still hope to recover a commit through `git reflog`. Once it is packed, there is
> no way back.

## D8. Browsers & IDEs (the non-AI parts)

> The VS Code/Cursor caches tied to AI panels are in §A2 — this section is
> browsers and JetBrains only.

```bash
# Ubuntu
du -sh ~/.cache/google-chrome ~/.cache/mozilla ~/.cache/chromium 2>/dev/null   # 🟢 read-only
# 🟢 page cache only, never the profile/passwords (find instead of a glob, for zsh)
find ~/.cache/google-chrome -maxdepth 2 -name 'Cache' -exec rm -rf {} + 2>/dev/null
find ~/.cache/mozilla -maxdepth 3 -name 'cache2' -exec rm -rf {} + 2>/dev/null

# macOS
du -sh ~/Library/Caches/Google/Chrome ~/Library/Caches/Firefox 2>/dev/null     # 🟢 read-only
# 🟢
find ~/Library/Caches/Google/Chrome -maxdepth 2 -name 'Cache' -exec rm -rf {} + 2>/dev/null

# JetBrains (including AI Assistant / Junie caches) — both OSes
du -sh ~/.cache/JetBrains ~/Library/Caches/JetBrains 2>/dev/null   # 🟢 read-only
# 🟡 the IDE has to re-index every project (slow)
find ~/.cache/JetBrains ~/Library/Caches/JetBrains -maxdepth 2 \
     \( -name 'caches' -o -name 'index' \) -exec rm -rf {} + 2>/dev/null
```

> 🔴 **Never** delete `~/.config/google-chrome` or
> `~/Library/Application Support/Google/Chrome` — that is the **profile**
> (bookmarks, passwords, sessions), not a cache. Only delete inside `~/.cache` /
> `~/Library/Caches`.

---

# PART E — NEVER DELETE

| Path | Why |
|---|---|
| `/System`, `/private/var/db` (macOS) | Read-only system volume; messing with it breaks the machine. |
| `~/Library` (as a whole, macOS) | Holds all app configuration **and** data, not just cache. |
| `/var/lib` (Ubuntu) | Databases for apt, Docker, MySQL… |
| `/boot` | Delete the running kernel and the machine will not boot. |
| `~/.ssh`, `~/.gnupg`, `~/.aws`, `~/.config/gh` | Keys and credentials, not regenerable. |
| `~/.claude/settings.json`, `~/.claude.json`, `CLAUDE.md`, `~/.claude/skills`, `~/.claude/agents`, `~/.claude/memory` | Config, skills and memory you wrote — not regenerable. |
| `~/.config/Code/User/{settings.json,keybindings.json,snippets,History}` | IDE config plus a local history that can rescue uncommitted code. |
| `.env`, `~/.config/*/auth.json`, Copilot/Claude/Codex tokens | Delete them and you re-authenticate everything. |
| `~/Library/Application Support/<app>` | Real app data, not cache. |
| Docker volumes | Project databases/local state. `prune --volumes` is 🔴. |
| Timeshift / Time Machine snapshots | They are backups — you lose the way back. |

Before any `rm -rf` with a wildcard, run the "preview" version with `ls` or
`du -sh` on the exact same pattern. With `find … -exec rm`, **always** run it with
`-print` first, read the list, and only then switch to `-exec`.

---

# PART F — AUTOMATION SCRIPT (detects the OS)

Save as `~/bin/cleanup.sh`, `chmod +x ~/bin/cleanup.sh`, run `cleanup.sh`. The
script performs **only 🟢 and light 🟡 actions**, and **prints free space before and
after**. It deliberately does **no 🔴 action**: it never touches AI transcripts,
never runs `docker system prune -a --volumes`, never deletes
`node_modules`/`.venv`/`target`, never removes Ollama models, never deletes
snapshots. Those are decisions for you to make per §A–§D. Each group is labelled
in the output as it runs.

> Prefer not to maintain this yourself? That is exactly what
> [`declutter`](../README.md) automates — same safety tiers, plus an interactive
> list with real sizes.

```bash
#!/usr/bin/env bash
# Runs under bash even on macOS (the shebang handles that) — no zsh dependency.
set -uo pipefail

human() { df -h / | awk 'NR==2 {print $4" free of "$2}'; }
say()   { printf '\n\033[1;36m▸ %s\033[0m\n' "$*"; }
run()   { echo "  $ $*"; "$@" >/dev/null 2>&1 || echo "    (skipped)"; }

echo "Before: $(human)"

say "[🟢] AI tools — cache only, no transcripts, no models"
for CODE in "$HOME/.config/Code" "$HOME/Library/Application Support/Code" \
            "$HOME/.config/Cursor" "$HOME/Library/Application Support/Cursor"; do
  [ -d "$CODE" ] || continue
  run rm -rf "$CODE/Cache" "$CODE/CachedData" "$CODE/CachedExtensionVSIXs" \
             "$CODE/GPUCache" "$CODE/Code Cache" "$CODE/logs"
done
run rm -rf "$HOME/.claude/shell-snapshots" "$HOME/.claude/statsig" \
           "$HOME/.cache/claude-cli-nodejs" "$HOME/.codex/cache" \
           "$HOME/.gemini/tmp" "$HOME/.cursor/ai-tracking"
run rm -rf "$HOME/.nv/ComputeCache" "$HOME/.triton/cache" "$HOME/.cache/torch/hub"
find /tmp -maxdepth 1 -name 'claude-*' -exec rm -rf {} + >/dev/null 2>&1
command -v ollama >/dev/null && echo "  (ollama: run 'ollama list' and remove unused models yourself)"

say "[🟢] Node package managers — re-downloadable caches"
command -v npm  >/dev/null && run npm cache clean --force
command -v yarn >/dev/null && run yarn cache clean
command -v pnpm >/dev/null && run pnpm store prune
command -v bun  >/dev/null && run bun pm cache rm

say "[🟢] Python / Go / Rust — build caches, modcache untouched"
command -v pip   >/dev/null && run pip cache purge
command -v go    >/dev/null && run go clean -cache -testcache
command -v cargo >/dev/null && run rm -rf "$HOME/.cargo/registry/cache"

say "[🟢] Docker — build cache only, NO image/volume prune"
command -v docker >/dev/null && run docker builder prune -af

case "$(uname -s)" in
  Linux)
    say "[🟢/🟡] Ubuntu — apt, journal, trash (🟡)"
    run sudo apt autoremove -y
    run sudo apt autoclean
    run sudo apt clean
    run sudo journalctl --vacuum-time=3d
    run find "$HOME/.local/share/Trash" -mindepth 1 -delete
    run rm -rf "$HOME/.cache/thumbnails"
    say "[🟢] Snap — disabled revisions only"
    LANG=C snap list --all 2>/dev/null | awk '/disabled/{print $1, $3}' \
      | while read -r n r; do sudo snap remove "$n" --revision="$r" >/dev/null 2>&1; done
    ;;
  Darwin)
    say "[🟢/🟡] macOS — brew, DerivedData, trash (🟡)"
    command -v brew >/dev/null && run brew cleanup -s --prune=all
    command -v brew >/dev/null && run rm -rf "$(brew --cache)"
    run rm -rf "$HOME/Library/Developer/Xcode/DerivedData"
    command -v xcrun >/dev/null && run xcrun simctl delete unavailable
    run find "$HOME/.Trash" -mindepth 1 -delete
    run sudo purge
    ;;
esac

echo
echo "After:  $(human)"
```

---

# PART G — QUICK CHECKLIST

When the disk is nearly full, work in exactly this order:

1. `df -h /` — confirm you are actually out of space (on macOS, check snapshots in §C4).
2. **Run the AI measurement command at the top of §A** — this group usually holds
   the most gigabytes with the least attention, and `apt`/`brew` never touch it.
3. If you have Ollama/LM Studio: `ollama list` → remove unused models (§A3). This
   is the one step that can free tens of gigabytes in a minute.
4. `ncdu -x /` or `du -sh ~/* | sort -rh | head` — find the remaining culprits.
5. Run the AI combo (§A6), then your OS's safe combo (§B4 or §C6).
6. Sweep `node_modules` / `target` / `DerivedData` / `.gradle` / `.venv` (§D).
7. `docker system df` → prune if it is holding a lot (§D6).
8. Uninstall apps/SDKs/Node versions you no longer use.
9. Measure `df -h /` again; only if you are still short, consider the 🔴 items.

---
*Written for Ubuntu/Debian and macOS (Intel & Apple Silicon).*
