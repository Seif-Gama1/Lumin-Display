import QtQuick
import QtQuick.Shapes

Item {
    id: root
    implicitWidth: 24
    implicitHeight: 24
    width: implicitWidth
    height: implicitHeight

    property color color: "#A0AAB0"

    Shape {
        id: shape
        width: 14
        height: 14
        anchors.centerIn: parent

        // Auto-scales the 14x14 path to match root.width and root.height
        transform: Scale {
            xScale: root.width / 14
            yScale: root.height / 14
            origin.x: 7
            origin.y: 7
        }

        layer.enabled: true
        layer.samples: 4

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.color
            strokeWidth: 1.5

            PathSvg {
                path: "M 2 3 L 9 3 L 9 12 L 2 12 Z M 9 5 L 11 5 L 12 7 L 12 11"
            }
        }
    }
}
