import QtQuick
import QtQuick.Controls
import QtQuick.Shapes

Item{
    id:root123
}

// Item {
//     id: root

//     property string transmission: "D"
//     property string driveMode: "DRIVE"

//     property real rpm: 2500
//     property real speed: 80
//     property real targetRpm: 2500
//     property real targetSpeed: 80

//     property int gear: 3

//     property real simFuel: 60
//     property real simTemp: 65
//     property real simBattery: 78
//     property real simRange: 318
//     property real simMotorTemp: 42
//     property real simOutsideTemp: 24
//     property real simDistance: 142
//     property real simEtaMin: 105

//     property real odometer: 125483
//     property int simulationTick: 0

//     property bool showMap: false

//     // TPMS values (bar)
//     property real tpmsFL: 2.2
//     property real tpmsFR: 2.2
//     property real tpmsRL: 2.3
//     property real tpmsRR: 2.3

//     // Signal states
//     property bool leftSignal: true
//     property bool rightSignal: false
//     property bool hazardSignal: false

//     // Warning states
//     property bool warningCheckEngine: true
//     property bool warningABS: false
//     property bool warningOil: false
//     property bool warningBattery: false
//     property bool warningHandbrake: true
//     property bool warningDoors: false
//     property bool warningSeatbelt: false

//     // Light states
//     property bool lightLowBeam: true
//     property bool lightHighBeam: false
//     property bool lightFogFront: false
//     property bool lightFogRear: false

//     property color primary     : "#00E68A"
//     property color background  : "#050807"
//     property color surface     : "#0A1110"
//     property color surface2    : "#101918"
//     property color border      : "#18352E"
//     property color text        : "#F6FFFF"
//     property color secondary   : "#8AA7A0"

//     property var modeMap: ({
//         "IDLE": {
//             rpmTarget: 900,
//             speedTarget: 0,
//             color: "#8E82C9"
//         },
//         "DRIVE": {
//             rpmTarget: 2500,
//             speedTarget: 80,
//             color: "#A88BFF"
//         },
//         "SPORT": {
//             rpmTarget: 4500,
//             speedTarget: 130,
//             color: "#C4B6FF"
//         },
//         "REDLINE": {
//             rpmTarget: 7200,
//             speedTarget: 180,
//             color: "#FF7EB8"
//         }
//     })

//     property var transMap: ({
//         "P": { rpmTarget: 900,  speedTarget: 0 },
//         "R": { rpmTarget: 1500, speedTarget: -15 },
//         "N": { rpmTarget: 900,  speedTarget: 0 },
//         "D": { rpmTarget: 2500, speedTarget: 80 }
//     })

//     function applyTargets() {
//         if (transmission === "D") {
//             targetRpm = modeMap[driveMode].rpmTarget
//             targetSpeed = modeMap[driveMode].speedTarget
//         } else {
//             targetRpm = transMap[transmission].rpmTarget
//             targetSpeed = transMap[transmission].speedTarget
//         }
//     }

//     function setMode(mode) {
//         driveMode = mode
//         applyTargets()
//     }

//     function setTransmission(t) {
//         transmission = t
//         applyTargets()
//     }

//     function motorTempColor(t) {
//         if (t > 110 || t < 85) return "#ff4466"
//         if (t >= 90 && t <= 105) return "#00ff88"
//         return "#ffcc00"
//     }

//     function fuelColor(p) {
//         if (p < 25) return "#ff4466"
//         if (p <= 50) return "#ffcc00"
//         return "#00ff88"
//     }

//     function batteryColor(p) {
//         if (p < 20) return "#ff4466"
//         if (p <= 40) return "#ffcc00"
//         return "#00ff88"
//     }

//     function updateClock() {
//         var d = new Date(Date.now() + (3 * 3600 * 1000))
//         var h = d.getHours() % 12 || 12
//         var m = d.getMinutes()
//         clockText.text = (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m
//         ampmText.text = d.getHours() < 12 ? "AM" : "PM"
//     }

//     Component.onCompleted: updateClock()

//     Timer {
//         interval: 1000
//         running: true
//         repeat: true
//         onTriggered: root.updateClock()
//     }

//     Timer {
//         interval: 16
//         running: true
//         repeat: true

//         onTriggered: {
//             simulationTick++

//             var rpmNoise = Math.sin(simulationTick * 0.08) * 80 +
//                            Math.sin(simulationTick * 0.17) * 40
//             var desiredRpm = targetRpm + rpmNoise
//             rpm += (desiredRpm - rpm) * 0.05

//             var speedNoise = Math.sin(simulationTick * 0.03) * 3
//             var desiredSpeed = targetSpeed + speedNoise
//             speed += (desiredSpeed - speed) * 0.03

