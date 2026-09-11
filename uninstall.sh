#!/usr/bin/env bash

set -euo pipefail

readonly PROJECT_NAME="caelestia-shell-aw"
readonly APP_ID="io.github.conlongnhong.caelestia-shell-aw"
readonly STATE_DIR="/var/lib/${PROJECT_NAME}"
readonly STATE_MANIFEST="${STATE_DIR}/install-manifest"
readonly STATE_PENDING_MANIFEST="${STATE_DIR}/install-manifest.pending"
readonly STATE_METADATA="${STATE_DIR}/metadata"
readonly STATE_PENDING_METADATA="${STATE_DIR}/metadata.pending"
readonly HYPR_SOURCE_BEGIN="# >>> ${PROJECT_NAME} managed source >>>"
readonly HYPR_SOURCE_END="# <<< ${PROJECT_NAME} managed source <<<"
readonly HYPR_SNIPPET_OWNER="# CAELESTIA_SHELL_AW_MANAGED=${APP_ID}"

readonly -a INSTALL_ROOTS=(
    "/etc/xdg/quickshell/caelestia"
    "/usr/lib/caelestia"
    "/usr/lib/qt6/qml/Caelestia"
    "/usr/lib/qt6/qml/M3Shapes"
)

REMOVE_HYPRLAND=true
UNINSTALL_INCOMPLETE=false
WORK_DIR=""

info() {
    printf '[%s] %s\n' "$PROJECT_NAME" "$*"
}

warn() {
    printf '[%s] CẢNH BÁO: %s\n' "$PROJECT_NAME" "$*" >&2
}

cleanup() {
    if [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]]; then
        rm -rf -- "$WORK_DIR"
    fi
}

die() {
    printf '[%s] LỖI: %s\n' "$PROJECT_NAME" "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Cách dùng: ./uninstall.sh [TÙY CHỌN]

Gỡ chỉ các tệp do installer Caelestia Shell AW ghi trong manifest.

Tùy chọn:
  --no-hyprland    Giữ nguyên snippet và source marker trong Hyprland.
  --skip-deps      Tùy chọn tương thích; dependency luôn được giữ lại.
  -h, --help       Hiển thị trợ giúp này.

Script không xóa dependency, ~/.config/caelestia, wallpaper, recording hay
bất kỳ tệp nào không có trong manifest root-owned của installer.
EOF
}

parse_args() {
    while (($# > 0)); do
        case "$1" in
            --no-hyprland)
                REMOVE_HYPRLAND=false
                ;;
            --skip-deps)
                # Dependencies are intentionally never removed. Accept this for
                # command-line symmetry with install.sh.
                ;;
            -h | --help)
                usage
                exit 0
                ;;
            --)
                shift
                (($# == 0)) || die "Không chấp nhận đối số vị trí: $*"
                break
                ;;
            *)
                die "Tùy chọn không hợp lệ: $1 (dùng --help để xem trợ giúp)"
                ;;
        esac
        shift
    done
}

check_not_root() {
    ((EUID != 0)) || die "Không chạy toàn bộ uninstall.sh bằng root hoặc sudo. Hãy chạy bằng user thường."
}

check_supported_os() {
    local os_release="${CAELESTIA_OS_RELEASE_FILE:-/etc/os-release}"
    [[ -r "$os_release" ]] || die "Không đọc được $os_release."

    local ID=""
    # shellcheck disable=SC1090
    source "$os_release"
    case "${ID,,}" in
        arch | cachyos) ;;
        *)
            die "Chỉ hỗ trợ Arch Linux và CachyOS (phát hiện ID=${ID:-unknown})."
            ;;
    esac

    command -v pacman >/dev/null 2>&1 || die "Không tìm thấy pacman."
}

path_is_allowed() {
    local path="$1"
    local root
    for root in "${INSTALL_ROOTS[@]}"; do
        if [[ "$path" == "$root/"* ]]; then
            return 0
        fi
    done
    return 1
}

validate_manifest_path() {
    local path="$1"
    [[ "$path" == /* ]] || die "Manifest chứa path không tuyệt đối: $path"
    [[ "$path" != *$'\n'* && "$path" != *$'\r'* ]] || die "Manifest chứa newline không an toàn."
    [[ "$path" != *'//'* && "$path" != */ ]] || die "Manifest chứa path không chuẩn hóa: $path"
    [[ "$path" != *'/../'* && "$path" != */.. && "$path" != *'/./'* && "$path" != */. ]] || die \
        "Manifest chứa path traversal: $path"
    path_is_allowed "$path" || die "Manifest chứa path ngoài phạm vi cho phép: $path"
}

