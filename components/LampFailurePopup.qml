import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: popupRoot
    anchors.fill: parent

    // ============================================================
    // PUBLIC API
    // ============================================================
    property var activeWarnings: []     // Main.qml supplies the currently active vehicle faults.
    // Emitted when the user dismisses the currently displayed fault.
    signal faultDismissed(string faultName)

    // ============================================================
    // INTERNAL QUEUE & ANIMATION TRACKING
    // ============================================================
    property var queue: []
    // Track queue head vs what is currently rendered on-screen
    readonly property string currentFault: queue.length > 0 ? queue[0] : ""
    property string displayedFault: ""

    visible: opacity > 0
    opacity: queue.length > 0 ? 1 : 0

    Behavior on opacity {
        NumberAnimation { duration: 200 }
    }

    // ============================================================
    // SYNCHRONIZATION & TRANSITION TRIGGER
    // ============================================================
    onActiveWarningsChanged: rebuildQueue()

    function rebuildQueue() {
        var newQueue = []
        for (var i = 0; i < activeWarnings.length; ++i)
            newQueue.push(activeWarnings[i])

        queue = newQueue
    }

    // Triggers text transition when the active fault changes
    onCurrentFaultChanged: {
        if (currentFault === "") {
            displayedFault = ""
            return
        }
        // Show immediately if popup just opened or was invisible
        if (displayedFault === "" || popupRoot.opacity === 0) {
            displayedFault = currentFault
            faultTextContainer.opacity = 1.0
            faultTextContainer.scale = 1.0
        } else if (displayedFault !== currentFault) {
            // Animate transition between faults
            faultSwitchAnim.restart()
        }
    }

    // ============================================================
    // FAULT SWITCH ANIMATION
    // ============================================================
    SequentialAnimation {
        id: faultSwitchAnim
        // Step 1: Fade out and shrink current fault
        ParallelAnimation {
            NumberAnimation {
                target: faultTextContainer
                property: "opacity"
                to: 0
                duration: 120
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: faultTextContainer
                property: "scale"
                to: 0.92
                duration: 120
                easing.type: Easing.InQuad
            }
        }

        // Step 2: Swap string mid-transition
        ScriptAction {
            script: popupRoot.displayedFault = popupRoot.currentFault
        }

        // Step 3: Fade in and pop new fault
        ParallelAnimation {
            NumberAnimation {
                target: faultTextContainer
                property: "opacity"
                to: 1
                duration: 180
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: faultTextContainer
                property: "scale"
                to: 1.0
                duration: 180
                easing.type: Easing.OutBack
            }
        }
    }

    // ============================================================
    // DISMISS CURRENT WARNING
    // ============================================================
    function dismissCurrent() {
        if (queue.length === 0)
            return
        var currentFault = queue[0]
        faultDismissed(currentFault)
    }

    // ============================================================
    // UN-SHADED OVERLAY (Transparent to leave gauges visible)
    // ============================================================
    Rectangle {
        anchors.fill: parent
        color: "transparent" // Removed dark shading

        MouseArea {
            anchors.fill: parent
            onClicked: popupRoot.dismissCurrent()
        }
    }

    // ============================================================
    // NARROWER POPUP CONTAINER (Compact for Center Cluster Slot)
    // ============================================================
    Rectangle {
        anchors.centerIn: parent
        width: 360  // Reduced from 520 to clear circular gauges
        height: 210
        color: "#121824"
        radius: 16
        border.color: "#FFC83B"
        border.width: 2

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            // ====================================================
            // HEADER
            // ====================================================
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "💡"
                    font.pixelSize: 20
                }

                Text {
                    text: "LAMP FAILURE"
                    color: "#FFC83B"
                    font.pixelSize: 14
                    font.bold: true
                    font.letterSpacing: 1.5
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    visible: popupRoot.queue.length > 1
                    text: "1 / " + popupRoot.queue.length
                    color: "#A0AAB8"
                    font.pixelSize: 12
                    font.bold: true
                    font.family: "Monospace"
                    Layout.rightMargin: 8
                }

                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: closeArea.containsMouse ? "#2A3447" : "#1A2230"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: "#A0AAB8"
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: popupRoot.dismissCurrent()
                    }
                }
            }

            // ====================================================
            // SEPARATOR
            // ====================================================
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#232D3F"
            }

            Item {
                Layout.fillHeight: true
            }

            // ====================================================
            // ANIMATED CURRENT FAULT CONTAINER
            // ====================================================
            Item {
                id: faultTextContainer
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: parent.width - 24
                Layout.preferredHeight: 50

                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width
                    spacing: 4

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: popupRoot.displayedFault
                        color: "#FFFFFF"
                        font.pixelSize: 20
                        font.bold: true
                        fontSizeMode: Text.Fit
                        minimumPixelSize: 14
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Check vehicle lighting system"
                        color: "#8A99AD"
                        font.pixelSize: 12
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            // ====================================================
            // FOOTER
            // ====================================================
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Press Steering Wheel 'X' Button"
                color: "#5C6A7F"
                font.pixelSize: 10
            }
        }
    }
}
