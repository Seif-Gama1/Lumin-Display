import QtQuick

Item {
    id: root
    implicitWidth: 34
    implicitHeight: 34

    property string iconType: "lowBeam" // Options: "lowBeam", "highBeam", "fogFront", "fogRear"
    property bool active: false
    property color iconColor: "#A88BFF"
    property string tooltip: ""
    property real topMargin: 0

    // Shift the ENTIRE Item visual context (bgContainer + Image + effects together)
    transform: Translate { y: root.topMargin }

    // 1. Optimized Path Data Dictionary
    readonly property var svgIcons: ({
        "lowBeam": `<svg viewBox="0 0 24 24" fill="none" stroke="${active ? iconColor : '#4A5A6A'}" stroke-width="2" stroke-linecap="round"><path d="M12 6a6 6 0 0 1 6 6 6 6 0 0 1-6 6V6z" fill="${active ? iconColor : 'none'}"/><path d="M5 9l4 2M5 12l4 1M5 15l4 0"/></svg>`,

        "highBeam": `<svg viewBox="0 0 24 24" fill="none" stroke="${active ? iconColor : '#4A5A6A'}" stroke-width="2" stroke-linecap="round"><path d="M12 6a6 6 0 0 1 6 6 6 6 0 0 1-6 6V6z" fill="${active ? iconColor : 'none'}"/><path d="M4 8h5M4 12h5M4 16h5"/></svg>`,

        "fogFront": `<svg viewBox="0 0 24 24" fill="none" stroke="${active ? iconColor : '#4A5A6A'}" stroke-width="2" stroke-linecap="round"><path d="M13 6a5 5 0 0 1 5 5 5 5 0 0 1-5 5V6z"/><path d="M5 9l4 1.5M5 13l4 1.5M3 18h12M6 21h12"/></svg>`,

        "fogRear": `<svg viewBox="0 0 24 24" fill="none" stroke="${active ? iconColor : '#4A5A6A'}" stroke-width="2" stroke-linecap="round"><path d="M11 6a5 5 0 0 0-5 5 5 5 0 0 0 5 5V6z"/><path d="M15 9l4 1.5M15 13l4 1.5M6 18h12M3 21h12"/></svg>`
    })

    // 2. Active State Scale Pop Effect
    scale: active ? 1.05 : 1.0
    Behavior on scale {
        NumberAnimation { duration: 200; easing.type: Easing.OutBack }
    }

    // 3. Background Container with Ambient Halo
    Rectangle {
        id: bgContainer
        anchors.fill: parent
        radius: 8
        color: root.active ? Qt.rgba(root.iconColor.r, root.iconColor.g, root.iconColor.b, 0.15) : "#0D131A"
        border.color: root.active ? Qt.rgba(root.iconColor.r, root.iconColor.g, root.iconColor.b, 0.8) : "#1E2A38"
        border.width: root.active ? 1.5 : 1.0

        Behavior on color { ColorAnimation { duration: 250 } }
        Behavior on border.color { ColorAnimation { duration: 250 } }

        // Radial bloom glow behind active indicator
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.85
            height: width
            radius: width / 2
            visible: root.active
            opacity: 0.35
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.iconColor }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    // 4. Icon Display Layer with Smooth Opacity Transition
    Image {
        id: iconImg
        anchors.centerIn: parent
        width: 22
        height: 22
        source: {
            var svg = root.svgIcons[root.iconType] || ""
            return "data:image/svg+xml;utf8," + encodeURIComponent(svg)
        }
        fillMode: Image.PreserveAspectFit
        opacity: root.active ? 1.0 : 0.45

        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}