//             var absSpeed = Math.abs(speed)
//             if (absSpeed < 5) gear = 1
//             else if (absSpeed < 40) gear = 2
//             else if (absSpeed < 80) gear = 3
//             else if (absSpeed < 120) gear = 4
//             else if (absSpeed < 150) gear = 5
//             else gear = 6

//             simFuel = Math.max(0, simFuel - 0.0004 * (rpm / 1000))
//             simRange = Math.max(0, simFuel * 5.3)

//             var targetTemp = 60 + (rpm / 8000) * 40
//             simTemp += (targetTemp - simTemp) * 0.02

//             var targetMotorTemp = 35 + (rpm / 8000) * 25
//             simMotorTemp += (targetMotorTemp - simMotorTemp) * 0.015

//             simBattery = Math.max(0, simBattery - 0.0008 * (rpm / 8000))

//             if (simDistance > 0 && absSpeed > 0)
//                 simDistance = Math.max(0, simDistance - absSpeed / 360000)

//             if (absSpeed > 5 && simDistance > 0)
//                 simEtaMin = Math.min(simEtaMin, simDistance / absSpeed * 60)
//             else if (simDistance <= 0)
//                 simEtaMin = 0

//             odometer += absSpeed / 360000
//         }
//     }

//     property bool leftSignalBlink: false
//     property bool rightSignalBlink: false

//     Timer {
//         id: signalTimer
//         interval: 500
//         running: true
//         repeat: true
//         onTriggered: {
//             var toggle = !leftSignalBlink
//             leftSignalBlink = (leftSignal || hazardSignal) ? toggle : false
//             rightSignalBlink = (rightSignal || hazardSignal) ? toggle : false
//         }
//     }

//     property bool warningFlash: false

//     Timer {
//         id: warningFlashTimer
//         interval: 500
//         running: true
//         repeat: true
//         onTriggered: {
//             warningFlash = !warningFlash
//         }
//     }

//     Rectangle {
//         anchors.fill: parent
//         color: "#04080a"
//     }

//     Background {
//         anchors.fill: parent
//         glowColor: root.modeMap[root.driveMode].color
//     }

//     Row {
//         anchors.fill: parent

//         Item {
//             width: parent.width / 3
//             height: parent.height

//             CircularGauge {
//                 id: speedGauge
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 anchors.top: parent.top
//                 anchors.topMargin: 50

//                 value: Math.abs(root.speed)
//                 maxValue: 180
//                 tickValues: [0, 45, 90, 135, 180]
//                 decimals: 0
//                 unit: "km/h"
//                 bottomLabel: root.transmission
//                 speedLimit: 130
//                 redlineThreshold: 0.9

//                 accentColor: root.modeMap[root.driveMode].color
//             }

//             Column {
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 anchors.bottom: parent.bottom
//                 anchors.bottomMargin: 30
//                 spacing: 10

//                 IconInfoTile {
//                     iconText: "->"
//                     iconColor: "#00E68A"
//                     title: "RANGE"
//                     value: Math.round(root.simRange) + " km"
//                 }
//                 IconInfoTile {
//                     iconText: "M"
//                     iconColor: root.motorTempColor(root.simMotorTemp)
//                     title: "MOTOR"
//                     value: Math.round(root.simMotorTemp) + " °C"
//                     valueColor: root.motorTempColor(root.simMotorTemp)
//                 }
//                 IconInfoTile {
//                     iconText: "F"
//                     iconColor: root.fuelColor(root.simFuel)
//                     title: "FUEL"
//                     value: Math.round(root.simFuel) + " %"
//                     valueColor: root.fuelColor(root.simFuel)
//                 }
//             }
//         }

//         Item {
//             width: parent.width / 3
//             height: parent.height

//             Row {
//                 id: clockRow
//                 anchors.top: parent.top
//                 anchors.topMargin: 35
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 spacing: 8

//                 Text {
//                     id: clockText
//                     color: "#F7F5FF"
//                     font.pixelSize: 44
//                     font.bold: true
//                 }

//                 Text {
//                     id: ampmText
//                     color: "#A88BFF"
//                     font.pixelSize: 15
//                     font.bold: true
//                     anchors.baseline: clockText.baseline
//                 }
//             }

//             // Turn signals
//             Text {
//                 anchors.top: clockRow.bottom
//                 anchors.topMargin: 0
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 anchors.horizontalCenterOffset: -93
//                 text: "◀"
//                 color: (leftSignal || hazardSignal) && leftSignalBlink ? "#00E68A" : "#5A4E5E"
//                 font.pixelSize: 32
//                 font.bold: true
//             }

//             Text {
//                 anchors.top: clockRow.bottom
//                 anchors.topMargin: 0
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 anchors.horizontalCenterOffset: 93
//                 text: "▶"
//                 color: (rightSignal || hazardSignal) && rightSignalBlink ? "#00E68A" : "#5A4E5E"
//                 font.pixelSize: 32
//                 font.bold: true
//             }

