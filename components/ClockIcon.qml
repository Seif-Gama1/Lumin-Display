import QtQuick
import QtQuick.Shapes

Item {
    id: root
    implicitWidth: 20
    implicitHeight: 20
    property color color: "#8A99AD"

    Shape {
        anchors.centerIn: parent
        width: 24; height: 24
        transform: Scale {
            xScale: root.width / 24; yScale: root.height / 24
            origin.x: 12; origin.y: 12
        }
        layer.enabled: true; layer.samples: 4

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            PathSvg {
                path: "M 12 2 C 6.48 2 2 6.48 2 12 C 2 17.52 6.48 22 12 22 C 17.52 22 22 17.52 22 12 C 22 6.48 17.52 2 12 2 Z M 12 20 C 7.59 20 4 16.41 4 12 C 4 7.59 7.59 4 12 4 C 16.41 4 20 7.59 20 12 C 20 16.41 16.41 20 12 20 Z M 12.5 7 L 11 7 L 11 13 L 16.25 16.15 L 17 14.92 L 12.5 12.25 Z"
            }
        }
    }
}
