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
        width: 16
        height: 18
        anchors.centerIn: parent

        // Auto-scales the 16x18 path to match root.width and root.height
        transform: Scale {
            xScale: root.width / 16
            yScale: root.height / 18
            origin.x: 8
            origin.y: 9
        }

        layer.enabled: true
        layer.samples: 4

        // Thermometer Body / Outline
        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"

            PathSvg {
                path: "M 8 1.5 C 6.6 1.5 5.5 2.6 5.5 4 L 5.5 8.3 C 4.3 9.2 3.5 10.7 3.5 12.3 C 3.5 14.8 5.5 16.8 8 16.8 C 10.5 16.8 12.5 14.8 12.5 12.3 C 12.5 10.7 11.7 9.2 10.5 8.3 L 10.5 4 C 10.5 2.6 9.4 1.5 8 1.5 Z M 8 3 C 8.6 3 9 3.4 9 4 L 9 8.8 L 9.4 9.1 C 10.4 9.8 11 11 11 12.3 C 11 13.9 9.7 15.3 8 15.3 C 6.3 15.3 5 13.9 5 12.3 C 5 11 5.6 9.8 6.6 9.1 L 7 8.8 L 7 4 C 7 3.4 7.4 3 8 3 Z"
            }
        }

        // Inner Mercury Fill
        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"

            PathSvg {
                path: "M 8 10.5 C 6.9 10.5 6 11.4 6 12.5 C 6 13.6 6.9 14.5 8 14.5 C 9.1 14.5 10 13.6 10 12.5 C 10 11.4 9.1 10.5 8 10.5 Z"
            }
        }
    }
}
