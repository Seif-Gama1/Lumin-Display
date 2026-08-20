import QtQuick
import QtQuick.Shapes

Item {
    id: root

    width: 120
    height: 120

    property int radius: 45
    property string fillColor: "#A88BFF"

    property real value: 50
    property real maxValue: 100
    property real smoothValue: value

    onValueChanged: smoothValue = value

    Behavior on smoothValue {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }
    property string label: ""
    property string unit: ""

    readonly property real progress:
        Math.max(0, Math.min(1, smoothValue / maxValue))

    Shape {
        anchors.fill: parent

        ShapePath {
            strokeWidth: 8
            strokeColor: "#3A3550"
            fillColor: "transparent"

            PathAngleArc {
                centerX: width / 2
                centerY: height / 2

                radiusX: root.radius
                radiusY: root.radius

                startAngle: 140
                sweepAngle: 260
            }
        }
    }

    Shape {
        anchors.fill: parent

        ShapePath {
            strokeWidth: 8
            strokeColor: root.fillColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: width / 2
                centerY: height / 2

                radiusX: root.radius
                radiusY: root.radius

                startAngle: 140
                sweepAngle: progress * 260
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: Math.round(smoothValue) + unit
        color: root.fillColor
        font.pixelSize: 20
        font.bold: true
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.verticalCenter
        anchors.topMargin: 18
        text: label
        color: "#AFA7C6"
        font.pixelSize: 10
    }
}