//             Item {
//                 id: centerStage
//                 anchors.top: clockRow.bottom
//                 anchors.topMargin: 40
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 width: 360
//                 height: 240

//                 CarOnRoad {
//                     anchors.fill: parent
//                     speed: root.speed
//                     accent: root.modeMap[root.driveMode].color
//                     driveMode: root.driveMode
//                     brakeState: root.simBattery < 30
//                     leftSignal: root.leftSignal || root.hazardSignal
//                     rightSignal: root.rightSignal || root.hazardSignal
//                     leftSignalBlink: root.leftSignalBlink
//                     rightSignalBlink: root.rightSignalBlink
//                     lightBeam: root.lightLowBeam || root.lightHighBeam
//                     visible: !root.showMap
//                 }

//                 Rectangle {
//                     anchors.fill: parent
//                     radius: 12
//                     color: "#0A1418"
//                     border.color: "#3B3552"
//                     visible: root.showMap

//                     Text {
//                         anchors.centerIn: parent
//                         text: "IVI MAP\n(not available)"
//                         color: "#AEA6C5"
//                         font.pixelSize: 14
//                         horizontalAlignment: Text.AlignHCenter
//                     }
//                 }
//             }

//             Row {
//                 id: infoRow
//                 anchors.top: centerStage.bottom
//                 anchors.topMargin: 6
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 spacing: 30

//                 Column {
//                     spacing: 2
//                     Text {
//                         anchors.horizontalCenter: parent.horizontalCenter
//                         text: root.gear
//                         color: "#A88BFF"
//                         font.pixelSize: 22
//                         font.bold: true
//                     }
//                     Text {
//                         anchors.horizontalCenter: parent.horizontalCenter
//                         text: "GEAR"
//                         color: "#AEA6C5"
//                         font.pixelSize: 10
//                     }
//                 }

//                 Column {
//                     spacing: 2
//                     Text {
//                         anchors.horizontalCenter: parent.horizontalCenter
//                         text: Math.round(root.odometer)
//                         color: "#F7F5FF"
//                         font.pixelSize: 22
//                         font.bold: true
//                     }
//                     Text {
//                         anchors.horizontalCenter: parent.horizontalCenter
//                         text: "ODO km"
//                         color: "#AEA6C5"
//                         font.pixelSize: 10
//                     }
//                 }
//             }

//             // Indicators section
//             Item {
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 anchors.bottom: parent.bottom
//                 anchors.bottomMargin: 60
//                 width: parent.width
//                 height: 110

//                 Column {
//                     anchors.horizontalCenter: parent.horizontalCenter
//                     spacing: 10

//                     Row {
//                         anchors.horizontalCenter: parent.horizontalCenter
//                         spacing: 16

//                         TPMSIcon { label: "FL"; pressure: root.tpmsFL; color: root.tpmsFL >= 2.0 && root.tpmsFL <= 2.5 ? "#00E68A" : "#FF4466" }
//                         TPMSIcon { label: "FR"; pressure: root.tpmsFR; color: root.tpmsFR >= 2.0 && root.tpmsFR <= 2.5 ? "#00E68A" : "#FF4466" }
//                         TPMSIcon { label: "RL"; pressure: root.tpmsRL; color: root.tpmsRL >= 2.0 && root.tpmsRL <= 2.5 ? "#00E68A" : "#FF4466" }
//                         TPMSIcon { label: "RR"; pressure: root.tpmsRR; color: root.tpmsRR >= 2.0 && root.tpmsRR <= 2.5 ? "#00E68A" : "#FF4466" }
//                     }

//                     Row {
//                         anchors.horizontalCenter: parent.horizontalCenter
//                         spacing: 8

//                         LightIcon { iconType: "lowBeam"; active: root.lightLowBeam; iconColor: "#A88BFF" }
//                         LightIcon { iconType: "highBeam"; active: root.lightHighBeam; iconColor: "#00E68A" }

//                         Rectangle { width: 1; height: 28; color: "#3B3552" }

//                         WarningIcon { iconType: "engine"; active: root.warningCheckEngine; iconColor: "#FF4466"; warningFlash: root.warningFlash }
//                         WarningIcon { iconType: "oil"; active: root.warningOil; iconColor: "#FF4466"; warningFlash: root.warningFlash }
//                         WarningIcon { iconType: "battery"; active: root.warningBattery; iconColor: "#FFCC00"; warningFlash: root.warningFlash }
//                         WarningIcon { iconType: "handbrake"; active: root.warningHandbrake; iconColor: "#FF4466"; warningFlash: root.warningFlash }

//                         Rectangle { width: 1; height: 28; color: "#3B3552" }

