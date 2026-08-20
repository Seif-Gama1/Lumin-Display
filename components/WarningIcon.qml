import QtQuick
import QtQuick.Effects

Item {
    id: root
    implicitWidth: 34
    implicitHeight: 34

    property string iconType: "engine"
    property bool active: false
    property color iconColor: "#FF4466"
    property bool warningFlash: false
    property string tooltip: ""
    property real topMargin: 0

    // Shift the ENTIRE Item visual context (bgContainer + Image + effects together)
    transform: Translate { y: root.topMargin }

    // 1. High-Performance SVG Paths
    readonly property var svgPaths: ({
        "engine": "M4 10h2V7h3V5h2v2h2V5h2v2h3v3h2v4h-2v3h-3v2h-2v-2h-2v2H9v-2H6v-3H4v-4z M9 10h6v4H9z",
        "oil": "M6 13c0-1.65 1.35-3 3-3h1V8.5C10 7.12 11.12 6 12.5 6S15 7.12 15 8.5V10h1c1.65 0 3 1.35 3 3v2.5c0 1.38-1.12 2.5-2.5 2.5H7.5C6.12 18 5 16.88 5 15.5V13h1zm12.5 1.5c.28 0 .5-.22.5-.5s-.22-.5-.5-.5-.5.22-.5.5.22.5.5.5zM3 13.5L2 15h2l-1-1.5z",
        "battery": "M2 7h18v11H2z M20 10h2v4h-2 M6 12.5h4 M14 12.5h4 M16 10.5v4",
        "handbrake": "M12 5a7 7 0 1 0 0 14 7 7 0 0 0 0-14z M12 9v4 M12 16v.01 M3 9.5a10 10 0 0 0 0 5 M21 9.5a10 10 0 0 1 0 5",
        "door": "M5 3h14v18H5z M8 12a1 1 0 1 0 0-2 1 1 0 0 0 0 2z",
        "seatbelt": "M4 4l7 7 M13 13l7 7 M10 4l-6 6 M20 14l-6 6 M9 9h6v6H9z",
        "lightFault": "M12 3a6 6 0 0 0-5 9.33c.83 1.18 1 2.07 1 3.67h8c0-1.6.17-2.49 1-3.67A6 6 0 0 0 12 3z M9 18h6 M10.5 20h3 M12 7v3.5 M12 13v.01"
    })

    // 2. Active State Scale Pop Effect
    scale: active ? 1.05 : 1.0
    Behavior on scale {
        NumberAnimation { duration: 200; easing.type: Easing.OutBack }
    }

    // 3. Warning Pulse Engine
    property real flashOpacity: 1.0
    SequentialAnimation on flashOpacity {
        running: root.active && root.warningFlash
        loops: Animation.Infinite
        NumberAnimation { to: 0.3; duration: 400; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.0; duration: 400; easing.type: Easing.InOutSine }
    }

    // 4. Background Container with Ambient Halo
    Rectangle {
        id: bgContainer
        anchors.fill: parent
        radius: 8
        color: root.active ? Qt.rgba(root.iconColor.r, root.iconColor.g, root.iconColor.b, 0.15 * root.flashOpacity) : "#0D131A"
        border.color: root.active ? Qt.rgba(root.iconColor.r, root.iconColor.g, root.iconColor.b, 0.8 * root.flashOpacity) : "#1E2A38"
        border.width: root.active ? 1.5 : 1.0

        Behavior on color { ColorAnimation { duration: 250 } }
        Behavior on border.color { ColorAnimation { duration: 250 } }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.8
            height: width
            radius: width / 2
            visible: root.active
            opacity: 0.4 * root.flashOpacity
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.iconColor }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    Image {
        id: iconImg
        anchors.centerIn: parent
        width: 20
        height: 20
        source: "data:image/svg+xml;utf8,<svg viewBox='0 0 24 24' fill='none' stroke='%1' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='%2'/></svg>"
                .arg(root.active ? root.iconColor : "#4A5A6A")
                .arg(root.svgPaths[root.iconType] || "")
        fillMode: Image.PreserveAspectFit
        opacity: root.active && root.warningFlash ? root.flashOpacity : (root.active ? 1.0 : 0.5)

        Behavior on opacity { NumberAnimation { duration: 150 } }
    }
}
