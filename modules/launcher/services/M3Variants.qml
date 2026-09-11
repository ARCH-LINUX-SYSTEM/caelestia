pragma Singleton

import ".."
import QtQuick
import Quickshell
import Caelestia.Config
import qs.utils

Searcher {
    id: root

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}variant `.length);
    }

    list: [
        Variant {
            variant: "vibrant"
            icon: "sentiment_very_dissatisfied"
            name: qsTr("Sống động")
            description: qsTr("Bảng màu có độ rực cao. Độ rực của bảng màu chính ở mức tối đa.")
        },
        Variant {
            variant: "tonalspot"
            icon: "android"
            name: qsTr("Điểm tông màu")
            description: qsTr("Mặc định cho màu chủ đề Material. Bảng màu pastel có độ rực thấp.")
        },
        Variant {
            variant: "expressive"
            icon: "compare_arrows"
            name: qsTr("Biểu cảm")
            description: qsTr("Bảng màu có độ rực trung bình. Sắc màu của bảng màu chính khác màu gốc để tạo sự đa dạng.")
        },
        Variant {
            variant: "fidelity"
            icon: "compare"
            name: qsTr("Trung thực")
            description: qsTr("Khớp với màu gốc, kể cả khi màu gốc rất rực (độ rực cao).")
        },
        Variant {
            variant: "content"
            icon: "sentiment_calm"
            name: qsTr("Nội dung")
            description: qsTr("Gần như giống chế độ Trung thực.")
        },
        Variant {
            variant: "fruitsalad"
            icon: "nutrition"
            name: qsTr("Salad trái cây")
            description: qsTr("Chủ đề vui mắt — sắc màu gốc không xuất hiện trong chủ đề.")
        },
        Variant {
            variant: "rainbow"
            icon: "looks"
            name: qsTr("Cầu vồng")
            description: qsTr("Chủ đề vui mắt — sắc màu gốc không xuất hiện trong chủ đề.")
        },
        Variant {
            variant: "neutral"
            icon: "contrast"
            name: qsTr("Trung tính")
            description: qsTr("Gần với thang xám, chỉ phảng phất màu sắc.")
        },
        Variant {
            variant: "monochrome"
            icon: "filter_b_and_w"
            name: qsTr("Đơn sắc")
            description: qsTr("Tất cả màu đều ở dạng thang xám, không có sắc màu.")
        }
    ]
    useFuzzy: GlobalConfig.launcher.useFuzzy.variants

    component Variant: QtObject {
        required property string variant
        required property string icon
        required property string name
        required property string description

        function onClicked(list: AppList): void {
            list.screenState.launcher = false;
            Quickshell.execDetached(["caelestia", "scheme", "set", "-v", variant]);
        }
    }
}