//                         WarningIcon { iconType: "door"; active: root.warningDoors; iconColor: "#FFCC00"; warningFlash: root.warningFlash }
//                         WarningIcon { iconType: "seatbelt"; active: root.warningSeatbelt; iconColor: "#FF4466"; warningFlash: root.warningFlash }
//                     }
//                 }
//             }

//             Row {
//                 anchors.bottom: parent.bottom
//                 anchors.bottomMargin: 15
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 spacing: 8

//                 Repeater {
//                     model: ["IDLE", "DRIVE", "SPORT", "REDLINE"]
//                     delegate: Rectangle {
//                         width: 82; height: 30; radius: 6
//                         property bool active: root.driveMode === modelData && root.transmission === "D"
//                         color: active ? "#0A2A2A" : "#0A1418"
//                         border.color: active ? root.modeMap[modelData].color : "#3B3552"
//                         border.width: 1
//                         opacity: root.transmission === "D" ? 1.0 : 0.4

//                         Text {
//                             anchors.centerIn: parent
//                             text: modelData
//                             color: parent.active ? root.modeMap[modelData].color : "#AEA6C5"
//                             font.pixelSize: 10
//                             font.bold: true
//                         }

//                         MouseArea {
//                             anchors.fill: parent
//                             onClicked: if (root.transmission === "D") root.setMode(modelData)
//                         }
//                     }
//                 }
//             }
//         }

//         Item {
//             width: parent.width / 3
//             height: parent.height

//             CircularGauge {
//                 id: rpmGauge
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 anchors.top: parent.top
//                 anchors.topMargin: 50

//                 value: root.rpm / 1000
//                 maxValue: 8
//                 tickValues: [0, 2, 4, 6, 8]
//                 decimals: 1
//                 unit: "x1000"
//                 bottomLabel: Math.round(root.simMotorTemp) + "°C"
//                 redlineThreshold: 0.85

//                 accentColor: root.modeMap[root.driveMode].color
//             }

//             Column {
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 anchors.bottom: parent.bottom
//                 anchors.bottomMargin: 30
//                 spacing: 10

//                 IconInfoTile {
//                     iconText: "W"
//                     iconColor: "#FFCC00"
//                     title: "WEATHER"
//                     value: Math.round(root.simOutsideTemp) + " °C"
//                 }
//                 IconInfoTile {
//                     iconText: "D"
//                     iconColor: "#00E5FF"
//                     title: "DST"
//                     value: Math.round(root.simDistance) + " km"
//                 }
//                 IconInfoTile {
//                     iconText: "E"
//                     iconColor: "#A88BFF"
//                     title: "ETA"
//                     value: Math.floor(root.simEtaMin / 60) + "h " +
//                            Math.round(root.simEtaMin % 60) + "m"
//                 }
//             }
//         }
//     }
// }


// import QtQuick
// import QtQuick.Controls
// import QtQuick.Shapes

// Item {
//     id: root

//     property string transmission: "D"
//     property string driveMode: "DRIVE"

//     property real rpm: 2500
//     property real speed: 80
//     property real targetRpm: 2500
//     property real targetSpeed: 80

//     property int gear: 3

//     property real simFuel: 60
//     property real simTemp: 65
//     property real simBattery: 78
//     property real simRange: 318
//     property real simMotorTemp: 42
//     property real simOutsideTemp: 24
//     property real simDistance: 142
//     property real simEtaMin: 105

//     property real odometer: 125483
//     property int simulationTick: 0

//     property bool showMap: false

//     // TPMS values (bar)
//     property real tpmsFL: 2.2
//     property real tpmsFR: 2.2
//     property real tpmsRL: 2.3
//     property real tpmsRR: 2.3

//     // Signal states
//     property bool leftSignal: true
//     property bool rightSignal: false
//     property bool hazardSignal: false

//     // Warning states
//     property bool warningCheckEngine: true
//     property bool warningABS: false
//     property bool warningOil: false
//     property bool warningBattery: false
//     property bool warningHandbrake: true
//     property bool warningDoors: false
//     property bool warningSeatbelt: false

//     // Light states
//     property bool lightLowBeam: true
//     property bool lightHighBeam: false
//     property bool lightFogFront: false
//     property bool lightFogRear: false

//     property color primary     : "#00E68A"
//     property color background  : "#050807"
//     property color surface     : "#0A1110"
//     property color surface2    : "#101918"
//     property color border      : "#18352E"
//     property color text        : "#F6FFFF"
//     property color secondary   : "#8AA7A0"

//     property var modeMap: ({
//                               "IDLE": {
//                                   rpmTarget: 900,
//                                   speedTarget: 0,
//                                   color: "#8E82C9"
//                               },

//                               "DRIVE": {
//                                   rpmTarget: 2500,
//                                   speedTarget: 80,
//                                   color: "#A88BFF"
//                               },

