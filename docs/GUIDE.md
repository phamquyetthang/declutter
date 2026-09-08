# Dọn dẹp bộ nhớ và data rác — Ubuntu & macOS

Tài liệu tổng hợp lệnh terminal để **tìm ra chỗ đang ngốn dung lượng** rồi giải phóng
nó: **rác của các công cụ AI** (transcript, cache IDE, model weights), cache hệ thống,
cache của package manager, môi trường dev (Node/Python/Rust/Go/Java/Docker) và các thư
mục rác đặc thù của từng OS.

Phần AI được đặt **đầu tiên (§A)** vì đó là nhóm phình nhanh nhất hiện nay và không
công cụ dọn dẹp nào của OS đụng tới nó.

> **Quy tắc vàng:** *đo trước, xóa sau.* Chạy phần **§0 Chẩn đoán** trước để biết GB
> đang nằm ở đâu — xóa mù thường chỉ thu lại vài trăm MB trong khi thủ phạm thật là
> một thư mục `node_modules` / `DerivedData` / Docker volume nặng 40 GB.

**Chú thích mức độ an toàn dùng xuyên suốt tài liệu:**

| Nhãn | Ý nghĩa |
|---|---|
| 🟢 An toàn | Chỉ xóa cache tái tạo được. Chạy thoải mái. |
| 🟡 Cân nhắc | Mất cache khiến lần build/cài kế tiếp chậm, hoặc phải đăng nhập lại. |
| 🔴 Cẩn thận | Có thể mất dữ liệu thật / cần đóng app trước / không hoàn tác được. |

**Quy ước:** *mọi* lệnh có thao tác xóa đều mang nhãn — hoặc ở đầu gạch đầu dòng,
hoặc dưới dạng comment ngay cuối dòng trong code block. Lệnh **không có nhãn xóa**
là lệnh **chỉ đọc** (`du`, `df`, `find … -print`, `ls`, `*list`) — chạy được vô tư.
Khi một lệnh vừa đo vừa xóa, nhãn luôn theo vế xóa.

---

## ⚠️ Người dùng macOS đọc trước: zsh khác bash ở chỗ glob

macOS mặc định dùng **zsh**. Khi một mẫu `*` **không khớp file nào**, zsh **báo lỗi
và hủy luôn cả lệnh**, trong khi bash chỉ giữ nguyên chuỗi rồi chạy tiếp:

```
zsh: no matches found: /Users/thang/.aider*
```

Nghĩa là chỉ cần **một** đường dẫn không tồn tại là cả vòng lặp không chạy dòng nào —
kể cả khi bạn đã có `2>/dev/null`, vì lỗi xảy ra lúc zsh khai triển glob, **trước
khi** lệnh được gọi, nên redirect không đỡ được.

Các lệnh **xóa** trong tài liệu này đã được viết lại cho **không còn glob** (dùng
`find … -exec` thay cho `rm -rf thư-mục/*`) để chạy đúng trên cả hai shell. Một số
lệnh **liệt kê** vẫn cần `*` (ví dụ `du -sh ~/.claude/*`). Nếu gặp `no matches found`:

```bash
setopt +o nomatch     # 🟢 chỉ đổi hành vi shell, tự mất khi đóng terminal
```

Muốn tắt vĩnh viễn thì thêm `unsetopt nomatch` vào `~/.zshrc`. Xem shell đang dùng:
`echo $SHELL`.

Các khác biệt macOS (BSD) ↔ Ubuntu (GNU) khác đã được xử lý sẵn trong tài liệu:
`du` không có `--max-depth` (dùng `-d`), `find` không có `-printf`, `find` không có
`-mindepth`… vẫn có. Riêng `sort -rh` thì **cả hai đều hỗ trợ**, dùng bình thường.

---

## §0. Chẩn đoán: dung lượng đang nằm ở đâu?

> 🟢 **Toàn bộ §0 là chỉ đọc** — không lệnh nào trong phần này xóa bất cứ thứ gì.
> Ngoại lệ duy nhất: trong `ncdu` bạn có thể bấm phím `d` để xóa — đó là thao tác
> tay của bạn, và nó là 🔴 (xóa ngay, không qua thùng rác).

### 0.1 Tổng quan ổ đĩa (cả 2 OS)

```bash
df -h            # dung lượng còn trống theo từng phân vùng
df -h /          # chỉ ổ hệ thống
```

### 0.2 Thư mục nào nặng nhất

```bash
# Top 20 thư mục nặng nhất trong thư mục hiện tại
du -sh -- * .[!.]* 2>/dev/null | sort -rh | head -20

# Quét cả home directory
du -sh ~/* ~/.[!.]* 2>/dev/null | sort -rh | head -25
```

Ubuntu — quét toàn hệ thống (`-x` = không đi sang phân vùng khác):

```bash
sudo du -xh / --max-depth=1 2>/dev/null | sort -rh | head -20
```

macOS — `du` bản BSD không có `--max-depth`, dùng `-d`:

```bash
sudo du -xh -d 1 / 2>/dev/null | sort -rh | head -20
sudo du -xh -d 1 ~/Library 2>/dev/null | sort -rh | head -20
```

### 0.3 Công cụ tương tác (khuyên dùng — nhanh hơn `du` nhiều)

```bash
# Ubuntu
sudo apt install ncdu
ncdu -x /                       # duyệt cây thư mục, bấm 'd' để xóa

# macOS
brew install ncdu
ncdu -x /                       # hoặc: brew install dust && dust -d 2 ~
```

Bản GUI: Ubuntu có **Disk Usage Analyzer** (`baobab`), macOS có
 *Apple  → About This Mac → Storage → Manage* hoặc app **GrandPerspective**.

### 0.4 Tìm file lớn riêng lẻ

```bash
# File > 500 MB trong home
find ~ -type f -size +500M -exec ls -lh {} \; 2>/dev/null | awk '{print $5, $9}'

# 20 file lớn nhất toàn máy (Ubuntu)
sudo find / -xdev -type f -printf '%s %p\n' 2>/dev/null | sort -rn | head -20

# macOS (find BSD không có -printf)
sudo find / -xdev -type f -size +500M 2>/dev/null -exec ls -lh {} + | awk '{print $5, $9}'
```

