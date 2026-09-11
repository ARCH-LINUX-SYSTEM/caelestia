import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property list<MenuItem> overviewStyleItems: [
        MenuItem {
            text: qsTr("Mặc định")
        },
        MenuItem {
            text: "Niri"
        }
    ]
    readonly property list<string> overviewStyleValues: ["default", "niri"]

    function rounded(value: real): real {
        return Math.round(value * 100) / 100;
    }

    function overviewStyleIndex(value: string): int {
        return Math.max(0, overviewStyleValues.indexOf(value));
    }

    title: qsTr("Task View & chụp vùng")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Task View")
        }

        ToggleRow {
            first: true
            text: qsTr("Bật bộ chuyển cửa sổ")
            subtext: qsTr("Áp dụng cho Task View và các phím tắt chuyển cửa sổ của Caelestia")
            checked: GlobalConfig.overview.enabled
            onToggled: GlobalConfig.overview.enabled = checked
        }

        SelectRow {
            enabled: GlobalConfig.overview.enabled
            opacity: enabled ? 1 : 0.55
            label: qsTr("Kiểu bố cục")
            menuItems: root.overviewStyleItems
            active: root.overviewStyleItems[root.overviewStyleIndex(GlobalConfig.overview.style)]
            onSelected: item => GlobalConfig.overview.style = root.overviewStyleValues[root.overviewStyleItems.indexOf(item)]
        }

        StepperRow {
            enabled: GlobalConfig.overview.enabled
            opacity: enabled ? 1 : 0.55
            label: qsTr("Tỷ lệ thẻ cửa sổ")
            value: GlobalConfig.overview.scale
            from: 0.05
            to: 0.5
            stepSize: 0.01
            onMoved: value => GlobalConfig.overview.scale = root.rounded(value)
        }

        StepperRow {
            enabled: GlobalConfig.overview.enabled
            opacity: enabled ? 1 : 0.55
            label: qsTr("Số hàng")
            value: GlobalConfig.overview.rows
            from: 1
            to: 10
            stepSize: 1
            onMoved: value => GlobalConfig.overview.rows = Math.round(value)
        }

        StepperRow {
            enabled: GlobalConfig.overview.enabled
            opacity: enabled ? 1 : 0.55
            label: qsTr("Số cột")
            value: GlobalConfig.overview.columns
            from: 1
            to: 10
            stepSize: 1
            onMoved: value => GlobalConfig.overview.columns = Math.round(value)
        }

        ToggleRow {
            enabled: GlobalConfig.overview.enabled
            opacity: enabled ? 1 : 0.55
            text: qsTr("Sắp xếp từ phải sang trái")
            checked: GlobalConfig.overview.orderRightLeft
            onToggled: GlobalConfig.overview.orderRightLeft = checked
        }

        ToggleRow {
            enabled: GlobalConfig.overview.enabled
            opacity: enabled ? 1 : 0.55
            text: qsTr("Sắp xếp từ dưới lên")
            checked: GlobalConfig.overview.orderBottomUp
            onToggled: GlobalConfig.overview.orderBottomUp = checked
        }

        ToggleRow {
            enabled: GlobalConfig.overview.enabled
            opacity: enabled ? 1 : 0.55
            last: true
            text: qsTr("Căn biểu tượng vào giữa")
            checked: GlobalConfig.overview.centerIcons
            onToggled: GlobalConfig.overview.centerIcons = checked
        }

        SectionHeader {
            text: qsTr("Gợi ý vùng chọn")
        }

        ToggleRow {
            first: true
            text: qsTr("Bám theo cửa sổ")
            subtext: qsTr("Tự chọn đúng khung cửa sổ bên dưới con trỏ")
            checked: GlobalConfig.regionSelector.targetRegions.windows
            onToggled: GlobalConfig.regionSelector.targetRegions.windows = checked
        }

        ToggleRow {
            text: qsTr("Nhận diện lớp shell")
            subtext: qsTr("Được lưu để dùng khi backend layer-region khả dụng")
            checked: GlobalConfig.regionSelector.targetRegions.layers
            onToggled: GlobalConfig.regionSelector.targetRegions.layers = checked
        }

        ToggleRow {
            text: qsTr("Nhận diện vùng nội dung")
            subtext: qsTr("Điều khiển cách làm nổi vùng ảnh đã chọn")
            checked: GlobalConfig.regionSelector.targetRegions.content
            onToggled: GlobalConfig.regionSelector.targetRegions.content = checked
        }

        ToggleRow {
            text: qsTr("Hiển thị nhãn kích thước")
            checked: GlobalConfig.regionSelector.targetRegions.showLabel
            onToggled: GlobalConfig.regionSelector.targetRegions.showLabel = checked
        }

        StepperRow {
            label: qsTr("Độ tối ngoài vùng chọn")
            value: GlobalConfig.regionSelector.targetRegions.opacity
            from: 0
            to: 1
            stepSize: 0.05
            onMoved: value => GlobalConfig.regionSelector.targetRegions.opacity = root.rounded(value)
        }

        StepperRow {
            label: qsTr("Độ rõ vùng nội dung")
            value: GlobalConfig.regionSelector.targetRegions.contentRegionOpacity
            from: 0
            to: 1
            stepSize: 0.05
            onMoved: value => GlobalConfig.regionSelector.targetRegions.contentRegionOpacity = root.rounded(value)
        }

        StepperRow {
            last: true
            label: qsTr("Đệm khi bám vùng")
            subtext: qsTr("Mở rộng vùng chọn quanh cửa sổ, tính bằng pixel")
            value: GlobalConfig.regionSelector.targetRegions.selectionPadding
            from: 0
            to: 100
            stepSize: 1
            onMoved: value => GlobalConfig.regionSelector.targetRegions.selectionPadding = Math.round(value)
        }

        SectionHeader {
            text: qsTr("Hình dạng vùng chọn")
        }

        ToggleRow {
            first: true
            text: qsTr("Hiển thị đường ngắm")
            checked: GlobalConfig.regionSelector.rect.showAimLines
            onToggled: GlobalConfig.regionSelector.rect.showAimLines = checked
        }

        ToggleRow {
            text: qsTr("Dùng vùng tròn khi tìm kiếm ảnh")
            checked: GlobalConfig.search.imageSearch.useCircleSelection
            onToggled: GlobalConfig.search.imageSearch.useCircleSelection = checked
        }

        StepperRow {
            label: qsTr("Độ dày nét tròn")
            value: GlobalConfig.regionSelector.circle.strokeWidth
            from: 1
            to: 20
            stepSize: 1
            onMoved: value => GlobalConfig.regionSelector.circle.strokeWidth = Math.round(value)
        }

        StepperRow {
            last: true
            label: qsTr("Đệm vùng tròn")
            value: GlobalConfig.regionSelector.circle.padding
            from: 0
            to: 100
            stepSize: 1
            onMoved: value => GlobalConfig.regionSelector.circle.padding = Math.round(value)
        }

        SectionHeader {
            text: qsTr("Lưu và chú thích")
        }

        TextFieldRow {
            first: true
            label: qsTr("Thư mục lưu ảnh chụp")
            subtext: qsTr("Để trống nếu chỉ muốn sao chép vào bảng nhớ tạm")
            value: GlobalConfig.paths.screenSnipDir
            placeholder: "~/Pictures/Screenshots"
            leadingIcon: "folder"
            onCommitted: value => GlobalConfig.paths.screenSnipDir = value.trim()
        }

        ToggleRow {
            last: true
            text: qsTr("Ưu tiên Satty để chú thích")
            subtext: qsTr("Tự quay về Swappy nếu Satty chưa được cài")
            checked: GlobalConfig.regionSelector.annotation.useSatty
            onToggled: GlobalConfig.regionSelector.annotation.useSatty = checked
        }
    }
}
