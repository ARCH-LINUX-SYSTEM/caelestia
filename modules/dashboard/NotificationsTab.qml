import QtQuick
import qs.components
import qs.modules.sidebar

Item {
    id: root

    required property ScreenState screenState

    // Own Props/reloadableId (distinct from the sidebar's) so this tab's expanded-notif
    // state doesn't collide with the sidebar's persisted state.
    // `var`, not `Props`: qmllint treats the type reached via this cross-directory
    // `import qs.modules.sidebar` as nominally distinct from the one NotifDock.qml
    // resolves via its own directory's implicit import, and flags a false
    // incompatible-type on `props: root.props` below otherwise.
    readonly property var props: Props {
        reloadableId: "dashboardNotifs"
    }

    implicitWidth: 760
    implicitHeight: 480

    NotifDock {
        anchors.fill: parent
        props: root.props
        screenState: root.screenState
    }
}
