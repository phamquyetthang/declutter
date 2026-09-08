# declutter — dọn rác, giải phóng dung lượng máy dev (macOS & Ubuntu)

[English](README.md) · **Tiếng Việt**

[![ci](https://github.com/quytstudio/declutter/actions/workflows/ci.yml/badge.svg)](https://github.com/quytstudio/declutter/actions/workflows/ci.yml)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![platform: macOS | Ubuntu](https://img.shields.io/badge/platform-macOS%20%7C%20Ubuntu-lightgrey.svg)](#yêu-cầu)
[![pure bash](https://img.shields.io/badge/pure-bash%203.2%2B-89e051.svg)](#yêu-cầu)

**Dọn rác máy dev — Ubuntu & macOS.** Quét, hiện danh sách có checkbox kèm dung
lượng thật, mục an toàn được tick sẵn. Bấm Enter là dọn. Không xóa gì trước đó.

Khác với các script dọn dẹp thông thường, `declutter` tập trung vào **rác của công
cụ AI** — transcript của Claude Code / Codex / Gemini CLI, WebStorage của panel chat
trong VS Code / Cursor, cache HuggingFace, model Ollama — nhóm phình nhanh nhất trên
máy lập trình viên hiện nay mà `apt clean` và `brew cleanup` không chạm tới.

> Bash thuần, không dependency, chạy được với bash 3.2 (bản mặc định của macOS).

```
declutter  —  linux  —  14.1G trống trên /
o = an toàn (tick sẵn)   ! = cân nhắc   x = tự quyết, không chọn được
──────────────────────────────────────────────────────────────────────────
  [x] o     3.0G  Code: WebStorage (webview panel AI)            ai-ide
> [x] o     1.3G  npx cache                                      pkg-node
  [x] o     430M  Cargo registry cache (tải lại khi build)       pkg-rust
  [ ] !     250M  Claude Code: transcript cũ hơn 60n (mất --res… ai-cli
  [ ] !      42M  Code: lịch sử Copilot Chat                     ai-ide
    -  x     2.2G  Extension đã cài (gỡ: code --uninstall-exten… ai-ide
──────────────────────────────────────────────────────────────────────────
  Đã chọn: 12 mục — 1.8G
  [↑↓/jk] di chuyển   [space] chọn   [a] đảo tất cả   [o] chỉ an toàn
  [n] bỏ hết   [enter] DỌN   [q] thoát
```

## Cài đặt

Cùng một lệnh cho cả Linux và macOS:

```bash
curl -fsSL https://raw.githubusercontent.com/quytstudio/declutter/main/install.sh | bash
```

Cài vào `~/.local/bin` (đổi bằng `PREFIX=...`). Nếu máy chưa có `git` — hay gặp
trên Mac mới vì cần Xcode Command Line Tools — installer tự chuyển sang tải
tarball bằng `curl`. Cài xong nó tự báo dòng `export PATH=...` cần thêm vào đúng
file rc của shell bạn đang dùng (`~/.zshrc` cho macOS, `~/.bashrc` cho Linux).

Hoặc clone rồi chạy trực tiếp — không cần cài:

```bash
git clone https://github.com/quytstudio/declutter.git
cd declutter && ./declutter
```

Gỡ ra: `./install.sh --uninstall` (file `~/.declutter.log` vẫn được giữ).

## Dùng

```bash
declutter                  # quét → chọn → Enter. Mặc định KHÔNG xóa gì.
declutter --report         # chỉ in danh sách rồi thoát
declutter --json           # in danh sách dạng JSON, cho script và agent
declutter --yes            # bỏ qua bước chọn, dọn thẳng mục an toàn
declutter --yes -l yellow  # dọn cả mức "cân nhắc"
declutter --dry-run --yes  # chạy thử, ghi ra log những gì SẼ xóa
declutter --projects       # liệt kê node_modules/target/.venv nặng
declutter --only ai-ide    # chỉ dọn cache IDE
declutter --lang en        # giao diện tiếng Anh (mặc định tự dò theo $LANG)
```

## Ba mức an toàn

| Mức | Nghĩa | Hành vi mặc định |
|---|---|---|
| `o` **an toàn** | Cache chắc chắn tái tạo được. Mất nó chỉ làm lần build/cài sau chậm hơn. | **Tick sẵn** |
| `!` **cân nhắc** | Mất lịch sử (transcript, Copilot Chat), hoặc build lại rất lâu (Gradle caches, Go modcache). | Không tick, bạn tự bật |
| `x` **tự quyết** | Dữ liệu thật hoặc thứ chỉ bạn mới biết còn cần không: `node_modules`, model Ollama, Docker volume, Xcode Archives, Maven repo. | **Không chọn được.** Chỉ hiện dung lượng để bạn tự xử lý |

`--level red` bị từ chối có chủ đích: không có cờ nào khiến tool tự xóa mục đỏ.

## Nó dọn những gì

Chia nhóm, lọc bằng `--only a,b` / `--skip a,b`:

| Nhóm | Nội dung |
|---|---|
| `ai-cli` | Claude Code (`shell-snapshots`, `statsig`, transcript cũ), Codex CLI, Gemini CLI, Cursor telemetry, Aider tags cache |
| `ai-ide` | VS Code / Cursor / Windsurf / VSCodium: `Cache`, `CachedExtensionVSIXs`, `GPUCache`, `WebStorage`, `globalStorage/github.copilot-chat`; cache JetBrains |
| `ai-ml` | CUDA/Triton JIT, PyTorch hub, HuggingFace hub, Whisper/CLIP/Keras |
| `ai-model` | Model Ollama và LM Studio — **chỉ báo cáo**, không bao giờ xóa |
| `pkg-node` | npm, yarn, pnpm, bun, npx, Electron builder |
| `pkg-python` | pip, uv, Poetry, conda, `__pycache__` (với `--deep`) |
| `pkg-rust` | Cargo registry cache và source |
| `pkg-go` | Go build cache, test cache, module cache |
| `pkg-java` | Gradle caches, daemon log, wrapper dists; Maven repo chỉ báo cáo |
| `docker` | Cache build, image dangling, container đã dừng |
| `browser` | Cache trang của Chrome / Chromium / Edge / Firefox — chỉ thư mục cache |
| `os` (Ubuntu) | apt cache, journal, snap revision cũ, flatpak, `/var/crash`, thùng rác |
| `os` (macOS) | Homebrew, log người dùng, thùng rác |
| `xcode` | DerivedData, SwiftPM cache, simulator không còn dùng, iOS DeviceSupport |

## Nó KHÔNG bao giờ đụng vào

`~/.ssh` · `~/.gnupg` · `~/.aws` · `.env` · token đăng nhập ·
`~/.claude/settings.json`, `skills`, `agents`, `memory` ·
`User/settings.json`, `keybindings.json`, `snippets`, `User/History` của VS Code ·
profile trình duyệt (chỉ đụng `~/.cache` và `~/Library/Caches`) ·
Docker volume · Xcode Archives · Maven repo · snapshot Timeshift / Time Machine ·
`node_modules` và `target/` (chỉ liệt kê qua `--projects`).

## An toàn

- **Mặc định không xóa gì.** Phải bấm Enter, hoặc truyền `--yes`.
- `--dry-run` ghi ra log chính xác từng đường dẫn sẽ bị xóa, không đụng vào đĩa.
- Mọi thao tác được ghi vào `~/.declutter.log`.
- Mục nào không tồn tại thì không xuất hiện — danh sách luôn là thứ thật trên máy bạn.
- Thư mục tạm `/tmp/claude-*` chỉ xóa bản cũ hơn 1 ngày, không giết phiên đang chạy.

## Đầu ra JSON, cho script và AI agent

`declutter --json` in đúng danh sách đó dưới dạng một object JSON, để agent hoặc
script tự quyết dọn gì mà không cần chạy giao diện:

```bash
# 5 mục an toàn nặng nhất
declutter --json | jq -r '.items[] | select(.level=="green")
  | "\(.size_human)\t\(.desc)"' | head -5

# tổng dung lượng có thể lấy lại ở mức an toàn
declutter --json | jq '.totals.preselected_human'
```

Mỗi mục có `level`, `group`, `action`, `desc`, `size_kb`, `size_human`,
`paths[]`, `selectable` (false với mức đỏ) và `preselected`. Cấu trúc này ổn định
từ bản 1.1.0.

## Câu hỏi thường gặp

### Chạy có an toàn không?

An toàn theo nghĩa quan trọng nhất: nó không xóa gì cho tới khi bạn đồng ý, và
mức tick sẵn chỉ toàn cache. Test khẳng định một lần chạy mức green giữ nguyên
`~/.ssh`, `~/.claude/settings.json`, settings VS Code, `workspaceStorage`, Maven
repo và toàn bộ transcript. Muốn đọc trước danh sách đường dẫn thì chạy
`declutter --dry-run --yes`.

### Nó có xóa lịch sử chat Claude Code không?

Không, ở mức mặc định. Transcript (`~/.claude/projects/*.jsonl`) nằm ở mức `!`,
không bao giờ tick sẵn, và chỉ những mục cũ hơn `--days N` (mặc định 60) mới được
xét. Xóa chúng là mất `--resume` của các phiên đó. `~/.claude/settings.json`,
`skills`, `agents`, `memory` nằm trong danh sách không bao giờ đụng.

### Thực tế giải phóng được bao nhiêu?

Trên một máy dev đang làm việc, thường 5–40 GB. Mấy chỗ hay nặng nhất:
`WebStorage` và cache của VS Code / Cursor, `~/.npm/_npx`, Cargo registry cache,
Xcode `DerivedData` trên macOS, và Docker build cache. Chạy `declutter --report`
để xem số liệu máy bạn trước khi quyết.

### Có chạy trên macOS không?

Có — macOS và Ubuntu/Debian là hai nền tảng được hỗ trợ, cùng một script. Nó chạy
được với bash 3.2 mà macOS ship sẵn, và CI chạy trên `macos-latest`
bằng đúng `/bin/bash` vì lý do đó. Nhóm Xcode, Homebrew, simulator và iOS
DeviceSupport chỉ có trên macOS.

### Khác gì CleanMyMac, BleachBit hay `brew cleanup`?

Mấy cái đó dọn *hệ điều hành*. `declutter` dọn *bộ công cụ lập trình*, đặc biệt là
những thư mục của công cụ AI mà chúng không biết tới: WebStorage của panel chat,
cache model, transcript CLI. Nó cũng chỉ là một script bash ~2.000 dòng: không
daemon, không telemetry, không thuê bao — bạn đọc được toàn bộ những gì nó sẽ xóa
trước khi chạy.

### Tự thêm mục dọn được không?

Được, thêm một dòng vào file trong `modules/`. Xem [Thêm mục dọn dẹp](#thêm-mục-dọn-dẹp).

### Gỡ ra thế nào?

`./install.sh --uninstall`, hoặc xóa tay `~/.local/bin/declutter` và
`~/.local/share/declutter`.

### Nó có gửi dữ liệu đi đâu không?

Không. Trong tool không có lệnh gọi mạng nào. Chỉ `install.sh` tải về, và chỉ tải
từ GitHub.

## Yêu cầu

- macOS (bash 3.2+, bản mặc định là đủ) hoặc Ubuntu/Debian
- `bash`, `du`, `df`, `find`, `awk`, `sort` — đều có sẵn trong bản cài cơ bản
- Không cần package manager, không runtime, không root. `sudo` chỉ dùng cho các
  mục hệ thống của Ubuntu, và chỉ khi nó sẵn sàng mà không hỏi mật khẩu.

## Phát triển

```bash
./tests/run.sh     # 69 assertion trong một $HOME giả, không đụng máy thật
```

Test đặt `DECLUTTER_SKIP_CMD=1` vì các mục dạng lệnh (`docker builder prune`,
`apt clean`, `brew cleanup`) **không** bị `$HOME` sandbox chặn — chúng tác động
lên daemon và hệ thống thật.

### Thêm mục dọn dẹp

Một dòng `add` trong file thuộc `modules/`:

```bash
add green ai-cli rm "" "$(L "Short description" "Mô tả ngắn")" "$H/.something/cache"
```

`L "english" "tiếng Việt"` là helper hai ngôn ngữ; xem `lib/i18n.sh`.

| Action | Việc |
|---|---|
| `rm` | xóa các path |
| `rmchild` | xóa nội dung bên trong, giữ thư mục (thùng rác) |
| `findrm` | `EXTRA="maxdepth\|pattern"` |
| `agerm` | `EXTRA="days\|pattern"` — chỉ xóa mục cũ hơn N ngày |
| `cmd` | chạy lệnh; path chỉ dùng để đo dung lượng |
| `note` | chỉ báo cáo, không bao giờ xóa |

## Cấu trúc

```
declutter          # CLI, phân tích tham số, điều phối
lib/core.sh        # đo dung lượng, format, log, sudo
lib/i18n.sh        # chuỗi hai ngôn ngữ (Anh + Việt)
lib/registry.sh    # add() + nạp module
lib/actions.sh     # thực thi xóa (tôn trọng --dry-run)
lib/ui.sh          # danh sách checkbox tương tác
lib/report.sh      # đầu ra --json
lib/runner.sh      # chạy phần đã chọn, báo dung lượng giải phóng
lib/projects.sh    # quét node_modules/target/.venv
modules/*.sh       # định nghĩa mục dọn, tách theo công cụ và theo OS
completions/       # gợi ý tự động cho bash + zsh
tests/run.sh       # test trong $HOME giả
```

## Tài liệu

[docs/GUIDE.vi.md](docs/GUIDE.vi.md) — hướng dẫn dọn dẹp thủ công đầy đủ cho
Ubuntu và macOS, kèm nhãn an toàn cho từng lệnh. Dùng khi bạn muốn tự chạy từng
lệnh thay vì dùng tool. ([English](docs/GUIDE.md))

## Giấy phép

MIT © [phamquyetthang](https://github.com/phamquyetthang)
