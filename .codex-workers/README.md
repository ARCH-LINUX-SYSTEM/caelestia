# Parallel Codex Workers

Thiết lập này tách công việc Caelestia thành bốn Git branch và bốn Git worktree độc lập. Mỗi Codex CLI chỉ được chạy trong một worktree tương ứng; repository chính chỉ dùng để điều phối.

## Sơ đồ worker

| Worker | Branch | Worktree tương đối với thư mục cha repository |
| --- | --- | --- |
| Launcher | `feat/dms-launcher` | `caelestia-workers/launcher` |
| System Tools | `feat/dms-system-tools` | `caelestia-workers/system-tools` |
| Control Center | `feat/dms-control-center` | `caelestia-workers/control-center` |
| Desktop Integration | `feat/dms-desktop-integration` | `caelestia-workers/desktop-integration` |

Mỗi worktree có:

- `AGENTS.md`: quy tắc và phạm vi bắt buộc.
- `CODEX_TASK.md`: prompt công việc chi tiết.
- `INTEGRATION_NOTES.md`: nơi ghi nhu cầu config, dependency và thay đổi file dùng chung.

## Cảnh báo an toàn

Bốn task worker chạy Codex bằng:

```bash
codex --sandbox danger-full-access --ask-for-approval never
```

Đây là YOLO/full-access mode. Codex có toàn quyền filesystem và không hỏi phê duyệt từng lệnh.

- Không mở hai Codex CLI trong cùng một worktree.
- Không chạy worker trong repository chính.
- Không checkout branch khác bên trong worktree.
- Không dùng `git pull`, `git merge`, `git rebase`, `git reset --hard` hoặc `git clean`.
- Không merge tự động trong giai đoạn setup này.

Script kiểm tra branch trước khi chạy và từ chối khởi động nếu worktree đang ở sai branch.

## Chạy từng worker

Từ repository chính:

```bash
.codex-workers/run-worker.sh launcher
.codex-workers/run-worker.sh system-tools
.codex-workers/run-worker.sh control-center
.codex-workers/run-worker.sh desktop-integration
```

Script không tự gửi prompt. Sau khi Codex CLI mở, nhập:

```text
Đọc AGENTS.md và CODEX_TASK.md, sau đó triển khai toàn bộ nhiệm vụ. Không làm ngoài phạm vi. Hãy commit khi hoàn thành.
```

## Chạy bằng VS Code Tasks

Mở Command Palette, chọn `Tasks: Run Task`, rồi dùng một trong các task:

- `Codex Worker: Launcher`
- `Codex Worker: System Tools`
- `Codex Worker: Control Center`
- `Codex Worker: Desktop Integration`
- `Codex Workers: Start All`

`Codex Workers: Start All` khởi động bốn task song song trong bốn terminal riêng. Không nhập prompt vào terminal nào cho đến khi kiểm tra đúng tên worker, worktree và branch.

Để mở cả repository chính lẫn bốn worktree trong một cửa sổ, dùng file `caelestia-workers.code-workspace`.

## Kiểm tra trạng thái

Chạy:

```bash
.codex-workers/check-workers.sh
```

Hoặc dùng task `Codex Workers: Check Status`.

Để xem danh sách Git worktree, dùng task `Codex Workers: List Worktrees` hoặc:

```bash
git worktree list
```

## Đóng Codex CLI

Dùng `Ctrl+C`. Nếu phiên Codex đang hỗ trợ lệnh thoát tương tác, có thể dùng lệnh thoát được hiển thị trong CLI.

## Xem commit của từng worker

Từ repository chính:

```bash
git -C ../caelestia-workers/launcher log -1 --oneline
git -C ../caelestia-workers/system-tools log -1 --oneline
git -C ../caelestia-workers/control-center log -1 --oneline
git -C ../caelestia-workers/desktop-integration log -1 --oneline
```

Kiểm tra trạng thái chưa commit:

```bash
git -C ../caelestia-workers/launcher status --short
```

Thay `launcher` bằng worker cần kiểm tra.

Nếu worker chưa commit:

1. Không merge branch đó.
2. Mở lại đúng worker/worktree.
3. Yêu cầu worker kiểm tra diff, chạy test phù hợp, cập nhật `INTEGRATION_NOTES.md` và commit.
4. Không stash, discard hoặc tự động commit thay đổi thay cho worker nếu chưa kiểm tra nội dung.

## Thứ tự merge đề xuất

```text
feat/dms-launcher
feat/dms-system-tools
feat/dms-control-center
feat/dms-desktop-integration
```

Desktop Integration được merge cuối vì sở hữu config schema, migration, Settings navigation và các file tích hợp chung. Setup này không tự động merge branch nào.

Plugin system hoàn chỉnh sẽ được thực hiện trên branch riêng sau khi cả bốn branch trên đã được tích hợp.
