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
                path: "M 18 10 L 18 6 C 18 4.34 16.66 3 15 3 L 5 3 C 3.34 3 2 4.34 2 6 L 2 19 C 2 20.66 3.34 22 5 22 L 15 22 C 16.66 22 18 20.66 18 19 L 18 14.5 C 19.1 14.5 20 13.6 20 12.5 L 20 8.5 C 20 7.4 19.1 6.5 18 6.5 Z M 16 19 C 16 19.55 15.55 20 15 20 L 5 20 C 4.45 20 4 19.55 4 19 L 4 6 C 4 5.45 4.45 5 5 5 L 15 5 C 15.55 5 16 5.45 16 6 L 16 19 Z M 6 7 L 14 7 L 14 11 L 6 11 Z"
            }
        }
    }
}
