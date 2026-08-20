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
                path: "M 12 2 C 8.13 2 5 5.13 5 9 C 5 14.25 12 22 12 22 C 12 22 19 14.25 19 9 C 19 5.13 15.87 2 12 2 Z M 12 11.5 C 10.62 11.5 9.5 10.38 9.5 9 C 9.5 7.62 10.62 6.5 12 6.5 C 13.38 6.5 14.5 7.62 14.5 9 C 14.5 10.38 13.38 11.5 12 11.5 Z"
            }
        }
    }
}