//                               "SPORT": {
//                                   rpmTarget: 4500,
//                                   speedTarget: 130,
//                                   color: "#C4B6FF"
//                               },

//                               "REDLINE": {
//                                   rpmTarget: 7200,
//                                   speedTarget: 180,
//                                   color: "#FF7EB8"
//                               }
//                           })

//     property var transMap: ({
//                               "P": { rpmTarget: 900,  speedTarget: 0 },
//                               "R": { rpmTarget: 1500, speedTarget: -15 },
//                               "N": { rpmTarget: 900,  speedTarget: 0 },
//                               "D": { rpmTarget: 2500, speedTarget: 80 }
//                           })

//     function applyTargets() {
//         if (transmission === "D") {
//             targetRpm = modeMap[driveMode].rpmTarget
//             targetSpeed = modeMap[driveMode].speedTarget
//         } else {
//             targetRpm = transMap[transmission].rpmTarget
//             targetSpeed = transMap[transmission].speedTarget
//         }
//     }

//     function setMode(mode) {
//         driveMode = mode
//         applyTargets()
//     }

//     function setTransmission(t) {
//         transmission = t
//         applyTargets()
//     }

//     function motorTempColor(t) {
//         if (t > 110 || t < 85) return "#ff4466"
//         if (t >= 90 && t <= 105) return "#00ff88"
//         return "#ffcc00"
//     }

//     function fuelColor(p) {
//         if (p < 25) return "#ff4466"
//         if (p <= 50) return "#ffcc00"
//         return "#00ff88"
//     }

//     function batteryColor(p) {
//         if (p < 20) return "#ff4466"
//         if (p <= 40) return "#ffcc00"
//         return "#00ff88"
//     }

//     Timer {
//         interval: 1000
//         running: true
//         repeat: true
//         onTriggered: {
//             var d = new Date(Date.now() + (3 * 3600 * 1000))
//             var h = d.getHours() % 12 || 12
//             var m = d.getMinutes()
//             clockText.text = (h < 10 ? "0" : "") + h + ":" +
//                              (m < 10 ? "0" : "") + m
//             ampmText.text = d.getHours() < 12 ? "AM" : "PM"
//         }
//     }

//     Timer {
//         interval: 16
//         running: true
//         repeat: true

//         onTriggered: {
//             simulationTick++

//             var rpmNoise = Math.sin(simulationTick * 0.08) * 80 +
//                            Math.sin(simulationTick * 0.17) * 40
//             var desiredRpm = targetRpm + rpmNoise
//             rpm += (desiredRpm - rpm) * 0.05

//             var speedNoise = Math.sin(simulationTick * 0.03) * 3
//             var desiredSpeed = targetSpeed + speedNoise
//             speed += (desiredSpeed - speed) * 0.03

//             var absSpeed = Math.abs(speed)
//             if (absSpeed < 5) gear = 1
//             else if (absSpeed < 40) gear = 2
//             else if (absSpeed < 80) gear = 3
//             else if (absSpeed < 120) gear = 4
//             else if (absSpeed < 150) gear = 5
//             else gear = 6

//             simFuel = Math.max(0, simFuel - 0.0004 * (rpm / 1000))
//             simRange = Math.max(0, simFuel * 5.3)

//             var targetTemp = 60 + (rpm / 8000) * 40
//             simTemp += (targetTemp - simTemp) * 0.02

//             var targetMotorTemp = 35 + (rpm / 8000) * 25
//             simMotorTemp += (targetMotorTemp - simMotorTemp) * 0.015

//             simBattery = Math.max(0, simBattery - 0.0008 * (rpm / 8000))

//             if (simDistance > 0 && absSpeed > 0)
//                 simDistance = Math.max(0, simDistance - absSpeed / 360000)

//             if (absSpeed > 5 && simDistance > 0)
//                 simEtaMin = Math.min(simEtaMin, simDistance / absSpeed * 60)
//             else if (simDistance <= 0)
//                 simEtaMin = 0

//             odometer += absSpeed / 360000
//         }
//     }

//     Timer {
//         id: signalTimer
//         interval: 500
//         running: true
//         repeat: true
//         onTriggered: {
//             if (leftSignal || rightSignal || hazardSignal) {
//                 leftSignal ? leftSignalBlink = !leftSignalBlink : leftSignalBlink = false
//                 rightSignal ? rightSignalBlink = !rightSignalBlink : rightSignalBlink = false
//             }
//         }
//     }

//     property bool leftSignalBlink: false
//     property bool rightSignalBlink: false

//     Timer {
//         id: warningFlashTimer
//         interval: 500
//         running: true
//         repeat: true
//         onTriggered: {
//             warningFlash = !warningFlash
//         }
//     }

//     property bool warningFlash: false

