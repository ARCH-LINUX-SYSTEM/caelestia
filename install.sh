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

# Packages available from the official Arch repositories. Missing packages are
# installed only after checking dependency satisfaction, so providers such as a
# locally installed Hyprland variant are not needlessly replaced.
readonly -a REPO_DEPENDENCIES=(
    base-devel
    git
    cmake
    ninja
    pkgconf
    qt6-base
    qt6-declarative
    qt6-shadertools
    qt6-multimedia
    qt6-imageformats
    libqalculate
    pipewire
    aubio
    networkmanager
    lm_sensors
    fish
    ddcutil
    brightnessctl
    swappy
    wl-clipboard
    libnotify
    libxml2
    ffmpeg
    power-profiles-daemon
    bash
    hyprland
    ttf-material-symbols-variable
    ttf-cascadia-code-nerd
)

# These packages are currently distributed through the AUR.
readonly -a AUR_DEPENDENCIES=(
    caelestia-cli
    quickshell-git
    libcava
    ttf-rubik-vf
)

readonly -a FORBIDDEN_PACKAGES=(
    caelestia-shell
    caelestia-shell-git
)

SKIP_DEPS=false
CONFIGURE_HYPRLAND=true
WORK_DIR=""

info() {
    printf '[%s] %s\n' "$PROJECT_NAME" "$*"
}

warn() {
    printf '[%s] CẢNH BÁO: %s\n' "$PROJECT_NAME" "$*" >&2
}

die() {
    printf '[%s] LỖI: %s\n' "$PROJECT_NAME" "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Cách dùng: ./install.sh [TÙY CHỌN]

Build và cài Caelestia Shell AW trên Arch Linux/CachyOS.

Tùy chọn:
  --skip-deps      Không cài dependency; chỉ kiểm tra toolchain tối thiểu.
  --no-hyprland    Không tạo snippet và source marker trong Hyprland.
  -h, --help       Hiển thị trợ giúp này.

Biến môi trường tùy chọn:
  CAELESTIA_VERSION  Phiên bản CMake dạng số (mặc định: tag Git hoặc 0.0.0).

Script phải chạy bằng user thường. Quyền root chỉ được yêu cầu cho
pacman và bước promote các tệp đã stage vào hệ thống.
EOF
}

parse_args() {
    while (($# > 0)); do
        case "$1" in
            --skip-deps)
                SKIP_DEPS=true
                ;;
            --no-hyprland)
                CONFIGURE_HYPRLAND=false
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

cleanup() {
    if [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]]; then
        rm -rf -- "$WORK_DIR"
    fi
}

check_not_root() {
    ((EUID != 0)) || die "Không chạy toàn bộ install.sh bằng root hoặc sudo. Hãy chạy bằng user thường."
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

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "Thiếu lệnh bắt buộc: $1"
}

check_forbidden_packages() {
    local package
    for package in "${FORBIDDEN_PACKAGES[@]}"; do
        if pacman -Q "$package" >/dev/null 2>&1; then
            die "Phát hiện package upstream '$package'. Hãy gỡ package này trước để tránh ghi đè fork."
        fi
    done
}

assert_no_forbidden_install_args() {
    local package forbidden
    for package in "$@"; do
        for forbidden in "${FORBIDDEN_PACKAGES[@]}"; do
            [[ "$package" != "$forbidden" ]] || die "Từ chối cài package upstream bị cấm: $package"
        done
    done
}

dependency_is_satisfied() {
    pacman -T "$1" >/dev/null 2>&1
}

collect_missing_dependencies() {
    local output_name="$1"
    shift
    local -n output_ref="$output_name"
    local package
    output_ref=()
    for package in "$@"; do
        if ! dependency_is_satisfied "$package"; then
            output_ref+=("$package")
        fi
    done
}

find_aur_helper() {
    local helper
    for helper in paru yay; do
        if command -v "$helper" >/dev/null 2>&1; then
            printf '%s\n' "$helper"
            return 0
        fi
    done
    return 1
}

