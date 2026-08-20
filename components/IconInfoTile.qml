import QtQuick

Rectangle {
    id: root

    width: 210
    height: 46
    radius: 8
    color: "#0a1418"
    border.color: "#3B3552"
    border.width: 1

    property string iconText: ""
    property color iconColor: "#00e5ff"
    property string title: ""
    property string value: ""
    property color valueColor: "#F7F5FF"

    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 30
        height: 30
        radius: 7
        color: Qt.rgba(root.iconColor.r,
                       root.iconColor.g,
                       root.iconColor.b, 0.15)
        border.color: root.iconColor
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: root.iconText
            color: root.iconColor
            font.pixelSize: 15
        }
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 52
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
            text: root.title
            color: "#AEA6C5"
            font.pixelSize: 9
            font.bold: true
            font.letterSpacing: 1
        }

        Text {
            text: root.value
            color: root.valueColor
            font.pixelSize: 15
            font.bold: true
        }
    }
}