---

# PHẦN A — CÔNG CỤ AI (dọn trước tiên)

Đây là nhóm rác **mới nhất và phình nhanh nhất** trên máy dev, nhưng gần như không
có công cụ dọn dẹp nào của hệ điều hành đụng tới: transcript hội thoại, cache
webview của IDE, extension VSIX đã tải, và **model weights hàng chục GB**.

**Lệnh đo 1 phát — chạy cái này trước:**

```bash
# 🟢 chỉ đọc. Không dùng glob nào → chạy đúng trên cả bash lẫn zsh (macOS).
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

> Số liệu thật đo trên một máy dev Ubuntu đang dùng nhiều công cụ AI (để bạn hình
> dung độ lớn): `~/.config/Code` **5.0 G**, `~/.vscode/extensions` **1.6 G**,
> `~/.cursor` **638 M**, `~/.claude` **369 M**, `~/.codex` **150 M**,
> `~/.gemini` **104 M** — tổng hơn **7 GB** mà `apt clean` không chạm được dòng nào.

---

## A1. Trợ lý code chạy trong terminal (Claude Code, Codex, Gemini CLI, Aider)

Rác chính là **transcript hội thoại** (JSONL/SQLite) tích lũy theo từng project.

**Claude Code** — xem cái gì đang nặng:

```bash
du -sh ~/.claude/* 2>/dev/null | sort -rh | head
```

Thường thấy: `projects/` (transcript, nặng nhất), `plugins/`, `file-history/`,
`shell-snapshots/`, `todos/`, `statsig/`, `backups/`.

* 🟡 **Xóa transcript cũ hơn 30 ngày** — đánh đổi: không `--resume`/`--continue`
  lại được các session đó nữa:
    ```bash
    du -sh ~/.claude/projects/* 2>/dev/null | sort -rh | head      # xem trước
    find ~/.claude/projects -name '*.jsonl' -mtime +30 -print      # kiểm tra danh sách
    # đồng ý rồi mới đổi -print thành -delete
    ```
* 🟢 **Rác chắc chắn tái tạo được:**
    ```bash
    # không glob → chạy được trên zsh; các thư mục này tự tạo lại ở lần chạy sau
    rm -rf ~/.claude/shell-snapshots ~/.claude/statsig ~/.cache/claude-cli-nodejs
    find /tmp -maxdepth 1 -name 'claude-*' -exec rm -rf {} + 2>/dev/null
    ```
* 🟡 **Lịch sử sửa file & backup** (dùng để undo các thay đổi cũ):
    ```bash
    du -sh ~/.claude/file-history ~/.claude/backups
    find ~/.claude/file-history -mtime +30 -delete
    ```
* 🔴 **Đừng xóa**: `~/.claude/settings.json`, `~/.claude.json`, `~/.claude/CLAUDE.md`,
  `~/.claude/skills`, `~/.claude/agents`, `~/.claude/memory` — là cấu hình và bộ nhớ
  bạn tự viết, không tái tạo được.

**Codex CLI:**

```bash
du -sh ~/.codex/* 2>/dev/null | sort -rh
rm -rf ~/.codex/cache                                  # 🟢
find ~/.codex/sessions -mtime +30 -delete              # 🟡 mất lịch sử session
ls -lh ~/.codex/logs*.sqlite                           # 🟡 file log có thể vài chục MB
```

**Gemini CLI / Antigravity:**

```bash
du -sh ~/.gemini/* 2>/dev/null | sort -rh
rm -rf ~/.gemini/tmp ~/.gemini/cache 2>/dev/null       # 🟢
```

**Aider** — rác nằm **trong từng repo**, không phải ở home:

```bash
# 🟢 chỉ đọc — tìm cache và lịch sử chat của Aider nằm rải trong các repo
find ~ -name '.aider.tags.cache.v*' -type d -prune 2>/dev/null \
  | xargs -I{} du -sh {} 2>/dev/null | sort -rh | head
find ~ \( -name '.aider.chat.history.md' -o -name '.aider.input.history' \) 2>/dev/null

# 🟢 cache tags — Aider tự dựng lại ở lần chạy sau
find ~ -name '.aider.tags.cache.v*' -type d -prune -exec rm -rf {} + 2>/dev/null
# 🔴 lịch sử chat là dữ liệu bạn tạo ra — xem trước rồi mới xóa từng file
```

**Nguyên tắc chung cho nhóm này:** transcript là dữ liệu **bạn** tạo ra. Nếu có
đoạn hội thoại quan trọng, export/copy ra trước khi xóa hàng loạt.

## A2. IDE có AI (VS Code + Copilot, Cursor, Windsurf)

Đây thường là **thư mục nặng nhất trong home** của một máy dev — chủ yếu do webview
storage của các panel chat AI và extension đã tải về.

Đường dẫn theo OS:

| Thành phần | Ubuntu | macOS |
|---|---|---|
| VS Code | `~/.config/Code` | `~/Library/Application Support/Code` |
| Cursor | `~/.config/Cursor` | `~/Library/Application Support/Cursor` |
| Windsurf | `~/.config/Windsurf` | `~/Library/Application Support/Windsurf` |
| Extensions | `~/.vscode/extensions`, `~/.cursor/extensions` | giống Ubuntu (nằm ở `~`) |

**Đóng IDE trước khi chạy các lệnh dưới đây.**

```bash
BASE=~/.config/Code          # macOS: BASE=~/Library/Application\ Support/Code
du -sh "$BASE"/* 2>/dev/null | sort -rh | head -8
```

* 🟢 **Cache thuần — xóa thoải mái:**
    ```bash
    rm -rf "$BASE"/Cache "$BASE"/CachedData "$BASE"/CachedExtensionVSIXs \
           "$BASE"/Code\ Cache "$BASE"/GPUCache "$BASE"/logs
    ```
    `CachedExtensionVSIXs` là các file `.vsix` đã tải để cài extension — cài xong là
    vô dụng (trên máy đo được: **654 MB**).
* 🟡 **`WebStorage` — thủ phạm lớn nhất, chính là storage của các webview AI chat**
  (đo được **3.1 GB**). Xóa sẽ mất state hiển thị của một số panel, không mất code:
    ```bash
    du -sh "$BASE"/WebStorage
    rm -rf "$BASE"/WebStorage
    ```
* 🟡 **`User/globalStorage` — dữ liệu extension, trong đó có lịch sử Copilot Chat:**
    ```bash
    du -sh "$BASE"/User/globalStorage/* 2>/dev/null | sort -rh | head
    rm -rf "$BASE"/User/globalStorage/github.copilot-chat     # mất lịch sử chat Copilot
    ```
* 🟡 **`User/workspaceStorage` — state riêng cho từng thư mục đã từng mở** (đo được
  **241 MB**). Rất nhiều mục trỏ tới project đã xóa từ lâu:
    ```bash
    du -sh "$BASE"/User/workspaceStorage | tail -1
    find "$BASE"/User/workspaceStorage -maxdepth 1 -mtime +180 -print   # kiểm tra trước
    ```
* 🟡 **Extensions — gỡ cái không dùng thay vì xóa cả thư mục:**
    ```bash
    du -sh ~/.vscode/extensions/* 2>/dev/null | sort -rh | head -15
    code --list-extensions
    code --uninstall-extension <publisher.name>
    ```
    Xóa trắng `~/.vscode/extensions` cũng được (🟡) — VS Code sẽ cài lại nếu bạn
    bật Settings Sync, nhưng phải tải lại toàn bộ.
* 🔴 **Đừng xóa**: `User/settings.json`, `User/keybindings.json`, `User/snippets`,
  `User/History` (là bản local history của file bạn sửa — có thể cứu code).

Cursor/Windsurf có thêm thư mục riêng ở home:

```bash
du -sh ~/.cursor/* 2>/dev/null | sort -rh          # extensions, projects, ai-tracking…
rm -rf ~/.cursor/ai-tracking 2>/dev/null           # 🟢 telemetry cục bộ
```

## A3. Model chạy local (Ollama, LM Studio, llama.cpp, GGUF)

Nhóm này **không tính bằng MB mà bằng chục GB**. Nếu bạn có cài, đây gần như chắc
chắn là thứ nặng nhất trong toàn bộ tài liệu này.

**Ollama:**

```bash
ollama list                                   # xem model + dung lượng
du -sh ~/.ollama/models 2>/dev/null           # macOS: ~/.ollama/models cũng vậy
ollama rm llama3:70b                          # 🔴 xóa hẳn, muốn dùng lại phải pull ~40GB
ollama ps                                     # model nào đang nạp trong RAM
```
Nếu chạy Ollama bằng Docker, model nằm trong volume: `docker volume ls | grep ollama`
rồi `docker volume rm <tên>` (🔴).

**LM Studio:**

```bash
du -sh ~/.lmstudio/models ~/.cache/lm-studio 2>/dev/null
# macOS: ~/.lmstudio, ~/Library/Application Support/LM Studio
```

**File GGUF/safetensors rải rác** (tải tay, để quên trong Downloads):

```bash
find ~ -type f \( -name '*.gguf' -o -name '*.safetensors' -o -name '*.ckpt' -o -name '*.pt' \) \
  -size +200M 2>/dev/null -exec ls -lh {} + | awk '{print $5, $9}' | sort -rh
```

## A4. Cache thư viện ML (HuggingFace, PyTorch, MediaPipe, Whisper, CUDA)

Model tải tự động khi chạy code — dễ quên vì không ai chủ động tải chúng.

```bash
du -sh ~/.cache/huggingface ~/.cache/torch ~/.cache/whisper \
       ~/.keras ~/.cache/clip ~/.triton ~/.nv 2>/dev/null | sort -rh
```

* 🟡 **HuggingFace** — có công cụ xóa chọn lọc, tốt hơn `rm -rf`:
    ```bash
    huggingface-cli scan-cache          # bảng model + dung lượng + lần dùng cuối
    huggingface-cli delete-cache        # chọn revision để xóa (giao diện tương tác)
    # hoặc thẳng tay:
    rm -rf ~/.cache/huggingface/hub
    ```
    *(Đặt `HF_HOME=/ổ/khác/hf` trong `~/.bashrc`/`~/.zshrc` để chuyển hẳn cache
    sang ổ rộng hơn thay vì phải dọn định kỳ.)*
* 🟢 **PyTorch / Keras / Whisper / CLIP:**
    ```bash
    rm -rf ~/.cache/torch/hub ~/.cache/torch/checkpoints
    rm -rf ~/.cache/whisper ~/.cache/clip
    du -sh ~/.keras/models 2>/dev/null
    ```
* 🟢 **Cache JIT của GPU** (tự sinh lại, chỉ chậm lần chạy đầu):
    ```bash
    rm -rf ~/.nv/ComputeCache ~/.triton/cache
    ```
* 🟡 **Virtualenv chứa `torch`/`mediapipe`/`onnxruntime`** — mỗi cái 2–6 GB, và
  thường có nhiều bản trùng nhau ở các project khác nhau:
    ```bash
    find ~ -maxdepth 5 -type d \( -name '.venv' -o -name 'venv' \) -prune 2>/dev/null \
      | xargs -I{} du -sh {} 2>/dev/null | sort -rh | head -10
    ```
    Xóa được vì `pip install -r requirements.txt` dựng lại được — nhưng **kiểm tra
  project đó có còn dùng không** trước khi xóa. Xem thêm §D2.

## A5. Ảnh / video do AI sinh ra

Output của Stable Diffusion, ComfyUI, Automatic1111… là **dữ liệu thật** (🔴) —
chỉ dọn phần model và cache, và tự rà thư mục output:

```bash
du -sh ~/stable-diffusion-webui/models ~/ComfyUI/models 2>/dev/null
du -sh ~/stable-diffusion-webui/outputs ~/ComfyUI/output 2>/dev/null
```

## A6. Combo AI 1 lệnh (mức an toàn 🟢 — chỉ cache, không đụng transcript)

Đóng IDE trước khi chạy:

```bash
# 🟢 TOÀN BỘ block này chỉ xóa cache tái tạo được: không đụng transcript
# (~/.claude/projects, ~/.codex/sessions), không đụng settings, không đụng model.
CODE=~/.config/Code   # macOS: CODE=~/Library/Application\ Support/Code
rm -rf "$CODE"/Cache "$CODE"/CachedData "$CODE"/CachedExtensionVSIXs "$CODE"/GPUCache "$CODE"/logs \
  && rm -rf ~/.claude/shell-snapshots ~/.claude/statsig ~/.cache/claude-cli-nodejs \
  && rm -rf ~/.codex/cache ~/.gemini/tmp ~/.cursor/ai-tracking \
  && find /tmp -maxdepth 1 -name 'claude-*' -exec rm -rf {} + 2>/dev/null \
  && rm -rf ~/.nv/ComputeCache ~/.triton/cache ~/.cache/torch/hub \
  && df -h /
```

---

# PHẦN B — UBUNTU / DEBIAN

## B1. Dọn dẹp hệ thống (cơ bản)

* 🟢 **Xóa các gói phụ thuộc không còn dùng** (kể cả kernel cũ):
    ```bash
    sudo apt autoremove -y
    ```
* 🔴 **Xóa luôn cả file cấu hình của các gói đó** (mạnh tay hơn, dọn kernel cũ triệt để):
    ```bash
    sudo apt autoremove --purge -y
    ```
* 🟢 **Xóa toàn bộ cache gói `.deb` đã tải:**
    ```bash
    sudo apt clean
    ```
* 🟢 **Chỉ xóa các gói `.deb` đã cũ/hết hạn** (nhẹ tay hơn `clean`):
    ```bash
    sudo apt autoclean
    ```
* 🟢 **Dọn nhật ký hệ thống** — giữ 3 ngày, hoặc giới hạn theo dung lượng:
    ```bash
    journalctl --disk-usage            # xem log đang chiếm bao nhiêu
    sudo journalctl --vacuum-time=3d
    sudo journalctl --vacuum-size=200M
    ```
* 🟢 **Log xoay vòng cũ trong `/var/log`:**
    ```bash
    sudo find /var/log -type f -regex '.*\.\(gz\|old\|[0-9]+\)$' -delete
    ```
* 🟢 **Dọn thùng rác:**
    ```bash
    find ~/.local/share/Trash -mindepth 1 -delete 2>/dev/null   # không glob, an toàn trên zsh
    ```
* 🟢 **Báo cáo crash cũ (`/var/crash`) — thường vài GB:**
    ```bash
    sudo rm -rf /var/crash/*
    ```
* 🟡 **Kiểm tra kernel đang dùng trước khi gỡ kernel cũ:**
    ```bash
    uname -r                                  # kernel đang chạy — TUYỆT ĐỐI không gỡ
    dpkg -l 'linux-image-*' | grep '^ii'      # danh sách kernel đã cài
    ```

## B2. Snap, Flatpak, cấu hình mồ côi

* 🟢 **Xóa các bản Snap cũ (thường giải phóng nhiều GB):**
    ```bash
    LANG=C snap list --all | awk '/disabled/{print $1, $3}' \
      | while read -r snapname revision; do
          sudo snap remove "$snapname" --revision="$revision"
        done
    ```
* 🟡 **Giới hạn snap chỉ giữ 2 bản (chặn rác từ gốc):**
    ```bash
    sudo snap set system refresh.retain=2
    ```
* 🟢 **Flatpak — gỡ runtime không còn ai dùng:**
    ```bash
    flatpak uninstall --unused -y
    flatpak repair --user
    ```
* 🟡 **Xóa file cấu hình rác của phần mềm đã gỡ (residual configs `rc`):**
    ```bash
    dpkg -l | awk '/^rc/ { print $2 }' | sudo xargs --no-run-if-empty dpkg --purge
    ```
* 🔴 **Xóa cache người dùng toàn bộ** — an toàn về mặt dữ liệu nhưng sẽ **đăng xuất
  một số app / mất thumbnail / lần mở app sau chậm**. Nên đóng hết ứng dụng trước:
    ```bash
    rm -rf ~/.cache/*
    # Nhẹ tay hơn — chỉ thumbnail:
    rm -rf ~/.cache/thumbnails
    ```

## B3. Timeshift / snapshot (nếu có cài)

🔴 Snapshot là bản sao lưu hệ thống — xóa là mất khả năng khôi phục.

```bash
sudo timeshift --list                                       # 🟢 chỉ đọc
sudo timeshift --delete --snapshot '2025-01-01_00-00-00'    # 🔴 mất bản khôi phục đó vĩnh viễn
```

## B4. Combo Ubuntu 1 lệnh (mức an toàn 🟢)

```bash
# 🟢 toàn bộ block: chỉ gói/cache/log tái tạo được. Thùng rác 🟡 — kiểm tra
# `ls ~/.local/share/Trash/files` trước nếu bạn hay dùng nó làm chỗ để tạm.
sudo apt autoremove -y && sudo apt autoclean && sudo apt clean \
  && sudo journalctl --vacuum-time=3d \
  && find ~/.local/share/Trash -mindepth 1 -delete 2>/dev/null \
  && rm -rf ~/.cache/thumbnails \
  && df -h /
```

---

# PHẦN C — macOS

macOS không có `apt`/`snap`/`journalctl`. Bảng đối chiếu nhanh:

| Việc cần làm | Ubuntu | macOS |
|---|---|---|
| Package manager hệ thống | `apt` | `brew` |
| Cache gói | `sudo apt clean` | `brew cleanup -s --prune=all` |
| Gỡ dependency thừa | `apt autoremove` | `brew autoremove` |
| Log hệ thống | `journalctl --vacuum-*` | `sudo rm -rf /private/var/log/*.gz` |
| Thùng rác | `~/.local/share/Trash` | `~/.Trash` |
| Cache người dùng | `~/.cache` | `~/Library/Caches` |
| Snapshot hệ thống | Timeshift | APFS local snapshots (`tmutil`) |

## C1. Homebrew

* 🟢 **Dọn version cũ + cache tải về (thường 5–20 GB):**
    ```bash
    brew cleanup -s --prune=all
    rm -rf "$(brew --cache)"
    ```
* 🟡 **Gỡ các formula chỉ còn tồn tại vì là dependency của thứ đã gỡ:**
    ```bash
    brew autoremove
    ```
* **Xem cái gì đang nặng để cân nhắc gỡ tay:**
    ```bash
    brew list --formula
    brew list --cask
    du -sh "$(brew --prefix)"/Cellar/* 2>/dev/null | sort -rh | head -20
    brew doctor
    ```

## C2. Xcode & iOS development — nguồn rác lớn nhất trên máy Mac dev

* 🟢 **DerivedData (build cache — hay chiếm 20–80 GB):**
    ```bash
    du -sh ~/Library/Developer/Xcode/DerivedData
    rm -rf ~/Library/Developer/Xcode/DerivedData      # Xcode tự tạo lại thư mục này
    ```
* 🟡 **iOS DeviceSupport — symbol của các bản iOS cũ, mỗi bản ~3–6 GB:**
    ```bash
    du -sh ~/Library/Developer/Xcode/iOS\ DeviceSupport/*
    rm -rf ~/Library/Developer/Xcode/iOS\ DeviceSupport/*     # chỉ giữ bản iOS đang test
    ```
* 🟢 **Simulator rác (runtime/thiết bị không còn khả dụng):**
    ```bash
    xcrun simctl delete unavailable
    xcrun simctl shutdown all && xcrun simctl erase all       # 🟡 xóa sạch data trong simulator
    rm -rf ~/Library/Developer/CoreSimulator/Caches/*
    du -sh ~/Library/Developer/CoreSimulator/Devices          # kiểm tra trước
    ```
* 🔴 **Archives (file `.xcarchive` để submit App Store — cần cho việc symbolicate crash):**
    ```bash
    du -sh ~/Library/Developer/Xcode/Archives
    # Xóa archive cũ hơn 90 ngày (-mindepth 2 để không đụng vào thư mục gốc):
    find ~/Library/Developer/Xcode/Archives -mindepth 2 -maxdepth 2 -type d -mtime +90 -print
    # kiểm tra danh sách trên xong mới thay -print bằng: -exec rm -rf {} +
    ```
* 🟢 **Cache khác của Xcode / SwiftPM:**
    ```bash
    rm -rf ~/Library/Caches/org.swift.swiftpm
    rm -rf ~/Library/Developer/Xcode/UserData/IB\ Support
    rm -rf ~/Library/Developer/Xcode/iOS\ Device\ Logs/*
    ```

## C3. Cache & log hệ thống macOS

* 🟡 **Cache người dùng** — đóng hết app trước khi chạy:
    ```bash
    du -sh ~/Library/Caches/* | sort -rh | head -20     # xem trước
    rm -rf ~/Library/Caches/*
    ```
* 🟡 **Log người dùng:**
    ```bash
    rm -rf ~/Library/Logs/*
    ```
* 🔴 **Cache cấp hệ thống** (cần `sudo`, một số app có thể phải mở lại):
    ```bash
    sudo rm -rf /Library/Caches/*
    sudo rm -rf /private/var/log/*.gz /private/var/log/asl/*.asl
    ```
* 🟢 **Thùng rác (cả ổ ngoài):**
    ```bash
    find ~/.Trash -mindepth 1 -delete 2>/dev/null              # không glob → chạy được trên zsh
    sudo find /Volumes -maxdepth 2 -name '.Trashes' -exec rm -rf {} + 2>/dev/null
    ```
* 🟢 **Giải phóng RAM/disk cache đang giữ (an toàn, chỉ hơi khựng máy vài giây):**
    ```bash
    sudo purge
    ```

## C4. APFS local snapshots & "Purgeable space"

Đây là lý do kinh điển khiến Finder báo còn 5 GB trong khi `du` chỉ thấy dữ liệu ít
hơn nhiều: Time Machine giữ snapshot cục bộ ngay trên ổ.

```bash
tmutil listlocalsnapshots /                       # liệt kê snapshot
```

* 🟡 **Ép hệ thống dọn snapshot cho tới khi có 20 GB trống** (`4` = mức khẩn cấp nhất):
    ```bash
    sudo tmutil thinlocalsnapshots / 21474836480 4
    ```
* 🔴 **Xóa hẳn một snapshot cụ thể:**
    ```bash
    sudo tmutil deletelocalsnapshots 2025-01-01-000000
    ```

## C5. Rác đặc thù macOS khác

* 🔴 **Backup iPhone/iPad (rất nặng, là dữ liệu thật):**
    ```bash
    du -sh ~/Library/Application\ Support/MobileSync/Backup/*
    ```
* 🟡 **File đính kèm Mail đã tải:**
    ```bash
    du -sh ~/Library/Containers/com.apple.mail/Data/Library/Mail\ Downloads 2>/dev/null
    ```
* 🟡 **Docker Desktop — file ổ ảo (xem thêm §D6):**
    ```bash
    du -sh ~/Library/Containers/com.docker.docker/Data/vms 2>/dev/null
    ```
* 🟢 **Bản cài đặt/DMG cũ trong Downloads:**
    ```bash
    find ~/Downloads -type f \( -name '*.dmg' -o -name '*.pkg' -o -name '*.zip' \) \
      -mtime +30 -exec ls -lh {} + | awk '{print $5, $9}'
    ```
* 🟡 **iOS/macOS software update đã tải dở:**
    ```bash
    sudo rm -rf /Library/Updates/*
    ```

## C6. Combo macOS 1 lệnh (mức an toàn 🟢)

```bash
# 🟢 toàn bộ block: cache brew, DerivedData, simulator rác, thùng rác.
# 🟡 duy nhất ~/.Trash — chắc chắn trong đó không còn gì bạn cần.
brew cleanup -s --prune=all \
  && rm -rf "$(brew --cache)" ~/Library/Developer/Xcode/DerivedData \
  && find ~/.Trash -mindepth 1 -delete 2>/dev/null \
  && xcrun simctl delete unavailable \
  && sudo purge \
  && df -h /
```

---

# PHẦN D — MÔI TRƯỜNG DEV (dùng chung cả 2 OS)

Với máy lập trình viên, phần này thường giải phóng **nhiều hơn cả phần hệ điều hành**.
Mọi dòng có thao tác xóa đều được gắn nhãn ngay trong code block.

## D1. Node.js — NVM, npm, yarn, pnpm, bun

**Quản lý phiên bản Node bằng NVM:**

```bash
nvm ls                              # 🟢 chỉ đọc — dòng N/A là chưa cài, không tốn dung lượng
du -sh ~/.nvm/versions/node/* | sort -rh   # 🟢 chỉ đọc
nvm uninstall 14.17.0               # 🟡 xóa 1 bản Node; project nào ghim bản đó sẽ gãy
nvm current && cat .nvmrc 2>/dev/null      # 🟢 kiểm tra bản đang dùng TRƯỚC khi gỡ
```

*(macOS cài qua Homebrew thì dùng `brew uninstall node@18` — cũng 🟡; hoặc dùng
`fnm`/`volta`, xóa tương tự trong `~/.local/share/fnm` / `~/.volta/tools`.)*

**Cache của các package manager:**

```bash
du -sh ~/.npm ~/.cache/yarn ~/Library/Caches/Yarn ~/.bun/install/cache 2>/dev/null  # 🟢 chỉ đọc
pnpm store path && du -sh "$(pnpm store path)"   # 🟢 chỉ đọc

npm cache clean --force            # 🟢 ~/.npm — cài lại tự tải về
yarn cache clean                   # 🟢 yarn classic
yarn cache clean --all             # 🟢 yarn berry
pnpm store prune                   # 🟢 chỉ xóa package không project nào tham chiếu
bun pm cache rm                    # 🟢
rm -rf ~/.npm/_npx                 # 🟢 cache của npx
```

> ⚠️ Chỉ 🟢 khi bạn **đang online**. Nếu sắp làm việc offline hoặc đang ở mạng chậm,
> mất cache = không `npm install` được nữa → khi đó phải coi là 🟡.

**`node_modules` — thủ phạm số 1.**

```bash
# 🟢 chỉ đọc — liệt kê mọi node_modules kèm dung lượng, nặng nhất lên đầu
find ~ -name node_modules -type d -prune 2>/dev/null \
  | xargs -I{} du -sh {} 2>/dev/null | sort -rh | head -20

# 🟢 chỉ đọc — xem project nào không đụng tới trong 90 ngày
find ~/projects -name node_modules -type d -prune -mtime +90 -print

# 🔴 XÓA THẬT — chỉ chạy sau khi đã đọc kỹ danh sách ở trên.
# Rủi ro: project dùng lockfile cũ / package đã bị gỡ khỏi registry sẽ không
# install lại được y hệt. Không đụng repo đang dở việc.
# find ~/projects -name node_modules -type d -prune -mtime +90 -exec rm -rf {} +
```

```bash
npx npkill        # 🟡 công cụ tương tác — bạn tự chọn thư mục để xóa, xóa là mất luôn
```

**Electron / build output:**

```bash
du -sh ~/.cache/electron ~/.electron ~/.cache/electron-builder 2>/dev/null   # 🟢 chỉ đọc
rm -rf ~/.cache/electron ~/.electron ~/.cache/electron-builder    # 🟡 build Electron kế tiếp phải tải lại ~200MB/bản
rm -rf ~/Library/Caches/electron ~/Library/Caches/electron-builder   # 🟡 macOS, tương tự
```

## D2. Python

```bash
du -sh ~/.cache/pip ~/.cache/uv ~/.cache/pypoetry 2>/dev/null   # 🟢 chỉ đọc

pip cache purge                       # 🟢 cache wheel — tải lại được
uv cache clean                        # 🟢 nếu dùng uv
conda clean --all -y                  # 🟡 gỡ cả package tarball + index; env vẫn còn nguyên
rm -rf ~/.cache/pypoetry              # 🟢 Poetry (Ubuntu)
rm -rf ~/Library/Caches/pypoetry      # 🟢 Poetry (macOS)
```

```bash
# 🟢 bytecode tự sinh lại khi chạy — an toàn tuyệt đối
find ~ -type d -name __pycache__ -prune -exec rm -rf {} + 2>/dev/null
find ~ -type f -name '*.pyc' -delete 2>/dev/null
```

```bash
# 🟢 chỉ đọc — tìm virtualenv nặng (bản có torch/mediapipe thường 2–6 GB, xem §A4)
find ~ -maxdepth 4 -type d \( -name '.venv' -o -name 'venv' \) -prune 2>/dev/null \
  | xargs -I{} du -sh {} 2>/dev/null | sort -rh | head

# 🔴 xóa 1 venv cụ thể — dựng lại được bằng requirements.txt/pyproject.toml,
# NHƯNG chỉ khi file đó còn và pin version còn cài được. Kiểm tra trước khi xóa:
# ls <project>/requirements.txt <project>/pyproject.toml && rm -rf <project>/.venv
```

## D3. Rust

`target/` là hố đen dung lượng — mỗi project vài GB là bình thường.

```bash
du -sh ~/.cargo/registry ~/.cargo/git        # 🟢 chỉ đọc
# 🟢 chỉ đọc — tìm mọi thư mục target/
find ~ -type d -name target -prune 2>/dev/null \
  | xargs -I{} du -sh {} 2>/dev/null | sort -rh | head -20

cargo clean                                  # 🟡 trong từng project — build kế tiếp là full rebuild (chậm)
rm -rf ~/.cargo/registry/cache ~/.cargo/registry/src   # 🟢 tải lại được khi build
```

```bash
cargo install cargo-sweep                    # 🟢 chỉ cài công cụ
cargo sweep --time 30 --dry-run --recursive ~/projects   # 🟢 xem trước sẽ xóa gì
cargo sweep --time 30 --recursive ~/projects             # 🟡 xóa artifact >30 ngày trong mọi target/
```

```bash
rustup toolchain list                        # 🟢 chỉ đọc
rustup toolchain uninstall nightly-2023-01-01   # 🟡 project ghim toolchain đó (rust-toolchain.toml) sẽ phải tải lại
```

## D4. Go

```bash
du -sh "$(go env GOMODCACHE)" "$(go env GOCACHE)"   # 🟢 chỉ đọc

go clean -cache        # 🟢 build cache — build sau chậm hơn, không mất gì
go clean -testcache    # 🟢 kết quả test cache
go clean -modcache     # 🟡 module cache — phải tải lại toàn bộ dependency, hỏng nếu offline
```

## D5. Java / Android / Gradle / Maven

```bash
du -sh ~/.gradle ~/.m2/repository 2>/dev/null   # 🟢 chỉ đọc
du -sh ~/Android/Sdk ~/Library/Android/sdk 2>/dev/null   # 🟢 chỉ đọc
du -sh ~/.android/avd/* 2>/dev/null             # 🟢 chỉ đọc — mỗi emulator vài GB

./gradlew --stop                       # 🟢 chỉ dừng daemon — BẮT BUỘC chạy trước khi xóa
# 🟢 chỉ cache build tăng tiến (find thay glob cho zsh)
find ~/.gradle/caches -maxdepth 1 -name 'build-cache-*' -exec rm -rf {} + 2>/dev/null
rm -rf ~/.gradle/daemon                # 🟢 log của daemon
rm -rf ~/.gradle/caches                # 🟡 build kế tiếp tải lại toàn bộ dependency (rất lâu)
rm -rf ~/.gradle/wrapper/dists         # 🟡 mỗi project tải lại bản Gradle của nó
rm -rf ~/.m2/repository                # 🟡 Maven — tương tự, và mất luôn artifact bạn `mvn install` cục bộ
```

> 🔴 `~/.m2/repository` có thể chứa **artifact nội bộ do bạn tự build và cài** mà
> không repo nào tải lại được. Kiểm tra trước: `find ~/.m2/repository -name '*.jar' -newer ~/.m2/settings.xml`.

```bash
# 🔴 xóa emulator (AVD) — mất luôn dữ liệu bên trong máy ảo đó
# avdmanager list avd            # 🟢 xem trước
# avdmanager delete avd -n <tên>
```

## D6. Docker

```bash
docker system df                       # 🟢 LUÔN chạy trước khi prune
docker system df -v                    # 🟢 chi tiết từng image/volume

docker builder prune -af               # 🟢 chỉ cache build — build lại chậm hơn, không mất gì
docker image prune                     # 🟢 chỉ xóa image dangling (<none>)
docker container prune                 # 🟡 xóa container đã dừng — mất dữ liệu ghi trong container layer
docker system prune                    # 🟡 container dừng + network thừa + image mồ côi + cache build
docker image prune -a                  # 🟡 xóa mọi image không có container dùng → phải pull lại
docker system prune -a --volumes       # 🔴 XÓA CẢ VOLUME — mất database/local state của mọi project
```

```bash
docker volume ls                       # 🟢 xem trước
docker volume rm <tên>                 # 🔴 mất hẳn dữ liệu trong volume đó
```

Trên macOS, dung lượng chỉ thực sự trả lại cho ổ đĩa sau khi Docker Desktop thu nhỏ
ổ ảo: **Docker Desktop → Settings → Resources → Advanced → Disk image size** (🟡),
hoặc **Troubleshoot → Reset to factory defaults** (🔴 mất toàn bộ image + volume).

## D7. Git

```bash
git count-objects -vH                  # 🟢 chỉ đọc — xem repo phình cỡ nào
# 🟢 chỉ đọc — tìm repo nặng
find ~ -name '.git' -type d -prune 2>/dev/null \
  | xargs -I{} du -sh {} 2>/dev/null | sort -rh | head -15

git gc                                 # 🟢 nén an toàn, giữ nguyên mọi thứ còn tham chiếu
git gc --aggressive --prune=now        # 🟡 nén mạnh + xóa NGAY object mồ côi:
                                       #    mất reflog cũ → không `git reset` ngược lại được nữa
```

> 🔴 Đừng chạy `--prune=now` khi vừa `reset --hard` / `rebase` hỏng và còn định
> cứu commit cũ bằng `git reflog`. Nén xong là mất đường lùi.

## D8. Trình duyệt & IDE (phần không liên quan AI)

> Cache của VS Code/Cursor gắn với panel AI đã nằm ở §A2 — phần này chỉ là trình
> duyệt và JetBrains.

```bash
# Ubuntu
du -sh ~/.cache/google-chrome ~/.cache/mozilla ~/.cache/chromium 2>/dev/null   # 🟢 chỉ đọc
# 🟢 chỉ cache trang, không đụng profile/mật khẩu (find thay glob cho zsh)
find ~/.cache/google-chrome -maxdepth 2 -name 'Cache' -exec rm -rf {} + 2>/dev/null
find ~/.cache/mozilla -maxdepth 3 -name 'cache2' -exec rm -rf {} + 2>/dev/null

# macOS
du -sh ~/Library/Caches/Google/Chrome ~/Library/Caches/Firefox 2>/dev/null     # 🟢 chỉ đọc
# 🟢
find ~/Library/Caches/Google/Chrome -maxdepth 2 -name 'Cache' -exec rm -rf {} + 2>/dev/null

# JetBrains (kể cả cache của AI Assistant / Junie) — cả 2 OS
du -sh ~/.cache/JetBrains ~/Library/Caches/JetBrains 2>/dev/null   # 🟢 chỉ đọc
# 🟡 IDE phải index lại toàn bộ project (lâu)
find ~/.cache/JetBrains ~/Library/Caches/JetBrains -maxdepth 2 \
     \( -name 'caches' -o -name 'index' \) -exec rm -rf {} + 2>/dev/null
```

> 🔴 **Không** xóa `~/.config/google-chrome` hay `~/Library/Application Support/Google/Chrome`
> — đó là **profile** (bookmark, mật khẩu, session), không phải cache. Chỉ xóa trong
> `~/.cache` / `~/Library/Caches`.

---

# PHẦN E — TUYỆT ĐỐI KHÔNG XÓA

| Đường dẫn | Vì sao |
|---|---|
| `/System`, `/private/var/db` (macOS) | Ổ hệ thống chỉ đọc; nghịch vào là hỏng máy. |
| `~/Library` (nguyên cụm, macOS) | Chứa toàn bộ cấu hình + dữ liệu app, **không phải** chỉ cache. |
| `/var/lib` (Ubuntu) | Database của apt, Docker, MySQL… |
| `/boot` | Xóa nhầm kernel đang chạy → máy không boot được. |
| `~/.ssh`, `~/.gnupg`, `~/.aws`, `~/.config/gh` | Khóa và credential, không tái tạo được. |
| `~/.claude/settings.json`, `~/.claude.json`, `CLAUDE.md`, `~/.claude/skills`, `~/.claude/agents`, `~/.claude/memory` | Cấu hình, skill, memory bạn tự viết — không tái tạo được. |
| `~/.config/Code/User/{settings.json,keybindings.json,snippets,History}` | Cấu hình IDE + local history có thể cứu code chưa commit. |
| `.env`, `~/.config/*/auth.json`, token của Copilot/Claude/Codex | Xóa là phải đăng nhập lại toàn bộ. |
| `~/Library/Application Support/<app>` | Dữ liệu thật của app (không phải cache). |
| Docker volume | Database/local state của dự án. `prune --volumes` là 🔴. |
| Snapshot Timeshift / Time Machine | Là bản backup — mất luôn đường lùi. |

Trước mọi lệnh `rm -rf` có wildcard, chạy phiên bản “xem trước” bằng `ls` hoặc
`du -sh` trên đúng pattern đó. Với `find … -exec rm`, **luôn** chạy với `-print`
trước, đọc kỹ danh sách, rồi mới đổi thành `-exec`.

---

# PHẦN F — SCRIPT TỰ ĐỘNG (nhận diện OS)

Lưu thành `~/bin/cleanup.sh`, `chmod +x ~/bin/cleanup.sh`, chạy `cleanup.sh`.
Script **chỉ làm các thao tác 🟢 và 🟡 nhẹ**, và **in dung lượng trước/sau**.
Nó cố tình **không** làm bất cứ thao tác 🔴 nào: không đụng transcript AI, không
`docker system prune -a --volumes`, không xóa `node_modules`/`.venv`/`target`,
không gỡ model Ollama, không xóa snapshot. Những việc đó phải do bạn tự quyết định
theo §A–§D. Mỗi nhóm trong script được gắn nhãn ngay trong output khi chạy.

```bash
#!/usr/bin/env bash
# Chạy bằng bash kể cả trên macOS (shebang lo việc đó) — không phụ thuộc zsh.
set -uo pipefail

