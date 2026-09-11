<a id="dau-trang"></a>

<p align="center">
  <img src="./assets/logo.svg" width="120" alt="Biểu trưng Caelestia Shell AW">
</p>

<h1 align="center">Caelestia Shell AW</h1>

<p align="center">
  <strong>Vỏ desktop hiện đại, giàu hiệu ứng và có khả năng tùy biến cao dành cho Hyprland.</strong>
</p>

<p align="center">
  Được xây dựng bằng Quickshell, Qt 6/QML và C++20; tích hợp thanh tác vụ, trình khởi chạy, bảng điều khiển, thông báo, màn hình khóa, hình nền động và trung tâm cài đặt Nexus trong một giao diện thống nhất.
</p>

<p align="center">
  <a href="https://github.com/conlongnhong/caelestia-shell-aw/commits/main"><img src="https://img.shields.io/github/last-commit/conlongnhong/caelestia-shell-aw?style=for-the-badge&logo=github&label=C%E1%BA%ADp%20nh%E1%BA%ADt&labelColor=1e1e2e&color=89b4fa&cacheSeconds=3600" alt="Lần cập nhật gần nhất"></a>
  <a href="https://github.com/conlongnhong/caelestia-shell-aw/stargazers"><img src="https://img.shields.io/github/stars/conlongnhong/caelestia-shell-aw?style=for-the-badge&logo=github&label=Sao&labelColor=1e1e2e&color=f9e2af&cacheSeconds=3600" alt="Số sao"></a>
  <a href="https://github.com/conlongnhong/caelestia-shell-aw/network/members"><img src="https://img.shields.io/github/forks/conlongnhong/caelestia-shell-aw?style=for-the-badge&logo=github&label=L%C6%B0%E1%BB%A3t%20fork&labelColor=1e1e2e&color=cba6f7&cacheSeconds=3600" alt="Số lượt fork"></a>
  <a href="https://github.com/conlongnhong/caelestia-shell-aw/issues"><img src="https://img.shields.io/github/issues/conlongnhong/caelestia-shell-aw?style=for-the-badge&logo=github&label=V%E1%BA%A5n%20%C4%91%E1%BB%81&labelColor=1e1e2e&color=f38ba8&cacheSeconds=3600" alt="Vấn đề đang mở"></a>
  <a href="https://github.com/conlongnhong/caelestia-shell-aw/blob/main/LICENSE"><img src="https://img.shields.io/github/license/conlongnhong/caelestia-shell-aw?style=for-the-badge&label=Gi%E1%BA%A5y%20ph%C3%A9p&labelColor=1e1e2e&color=a6e3a1&cacheSeconds=3600" alt="Giấy phép"></a>
</p>

<p align="center">
  <a href="https://github.com/conlongnhong/caelestia-shell-aw/actions/workflows/lint.yml"><img src="https://img.shields.io/github/actions/workflow/status/conlongnhong/caelestia-shell-aw/lint.yml?branch=main&style=flat-square&logo=githubactions&logoColor=white&label=Ki%E1%BB%83m%20tra%20m%C3%A3&labelColor=313244&color=a6e3a1" alt="Trạng thái kiểm tra mã"></a>
  <a href="https://github.com/conlongnhong/caelestia-shell-aw/actions/workflows/check-format.yml"><img src="https://img.shields.io/github/actions/workflow/status/conlongnhong/caelestia-shell-aw/check-format.yml?branch=main&style=flat-square&logo=githubactions&logoColor=white&label=%C4%90%E1%BB%8Bnh%20d%E1%BA%A1ng&labelColor=313244&color=94e2d5" alt="Trạng thái kiểm tra định dạng"></a>
  <a href="https://quickshell.outfoxxed.me"><img src="https://img.shields.io/badge/Quickshell-Git-89b4fa?style=flat-square&labelColor=313244" alt="Quickshell Git"></a>
  <a href="https://hyprland.org"><img src="https://img.shields.io/badge/Hyprland-Wayland-cba6f7?style=flat-square&labelColor=313244" alt="Hyprland trên Wayland"></a>
</p>

https://github.com/user-attachments/assets/0840f496-575c-4ca6-83a8-87bb01a85c5f

<p align="center"><em>Video minh họa từ dự án upstream; giao diện thực tế thay đổi theo hình nền, bảng màu, phông chữ và cấu hình của bạn.</em></p>