install_dependencies() {
    local -a missing_repo=()
    local -a missing_aur=()
    collect_missing_dependencies missing_repo "${REPO_DEPENDENCIES[@]}"
    collect_missing_dependencies missing_aur "${AUR_DEPENDENCIES[@]}"

    if ((${#missing_repo[@]} > 0)); then
        assert_no_forbidden_install_args "${missing_repo[@]}"
        info "Cài dependency từ repository chính thức: ${missing_repo[*]}"
        sudo pacman -S --needed "${missing_repo[@]}"
    else
        info "Các dependency trong repository chính thức đã đầy đủ."
    fi

    if ((${#missing_aur[@]} > 0)); then
        local helper
        helper="$(find_aur_helper)" || die \
            "Thiếu AUR helper (paru/yay) để cài: ${missing_aur[*]}. Cài chúng thủ công hoặc dùng --skip-deps."
        assert_no_forbidden_install_args "${missing_aur[@]}"
        info "Cài dependency AUR bằng $helper: ${missing_aur[*]}"
        "$helper" -S --needed "${missing_aur[@]}"
    else
        info "Các dependency AUR đã đầy đủ."
    fi

    local -a still_missing=()
    collect_missing_dependencies still_missing "${REPO_DEPENDENCIES[@]}" "${AUR_DEPENDENCIES[@]}"
    ((${#still_missing[@]} == 0)) || die "Dependency vẫn còn thiếu: ${still_missing[*]}"
}

check_minimal_toolchain() {
    local command
    for command in git cmake ninja pkg-config; do
        require_command "$command"
    done
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

directory_is_managed_root_or_child() {
    local path="$1"
    local root
    for root in "${INSTALL_ROOTS[@]}"; do
        if [[ "$path" == "$root" || "$path" == "$root/"* ]]; then
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
    path_is_allowed "$path" || die "Manifest muốn cài ngoài phạm vi cho phép: $path"
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

load_owned_paths() {
    local output_name="$1"
    local -n output_ref="$output_name"
    output_ref=()

    local manifest path
    for manifest in "$STATE_MANIFEST" "$STATE_PENDING_MANIFEST"; do
        [[ -f "$manifest" ]] || continue
        while IFS= read -r path || [[ -n "$path" ]]; do
            [[ -n "$path" ]] || continue
            validate_manifest_path "$path"
            output_ref["$path"]=1
        done < "$manifest"
    done
}

detect_version() {
    local version="${CAELESTIA_VERSION:-}"
    if [[ -z "$version" ]]; then
        version="$(git -C "$SCRIPT_DIR" describe --tags --abbrev=0 2>/dev/null || true)"
        version="${version#v}"
    fi
    [[ -n "$version" ]] || version="0.0.0"
    [[ "$version" =~ ^[0-9]+([.][0-9]+){0,3}$ ]] || die \
        "CAELESTIA_VERSION phải là phiên bản dạng số CMake (ví dụ 2.1.0), nhận: $version"
    printf '%s\n' "$version"
}

detect_revision() {
    local revision=""
    revision="$(git -C "$SCRIPT_DIR" rev-parse HEAD 2>/dev/null || true)"
    if [[ -z "$revision" && -r "$SCRIPT_DIR/REVISION" ]]; then
        revision="$(tr -d '\r\n' < "$SCRIPT_DIR/REVISION")"
    fi
    [[ "$revision" =~ ^[0-9a-fA-F]{7,64}$ ]] || die "Không xác định được Git revision hợp lệ."
    printf '%s\n' "$revision"
}

build_and_stage() {
    local build_dir="$1"
    local stage_dir="$2"
    local version="$3"
    local revision="$4"

    info "Configure CMake (VERSION=$version, GIT_REVISION=${revision:0:12})."
    cmake -S "$SCRIPT_DIR" -B "$build_dir" -G Ninja \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCMAKE_INSTALL_PREFIX=/ \
        -DVERSION="$version" \
        -DGIT_REVISION="$revision" \
        -DDISTRIBUTOR="${PROJECT_NAME} installer"

    info "Build project bằng user hiện tại."
    cmake --build "$build_dir"

    info "Stage kết quả cài đặt trong thư mục tạm."
    mkdir -p -- "$stage_dir"
    DESTDIR="$stage_dir" cmake --install "$build_dir"
}

create_stage_manifest() {
    local stage_dir="$1"
    local manifest="$2"
    : > "$manifest"

    local staged_path final_path
    while IFS= read -r -d '' staged_path; do
        final_path="/${staged_path#"$stage_dir"/}"
        validate_manifest_path "$final_path"
        printf '%s\n' "$final_path" >> "$manifest"
    done < <(find "$stage_dir" \( -type f -o -type l \) -print0)

    LC_ALL=C sort -u -o "$manifest" "$manifest"
    [[ -s "$manifest" ]] || die "Stage không tạo ra tệp nào để cài."
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
                [[ ! -L "$parent" ]] || die "Parent path là symlink, từ chối ghi theo symlink: $parent"
                [[ "$parent" != "$root" ]] || break
                parent="$(dirname -- "$parent")"
            done
            return 0
        fi
    done
    die "Path nằm ngoài install roots: $path"
}

check_stage_collisions() {
    local stage_dir="$1"
    local manifest="$2"
    local -n owned_ref="$3"

    local staged_dir final_dir
    local root root_parent
    for root in "${INSTALL_ROOTS[@]}"; do
        root_parent="$(dirname -- "$root")"
        [[ ! -L "$root_parent" ]] || die "Install root parent là symlink, từ chối ghi: $root_parent"
        if [[ -e "$root_parent" && ! -d "$root_parent" ]]; then
            die "Install root parent không phải directory: $root_parent"
        fi
    done

    while IFS= read -r -d '' staged_dir; do
        final_dir="/${staged_dir#"$stage_dir"/}"
        directory_is_managed_root_or_child "$final_dir" || continue
        if [[ -L "$final_dir" || ( -e "$final_dir" && ! -d "$final_dir" ) ]]; then
            die "Directory cần cài xung đột với path hiện có: $final_dir"
        fi
    done < <(find "$stage_dir" -mindepth 1 -type d -print0)

    local path staged_path
    while IFS= read -r path || [[ -n "$path" ]]; do
        [[ -n "$path" ]] || continue
        validate_manifest_path "$path"
        assert_no_symlink_parent "$path"
        staged_path="${stage_dir}${path}"

        if [[ -e "$path" || -L "$path" ]]; then
            if pacman -Qo "$path" >/dev/null 2>&1; then
                die "Tệp đích thuộc một package pacman, từ chối ghi đè: $path"
            fi
            [[ -n "${owned_ref[$path]+x}" ]] || die \
                "Tệp đích đã tồn tại nhưng không do ${PROJECT_NAME} sở hữu: $path"

            if { [[ -L "$staged_path" ]] && [[ ! -L "$path" ]]; } ||
                { [[ ! -L "$staged_path" ]] && [[ -L "$path" ]]; }; then
                die "Kiểu tệp thay đổi giữa các lần cài, hãy uninstall trước: $path"
            fi
            if [[ ! -L "$staged_path" && ! -f "$path" ]]; then
                die "Tệp đích có kiểu không an toàn: $path"
            fi
        fi
    done < "$manifest"
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

remove_stale_owned_paths() {
    local previous_manifest="$1"
    local new_manifest="$2"
    local stale_manifest="$3"
    comm -23 "$previous_manifest" "$new_manifest" > "$stale_manifest"

    local path
    while IFS= read -r path || [[ -n "$path" ]]; do
        [[ -n "$path" ]] || continue
        validate_manifest_path "$path"
        assert_no_symlink_parent "$path"
        if pacman -Qo "$path" >/dev/null 2>&1; then
            warn "Giữ lại stale path vì hiện thuộc package pacman: $path"
            continue
        fi
        if [[ -e "$path" || -L "$path" ]]; then
            if [[ -d "$path" && ! -L "$path" ]]; then
                warn "Không xóa directory xuất hiện trong file manifest: $path"
                continue
            fi
            sudo rm -f -- "$path"
        fi
        prune_empty_parents "$path"
    done < "$stale_manifest"
}

promote_stage() {
    local stage_dir="$1"
    local manifest="$2"
    local previous_manifest="$3"
    local version="$4"
    local revision="$5"
    local stale_manifest="$6"

    sudo install -d -o root -g root -m 0755 -- "$STATE_DIR"
    sudo install -o root -g root -m 0644 -- "$manifest" "$STATE_PENDING_MANIFEST"

    local metadata_tmp="${WORK_DIR}/metadata"
    {
        printf 'project=%s\n' "$PROJECT_NAME"
        printf 'version=%s\n' "$version"
        printf 'revision=%s\n' "$revision"
        printf 'installed_at_utc=%s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
        printf 'installed_uid=%s\n' "$EUID"
    } > "$metadata_tmp"
    sudo install -o root -g root -m 0644 -- "$metadata_tmp" "$STATE_PENDING_METADATA"

    local root staged_root root_parent
    for root in "${INSTALL_ROOTS[@]}"; do
        staged_root="${stage_dir}${root}"
        [[ -e "$staged_root" || -L "$staged_root" ]] || continue
        root_parent="$(dirname -- "$root")"
        if [[ ! -d "$root_parent" ]]; then
            sudo install -d -o root -g root -m 0755 -- "$root_parent"
        fi
        sudo cp -a --no-preserve=ownership -- "$staged_root" "$root_parent/"
    done

    remove_stale_owned_paths "$previous_manifest" "$manifest" "$stale_manifest"

    sudo mv -f -- "$STATE_PENDING_MANIFEST" "$STATE_MANIFEST"
    sudo mv -f -- "$STATE_PENDING_METADATA" "$STATE_METADATA"
    sudo chown root:root -- "$STATE_MANIFEST" "$STATE_METADATA"
    sudo chmod 0644 -- "$STATE_MANIFEST" "$STATE_METADATA"
}

resolve_hypr_main_config() {
    local configured_path="$1"
    if [[ -L "$configured_path" ]]; then
        local resolved
        resolved="$(readlink -f -- "$configured_path")" || die "Hyprland config symlink bị hỏng: $configured_path"
        [[ -n "$resolved" ]] || die "Không resolve được Hyprland config: $configured_path"
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
    [[ "$starts" == "$ends" ]] || die "Source marker Hyprland không cân bằng; không tự động sửa $input"

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
        die "Source marker Hyprland sai thứ tự; không tự động sửa $input"
    fi
}

configure_hyprland() {
    local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    local hypr_dir="${config_home}/hypr"
    local requested_main="${hypr_dir}/hyprland.conf"
    local snippet="${hypr_dir}/${PROJECT_NAME}.conf"

    mkdir -p -- "$hypr_dir"
    [[ ! -L "$snippet" ]] || die "Snippet Hyprland là symlink, từ chối ghi: $snippet"
    if [[ -e "$snippet" ]]; then
        [[ -f "$snippet" ]] || die "Snippet Hyprland không phải regular file: $snippet"
        [[ "$(head -n 1 -- "$snippet")" == "$HYPR_SNIPPET_OWNER" ]] || die \
            "Snippet $snippet đã tồn tại nhưng không do ${PROJECT_NAME} sở hữu."
    fi

    local snippet_tmp
    snippet_tmp="$(mktemp "${hypr_dir}/.${PROJECT_NAME}.snippet.XXXXXX")"
    {
        printf '%s\n' "$HYPR_SNIPPET_OWNER"
        printf '%s\n' "# Autostart Caelestia Shell AW."
        printf '%s\n' "exec-once = caelestia shell -d"
        printf '\n'
        printf '%s\n' "# Keep this order: a window must float before it can be centered."
        printf '# Wayland AppId: %s\n' "$APP_ID"
        printf '%s\n' "windowrule = float true, match:class ^io\\.github\\.conlongnhong\\.caelestia-shell-aw$"
        printf '%s\n' "windowrule = center true, match:class ^io\\.github\\.conlongnhong\\.caelestia-shell-aw$"
    } > "$snippet_tmp"
    chmod 0644 -- "$snippet_tmp"
    mv -f -- "$snippet_tmp" "$snippet"

    local main_config
    main_config="$(resolve_hypr_main_config "$requested_main")"
    if [[ ! -e "$main_config" ]]; then
        warn "Không tìm thấy $requested_main; đã tạo snippet nhưng không tự tạo hyprland.conf rỗng."
        warn "Sau khi có Hyprland config, thêm dòng: source = $snippet"
        info "Đã tạo Hyprland snippet: $snippet"
        return 0
    fi
    [[ -f "$main_config" ]] || die "Hyprland config không phải regular file: $main_config"
    [[ -w "$main_config" ]] || die "Không có quyền ghi Hyprland config: $main_config"

    local main_tmp
    main_tmp="$(mktemp "$(dirname -- "$main_config")/.${PROJECT_NAME}.main.XXXXXX")"
    strip_hypr_source_blocks "$main_config" "$main_tmp"
    if [[ -s "$main_tmp" ]]; then
        printf '\n' >> "$main_tmp"
    fi
    {
        printf '%s\n' "$HYPR_SOURCE_BEGIN"
        printf 'source = %s\n' "$snippet"
        printf '%s\n' "$HYPR_SOURCE_END"
    } >> "$main_tmp"
    chmod --reference="$main_config" "$main_tmp"
    mv -f -- "$main_tmp" "$main_config"

    info "Đã cập nhật Hyprland snippet: $snippet"
    if command -v hyprctl >/dev/null 2>&1 && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        hyprctl reload >/dev/null 2>&1 || warn "Không reload được Hyprland; thay đổi sẽ có hiệu lực ở lần reload sau."
    fi
}

main() {
    parse_args "$@"
    check_not_root
    check_supported_os
    require_command sudo
    check_forbidden_packages
    validate_existing_state

    sudo -v
    if [[ "$SKIP_DEPS" == false ]]; then
        install_dependencies
    else
        warn "Bỏ qua cài dependency theo yêu cầu."
    fi
    check_minimal_toolchain
    check_forbidden_packages

    local version revision
    version="$(detect_version)"
    revision="$(detect_revision)"

    WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/${PROJECT_NAME}.XXXXXX")"
    trap cleanup EXIT INT TERM
    local build_dir="${WORK_DIR}/build"
    local stage_dir="${WORK_DIR}/stage"
    local manifest="${WORK_DIR}/install-manifest"
    local previous_manifest="${WORK_DIR}/previous-manifest"
    local stale_manifest="${WORK_DIR}/stale-manifest"

    build_and_stage "$build_dir" "$stage_dir" "$version" "$revision"
    create_stage_manifest "$stage_dir" "$manifest"

    declare -A owned_paths=()
    load_owned_paths owned_paths
    printf '%s\n' "${!owned_paths[@]}" | sed '/^$/d' | LC_ALL=C sort -u > "$previous_manifest"
    check_stage_collisions "$stage_dir" "$manifest" owned_paths

    info "Promote các tệp đã stage và ghi manifest sở hữu."
    promote_stage "$stage_dir" "$manifest" "$previous_manifest" "$version" "$revision" "$stale_manifest"

    if [[ "$CONFIGURE_HYPRLAND" == true ]]; then
        configure_hyprland
    else
        info "Bỏ qua cấu hình Hyprland theo --no-hyprland."
    fi

    info "Cài đặt hoàn tất. Khởi chạy: caelestia shell -d"
    info "Manifest hệ thống: $STATE_MANIFEST"
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
