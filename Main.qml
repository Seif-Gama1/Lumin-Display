import QtQuick
import QtQuick.Window

Window {
    width: 1280
    height: 720
    visible: true
    color: "#04080a"
    title: "Digital Cluster"

    ClusterScreen {
        anchors.fill: parent
    }
}