validate_root_owned_state_path() {
    local path="$1"
    [[ ! -L "$path" ]] || die "State path không được là symlink: $path"
    local uid mode
    uid="$(stat -c '%u' -- "$path")"
    mode="$(stat -c '%a' -- "$path")"
    [[ "$uid" == 0 ]] || die "State path không thuộc root: $path"
    (( (8#$mode & 8#022) == 0 )) || die "State path cho phép group/other ghi, không an toàn: $path"
}

validate_existing_state() {
    if [[ -e "$STATE_DIR" || -L "$STATE_DIR" ]]; then
        [[ -d "$STATE_DIR" ]] || die "$STATE_DIR tồn tại nhưng không phải thư mục."
        validate_root_owned_state_path "$STATE_DIR"
    fi

    local state_file
    for state_file in "$STATE_MANIFEST" "$STATE_PENDING_MANIFEST" "$STATE_METADATA" "$STATE_PENDING_METADATA"; do
        if [[ -e "$state_file" || -L "$state_file" ]]; then
            [[ -f "$state_file" ]] || die "State entry không phải regular file: $state_file"
            validate_root_owned_state_path "$state_file"
        fi
    done
}

assert_no_symlink_parent() {
    local path="$1"
    local root root_parent parent
    for root in "${INSTALL_ROOTS[@]}"; do
        if [[ "$path" == "$root/"* ]]; then
            root_parent="$(dirname -- "$root")"
            [[ ! -L "$root_parent" ]] || die "Install root parent là symlink, từ chối thao tác: $root_parent"
            parent="$(dirname -- "$path")"
            while [[ "$parent" == "$root" || "$parent" == "$root/"* ]]; do
                [[ ! -L "$parent" ]] || die "Parent path là symlink, từ chối xóa theo symlink: $parent"
                [[ "$parent" != "$root" ]] || break
                parent="$(dirname -- "$parent")"
            done
            return 0
        fi
    done
    die "Path nằm ngoài install roots: $path"
}

root_for_path() {
    local path="$1"
    local root
    for root in "${INSTALL_ROOTS[@]}"; do
        if [[ "$path" == "$root/"* ]]; then
            printf '%s\n' "$root"
            return 0
        fi
    done
    return 1
}

prune_empty_parents() {
    local file_path="$1"
    local root dir
    root="$(root_for_path "$file_path")" || return 0
    dir="$(dirname -- "$file_path")"
    while [[ "$dir" == "$root" || "$dir" == "$root/"* ]]; do
        sudo rmdir -- "$dir" 2>/dev/null || break
        [[ "$dir" != "$root" ]] || break
        dir="$(dirname -- "$dir")"
    done
}

collect_manifest_paths() {
    local output="$1"
    : > "$output"

    local manifest path
    for manifest in "$STATE_MANIFEST" "$STATE_PENDING_MANIFEST"; do
        [[ -f "$manifest" ]] || continue
        while IFS= read -r path || [[ -n "$path" ]]; do
            [[ -n "$path" ]] || continue
            validate_manifest_path "$path"
            printf '%s\n' "$path" >> "$output"
        done < "$manifest"
    done
    LC_ALL=C sort -u -o "$output" "$output"
}

remove_manifest_paths() {
    local manifest="$1"
    local path
    # Reverse lexical order generally removes children before similarly named
    # parents; the manifest itself contains files/symlinks only.
    while IFS= read -r path || [[ -n "$path" ]]; do
        [[ -n "$path" ]] || continue
        validate_manifest_path "$path"
        assert_no_symlink_parent "$path"

        if pacman -Qo "$path" >/dev/null 2>&1; then
            warn "Giữ lại path vì hiện thuộc package pacman: $path"
            continue
        fi
        if [[ -e "$path" || -L "$path" ]]; then
            if [[ -d "$path" && ! -L "$path" ]]; then
                warn "Bỏ qua directory bất ngờ trong file manifest: $path"
                UNINSTALL_INCOMPLETE=true
                continue
            fi
            sudo rm -f -- "$path"
        fi
        prune_empty_parents "$path"
    done < <(LC_ALL=C sort -r -- "$manifest")
}

resolve_hypr_main_config() {
    local configured_path="$1"
    if [[ -L "$configured_path" ]]; then
        local resolved
        resolved="$(readlink -f -- "$configured_path")" || return 1
        [[ -n "$resolved" ]] || return 1
        printf '%s\n' "$resolved"
    else
        printf '%s\n' "$configured_path"
    fi
}

strip_hypr_source_blocks() {
    local input="$1"
    local output="$2"
    local starts ends
    starts="$(grep -Fxc -- "$HYPR_SOURCE_BEGIN" "$input" || true)"
    ends="$(grep -Fxc -- "$HYPR_SOURCE_END" "$input" || true)"
    if [[ "$starts" != "$ends" ]]; then
        warn "Source marker Hyprland không cân bằng; giữ nguyên $input"
        return 1
    fi

    if ! awk -v start="$HYPR_SOURCE_BEGIN" -v end="$HYPR_SOURCE_END" '
        $0 == start {
            if (managed) exit 41
            managed = 1
            next
        }
        $0 == end {
            if (!managed) exit 42
            managed = 0
            next
        }
        !managed { lines[++count] = $0 }
        END {
            if (managed) exit 43
            while (count > 0 && lines[count] == "") count--
            for (i = 1; i <= count; i++) print lines[i]
        }
    ' "$input" > "$output"; then
        rm -f -- "$output"
        warn "Source marker Hyprland sai thứ tự; giữ nguyên $input"
        return 1
    fi
}

remove_hyprland_integration() {
    local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    local hypr_dir="${config_home}/hypr"
    local requested_main="${hypr_dir}/hyprland.conf"
    local snippet="${hypr_dir}/${PROJECT_NAME}.conf"

    if [[ -e "$snippet" || -L "$snippet" ]]; then
        if [[ -L "$snippet" || ! -f "$snippet" ]]; then
            warn "Không xóa snippet không phải regular file do installer sở hữu: $snippet"
        elif [[ "$(head -n 1 -- "$snippet")" != "$HYPR_SNIPPET_OWNER" ]]; then
            warn "Không xóa snippet đã mất owner marker: $snippet"
        else
            rm -f -- "$snippet"
            info "Đã xóa snippet Hyprland do installer sở hữu."
        fi
    fi

    local main_config
    main_config="$(resolve_hypr_main_config "$requested_main")" || {
        warn "Hyprland config symlink bị hỏng; không sửa source marker: $requested_main"
        return 0
    }
    [[ -f "$main_config" ]] || return 0

    local starts
    starts="$(grep -Fxc -- "$HYPR_SOURCE_BEGIN" "$main_config" || true)"
    ((starts > 0)) || return 0
    [[ -w "$main_config" ]] || {
        warn "Không có quyền sửa source marker: $main_config"
        return 0
    }

    local main_tmp
    main_tmp="$(mktemp "$(dirname -- "$main_config")/.${PROJECT_NAME}.uninstall.XXXXXX")"
    if strip_hypr_source_blocks "$main_config" "$main_tmp"; then
        chmod --reference="$main_config" "$main_tmp"
        mv -f -- "$main_tmp" "$main_config"
        info "Đã xóa source marker do installer sở hữu khỏi Hyprland config."
    else
        rm -f -- "$main_tmp"
    fi

    if command -v hyprctl >/dev/null 2>&1 && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        hyprctl reload >/dev/null 2>&1 || warn "Không reload được Hyprland."
    fi
}

main() {
    parse_args "$@"
    check_not_root
    check_supported_os
    command -v sudo >/dev/null 2>&1 || die "Thiếu lệnh bắt buộc: sudo"
    validate_existing_state

    local manifest
    WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/${PROJECT_NAME}-uninstall.XXXXXX")"
    trap cleanup EXIT INT TERM
    manifest="${WORK_DIR}/install-manifest"
    collect_manifest_paths "$manifest"

    if [[ -s "$manifest" ]]; then
        sudo -v
        info "Gỡ các tệp có trong manifest sở hữu."
        remove_manifest_paths "$manifest"
        [[ "$UNINSTALL_INCOMPLETE" == false ]] || die \
            "Gỡ cài đặt chưa hoàn tất; state manifest được giữ lại để xử lý an toàn."
        sudo rm -f -- "$STATE_MANIFEST" "$STATE_PENDING_MANIFEST" "$STATE_METADATA" "$STATE_PENDING_METADATA"
        sudo rmdir -- "$STATE_DIR" 2>/dev/null || true
    else
        info "Không có manifest hệ thống; không xóa bất kỳ tệp cài đặt nào."
    fi

    if [[ "$REMOVE_HYPRLAND" == true ]]; then
        remove_hyprland_integration
    else
        info "Giữ nguyên tích hợp Hyprland theo --no-hyprland."
    fi

    info "Gỡ cài đặt hoàn tất. Dependency và config người dùng được giữ nguyên."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