//     // Reusable component definitions (Scaled 1.7x)
//     Component {
//         id: warningIconComponent
//         Item {
//             width: 48    // 28 * 1.7
//             height: 48   // 28 * 1.7

//             property string icon: "!"
//             property bool active: false
//             property color color: "#FF4466"
//             property string tooltip: ""

//             Rectangle {
//                 anchors.fill: parent
//                 radius: 10 // 6 * 1.7
//                 color: active ? Qt.rgba(warningFlash ? 1 : 0.5, 0, 0, 0.9) : "#2A1A1A"
//                 border.color: active ? color : "#4A3A3A"
//                 border.width: active ? 3 : 2

//                 Text {
//                     anchors.centerIn: parent
//                     text: icon
//                     color: active ? "white" : "#6A5A5A"
//                     font.pixelSize: icon.length > 1 ? 19 : 24 // 11, 14 * 1.7
//                     font.bold: true
//                 }
//             }

//             Behavior on opacity {
//                 NumberAnimation { duration: 200 }
//             }
//         }
//     }

//     Component {
//         id: lightIconComponent
//         Item {
//             width: 48    // 28 * 1.7
//             height: 48   // 28 * 1.7

//             property string icon: "💡"
//             property bool active: false
//             property color color: "#A88BFF"
//             property string tooltip: ""

//             Rectangle {
//                 anchors.fill: parent
//                 radius: 10 // 6 * 1.7
//                 color: active ? Qt.rgba(color.r, color.g, color.b, 0.3) : "#2A1A1A"
//                 border.color: active ? color : "#4A3A3A"
//                 border.width: active ? 3 : 2

//                 Text {
//                     anchors.centerIn: parent
//                     text: icon
//                     color: active ? color : "#5A4A5A"
//                     font.pixelSize: 24 // 14 * 1.7
//                 }
//             }
//         }
//     }

//     Component {
//         id: tpmsIconComponent
//         Item {
//             width: 119   // 70 * 1.7
//             height: 94   // 55 * 1.7

//             property string label: "FL"
//             property real pressure: 2.2
//             property color color: "#00E68A"

//             Rectangle {
//                 anchors.fill: parent
//                 radius: 14 // 8 * 1.7
//                 color: "#1A1A2A"
//                 border.color: color
//                 border.width: 2

//                 Column {
//                     anchors.centerIn: parent
//                     spacing: 3 // 2 * 1.7

//                     Text {
//                         text: label
//                         color: "#8A8A9A"
//                         font.pixelSize: 17 // 10 * 1.7
//                         font.bold: true
//                     }

//                     Text {
//                         text: pressure.toFixed(1) + " bar"
//                         color: color
//                         font.pixelSize: 24 // 14 * 1.7
//                         font.bold: true
//                     }
//                 }
//             }
//         }
//     }

//     Rectangle {
//         anchors.fill: parent
//         color: "#04080a"
//     }

//     Background {
//         anchors.fill: parent
//         glowColor: root.modeMap[root.driveMode].color
//     }

//     Row {
//         anchors.fill: parent

//         Item {
//             width: parent.width / 3
//             height: parent.height

//             CircularGauge {
//                 id: speedGauge
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 anchors.top: parent.top
//                 anchors.topMargin: 85 // 50 * 1.7

//                 value: Math.abs(root.speed)
//                 maxValue: 180
//                 tickValues: [0, 45, 90, 135, 180]
//                 decimals: 0
//                 unit: "km/h"
//                 bottomLabel: root.transmission
//                 speedLimit: 130
//                 redlineThreshold: 0.9

//                 accentColor: root.modeMap[root.driveMode].color
//             }

//             Column {
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 anchors.bottom: parent.bottom
//                 anchors.bottomMargin: 51 // 30 * 1.7
//                 spacing: 17             // 10 * 1.7

//                 IconInfoTile {
//                     iconText: "->"; iconColor: "#00E68A"
//                     title: "RANGE"; value: Math.round(root.simRange) + " km"
//                 }
//                 IconInfoTile {
//                     iconText: "M"; iconColor: root.motorTempColor(root.simMotorTemp)
//                     title: "MOTOR"; value: Math.round(root.simMotorTemp) + " C"
//                     valueColor: root.motorTempColor(root.simMotorTemp)
//                 }
//                 IconInfoTile {
//                     iconText: "F"; iconColor: root.fuelColor(root.simFuel)
//                     title: "FUEL"; value: Math.round(root.simFuel) + " %"
//                     valueColor: root.fuelColor(root.simFuel)
//                 }
//             }
//         }

//         Item {
//             width: parent.width / 3
//             height: parent.height

//             Row {
//                 id: clockRow
//                 anchors.top: parent.top
//                 anchors.topMargin: 60 // 35 * 1.7
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 spacing: 14            // 8 * 1.7