human() { df -h / | awk 'NR==2 {print $4" free of "$2}'; }
say()   { printf '\n\033[1;36m▸ %s\033[0m\n' "$*"; }
run()   { echo "  $ $*"; "$@" >/dev/null 2>&1 || echo "    (bỏ qua)"; }

echo "Trước: $(human)"

say "[🟢] Công cụ AI — chỉ cache, không đụng transcript/model"
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
command -v ollama >/dev/null && echo "  (ollama: chạy 'ollama list' để tự gỡ model không dùng)"

say "[🟢] Package manager Node — cache tải lại được"
command -v npm  >/dev/null && run npm cache clean --force
command -v yarn >/dev/null && run yarn cache clean
command -v pnpm >/dev/null && run pnpm store prune
command -v bun  >/dev/null && run bun pm cache rm

say "[🟢] Python / Go / Rust — cache build, không đụng modcache"
command -v pip   >/dev/null && run pip cache purge
command -v go    >/dev/null && run go clean -cache -testcache
command -v cargo >/dev/null && run rm -rf "$HOME/.cargo/registry/cache"

say "[🟢] Docker — chỉ cache build, KHÔNG prune image/volume"
command -v docker >/dev/null && run docker builder prune -af

case "$(uname -s)" in
  Linux)
    say "[🟢/🟡] Ubuntu — apt, journal, thùng rác (🟡)"
    run sudo apt autoremove -y
    run sudo apt autoclean
    run sudo apt clean
    run sudo journalctl --vacuum-time=3d
    run find "$HOME/.local/share/Trash" -mindepth 1 -delete
    run rm -rf "$HOME/.cache/thumbnails"
    say "[🟢] Snap — chỉ xóa revision đã disabled"
    LANG=C snap list --all 2>/dev/null | awk '/disabled/{print $1, $3}' \
      | while read -r n r; do sudo snap remove "$n" --revision="$r" >/dev/null 2>&1; done
    ;;
  Darwin)
    say "[🟢/🟡] macOS — brew, DerivedData, thùng rác (🟡)"
    command -v brew >/dev/null && run brew cleanup -s --prune=all
    command -v brew >/dev/null && run rm -rf "$(brew --cache)"
    run rm -rf "$HOME/Library/Developer/Xcode/DerivedData"
    command -v xcrun >/dev/null && run xcrun simctl delete unavailable
    run find "$HOME/.Trash" -mindepth 1 -delete
    run sudo purge
    ;;
