import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import QtQuick.Layouts

Item {
    id: root
    width: 1280
    height: 480

    // =========================================================================
    // CAN BUS DATA BINDINGS
    // =========================================================================
    readonly property var canCtx: typeof canController !== "undefined" ? canController : null
    readonly property var dmsCtx: typeof dmsReceiver !== "undefined" ? dmsReceiver : null

    // DMS Properties (Safe fallback values if dmsCtx is null)
    readonly property int dmsAlertStatus: (typeof dmsReceiver !== "undefined" && dmsReceiver) ? dmsReceiver.alertStatus : 0
    readonly property real dmsRiskPercentage: (typeof dmsReceiver !== "undefined" && dmsReceiver) ? dmsReceiver.riskPercentage : 0.0
    readonly property string dmsStateString: (typeof dmsReceiver !== "undefined" && dmsReceiver) ? dmsReceiver.stateString : "Focused"

    Connections {
        target: dmsReceiver

        // In Qt 6, signal parameters are passed explicitly into arrow functions or functions
        onDmsAlertReceived: (alertStatus, riskPercentage) => {     // [!code ++]
            console.log("[QML] DMS alert received:", alertStatus, riskPercentage)
            // Forward to CAN Controller
            canController.sendDmsAlert(alertStatus, riskPercentage)
        }
    }

    // Vehicle Dynamics
    readonly property string transmission: (canCtx && canCtx.transmission !== undefined) ? canCtx.transmission : "D"
    property string driveMode: (canCtx && canCtx.driveMode !== undefined) ? canCtx.driveMode : "DRIVE"
    // property real rpm: (canCtx && canCtx.rpm !== undefined) ? canCtx.rpm : 0
    // property real speed: (canCtx && canCtx.speed !== undefined) ? canCtx.speed : 0
    // property int gear: (canCtx && canCtx.gear !== undefined) ? canCtx.gear : 1
    property real rpm: 3200
    property real speed: 125
    property int gear: 6
    property real odometer: (canCtx && canCtx.odometer !== undefined) ? canCtx.odometer : 125483

    // Telemetry & States
    property real simFuel: (canCtx && canCtx.fuelLevel !== undefined) ? canCtx.fuelLevel : 60
    property real simTemp: (canCtx && canCtx.motorTemperature !== undefined) ? canCtx.motorTemperature : 65
    property real simBattery: (canCtx && canCtx.batteryVoltage !== undefined) ? canCtx.batteryVoltage : 12.6
    property real simRange: (canCtx && canCtx.rangeKm !== undefined) ? canCtx.rangeKm: Math.round((simFuel / 100.0) * maxSedanRangeKm)

    property real simMotorTemp: (canCtx && canCtx.motorTemperature !== undefined) ? canCtx.motorTemperature : 65
    property real simOutsideTemp: (canCtx && canCtx.outsideTemp !== undefined) ? canCtx.outsideTemp : 24
    property real simDistance: (canCtx && canCtx.tripDistance !== undefined) ? canCtx.tripDistance : 142
    property real simEtaMin: (canCtx && canCtx.etaMinutes !== undefined) ? canCtx.etaMinutes : 105

    readonly property real maxSedanRangeKm: 720


    property bool showMap: true

    // Signal & Warning States
    property bool leftSignal: (canCtx && canCtx.leftSignal !== undefined) ? canCtx.leftSignal : false
    // property bool rightSignal: (canCtx && canCtx.rightSignal !== undefined) ? canCtx.rightSignal : false
    property bool hazardSignal: (canCtx && canCtx.hazardSignal !== undefined) ? canCtx.hazardSignal : false

    property bool warningCheckEngine: (canCtx && canCtx.warningCheckEngine !== undefined) ? canCtx.warningCheckEngine : false
    property bool warningABS: (canCtx && canCtx.warningABS !== undefined) ? canCtx.warningABS : false
    property bool warningOil: (canCtx && canCtx.warningOil !== undefined) ? canCtx.warningOil : false
    property bool warningBattery: (canCtx && canCtx.warningBattery !== undefined) ? canCtx.warningBattery : false
    property bool warningHandbrake: (canCtx && canCtx.warningHandbrake !== undefined) ? canCtx.warningHandbrake : false
    // property bool warningDoors: (canCtx && canCtx.warningDoors !== undefined) ? canCtx.warningDoors : false
    // property bool warningSeatbelt: (canCtx && canCtx.warningSeatbelt !== undefined) ? canCtx.warningSeatbelt : false
    property bool warningLightFault: (canController && (canController.lightLowBeamFault || canController.lightHighBeamFault ||
                                                        canController.lightDirectionLeftFault || canController.lightDirectionRightFault
    ))



    property bool rightSignal: true
    property bool warningDoors: true
    property bool warningSeatbelt: true
    property bool lightHighBeam: true

    // Lighting states
    property bool lightLowBeam: (canCtx && canCtx.lightLowBeam !== undefined) ? canCtx.lightLowBeam : false
    // property bool lightHighBeam: (canCtx && canCtx.lightHighBeam !== undefined) ? canCtx.lightHighBeam : false

    property bool ackButtonPressed: (canCtx && canCtx.ackButtonPressed !== undefined) ? canCtx.ackButtonPressed : false
    // Lighting Fault Signals
    property bool lightLowBeamFault: (canCtx && canCtx.lightLowBeamFault !== undefined) ? canCtx.lightLowBeamFault : false
    property bool lightHighBeamFault: (canCtx && canCtx.lightHighBeamFault !== undefined) ? canCtx.lightHighBeamFault : false
    property bool lightDirectionLeftFault: (canCtx && canCtx.lightDirectionLeftFault !== undefined) ? canCtx.lightDirectionLeftFault : false
    property bool lightDirectionRightFault: (canCtx && canCtx.lightDirectionRightFault !== undefined) ? canCtx.lightDirectionRightFault : false

    // =========================================================================
    // FAULT QUEUE & ACKNOWLEDGMENT MANAGEMENT
    // =========================================================================
    property var activeLampFaults: []
    property var acknowledgedFaults: ({})

    function updateLampFault(faultName, isFaulty) {
        var index = activeLampFaults.indexOf(faultName)

        if (isFaulty) {
            if (index === -1 && !acknowledgedFaults[faultName]) {
                activeLampFaults.push(faultName)
                activeLampFaults = activeLampFaults.slice() // Trigger QML binding update
            }
        } else {
            acknowledgedFaults[faultName] = false
            if (index !== -1) {
                activeLampFaults.splice(index, 1)
                activeLampFaults = activeLampFaults.slice()
            }
        }
    }

    onLightLowBeamFaultChanged: updateLampFault("LowBeam", lightLowBeamFault)
    onLightHighBeamFaultChanged: updateLampFault("HighBeam", lightHighBeamFault)
    onLightDirectionLeftFaultChanged: updateLampFault("DirectionLeft", lightDirectionLeftFault)
    onLightDirectionRightFaultChanged: updateLampFault("DirectionRight", lightDirectionRightFault)

    onAckButtonPressedChanged: {
        if (ackButtonPressed) {
            failurePopup.dismissCurrent()
        }
    }

    // Theme Color Mappings
    property var modeMap: ({
        "IDLE":    { color: "#8E82C9" },
        "DRIVE":   { color: "#A88BFF" },
        "SPORT":   { color: "#FF4466" },
        "REDLINE": { color: "#FF7EB8" }
    })

    property color currentAccentColor: root.modeMap[root.driveMode] ? root.modeMap[root.driveMode].color : "#A88BFF"
    Behavior on currentAccentColor { ColorAnimation { duration: 400; easing.type: Easing.OutQuart } }

    function setMode(mode) {
        if (canCtx && typeof canCtx.requestDriveMode === "function") {
            canCtx.requestDriveMode(mode)
        } else {
            root.driveMode = mode
        }
    }

    function fuelColor(p) {
        if (p < 25) return "#FF4466"
        if (p <= 50) return "#FFCC00"
        return "#00FF88"
    }

    function updateClock() {
        var d = new Date()
        var h = d.getHours() % 12 || 12
        var m = d.getMinutes()
        clockText.text = (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m + (d.getHours() < 12 ? " AM" : " PM")
    }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.updateClock()
    }

    // Blink & Flash Timers
    property bool _flashState: false
    property bool warningFlash: false

    property bool leftSignalActive: root.leftSignal || root.hazardSignal
    property bool rightSignalActive: root.rightSignal || root.hazardSignal

    Timer {
        interval: 500; running: true; repeat: true
        onTriggered: {
            root._flashState = !root._flashState
            root.warningFlash = root._flashState
        }
    }

    // --- Background Layer ---
    Rectangle { anchors.fill: parent; color: "#030608" }

    Background {
        anchors.fill: parent
        glowColor: root.currentAccentColor
    }

    // -------------------------------------------------------------------------
    // 0. FANCY CAT COMPANION (TOP LEFT)
    // -------------------------------------------------------------------------
    Item {
        id: fancyCat
        anchors {
            top: parent.top
            left: parent.left
            topMargin: 18
            leftMargin: 24
        }
        width: 70
        height: 60
        z: 100

        property real floatOffset: 0
        NumberAnimation on floatOffset {
            from: -3; to: 3; duration: 2000; loops: Animation.Infinite; easing.type: Easing.InOutSine
        }

        Item {
            y: fancyCat.floatOffset
            anchors.centerIn: parent

            Rectangle {
                anchors.centerIn: parent
                width: 50; height: 50; radius: 25
                color: Qt.alpha(root.currentAccentColor, 0.12)
                border.color: Qt.alpha(root.currentAccentColor, 0.35)
                border.width: 1
            }

            Rectangle {
                id: catHead
                width: 36; height: 30; radius: 14
                anchors.centerIn: parent
                color: "#181824"
                border.color: root.currentAccentColor
                border.width: 1.5

                Shape {
                    anchors.bottom: parent.top
                    anchors.left: parent.left
                    anchors.bottomMargin: -6
                    anchors.leftMargin: 2
                    width: 10; height: 10
                    ShapePath {
                        fillColor: "#181824"
                        strokeColor: root.currentAccentColor
                        strokeWidth: 1.5
                        startX: 0; startY: 10
                        PathLine { x: 5; y: 0 }
                        PathLine { x: 10; y: 10 }
                    }
                }

                Shape {
                    anchors.bottom: parent.top
                    anchors.right: parent.right
                    anchors.bottomMargin: -6
                    anchors.rightMargin: 2
                    width: 10; height: 10
                    ShapePath {
                        fillColor: "#181824"
                        strokeColor: root.currentAccentColor
                        strokeWidth: 1.5
                        startX: 0; startY: 10
                        PathLine { x: 5; y: 0 }
                        PathLine { x: 10; y: 10 }
                    }
                }

                Text {
                    text: "🎩"
                    font.pixelSize: 18
                    anchors.bottom: parent.top
                    anchors.bottomMargin: -7
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                property bool blinking: false
                Timer {
                    interval: 3800; running: true; repeat: true
                    onTriggered: {
                        catHead.blinking = true
                        blinkReset.start()
                    }
                }
                Timer {
                    id: blinkReset
                    interval: 140
                    onTriggered: catHead.blinking = false
                }

                Row {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -2
                    spacing: 7

                    Rectangle {
                        width: 5; height: catHead.blinking ? 1 : 5; radius: 2.5
                        color: root.currentAccentColor
                    }

                    Item {
                        width: 5; height: 5
                        Rectangle {
                            anchors.fill: parent
                            height: catHead.blinking ? 1 : 5; radius: 2.5
                            color: root.currentAccentColor
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: 9; height: 9; radius: 4.5
                            color: "transparent"
                            border.color: "#FFD700"
                            border.width: 1
                            visible: !catHead.blinking
                        }
                    }
                }

                Rectangle {
                    width: 3; height: 2; radius: 1
                    color: "#FF7EB8"
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 4
                }

                Text {
                    text: "🎀"
                    font.pixelSize: 10
                    anchors.top: parent.bottom
                    anchors.topMargin: -5
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: meowBubble.triggerSpeech()
            }

            Rectangle {
                id: meowBubble
                anchors.bottom: catHead.top
                anchors.bottomMargin: 14
                anchors.horizontalCenter: parent.horizontalCenter
                width: bubbleText.implicitWidth + 14
                height: 20
                radius: 10
                color: "#222234"
                border.color: root.currentAccentColor
                border.width: 1
                opacity: 0
                scale: opacity

                Behavior on opacity { NumberAnimation { duration: 180 } }

                Text {
                    id: bubbleText
                    anchors.centerIn: parent
                    text: "Meow! 🐾"
                    color: "#FFFFFF"
                    font.pixelSize: 10
                    font.bold: true
                }

                function triggerSpeech() {
                    var msgs = ["Purr-fect! ✨", "Fancy ride! 🎩", "Meow! 🐾", "Smooth driving! 🏎️"]
                    if (root.speed > 120) msgs = ["Slow down, meow! 🙀", "Too fast! 💨"]
                    else if (root.driveMode === "SPORT") msgs = ["Sport mode activated! ⚡", "Let's go! 🏁"]

                    bubbleText.text = msgs[Math.floor(Math.random() * msgs.length)]
                    opacity = 1
                    hideTimer.restart()
                }

                Timer {
                    id: hideTimer
                    interval: 2200
                    onTriggered: meowBubble.opacity = 0
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // 1. TOP STATUS BAR (ELEGANT SMOOTHED DIP CONTOUR)
    // -------------------------------------------------------------------------
    Item {
        id: topBarContainer
        anchors {
            top: parent.top
            topMargin: 8  // Hug closer to the top frame edge
            horizontalCenter: parent.horizontalCenter
        }
        width: 640
        height: 84

        Shape {
            anchors.fill: parent
            layer.enabled: true
            layer.samples: 4

            ShapePath {
                fillColor: "#E61A1D24"
                // Crisp, subtle frosted top edge border
                strokeColor: "#40FFFFFF"
                strokeWidth: 1.5
                joinStyle: ShapePath.RoundJoin
                capStyle: ShapePath.RoundCap

                // Start at top-left inner shoulder
                startX: 20
                startY: 14

                // 1. TOP EDGE: Smooth downward central dip
                PathCubic {
                    x: topBarContainer.width - 20
                    y: 14
                    control1X: topBarContainer.width * 0.35
                    control1Y: 42
                    control2X: topBarContainer.width * 0.65
                    control2Y: 42
                }

                // 2. RIGHT CORNER: Elegant rounded wing cap
                PathCubic {
                    x: topBarContainer.width - 35
                    y: 58
                    control1X: topBarContainer.width - 5
                    control1Y: 22
                    control2X: topBarContainer.width - 15
                    control2Y: 52
                }

                // 3. BOTTOM EDGE: Parallel bottom curve
                PathCubic {
                    x: 35
                    y: 58
                    control1X: topBarContainer.width * 0.65
                    control1Y: 80
                    control2X: topBarContainer.width * 0.35
                    control2Y: 80
                }

                // 4. LEFT CORNER: Smooth rounded wing cap back to start
                PathCubic {
                    x: 20
                    y: 14
                    control1X: 15
                    control1Y: 52
                    control2X: 5
                    control2Y: 22
                }
            }
        }

        Row {
            id: topBar
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 22
            spacing: 12

            LightIcon { iconType: "lowBeam"; active: root.lightLowBeam; iconColor: "#A88BFF"; topMargin: 9 }
            LightIcon { iconType: "highBeam"; active: root.lightHighBeam; iconColor: "#00E68A"; topMargin: 11 }

            Rectangle { width: 2; height: 20; color: "#40FFFFFF"; transform: Translate { y: 20 } }

            WarningIcon {
                iconType: "lightFault"
                active: root.warningLightFault
                iconColor: "#FFCC00"
                warningFlash: root.warningFlash
                topMargin: 12
            }
            WarningIcon { iconType: "engine"; active: root.warningCheckEngine; iconColor: "#FF4466"; warningFlash: root.warningFlash; topMargin: 14 }
            WarningIcon { iconType: "oil"; active: root.warningOil; iconColor: "#FF4466"; warningFlash: root.warningFlash; topMargin: 15 }
            WarningIcon { iconType: "battery"; active: root.warningBattery; iconColor: "#FFCC00"; warningFlash: root.warningFlash; topMargin: 14 }
            WarningIcon { iconType: "handbrake"; active: root.warningHandbrake; iconColor: "#FF4466"; warningFlash: root.warningFlash; topMargin: 12 }

            Rectangle { width: 2; height: 20; color: "#40FFFFFF"; transform: Translate { y: 20 } }

            WarningIcon { iconType: "door"; active: root.warningDoors; iconColor: "#FFCC00"; warningFlash: root.warningFlash; topMargin: 11 }
            WarningIcon { iconType: "seatbelt"; active: root.warningSeatbelt; iconColor: "#FF4466"; warningFlash: root.warningFlash; topMargin: 9 }


            /* extra stuff */
            // Rectangle { width: 2; height: 20; color: "#40FFFFFF"; transform: Translate { y: 20 } }

            // Text {
            //     id: dmsStatusText
            //     text: "DMS: " + root.dmsStateString + " | Risk: " + (root.dmsRiskPercentage * 100).toFixed(0) + "% | Alert: " + root.dmsAlertStatus
            //     color: (root.dmsAlertStatus === 1 || root.dmsRiskPercentage > 0.7) ? "#FF4466" : "#00E68A"
            //     font.pixelSize: 12
            //     font.bold: true
            //     verticalAlignment: Text.AlignVCenter
            //     transform: Translate { y: 12 }
            //     visible: true
            // }
            /* extra stuff */
        }
    }

    // -------------------------------------------------------------------------
    // 2. MAIN 3-COLUMN CONTENT AREA
    // -------------------------------------------------------------------------
    Row {
        anchors {
            top: topBarContainer.bottom
            bottom: bottomBarContainer.top
            left: parent.left
            right: parent.right
            topMargin: 0
            bottomMargin: 2
        }

        // --- LEFT COLUMN: Speedometer ---
        Item {
            width: parent.width / 3
            height: parent.height

            CircularGauge {
                id: speedGauge
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height)
                height: width

                value: Math.abs(root.speed)
                maxValue: 200
                tickValues: [0, 20, 40, 60, 80, 100, 120, 140, 160, 180, 200]
                decimals: 0
                unit: "km/h"
                redlineStartValue: 220

                bottomLabel: {
                    var trans = (root.transmission || "").toUpperCase()
                    if (trans === "P" || trans === "R" || trans === "N") {
                        return trans
                    } else if (trans === "D") {
                        return root.gear === 0 ? "N" : "D" + root.gear
                    } else {
                        return trans
                    }
                }

                accentColor: root.modeMap[root.driveMode] ? root.modeMap[root.driveMode].color : "#A88BFF"
                trackColor: "#342E47"
                panelColor: "transparent"
                borderColor: "#3B3552"
            }
        }

        // --- CENTER COLUMN: 3D Road Stage & Gear Display ---
        Item {
            id: centerColumn
            width: parent.width / 3
            height: parent.height

            // Turn Signals
            Text {
                anchors.top: parent.top
                anchors.topMargin: 2
                anchors.left: parent.left
                anchors.leftMargin: 20
                text: "◀"
                color: root.leftSignalActive && root._flashState ? "#00E68A" : "#1AFFFFFF"
                font.pixelSize: 26
                font.bold: true
            }
            Text {
                anchors.top: parent.top
                anchors.topMargin: 2
                anchors.right: parent.right
                anchors.rightMargin: 20
                text: "▶"
                color: root.rightSignalActive && root._flashState ? "#00E68A" : "#1AFFFFFF"
                font.pixelSize: 26
                font.bold: true
            }

            // 3D Road Stage Area
            Item {
                id: centerStage
                anchors.top: parent.top
                anchors.topMargin: 12
                anchors.horizontalCenter: parent.horizontalCenter
                width: 340
                height: 220

                CarOnRoadNew {
                    anchors.fill: parent
                    speed: root.speed
                    driveMode: root.driveMode
                    accent: root.modeMap[root.driveMode] ? root.modeMap[root.driveMode].color : "#3B82F6"
                    lightLowBeam: root.lightLowBeam
                    lightHighBeam: root.lightHighBeam
                    leftSignal: root.leftSignal || root.hazardSignal
                    rightSignal: root.rightSignal || root.hazardSignal
                    flashState: root._flashState
                    visible: !root.showMap
                    transmission: root.transmission
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 30
                    radius: 12
                    color: "#0A1418"
                    border.color: "#3B3552"
                    visible: root.showMap

                    MapStreamItem {
                        anchors.fill: parent
                        sourceCrop: Qt.rect(0.25, 0.25, 0.5, 0.5)   // center 50% crop
                        typedMemName: "ivi_map_fb"
                    }
                }
            }

            // --- TRANSMISSION GEAR INDICATOR & INTEGRATED CHEVRON TELEMETRY ---
            Item {
                id: gearDisplay
                width: 280
                height: 110
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: centerStage.bottom
                anchors.topMargin: 50

                // 1. Italicized Central Gear Letter
                Item {
                    id: gearTextContainer
                    width: 100
                    height: 60
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        anchors.centerIn: parent
                        text: root.transmission.toUpperCase()
                        color: "#2C3539"
                        font.pixelSize: 64
                        font.bold: true
                        font.italic: true
                        font.family: "Orbitron, Trebuchet MS, Montserrat, Impact, sans-serif"
                        style: Text.Outline
                        styleColor: "#708090"
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.transmission.toUpperCase()
                        color: "#E6E8FA"
                        font.pixelSize: 62
                        font.bold: true
                        font.italic: true
                        font.family: "Orbitron, Trebuchet MS, Montserrat, Impact, sans-serif"
                        style: Text.Outline
                        styleColor: "#FFFFFF"
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.transmission.toUpperCase()
                        color: "#FF2A4D"
                        font.pixelSize: 58
                        font.bold: true
                        font.italic: true
                        font.family: "Orbitron, Trebuchet MS, Montserrat, Impact, sans-serif"
                    }
                }

                // 2. Modern Angular Wings (Fuel/Battery Left / Temp Right)
                Item {
                    id: chevronFrame
                    anchors.top: gearTextContainer.bottom
                    anchors.topMargin: 20
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 340
                    height: 52

                    // --- FUEL / BATTERY SECTION (LEFT) ---
                    Item {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        width: 170
                        height: parent.height

                        Row {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            spacing: 6

                            FuelIcon {
                                color: "#A0AAB0"
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "FUEL"
                                color: "#A0AAB0"
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 1.2
                                font.family: "Orbitron, sans-serif"
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: Math.round(root.simFuel) + "%"
                                color: root.fuelColor(root.simFuel)
                                font.pixelSize: 13
                                font.bold: true
                                font.family: "Orbitron, sans-serif"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }


                        // Segmented Micro-Bar for Fuel / Battery (Left Side)
                        Row {
                            anchors.left: parent.left
                            anchors.rightMargin: 30 // Increase to push inward, or decrease/set to 0 to push outward
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 6
                            spacing: 3

                            Repeater {
                                model: 6

                                Rectangle {
                                    width: 24
                                    height: 8
                                    radius: 2
                                    transform: Rotation { angle: -12 }

                                    // Zone colors per segment index (Left -> Right)
                                    readonly property var segmentColors: [
                                        "#FF4466", // Index 0: Critical Low (Red)
                                        "#FF8800", // Index 1: Low (Orange)
                                        "#FFCC00", // Index 2: Mid-Low (Yellow)
                                        "#FFCC00", // Index 3: Mid-High (Yellow)
                                        "#00FF88", // Index 4: High (Green)
                                        "#00FF88"  // Index 5: Full (Green)
                                    ]

                                    property color baseColor: segmentColors[index]
                                    // Activates each ~16.6% step (100% / 6)
                                    property bool active: root.simFuel >= ((index + 1) * 16.67)

                                    color: active ? baseColor : "#15FFFFFF"
                                    border.color: active ? Qt.lighter(baseColor, 1.25) : "#10FFFFFF"
                                    border.width: 0.5

                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }
                            }
                        }
                    }

                    // Center Accent Divider
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 8
                        anchors.leftMargin: 4
                        width: 3
                        height: 20
                        color: "#30FFFFFF"
                    }

                    // --- MOTOR TEMP SECTION (RIGHT) ---
                    Item {
                        id: tempSection
                        anchors.right: parent.right
                        anchors.top: parent.top
                        width: 170
                        height: parent.height

                        property color tempColor: {
                            var t = root.simMotorTemp
                            if (t > 105) return "#FF4466"
                            if (t > 90) return "#FFCC00"
                            if (t < 40) return "#00E6FF"
                            return "#00FF88"
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            spacing: 6

                            Text {
                                text: Math.round(root.simMotorTemp) + "°C"
                                color: tempSection.tempColor
                                font.pixelSize: 13
                                font.bold: true
                                font.family: "Orbitron, sans-serif"
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "MOTOR TEMP"
                                color: "#A0AAB0"
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 1.0
                                font.family: "Orbitron, sans-serif"
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            TempIcon {
                                // color: tempSection.tempColor
                                color: "#A0AAB0"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Segmented Micro-Bar for Motor Temperature (Right Side)
                        Row {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 30 // Increase to push inward, or decrease/set to 0 to push outward
                            anchors.bottomMargin: 6
                            spacing: 3

                            Repeater {
                                model: 6

                                Rectangle {
                                    width: 24
                                    height: 8
                                    radius: 2
                                    transform: Rotation { angle: 12 }

                                    // Symmetric zone colors: Extremes are Red, Center is Green
                                    readonly property var segmentColors: [
                                        "#FF4466", // Index 0: Extreme Cold / Low (Red)
                                        "#FFCC00", // Index 1: Warm-up Zone (Yellow)
                                        "#00FF88", // Index 2: Optimal Center (Green)
                                        "#00FF88", // Index 3: Optimal Center (Green)
                                        "#FFCC00", // Index 4: High Warning Zone (Yellow)
                                        "#FF4466"  // Index 5: Overheat Extreme (Red)
                                    ]

                                    property color baseColor: segmentColors[index]
                                    // Activates in 20°C steps up to 120°C scale
                                    property bool active: root.simMotorTemp >= ((index + 1) * 20.0)

                                    color: active ? baseColor : "#15FFFFFF"
                                    border.color: active ? Qt.lighter(baseColor, 1.25) : "#10FFFFFF"
                                    border.width: 0.5

                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }
                            }
                        }
                    }
                }
            }

        }

        // --- RIGHT COLUMN: Tachometer ---
        Item {
            width: parent.width / 3
            height: parent.height

            CircularGauge {
                id: rpmGauge
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height)
                height: width

                value: Math.min(Math.max(root.rpm / 1000, 0), maxValue)
                maxValue: 8
                tickValues: [0, 1, 2, 3, 4, 5, 6, 7, 8]
                decimals: 1
                unit: "x1000"
                // bottomLabel: Math.round(root.simMotorTemp) + "°C"
                bottomLabel: ""
                redlineStartValue: 6
                accentColor: root.currentAccentColor
                trackColor: "#1AFFFFFF"
                panelColor: "transparent"
                borderColor: "#33FFFFFF"
            }
        }
    }

    // -------------------------------------------------------------------------
    // 3. BOTTOM STATUS BAR (RAISED & COMPACT)
    // -------------------------------------------------------------------------
    Item {
        id: bottomBarContainer
        anchors {
            bottom: parent.bottom
            bottomMargin: 25
            horizontalCenter: parent.horizontalCenter
        }
        width: parent.width - 240
        height: 52

        // Outer Background Path
        Shape {
            anchors.fill: parent
            layer.enabled: true
            layer.samples: 4

            ShapePath {
                fillColor: "#F012161F"
                strokeColor: "#3000E6FF" // Subtle cyan highlight border
                strokeWidth: 1.5

                startX: 0; startY: 8
                PathCubic {
                    x: bottomBarContainer.width; y: 8
                    control1X: bottomBarContainer.width * 0.3; control1Y: 20
                    control2X: bottomBarContainer.width * 0.7; control2Y: 20
                }
                PathLine { x: bottomBarContainer.width - 18; y: bottomBarContainer.height }
                PathCubic {
                    x: 18; y: bottomBarContainer.height
                    control1X: bottomBarContainer.width * 0.7; control1Y: bottomBarContainer.height + 12
                    control2X: bottomBarContainer.width * 0.3; control2Y: bottomBarContainer.height + 12
                }
                PathLine { x: 0; y: 8 }
            }
        }

        Item {
            anchors.fill: parent
            anchors.leftMargin: 28
            anchors.rightMargin: 28

            // LEFT: Time & Outside Temp
            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 4
                spacing: 20

                Row {
                    spacing: 8
                    anchors.verticalCenter: parent.verticalCenter

                    ClockIcon {
                        width: 16; height: 16
                        color: "#00E6FF"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        id: clockText
                        color: "#FFFFFF"
                        font.pixelSize: 13
                        font.bold: true
                        font.letterSpacing: 0.8
                        font.family: "Orbitron, sans-serif"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle { width: 1; height: 14; color: "#20FFFFFF"; anchors.verticalCenter: parent.verticalCenter }

                Row {
                    spacing: 8
                    anchors.verticalCenter: parent.verticalCenter

                    OutsideTempIcon {
                        width: 16; height: 16
                        color: "#8A99AD"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: Math.round(root.simOutsideTemp) + "°C"
                        color: "#D0D7DE"
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "Orbitron, sans-serif"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // CENTER: Trip Distance & ETA
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 5
                spacing: 24

                Row {
                    spacing: 8
                    anchors.verticalCenter: parent.verticalCenter

                    TripIcon {
                        width: 16; height: 16
                        color: "#8A99AD"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "TRIP"
                        color: "#8A99AD"
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 1.2
                        font.family: "Orbitron, sans-serif"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: Math.round(root.simDistance) + " km"
                        color: "#FFFFFF"
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "Orbitron, sans-serif"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle { width: 1; height: 14; color: "#30FFFFFF"; anchors.verticalCenter: parent.verticalCenter }

                Row {
                    spacing: 8
                    anchors.verticalCenter: parent.verticalCenter

                    ClockIcon {
                        width: 16; height: 16
                        color: "#8A99AD"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "ETA"
                        color: "#8A99AD"
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 1.2
                        font.family: "Orbitron, sans-serif"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: Math.floor(root.simEtaMin / 60) + "h " + Math.round(root.simEtaMin % 60) + "m"
                        color: "#FFFFFF"
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "Orbitron, sans-serif"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // RIGHT: Fuel / Range
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 4
                spacing: 8

                RangeIcon {
                    width: 16; height: 16
                    color: "#00FF88"
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "RANGE"
                    color: "#8A99AD"
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1.2
                    font.family: "Orbitron, sans-serif"
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: Math.round(root.simRange) + " km"
                    color: "#00FF88"
                    font.pixelSize: 13
                    font.bold: true
                    font.family: "Orbitron, sans-serif"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    LampFailurePopup {
        id: failurePopup
        anchors.fill: parent
        z: 200

        activeWarnings: root.activeLampFaults

        onFaultDismissed: function(faultName) {
            root.acknowledgedFaults[faultName] = true
            var index = root.activeLampFaults.indexOf(faultName)
            if (index !== -1) {
                activeLampFaults.splice(index, 1)
                activeLampFaults = activeLampFaults.slice()
            }
        }
    }

    Rectangle {
        id: dmsAlertPopup
        anchors.centerIn: parent
        width: 360
        height: 210
        radius: 16
        z: 999

        property bool alertActive: root.dmsAlertStatus === 1
        visible: alertActive || opacity > 0
        opacity: alertActive ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
        }

        color: "#E61A0000"
        border.color: "#FF4466"
        border.width: 1.5

        // Inner Glow/Accent Border
        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            radius: 12
            color: "transparent"
            border.color: Qt.alpha("#FF4466", glowAnimation.running ? 0.4 : 0.2)
            border.width: 1
        }

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - 32
            spacing: 8

            // Centered Glowing Caution Sign
            Item {
                Layout.alignment: Qt.AlignHCenter
                width: 50
                height: 50

                // Ambient Glow Backing
                Rectangle {
                    id: glowCircle
                    anchors.centerIn: parent
                    width: 44
                    height: 44
                    radius: 22
                    color: "#FF3355"
                    opacity: 0.2
                    scale: 1.0

                    SequentialAnimation on scale {
                        id: glowAnimation
                        running: dmsAlertPopup.visible
                        loops: Animation.Infinite

                        NumberAnimation { to: 1.35; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                    }

                    SequentialAnimation on opacity {
                        running: dmsAlertPopup.visible
                        loops: Animation.Infinite

                        NumberAnimation { to: 0.6; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0.15; duration: 600; easing.type: Easing.InOutSine }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "⚠️"
                    font.pixelSize: 32
                }
            }

            // Header Title
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "DRIVER WARNING"
                color: "#FFFFFF"
                font.pixelSize: 18
                font.bold: true
                font.letterSpacing: 2
                font.family: "Orbitron, Montserrat, sans-serif"
            }

            // State Detail Text
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: root.dmsStateString.toUpperCase()
                color: "#FFD700"
                font.pixelSize: 13
                font.bold: true
                font.letterSpacing: 1
            }

            // Risk Percentage Badge
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 210
                height: 24
                radius: 12
                color: "#40000000"
                border.color: "#66FF4466"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "DISTRACTION RISK: " + Math.round(root.dmsRiskPercentage * 100) + "%"
                    color: "#FFFFFF"
                    font.pixelSize: 10
                    font.bold: true
                    font.family: "Orbitron, sans-serif"
                }
            }
        }
    }
}
