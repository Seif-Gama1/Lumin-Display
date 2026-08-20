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
                path: "M 12 2 C 10.34 2 9 3.34 9 5 L 9 11.17 C 7.8 12.23 7 13.78 7 15.5 C 7 18.26 9.24 20.5 12 20.5 C 14.76 20.5 17 18.26 17 15.5 C 17 13.78 16.2 12.23 15 11.17 L 15 5 C 15 3.34 13.66 2 12 2 Z M 12 18.5 C 10.34 18.5 9 17.16 9 15.5 C 9 14.39 9.6 13.41 10.5 12.87 L 11 12.57 L 11 5 C 11 4.45 11.45 4 12 4 C 12.55 4 13 4.45 13 5 L 13 12.57 L 13.5 12.87 C 14.4 13.41 15 14.39 15 15.5 C 15 17.16 13.66 18.5 12 18.5 Z"
            }
        }
    }
}
