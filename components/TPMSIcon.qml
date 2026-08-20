import QtQuick

Item {
    id: root

    width: 70
    height: 58

    property string label: "FL"
    property real pressure: 2.2
    property color color: "#00E68A"

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: "#0A1110"
        border.color: "#3B3552"
        border.width: 1

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 3
            radius: 1
            color: root.color
            opacity: 0.8
        }

        Column {
            anchors.centerIn: parent
            spacing: 1

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: label
                color: "#AEA6C5"
                font.pixelSize: 10
                font.bold: true
            }

            // Inline row for pressure value and unit
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 3

                Text {
                    id: valText
                    text: pressure.toFixed(1)
                    color: root.color
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "bar"
                    color: "#5A5A6A"
                    font.pixelSize: 9
                    anchors.baseline: valText.baseline // Align unit along the bottom baseline of the number
                }
            }
        }
    }
}