esac

echo
echo "Sau:   $(human)"
```

---

# PHẦN G — CHECKLIST NHANH

Khi ổ đĩa gần đầy, làm theo đúng thứ tự này:

1. `df -h /` — xác nhận thật sự hết chỗ (macOS: nhớ kiểm tra snapshot ở §C4).
2. **Chạy lệnh đo công cụ AI ở đầu §A** — nhóm này thường chiếm nhiều GB nhất mà
   không ai để ý, và `apt`/`brew` không chạm tới.
3. Nếu có Ollama/LM Studio: `ollama list` → gỡ model không dùng (§A3). Đây là bước
   duy nhất có thể giải phóng vài chục GB trong 1 phút.
4. `ncdu -x /` hoặc `du -sh ~/* | sort -rh | head` — tìm thủ phạm còn lại.
5. Chạy combo AI (§A6) rồi combo an toàn của OS (§B4 hoặc §C6).
6. Quét `node_modules` / `target` / `DerivedData` / `.gradle` / `.venv` (§D).
7. `docker system df` → prune nếu đang chiếm nhiều (§D6).
8. Gỡ hẳn app/SDK/phiên bản Node không còn dùng.
9. Đo lại `df -h /`; nếu vẫn thiếu, mới tính đến các mục 🔴.

---
*Tài liệu dành cho Ubuntu/Debian và macOS (Intel & Apple Silicon).*
