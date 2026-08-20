import QtQuick

Rectangle {
    width: 110
    height: 35
    radius: 8
    color: "#0f1722"
    border.color: "#3B3552"

    property string title: ""
    property string value: ""

    Row {
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: title
            color: "#AFA7C6"
            font.pixelSize: 14
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: value
            color: "#00e5ff"
            font.pixelSize: 12
            font.bold: true
        }
    }
}

