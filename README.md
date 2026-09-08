# declutter

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

```bash
curl -fsSL https://raw.githubusercontent.com/phamquyetthang/declutter/main/install.sh | bash
```

Hoặc clone rồi chạy trực tiếp — không cần cài:

```bash
git clone https://github.com/phamquyetthang/declutter.git
cd declutter && ./declutter
```

## Dùng

```bash
declutter                  # quét → chọn → Enter. Mặc định KHÔNG xóa gì.
declutter --report         # chỉ in danh sách rồi thoát
declutter --yes            # bỏ qua bước chọn, dọn thẳng mục an toàn
declutter --yes -l yellow  # dọn cả mức "cân nhắc"
declutter --dry-run --yes  # chạy thử, ghi ra log những gì SẼ xóa
declutter --projects       # liệt kê node_modules/target/.venv nặng
declutter --only ai-ide    # chỉ dọn cache IDE
```

## Ba mức an toàn

| Mức | Nghĩa | Hành vi mặc định |
|---|---|---|
| `o` **an toàn** | Cache chắc chắn tái tạo được. Mất nó chỉ làm lần build/cài sau chậm hơn. | **Tick sẵn** |
| `!` **cân nhắc** | Mất lịch sử (transcript, Copilot Chat), hoặc build lại rất lâu (Gradle caches, Go modcache). | Không tick, bạn tự bật |
| `x` **tự quyết** | Dữ liệu thật hoặc thứ chỉ bạn mới biết còn cần không: `node_modules`, model Ollama, Docker volume, Xcode Archives, Maven repo. | **Không chọn được.** Chỉ hiện dung lượng để bạn tự xử lý |

`--level red` bị từ chối có chủ đích: không có cờ nào khiến tool tự xóa mục đỏ.

## Nhóm

`ai-cli` `ai-ide` `ai-ml` `ai-model` `pkg-node` `pkg-python` `pkg-rust` `pkg-go`
`pkg-java` `docker` `browser` `os` `xcode`

Lọc bằng `--only a,b` / `--skip a,b`.

## Nó dọn những gì

**Công cụ AI** — Claude Code (`shell-snapshots`, `statsig`, transcript cũ),
Codex CLI, Gemini CLI, Cursor telemetry, Aider tags cache.
**IDE** — `Cache`, `CachedExtensionVSIXs`, `GPUCache`, `WebStorage`,
`globalStorage/github.copilot-chat` của VS Code / Cursor / Windsurf / VSCodium; JetBrains.
**ML** — CUDA/Triton JIT, PyTorch hub, HuggingFace hub, Whisper/CLIP/Keras.
**Dev** — npm/yarn/pnpm/bun, pip/uv/Poetry, Cargo registry, Go build cache,
Gradle/Maven, Docker build cache & image dangling, cache trình duyệt.
**Ubuntu** — apt cache, journal, snap revision cũ, flatpak, `/var/crash`, thùng rác.
**macOS** — Homebrew, Xcode DerivedData, SwiftPM, simulator rác, iOS DeviceSupport, thùng rác.

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

## Phát triển

```bash
./tests/run.sh     # 52 assertion trong một $HOME giả, không đụng máy thật
```

Test đặt `DECLUTTER_SKIP_CMD=1` vì các mục dạng lệnh (`docker builder prune`,
`apt clean`, `brew cleanup`) **không** bị `$HOME` sandbox chặn — chúng tác động
lên daemon và hệ thống thật.

Thêm mục dọn dẹp mới = thêm một dòng `add` vào file trong `modules/`:

```bash
add green ai-cli rm "" "Mô tả ngắn" "$H/.something/cache"
```

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
lib/registry.sh    # add() + nạp module
lib/actions.sh     # thực thi xóa (tôn trọng --dry-run)
lib/ui.sh          # danh sách checkbox tương tác
lib/runner.sh      # chạy phần đã chọn, báo dung lượng giải phóng
lib/projects.sh    # quét node_modules/target/.venv
modules/*.sh       # định nghĩa mục dọn, tách theo công cụ và theo OS
tests/run.sh       # test trong $HOME giả
```

## Tài liệu

[docs/GUIDE.md](docs/GUIDE.md) — hướng dẫn dọn dẹp thủ công đầy đủ cho Ubuntu và
macOS, kèm nhãn an toàn cho từng lệnh. Dùng khi bạn muốn tự chạy từng lệnh thay vì
dùng tool.

## Giấy phép

MIT © phamquyetthang