> [!IMPORTANT]
> Kho mã nguồn này được phát triển dựa trên [Caelestia Shell gốc](https://github.com/caelestia-dots/shell). Để nhận đúng các thay đổi của bản AW, hãy dùng URL `conlongnhong/caelestia-shell-aw` khi cài qua Nix hoặc khi clone thủ công. Các gói AUR `caelestia-shell` và `caelestia-shell-git` thuộc dự án upstream nên có thể không chứa những tùy biến của kho này.

<a id="muc-luc"></a>

## Mục lục

- [Giới thiệu](#gioi-thieu)
- [Tính năng nổi bật](#tinh-nang-noi-bat)
- [Thành phần công nghệ](#thanh-phan-cong-nghe)
- [Yêu cầu hệ thống](#yeu-cau-he-thong)
- [Cài đặt](#cai-dat)
  - [Nix và NixOS](#nix-va-nixos)
  - [Arch Linux và CachyOS](#arch-linux-va-aur)
  - [Cài đặt thủ công](#cai-dat-thu-cong)
- [Khởi chạy và tự khởi động](#khoi-chay-va-tu-khoi-dong)
- [Phím tắt và IPC](#phim-tat-va-ipc)
- [Cấu hình và cá nhân hóa](#cau-hinh-va-ca-nhan-hoa)
- [Cập nhật](#cap-nhat)
- [Gỡ cài đặt](#go-cai-dat)
- [Cấu trúc dự án](#cau-truc-du-an)
- [Khắc phục sự cố](#khac-phuc-su-co)
- [Phát triển và đóng góp](#phat-trien-va-dong-gop)
- [Thống kê dự án](#thong-ke-du-an)
- [Hỗ trợ và cộng đồng](#ho-tro-va-cong-dong)
- [Ghi công](#ghi-cong)
- [Giấy phép](#giay-phep)

<a id="gioi-thieu"></a>

## Giới thiệu

Caelestia Shell AW là một **desktop shell** dành cho Hyprland, không phải trình quản lý cửa sổ hoặc môi trường desktop độc lập. Shell cung cấp lớp giao diện người dùng chạy phía trên Hyprland: thanh tác vụ, trình khởi chạy ứng dụng, bảng điều khiển, trung tâm thông báo, màn hình khóa, OSD, hình nền và nhiều dịch vụ tích hợp.

| Hạng mục | Thông tin |
| --- | --- |
| Nền tảng | Linux, Wayland và Hyprland |
| Giao diện | Quickshell + Qt 6/QML |
| Phần mở rộng | C++20, CMake và Ninja |
| Cấu hình | JSON, cấu hình riêng theo màn hình và Home Manager |
| Đóng gói | Nix Flake, mô-đun Home Manager và CMake |
| Giấy phép | GNU GPL v3 (`GPL-3.0`) |
| Dự án gốc | [`caelestia-dots/shell`](https://github.com/caelestia-dots/shell) |

Nếu đã bật Nix Flakes, bạn có thể chạy thử ngay bản kèm CLI:

```sh
nix run github:conlongnhong/caelestia-shell-aw#with-cli
```

<a id="tinh-nang-noi-bat"></a>

## Tính năng nổi bật

- **Thanh tác vụ linh hoạt:** workspace, cửa sổ đang hoạt động, system tray, đồng hồ, âm thanh, microphone, mạng, Wi-Fi, Bluetooth, pin, trạng thái phím khóa và menu nguồn.
- **Trình khởi chạy đa năng:** tìm ứng dụng, thực thi hành động, tính toán bằng Qalculate, đổi hình nền, bảng màu và biến thể Material 3.
- **Dashboard đầy đủ:** lịch, thời tiết, media/MPRIS, lời bài hát, CPU, GPU, bộ nhớ, lưu trữ, mạng và pin.
- **Nexus:** trung tâm cài đặt cho hình nền, kiểu giao diện, mạng, Bluetooth, âm thanh, ứng dụng, panel, dịch vụ, ngôn ngữ và khu vực.
- **Thông báo và sidebar:** nhóm thông báo, hành động nhanh, chế độ không làm phiền và lịch sử thông báo trực quan.
- **Màn hình khóa và menu phiên:** khóa bằng mật khẩu, hỗ trợ PAM, tùy chọn vân tay/Howdy, đăng xuất, tắt máy, khởi động lại và ngủ đông.
- **Hình nền thông minh:** ảnh, hình nền video, chuyển cảnh mượt, visualiser âm thanh và đồng hồ desktop.
- **Tối ưu hình nền động:** tự tạm dừng video khi dùng pin hoặc khi cửa sổ che phần lớn màn hình; có thể chọn bộ giải mã `auto`, `VAAPI`, `VDPAU`, `CUDA`, `Vulkan`, `DRM` hoặc giải mã phần mềm.
- **Tiện ích tích hợp:** OSD âm lượng/độ sáng, ảnh chụp vùng màn hình, ghi màn hình, VPN, game mode, idle inhibitor, quick toggles và toast.
- **Đa màn hình:** cấu hình riêng theo tên màn hình, workspace theo màn hình và loại trừ panel trên màn hình được chọn.
- **Điều khiển từ bên ngoài:** phím tắt toàn cục của Hyprland và IPC qua `caelestia shell`.

<a id="thanh-phan-cong-nghe"></a>

## Thành phần công nghệ

| Vai trò | Công nghệ |
| --- | --- |
| Khung widget | [Quickshell](https://quickshell.outfoxxed.me) bản Git |
| Compositor / trình quản lý cửa sổ | [Hyprland](https://hyprland.org) |
| UI | Qt 6, QML và Material 3 |
| Plugin và dịch vụ hệ thống | C++20 |
| Hệ thống build | [CMake](https://cmake.org) 3.19+ và [Ninja](https://ninja-build.org) |
| Công cụ dòng lệnh | [Caelestia CLI](https://github.com/caelestia-dots/cli) |
| Âm thanh và visualiser | PipeWire, libcava, aubio và FFTW |
| Hệ thống mạng | NetworkManager và `nmcli` |
| Đóng gói khai báo | Nix Flake và Home Manager |

<a id="yeu-cau-he-thong"></a>

## Yêu cầu hệ thống

> [!NOTE]
> Dự án nhắm đến Linux chạy Wayland/Hyprland. Windows, macOS, X11 và các compositor khác không phải môi trường được hỗ trợ chính thức.

### Thành phần bắt buộc

- Hyprland và một phiên Wayland hoạt động bình thường.
- [`quickshell-git`](https://quickshell.outfoxxed.me); bản Git là yêu cầu quan trọng, bản phát hành cũ có thể thiếu API cần thiết.
- Qt 6.9 trở lên: `qt6-base`, `qt6-declarative`, `qt6-shadertools`, `qt6-imageformats` và `qt6-multimedia`.
- `caelestia-cli` nếu muốn dùng đầy đủ lệnh quản lý shell, hình nền, bảng màu và ghi màn hình.
- NetworkManager, PipeWire, `ddcutil`, `brightnessctl`, `lm-sensors`, `fish`, `bash`, `swappy`, `wl-clipboard`, `libnotify`, FFmpeg, `libxml2`, `power-profiles-daemon` và `libqalculate`.
- `libcava`, `aubio`, FFTW, `xkeyboard-config` và các thư viện C/C++ tiêu chuẩn để build plugin.
- Phông Material Symbols, Rubik và Caskaydia Cove Nerd Font để biểu tượng và bố cục hiển thị đúng.

### Thành phần chỉ cần khi build

- Git.
- CMake 3.19 trở lên.
- Ninja.
- Trình biên dịch hỗ trợ C++20, chẳng hạn GCC hoặc Clang.
- `pkg-config`/`pkgconf`.

### Thành phần tùy chọn

- `gpu-screen-recorder` để dùng tính năng ghi màn hình.
- `fprintd` hoặc Howdy nếu bật xác thực sinh trắc học.
- Một dịch vụ VPN tương thích với cấu hình của bạn.

<a id="cai-dat"></a>

## Cài đặt

Trước khi cài, nên sao lưu cấu hình Caelestia hiện có:

```sh
cp -a ~/.config/caelestia ~/.config/caelestia.backup
```

Nếu thư mục chưa tồn tại, bạn có thể bỏ qua bước sao lưu.

<a id="nix-va-nixos"></a>

### Nix và NixOS

Đây là cách gọn nhất để chạy đúng phiên bản trong kho AW.

#### Chạy trực tiếp

```sh
# Bản mặc định
nix run github:conlongnhong/caelestia-shell-aw

# Khuyến nghị: kèm Caelestia CLI để có đầy đủ chức năng
nix run github:conlongnhong/caelestia-shell-aw#with-cli
```

#### Thêm vào flake của hệ thống

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    caelestia-shell-aw = {
      url = "github:conlongnhong/caelestia-shell-aw";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

Sau đó thêm gói phù hợp vào cấu hình:

```nix
{ inputs, pkgs, ... }:
{
  environment.systemPackages = [
    inputs.caelestia-shell-aw.packages.${pkgs.system}.with-cli
  ];
}
```

Các đầu ra gói hiện có:

| Đầu ra | Mục đích |
| --- | --- |
| `default` / `caelestia-shell` | Shell mặc định, không kèm CLI |
| `with-cli` | Shell kèm CLI, phù hợp với hầu hết người dùng |
| `debug` | Bản build phục vụ gỡ lỗi |

#### Home Manager

Import mô-đun từ flake rồi cấu hình `programs.caelestia`:

```nix
{ inputs, ... }:
{
  imports = [
    inputs.caelestia-shell-aw.homeManagerModules.default
  ];

  programs.caelestia = {
    enable = true;

    systemd = {
      enable = true;
      target = "graphical-session.target";
      environment = [ ];
    };

    settings = {
      bar.status.showBattery = true;
      paths.wallpaperDir = "~/Pictures/Wallpapers";
    };

    cli = {
      enable = true;
      settings.theme.enableGtk = false;
    };
  };
}
```

Mô-đun có thể tạo `~/.config/caelestia/shell.json`, cài shell/CLI và khởi động shell bằng user service của systemd.

<a id="arch-linux-va-aur"></a>

### Arch Linux và CachyOS

Cách được hỗ trợ cho bản AW là clone đúng fork này và chạy installer bằng user thường:

```sh
git clone https://github.com/conlongnhong/caelestia-shell-aw.git
cd caelestia-shell-aw
./install.sh
```

Installer cài các dependency còn thiếu bằng `pacman` và `paru`/`yay`, build trong thư mục tạm, kiểm tra xung đột với package upstream, stage kết quả trước khi đưa vào hệ thống và ghi manifest để gỡ cài đặt an toàn. Quyền `sudo` chỉ được yêu cầu cho package và tệp hệ thống.

Các tùy chọn thường dùng:

```sh
./install.sh --help
./install.sh --skip-deps    # Dependency đã được cài đầy đủ
./install.sh --no-hyprland  # Không tạo đoạn cấu hình Hyprland do fork quản lý
```

> [!WARNING]
> Không cài đồng thời `caelestia-shell` hoặc `caelestia-shell-git` từ AUR. Hai package đó thuộc upstream và ghi vào cùng đường dẫn hệ thống; installer AW sẽ chủ động từ chối nếu phát hiện xung đột.

Installer tự động hiện chỉ hỗ trợ Arch Linux và CachyOS. Các distro khác có thể dùng Nix hoặc quy trình thủ công ở phần tiếp theo.

<a id="cai-dat-thu-cong"></a>

### Cài đặt thủ công

1. Cài các phụ thuộc ở phần [Yêu cầu hệ thống](#yeu-cau-he-thong).
2. Clone kho mã nguồn này.
3. Build plugin, thư viện và QML bằng CMake/Ninja.

```sh
mkdir -p "$HOME/src"
git clone https://github.com/conlongnhong/caelestia-shell-aw.git "$HOME/src/caelestia-shell-aw"
cd "$HOME/src/caelestia-shell-aw"

cmake -S . -B build -G Ninja \
  -DVERSION=1.0.0 \
  -DGIT_REVISION="$(git rev-parse HEAD)" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/

cmake --build build --parallel
sudo cmake --install build
```

> [!NOTE]
> Kho hiện chưa phát hành tag phiên bản, trong khi CMake tự tìm phiên bản bằng `git describe`. Vì vậy lệnh trên truyền rõ `-DVERSION=1.0.0` để bước configure không dừng lại. Khi kho đã có tag `v*`, bạn có thể bỏ cờ này.

Trong lần configure đầu tiên, CMake tải mô-đun `m3shapes`; máy cần kết nối mạng. Mặc định, các thành phần được cài vào:

| Biến CMake | Giá trị mặc định | Nội dung |
| --- | --- | --- |
| `INSTALL_LIBDIR` | `usr/lib/caelestia` | Thư viện phụ trợ |
| `INSTALL_QMLDIR` | `usr/lib/qt6/qml` | Plugin QML |
| `INSTALL_QSCONFDIR` | `etc/xdg/quickshell/caelestia` | Cấu hình Quickshell |

Bạn có thể đổi vị trí bằng cờ CMake. Ví dụ, đặt phần cấu hình QML trong thư mục người dùng để tiện sửa trực tiếp:

```sh
CONFIG_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}"

cmake -S . -B build -G Ninja \
  -DVERSION=1.0.0 \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/ \
  -DINSTALL_QSCONFDIR="$CONFIG_ROOT/quickshell/caelestia"

cmake --build build --parallel
sudo cmake --install build
sudo chown -R "$USER":"$(id -gn)" "$CONFIG_ROOT/quickshell/caelestia"
```

Nếu đổi `INSTALL_LIBDIR`, hãy đặt biến môi trường `CAELESTIA_LIB_DIR` về đúng thư mục thư viện trước khi khởi chạy shell.

<a id="khoi-chay-va-tu-khoi-dong"></a>

## Khởi chạy và tự khởi động

Chọn **một** trong các cách sau:

```sh
# Khi đã cài Caelestia CLI
caelestia shell -d

# Chạy trực tiếp bằng Quickshell
qs -c caelestia

# Tên executable của gói Nix
caelestia-shell
```

Không nên chạy đồng thời nhiều lệnh trên vì có thể tạo nhiều phiên shell chồng lên nhau.

Để dừng phiên do CLI quản lý:

```sh
caelestia shell -k
```

Nếu dùng toàn bộ Caelestia Dots, shell thường đã được tự khởi động. Nếu tự cấu hình Hyprland, thêm một dòng vào cấu hình của bạn:

```conf
exec-once = caelestia shell -d

# FloatingWindow của fork: luật float phải đứng trước luật center.
windowrule = float true, match:class ^io\.github\.conlongnhong\.caelestia-shell-aw$
windowrule = center true, match:class ^io\.github\.conlongnhong\.caelestia-shell-aw$
```

Người dùng Home Manager đã bật `programs.caelestia.systemd.enable` không cần thêm `exec-once`. Có thể theo dõi service bằng:

```sh
systemctl --user status caelestia
journalctl --user -u caelestia -f
```

<a id="phim-tat-va-ipc"></a>

## Phím tắt và IPC

### Phím tắt toàn cục của Hyprland

Shell đăng ký các global shortcut dưới namespace `caelestia`. Ví dụ:

```conf
bind = SUPER, SPACE, global, caelestia:launcher
bind = SUPER, N, global, caelestia:nexus
bind = SUPER, D, global, caelestia:dashboard
bind = SUPER, A, global, caelestia:sidebar
bind = SUPER, X, global, caelestia:session
bind = SUPER, L, global, caelestia:lock

bind = , XF86AudioPlay, global, caelestia:mediaToggle
bind = , XF86AudioNext, global, caelestia:mediaNext
bind = , XF86AudioPrev, global, caelestia:mediaPrev
bind = , XF86MonBrightnessUp, global, caelestia:brightnessUp
bind = , XF86MonBrightnessDown, global, caelestia:brightnessDown
```

Các shortcut chính:

| Tên | Chức năng |
| --- | --- |
| `launcher` | Mở/đóng trình khởi chạy |
| `nexus` | Mở trung tâm cài đặt Nexus |
| `dashboard` | Mở/đóng dashboard |
| `sidebar` | Mở/đóng sidebar và thông báo |
| `utilities` | Mở/đóng bảng tiện ích |
| `session` | Mở/đóng menu phiên |
| `showall` | Chuyển trạng thái launcher, dashboard, OSD và tiện ích |
| `lock` / `unlock` | Khóa hoặc mở khóa phiên |
| `screenshot*` | Mở công cụ chụp vùng với chế độ thường, freeze hoặc clipboard |
| `mediaToggle`, `mediaPrev`, `mediaNext`, `mediaStop` | Điều khiển trình phát MPRIS |
| `brightnessUp`, `brightnessDown` | Tăng hoặc giảm độ sáng |
| `clearNotifs` | Xóa toàn bộ thông báo |

### IPC qua Caelestia CLI

Liệt kê toàn bộ target và hàm IPC đang có:

```sh
caelestia shell -s
```

Một số ví dụ:

```sh
# Mở/đóng hoặc liệt kê drawer
caelestia shell drawers toggle launcher
caelestia shell drawers list

# Mở Nexus
caelestia shell nexus open

# Điều khiển media
caelestia shell mpris playPause
caelestia shell mpris next
caelestia shell mpris getActive trackTitle

# Hình nền
caelestia shell wallpaper get
caelestia shell wallpaper set "$HOME/Pictures/Wallpapers/example.jpg"

# Thông báo và màn hình khóa
caelestia shell notifs clear
caelestia shell lock lock
caelestia shell lock isLocked
```

Tên target, hàm và tham số có thể thay đổi giữa các phiên bản; kết quả của `caelestia shell -s` là nguồn tham chiếu chính xác nhất cho bản đang chạy.

<a id="cau-hinh-va-ca-nhan-hoa"></a>

## Cấu hình và cá nhân hóa

### Tệp cấu hình toàn cục

Cấu hình chính nằm tại:

```text
~/.config/caelestia/shell.json
```

Tệp này không nhất thiết được tạo sẵn. Bạn chỉ cần khai báo những khóa muốn thay đổi; khóa bị lược bỏ sẽ dùng giá trị mặc định.

Ví dụ cấu hình gọn:

```json
{
  "appearance": {
    "transparency": {
      "enabled": true,
      "base": 0.85,
      "layers": 0.4
    }
  },
  "bar": {
    "persistent": true,
    "showOnHover": true,
    "status": {
      "showNetwork": true,
      "showBluetooth": true,
      "showBattery": true
    }
  },
  "dashboard": {
    "showWeather": true,
    "showPerformance": true
  },
  "general": {
    "battery": {
      "autoHibernate": true,
      "criticalLevel": 3,
      "hibernateDelay": 5
    }
  },
  "services": {
    "audioProtection": {
      "enabled": false,
      "maxIncrease": 0.1
    },
    "weatherLocation": "Ha Noi",
    "useFahrenheit": false,
    "useTwelveHourClock": false
  },
  "paths": {
    "wallpaperDir": "~/Pictures/Wallpapers",
    "lyricsDir": "~/Music/lyrics"
  }
}
```

Các nhóm cấu hình thường dùng:

| Nhóm | Nội dung |
| --- | --- |
| `appearance` | Tỷ lệ giao diện, bo góc, khoảng cách, phông chữ, animation và độ trong suốt |
| `general` | Ứng dụng mặc định, idle, pin, logo và hành vi toàn cục |
| `background` | Hình nền, đồng hồ desktop và visualiser |
| `bar` | Thành phần thanh tác vụ, workspace, tray, trạng thái và màn hình loại trừ |
| `dashboard` | Media, thời tiết và thống kê tài nguyên |
| `launcher` | Ứng dụng ưa thích/ẩn, prefix, fuzzy search và hành động |
| `lock` | Màn hình khóa, vân tay và Howdy |
| `notifs` | Thời gian hết hạn, hành vi click và nhóm thông báo |
| `services` | Thời tiết, đơn vị, GPU, media, âm lượng, độ sáng và lời bài hát |
| `utilities` | Toast, VPN và quick toggles |
| `paths` | Thư mục hình nền, lời bài hát và tài nguyên tùy chỉnh |

Các tùy chọn đáng chú ý:

- `services.audioProtection.enabled` chặn mức tăng âm lượng đầu ra bất thường từ ứng dụng bên ngoài. `maxIncrease` dùng tỷ lệ từ `0.0` đến `1.0`; giới hạn tuyệt đối vẫn là `services.maxVolume`.
- `general.battery.autoHibernate` cho phép tắt hành vi ngủ đông tự động. `criticalLevel` là phần trăm pin và `hibernateDelay` là số giây đếm ngược.
- `bar.entries` điều khiển thứ tự và trạng thái bật/tắt của các thành phần bar. Nexus giữ nguyên cả entry không nhận diện được khi sắp xếp.
- `utilities.quickToggles` điều khiển thứ tự và trạng thái các nút bật/tắt nhanh.

### Cấu hình theo màn hình

Tạo tệp theo tên màn hình:

```text
~/.config/caelestia/monitors/<ten-man-hinh>/shell.json
```

Ví dụ tắt bar cố định trên `DP-1`:

```json
{
  "bar": {
    "persistent": false
  }
}
```

Giá trị trong tệp theo màn hình sẽ ghi đè cấu hình toàn cục khi tùy chọn đó hỗ trợ override. Một số thiết lập dịch vụ, đường dẫn, launcher, lock và hành vi toàn hệ thống chỉ đọc từ cấu hình toàn cục.

<details>
<summary>Các nhóm chỉ đọc từ cấu hình toàn cục</summary>

- `appearance`: animation và transparency.
- `general`: logo, ứng dụng mặc định, idle và pin.
- `bar.workspaces`: `perMonitorWorkspaces`, `specialWorkspaceIcons`, `windowIcons`; `bar.tray`: `iconSubs`, `hiddenIcons`.
- `dashboard`: chu kỳ cập nhật media và tài nguyên.
- `launcher`: prefix, fuzzy search, danh sách ứng dụng và action.
- `notifs`: timeout, chế độ fullscreen và action khi click.
- `lock`: vân tay và Howdy.
- `nexus.networkRescanInterval`.
- `utilities.toasts` và `utilities.vpn`, ngoại trừ các thuộc tính được khai báo per-monitor.
- `services`: thời tiết/đơn vị, GPU, tạm dừng và decoder wallpaper, audio/brightness, player và lyrics.
- `paths`: thư mục wallpaper và lyrics.

Nếu đặt các khóa này trong `monitors/<ten-man-hinh>/shell.json`, shell sẽ bỏ qua và ghi cảnh báo `global-only` vào log.

</details>

### Nexus

Mở trung tâm cài đặt bằng phím tắt `caelestia:nexus` hoặc lệnh:

```sh
caelestia shell nexus open
```

Trong trang **Wallpaper & style**, bạn có thể chọn hình nền, phông chữ, bảng màu, bộ giải mã video và hai chế độ tiết kiệm tài nguyên:

- Tạm dừng hình nền động khi dùng pin.
- Tạm dừng hình nền động khi bị cửa sổ che.

Các trang cấu hình mở rộng trong Nexus:

- **Wallpaper & style → Tinh chỉnh giao diện:** tỷ lệ bo góc, khoảng cách, phần đệm, phông chữ, animation, độ trong suốt và viền shell.
- **Wallpaper & style → Desktop & hiệu ứng nền:** desktop clock, visualiser, thư mục hình nền và số ảnh mỗi hàng.
- **Panels → Taskbar → Bố cục:** bật/tắt, sắp xếp entry và loại trừ bar theo màn hình.
- **Panels → Sidebar → Bật/tắt nhanh:** bật/tắt và sắp xếp quick toggles.
- **Hành vi shell:** pin, màn hình khóa, OSD và hành vi toàn màn hình.
- **Services:** bảo vệ tăng âm lượng đột ngột.

### Ảnh đại diện và hình nền

- Ảnh đại diện dashboard được đọc từ `~/.face`.
- Thư mục hình nền mặc định là `~/Pictures/Wallpapers`.
- Hình nền động được đọc từ thư mục con `~/Pictures/Wallpapers/Animated` và hỗ trợ các tệp video phổ biến như MP4, WebM và MKV.
- Có thể đổi thư mục bằng `paths.wallpaperDir`.

Nếu thumbnail của hình nền động chưa xuất hiện, yêu cầu CLI tạo lại ảnh xem trước:

```sh
caelestia wallpaper --extract-thumbs
```

Trong launcher, dùng `Ctrl+Tab` để chuyển nhanh giữa danh sách hình nền tĩnh và hình nền động.

Đổi hình nền và tạo bảng màu động:

```sh
caelestia wallpaper -f "$HOME/Pictures/Wallpapers/example.jpg"
caelestia scheme set -n dynamic
```

Xem đầy đủ tùy chọn của CLI:

```sh
caelestia wallpaper -h
caelestia scheme -h
```

### Token nâng cao

Các token nội bộ nằm trong:

```text
~/.config/caelestia/shell-tokens.json
~/.config/caelestia/monitors/<ten-man-hinh>/shell-tokens.json
```

> [!WARNING]
> Token điều khiển kích thước, khoảng cách, bo góc, phông chữ, thời lượng animation và easing curve. Chỉ chỉnh khi bạn hiểu rõ tác động; tên và cấu trúc token có thể thay đổi mà không giữ tương thích giữa các phiên bản.

<a id="cap-nhat"></a>

## Cập nhật

### Nix Flake

Trong flake của hệ thống:

```sh
nix flake update caelestia-shell-aw
sudo nixos-rebuild switch --flake .
```

Nếu dùng Home Manager độc lập, thay lệnh rebuild bằng lệnh Home Manager phù hợp với cấu hình của bạn.

### Cài bằng installer trên Arch Linux/CachyOS

```sh
cd "$HOME/src/caelestia-shell-aw"
git pull --ff-only
./install.sh --skip-deps
```

### Cài thủ công bằng CMake

Sau khi pull, nên build lại vì thay đổi có thể nằm trong plugin C++ chứ không chỉ ở QML:

```sh
cd "$HOME/src/caelestia-shell-aw"
git pull --ff-only

cmake -S . -B build -G Ninja \
  -DVERSION=1.0.0 \
  -DGIT_REVISION="$(git rev-parse HEAD)" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/

cmake --build build --parallel
sudo cmake --install build
caelestia shell -d
```

Không dùng package AUR upstream để cập nhật bản AW.

<a id="go-cai-dat"></a>

## Gỡ cài đặt

Chạy uninstaller từ chính clone đã dùng để cài:

```sh
./uninstall.sh
```

Script chỉ xóa các đường dẫn có trong manifest và đoạn Hyprland do fork quản lý. Dependency, `~/.config/caelestia`, hình nền và cấu hình Hyprland không liên quan sẽ được giữ nguyên. Dùng `./uninstall.sh --no-hyprland` nếu muốn giữ cả đoạn tích hợp Hyprland.

<a id="cau-truc-du-an"></a>

## Cấu trúc dự án

```text
.
├── assets/                 # Biểu trưng, hình ảnh, phông chữ và tệp PAM
├── components/             # Thành phần QML dùng lại
├── extras/                 # Thư viện phụ trợ native
├── modules/                # Bar, dashboard, launcher, lock, Nexus...
├── nix/                    # Gói Nix và mô-đun Home Manager
├── plugin/                 # Plugin C++/QML Caelestia
├── scripts/                # Công cụ kiểm tra quy ước QML
├── services/               # Audio, mạng, hình nền, media, thông báo...
├── utils/                  # Tiện ích QML và thuật toán tìm kiếm
├── shell.qml               # Điểm vào chính của Quickshell
├── CMakeLists.txt          # Cấu hình build CMake
├── flake.nix               # Đầu vào/đầu ra Nix Flake
└── LICENSE                 # GNU GPL v3
```

<a id="khac-phuc-su-co"></a>

## Khắc phục sự cố

### `caelestia: command not found`

Cài `caelestia-cli` hoặc dùng gói Nix `#with-cli`. Nếu chỉ muốn chạy shell mà không có CLI, thử:

```sh
qs -c caelestia
```

### Shell không khởi động

Chạy foreground để xem lỗi trực tiếp:

```sh
qs -c caelestia
```

Kiểm tra các điểm sau:

- Đang chạy phiên Hyprland/Wayland.
- Đã cài đúng `quickshell-git`.
- Plugin QML nằm trong đường dẫn Qt có thể tìm thấy.
- `CAELESTIA_LIB_DIR` đúng nếu bạn đổi vị trí cài thư viện.
- Không có một phiên Caelestia khác đang chạy.

### Màn hình nhấp nháy

Thử tắt VRR trong cấu hình Hyprland:

```conf
misc {
    vrr = 0
}
```

Nếu cài toàn bộ Caelestia Dots, có thể đặt tùy chỉnh trong `~/.config/caelestia/hypr-user.conf`; nếu không, dùng tệp cấu hình Hyprland của bạn.

### Hình nền không xuất hiện trong launcher

- Kiểm tra `paths.wallpaperDir`.
- Đảm bảo thư mục tồn tại và người dùng có quyền đọc.
- Thử đặt trực tiếp một tệp bằng `caelestia wallpaper -f <duong-dan>`.
- Khởi động lại shell sau khi thay đổi đường dẫn.

### Hình nền video dùng nhiều CPU/GPU

Mở **Nexus → Wallpaper & style**, bật tạm dừng khi dùng pin hoặc khi bị cửa sổ che, sau đó chọn bộ giải mã phần cứng phù hợp với GPU. Nếu driver không hỗ trợ, chọn `Software` để tránh lỗi phát video.

### Thời tiết trống hoặc sai đơn vị

Đặt `services.weatherLocation`, `services.useFahrenheit` và `services.useTwelveHourClock` trong `shell.json`, hoặc chỉnh tại **Nexus → Language & region**.

### Cấu hình theo màn hình không có tác dụng

Lấy đúng tên màn hình bằng:

```sh
hyprctl monitors
```

Đặt tệp vào `~/.config/caelestia/monitors/<ten-man-hinh>/shell.json`. Nếu khóa vẫn không đổi, khóa đó có thể chỉ hỗ trợ cấu hình toàn cục.

### Wi-Fi, Bluetooth hoặc âm thanh không hiển thị

Kiểm tra NetworkManager, Bluetooth và PipeWire đã chạy; đồng thời xác nhận người dùng có quyền truy cập thiết bị tương ứng. Ví dụ:

```sh
systemctl status NetworkManager
systemctl --user status pipewire
```

<a id="phat-trien-va-dong-gop"></a>

## Phát triển và đóng góp

Đọc [hướng dẫn đóng góp](./.github/CONTRIBUTING.md) trước khi mở pull request. Quy trình gợi ý:

```sh
git clone https://github.com/conlongnhong/caelestia-shell-aw.git
cd caelestia-shell-aw
git switch -c ten-nhanh-cua-ban

cmake -S . -B build -G Ninja -DVERSION=1.0.0 -DCMAKE_BUILD_TYPE=Debug
cmake --build build --parallel
python3 scripts/qml-lint-conventions.py
```

Khi đóng góp:

- Giữ phong cách QML/C++ nhất quán với mã hiện có.
- Chạy formatter và lint trước khi gửi pull request.
- Kiểm thử thay đổi trong một phiên Hyprland thật.
- Mô tả rõ chức năng, cách kiểm thử, tác dụng phụ và thay đổi phá vỡ tương thích.
- Dùng thông điệp commit dạng `module: change`, theo quy ước của dự án.

Bạn có thể dùng các mẫu sẵn có để [báo lỗi](https://github.com/conlongnhong/caelestia-shell-aw/issues/new/choose) hoặc đề xuất tính năng.

<a id="thong-ke-du-an"></a>

## Thống kê dự án

<p align="center">
  <a href="https://github.com/conlongnhong/caelestia-shell-aw"><img src="https://img.shields.io/github/repo-size/conlongnhong/caelestia-shell-aw?style=for-the-badge&logo=github&label=Dung%20l%C6%B0%E1%BB%A3ng&labelColor=1e1e2e&color=94e2d5&cacheSeconds=3600" alt="Dung lượng kho mã nguồn"></a>
  <a href="https://github.com/conlongnhong/caelestia-shell-aw"><img src="https://img.shields.io/github/languages/code-size/conlongnhong/caelestia-shell-aw?style=for-the-badge&logo=github&label=K%C3%ADch%20th%C6%B0%E1%BB%9Bc%20m%C3%A3&labelColor=1e1e2e&color=89dceb&cacheSeconds=3600" alt="Kích thước mã nguồn"></a>
  <a href="https://github.com/conlongnhong/caelestia-shell-aw/graphs/contributors"><img src="https://img.shields.io/github/contributors/conlongnhong/caelestia-shell-aw?style=for-the-badge&logo=github&label=%C4%90%C3%B3ng%20g%C3%B3p&labelColor=1e1e2e&color=a6e3a1&cacheSeconds=3600" alt="Số người đóng góp"></a>
</p>

<p align="center">
  <a href="https://github.com/conlongnhong/caelestia-shell-aw"><img src="https://img.shields.io/github/languages/top/conlongnhong/caelestia-shell-aw?style=flat-square&logo=qt&label=Ng%C3%B4n%20ng%E1%BB%AF%20ch%C3%ADnh&labelColor=313244&color=cba6f7&cacheSeconds=3600" alt="Ngôn ngữ chính"></a>
  <a href="https://github.com/conlongnhong/caelestia-shell-aw"><img src="https://img.shields.io/github/languages/count/conlongnhong/caelestia-shell-aw?style=flat-square&logo=github&label=S%E1%BB%91%20ng%C3%B4n%20ng%E1%BB%AF&labelColor=313244&color=f5c2e7&cacheSeconds=3600" alt="Số ngôn ngữ"></a>
  <a href="https://github.com/conlongnhong/caelestia-shell-aw/commits/main"><img src="https://img.shields.io/github/commit-activity/m/conlongnhong/caelestia-shell-aw?style=flat-square&logo=git&label=Commit%20m%E1%BB%97i%20th%C3%A1ng&labelColor=313244&color=fab387&cacheSeconds=3600" alt="Số commit mỗi tháng"></a>
  <a href="https://github.com/conlongnhong/caelestia-shell-aw/pulls"><img src="https://img.shields.io/github/issues-pr/conlongnhong/caelestia-shell-aw?style=flat-square&logo=github&label=Pull%20request&labelColor=313244&color=89b4fa&cacheSeconds=3600" alt="Pull request đang mở"></a>
</p>

<p align="center">
  <a href="https://www.star-history.com/#conlongnhong/caelestia-shell-aw&Date">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=conlongnhong/caelestia-shell-aw&type=Date&theme=dark">
      <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=conlongnhong/caelestia-shell-aw&type=Date">
      <img alt="Biểu đồ lịch sử số sao của Caelestia Shell AW" src="https://api.star-history.com/svg?repos=conlongnhong/caelestia-shell-aw&type=Date">
    </picture>
  </a>
</p>

<p align="center"><sub>Các số liệu được tải động từ GitHub qua Shields.io và Star History nên có thể tạm thời không hiển thị khi dịch vụ bên thứ ba bị giới hạn.</sub></p>

<a id="ho-tro-va-cong-dong"></a>

## Hỗ trợ và cộng đồng

- Lỗi hoặc đề xuất riêng cho bản AW: [GitHub Issues](https://github.com/conlongnhong/caelestia-shell-aw/issues).
- Mã nguồn và tài liệu upstream: [`caelestia-dots/shell`](https://github.com/caelestia-dots/shell).
- Cộng đồng Caelestia trên Discord: [discord.gg/BGDCFCmMBk](https://discord.gg/BGDCFCmMBk).
- Ủng hộ tác giả upstream: [Ko-fi của soramane](https://ko-fi.com/soramane).

Khi báo lỗi, hãy gửi kèm distro, phiên bản Hyprland/Quickshell/Qt, cách cài đặt, log liên quan và các bước tái hiện.

<a id="ghi-cong"></a>

## Ghi công

- [Caelestia Dots](https://github.com/caelestia-dots) và các tác giả/đóng góp viên của [Caelestia Shell](https://github.com/caelestia-dots/shell) đã xây dựng nền tảng ban đầu.
- [@outfoxxed](https://github.com/outfoxxed) đã phát triển Quickshell và hỗ trợ nhiều yêu cầu kỹ thuật của cộng đồng.
- [@end-4](https://github.com/end-4) cùng dự án [dots-hyprland](https://github.com/end-4/dots-hyprland) là nguồn tham khảo quan trọng cho việc học và phát triển Quickshell.
- [Axenide/Ax-Shell](https://github.com/Axenide/Ax-Shell) là một trong những nguồn cảm hứng về giao diện.
- Cộng đồng Hyprland, đặc biệt các thành viên thảo luận về rice và desktop shell, đã đóng góp nhiều ý tưởng và phản hồi.
- Cảm ơn mọi người đã báo lỗi, gửi pull request, viết tài liệu và chia sẻ cấu hình.

<a id="giay-phep"></a>

## Giấy phép

Dự án được phân phối theo **GNU General Public License v3**. Bạn có thể sử dụng, nghiên cứu, sửa đổi và phân phối lại mã nguồn theo các điều khoản trong tệp [LICENSE](./LICENSE).

<p align="center">
  <a href="#dau-trang">Về đầu trang</a>
</p>