//                 Text {
//                     id: clockText
//                     text: {
//                         var d = new Date(Date.now() + (3 * 3600 * 1000))
//                         var h = d.getHours() % 12 || 12
//                         var m = d.getMinutes()
//                         return (h < 10 ? "0" : "") + h + ":" +
//                                (m < 10 ? "0" : "") + m
//                     }
//                     color: "#F7F5FF"
//                     font.pixelSize: 75 // 44 * 1.7
//                     font.bold: true
//                 }

//                 Text {
//                     id: ampmText
//                     text: new Date(Date.now() + (3 * 3600 * 1000)).getHours() < 12 ? "AM" : "PM"
//                     color: "#A88BFF"
//                     font.pixelSize: 26 // 15 * 1.7
//                     font.bold: true
//                     anchors.baseline: clockText.baseline
//                 }
//             }

//             // Turn signals - spaced out proportionally
//             Text {
//                 anchors.top: clockRow.bottom
//                 anchors.topMargin: 0
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 anchors.horizontalCenterOffset: -158 // -93 * 1.7
//                 text: "◀"
//                 color: leftSignal && leftSignalBlink ? "#00E68A" : "#5A4E5E"
//                 font.pixelSize: 54; font.bold: true // 32 * 1.7
//             }

//             Text {
//                 anchors.top: clockRow.bottom
//                 anchors.topMargin: 0
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 anchors.horizontalCenterOffset: 158 // 93 * 1.7
//                 text: "▶"
//                 color: rightSignal && rightSignalBlink ? "#00E68A" : "#5A4E5E"
//                 font.pixelSize: 54; font.bold: true // 32 * 1.7
//             }

//             Item {
//                 id: centerStage
//                 anchors.top: clockRow.bottom
//                 anchors.topMargin: 68 // 40 * 1.7
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 width: 547; height: 364 // 360*1.7, 240*1.7

//                 CarOnRoad {
//                     anchors.fill: parent
//                     speed: root.speed
//                     accent: root.modeMap[root.driveMode].color
//                     driveMode: root.driveMode
//                     brakeState: root.simBattery < 30
//                     leftSignal: root.leftSignal
//                     rightSignal: root.rightSignal
//                     leftSignalBlink: root.leftSignalBlink
//                     rightSignalBlink: root.rightSignalBlink
//                     lightBeam: root.lightLowBeam || root.lightHighBeam
//                     visible: !root.showMap
//                 }

//                 Rectangle {
//                     anchors.fill: parent
//                     radius: 20 // 12 * 1.7
//                     color: "#0A1418"
//                     border.color: "#3B3552"
//                     visible: root.showMap

//                     Text {
//                         anchors.centerIn: parent
//                         text: "IVI MAP\n(not available)"
//                         color: "#AEA6C5"
//                         font.pixelSize: 24 // 14 * 1.7
//                         horizontalAlignment: Text.AlignHCenter
//                     }
//                 }
//             }

//             Row {
//                 id: infoRow
//                 anchors.top: centerStage.bottom
//                 anchors.topMargin: 10 // 6 * 1.7
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 spacing: 51            // 30 * 1.7

//                 Column {
//                     spacing: 3 // 2 * 1.7
//                     Text {
//                         anchors.horizontalCenter: parent.horizontalCenter
//                         text: root.gear
//                         color: "#A88BFF"
//                         font.pixelSize: 37; font.bold: true // 22 * 1.7
//                     }
//                     Text {
//                         anchors.horizontalCenter: parent.horizontalCenter
//                         text: "GEAR"
//                         color: "#AEA6C5"
//                         font.pixelSize: 17 // 10 * 1.7
//                     }
//                 }

//                 Column {
//                     spacing: 3 // 2 * 1.7
//                     Text {
//                         anchors.horizontalCenter: parent.horizontalCenter
//                         text: Math.round(root.odometer)
//                         color: "#F7F5FF"
//                         font.pixelSize: 37; font.bold: true // 22 * 1.7
//                     }
//                     Text {
//                         anchors.horizontalCenter: parent.horizontalCenter
//                         text: "ODO km"
//                         color: "#AEA6C5"
//                         font.pixelSize: 17 // 10 * 1.7
//                     }
//                 }
//             }

//             // Indicators section
//             Item {
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 anchors.bottom: parent.bottom
//                 anchors.bottomMargin: 102 // 60 * 1.7
//                 width: parent.width
//                 height: 187               // 110 * 1.7

//                 Column {
//                     anchors.horizontalCenter: parent.horizontalCenter
//                     spacing: 17 // 10 * 1.7

//                     Row {
//                         anchors.horizontalCenter: parent.horizontalCenter
//                         spacing: 27 // 16 * 1.7

//                         TPMSIcon { label: "FL"; pressure: root.tpmsFL; color: root.tpmsFL >= 2.0 && root.tpmsFL <= 2.5 ? "#00E68A" : "#FF4466" }
//                         TPMSIcon { label: "FR"; pressure: root.tpmsFR; color: root.tpmsFR >= 2.0 && root.tpmsFR <= 2.5 ? "#00E68A" : "#FF4466" }
//                         TPMSIcon { label: "RL"; pressure: root.tpmsRL; color: root.tpmsRL >= 2.0 && root.tpmsRL <= 2.5 ? "#00E68A" : "#FF4466" }
//                         TPMSIcon { label: "RR"; pressure: root.tpmsRR; color: root.tpmsRR >= 2.0 && root.tpmsRR <= 2.5 ? "#00E68A" : "#FF4466" }
//                     }

//                     Row {
//                         anchors.horizontalCenter: parent.horizontalCenter
//                         spacing: 14 // 8 * 1.7

//                         LightIcon { iconType: "lowBeam"; active: lightLowBeam; iconColor: "#A88BFF" }
//                         LightIcon { iconType: "highBeam"; active: lightHighBeam; iconColor: "#00E68A" }

//                         Rectangle { width: 2; height: 34; color: "#3B3552" } // 1x28 -> 2x48

//                         WarningIcon { iconType: "engine"; active: warningCheckEngine; iconColor: "#FF4466"; warningFlash: root.warningFlash }
//                         WarningIcon { iconType: "oil"; active: warningOil; iconColor: "#FF4466"; warningFlash: root.warningFlash }
//                         WarningIcon { iconType: "battery"; active: warningBattery; iconColor: "#FFCC00"; warningFlash: root.warningFlash }
//                         WarningIcon { iconType: "handbrake"; active: warningHandbrake; iconColor: "#FF4466"; warningFlash: root.warningFlash }

//                         Rectangle { width: 2; height: 34; color: "#3B3552" } // 1x28 -> 2x48

//                         WarningIcon { iconType: "door"; active: warningDoors; iconColor: "#FFCC00"; warningFlash: root.warningFlash }
//                         WarningIcon { iconType: "seatbelt"; active: warningSeatbelt; iconColor: "#FF4466"; warningFlash: root.warningFlash }
//                     }
//                 }
//             }

//             Row {
//                 anchors.bottom: parent.bottom
//                 anchors.bottomMargin: 26 // 15 * 1.7
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 spacing: 14               // 8 * 1.7

//                 Repeater {
//                     model: ["IDLE", "DRIVE", "SPORT", "REDLINE"]
//                     delegate: Rectangle {
//                         width: 139; height: 51; radius: 10 // 82x30 -> 139x51, radius 6->10
//                         property bool active: root.driveMode === modelData && root.transmission === "D"
//                         color: active ? "#0A2A2A" : "#0A1418"
//                         border.color: active ? root.modeMap[modelData].color : "#3B3552"
//                         border.width: 2
//                         opacity: root.transmission === "D" ? 1.0 : 0.4

//                         Text {
//                             anchors.centerIn: parent
//                             text: modelData
//                             color: parent.active ? root.modeMap[modelData].color : "#AEA6C5"
//                             font.pixelSize: 17; font.bold: true // 10 * 1.7
//                         }

//                         MouseArea {
//                             anchors.fill: parent
//                             onClicked: if (root.transmission === "D") root.setMode(modelData)
//                         }
//                     }
//                 }
//             }
//         }

//         Item {
//             width: parent.width / 3
//             height: parent.height

//             CircularGauge {
//                 id: rpmGauge
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 anchors.top: parent.top
//                 anchors.topMargin: 85 // 50 * 1.7

//                 value: root.rpm / 1000
//                 maxValue: 8
//                 tickValues: [0, 2, 4, 6, 8]
//                 decimals: 1
//                 unit: "x1000"
//                 bottomLabel: Math.round(root.simMotorTemp) + "°C"
//                 redlineThreshold: 0.85

//                 accentColor: root.modeMap[root.driveMode].color
//             }

//             Column {
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 anchors.bottom: parent.bottom
//                 anchors.bottomMargin: 51 // 30 * 1.7
//                 spacing: 17             // 10 * 1.7

//                 IconInfoTile {
//                     iconText: "W"; iconColor: "#FFCC00"
//                     title: "WEATHER"; value: Math.round(root.simOutsideTemp) + " C"
//                 }
//                 IconInfoTile {
//                     iconText: "D"; iconColor: "#00E5FF"
//                     title: "DST"; value: Math.round(root.simDistance) + " km"
//                 }
//                 IconInfoTile {
//                     iconText: "E"; iconColor: "#A88BFF"
//                     title: "ETA"
//                     value: Math.floor(root.simEtaMin / 60) + "h " +
//                            Math.round(root.simEtaMin % 60) + "m"
//                 }
//             }
//         }
//     }
// }
