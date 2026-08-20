import QtQuick
import QtQuick.Shapes

Item {
    id: root

    width: 360
    height: 240
    clip: true

    property real speed: 0
    property color accent: "#A88BFF"
    property real animProgress: 0
    property real tireSpin: 0
    property bool brakeState: false
    property bool leftSignal: false
    property bool rightSignal: false
    property bool leftSignalBlink: false
    property bool rightSignalBlink: false
    property string driveMode: "DRIVE"
    property bool lightBeam: true
    property real auraPulse: 0

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#201A2D" }
            GradientStop { position: 0.55; color: "#18141F" }
            GradientStop { position: 0.551; color: "#14111A" }
            GradientStop { position: 1.0; color: "#100D14" }
        }
    }

    Repeater {
        model: 24
        delegate: Item {
            property real starSeed: index * 37.0
            property real sx: (starSeed * 13.37) % 1
            property real sy: (starSeed * 7.91) % 1
            x: sx * root.width
            y: sy * (root.height * 0.55)
            width: 2
            height: 2

            Rectangle {
                anchors.centerIn: parent
                width: 1.5
                height: 1.5
                radius: 1
                color: "#7fa9b0"
                opacity: 0.3 + (sx * 0.5)
            }
        }
    }

    Rectangle {
        y: parent.height * 0.55
        width: parent.width
        height: 1
        color: root.accent
        opacity: 0.3
    }

    // Road surface
    Shape {
        anchors.fill: parent
        ShapePath {
            strokeWidth: 0
            fillColor: "#0a0e16"
            PathMove { x: root.width * 0.42; y: root.height * 0.55 }
            PathLine { x: root.width * 0.58; y: root.height * 0.55 }
            PathLine { x: root.width * 1.2;  y: root.height }
            PathLine { x: root.width * -0.2; y: root.height }
            PathLine { x: root.width * 0.42; y: root.height * 0.55 }
        }
    }

    // Road edge lines
    Shape {
        anchors.fill: parent
        opacity: 0.45
        ShapePath {
            strokeWidth: 2
            strokeColor: root.accent
            fillColor: "transparent"
            PathMove { x: root.width * 0.42; y: root.height * 0.55 }
            PathLine { x: root.width * -0.2; y: root.height }
        }
    }

    Shape {
        anchors.fill: parent
        opacity: 0.45
        ShapePath {
            strokeWidth: 2
            strokeColor: root.accent
            fillColor: "transparent"
            PathMove { x: root.width * 0.58; y: root.height * 0.55 }
            PathLine { x: root.width * 1.2; y: root.height }
        }
    }

    // Road dashes
    Repeater {
        model: 8
        delegate: Rectangle {
            property real t: (index / 8 + root.animProgress) % 1
            y: root.height * (0.55 + t * 0.45)
            x: root.width / 2 - width / 2
            width: 3 + t * 8
            height: 4 + t * 24
            radius: 1
            color: "#dfe7f0"
            opacity: t * 0.9
        }
    }

    // Main timer - road animation + tire spin
    Timer {
        interval: 24
        running: true
        repeat: true
        onTriggered: {
            var rate = 0.003 + (Math.abs(root.speed) / 260) * 0.06
            root.animProgress = (root.animProgress + rate) % 1
            root.tireSpin = (root.tireSpin + rate * 3) % 1
            root.auraPulse = (root.auraPulse + 0.04 + rate * 2) % (2 * Math.PI)
        }
    }

    // Drive mode aura
    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 68
        width: 140; height: 100

        Rectangle {
            anchors.centerIn: parent
            width: 100; height: 60
            radius: 30
            color: root.accent
            opacity: root.driveMode === "REDLINE" ? 0.08 : 0.04
            scale: root.driveMode === "REDLINE" ? 1 + Math.sin(root.auraPulse * 2.5) * 0.06
                 : root.driveMode === "SPORT" ? 1 + Math.sin(root.auraPulse * 1.5) * 0.03
                 : 1
        }
    }

    Item {
        id: car
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 75
        width: 110
        height: 70
        transformOrigin: Item.Bottom
        scale: 0.85

        // Ambient underglow
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 60
            width: 60; height: 16
            radius: 8
            color: root.accent
            opacity: root.brakeState ? 0.12 : 0.06
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 62
            width: 40; height: 10
            radius: 5
            color: root.accent
            opacity: root.brakeState ? 0.08 : 0.03
        }

        // Car body
        Shape {
            anchors.fill: parent
            ShapePath {
                strokeWidth: 0
                fillColor: "#40386A"
                PathMove { x: 20; y: 70 }
                PathLine { x: 25; y: 40 }
                PathLine { x: 40; y: 20 }
                PathLine { x: 70; y: 20 }
                PathLine { x: 85; y: 40 }
                PathLine { x: 90; y: 70 }
                PathLine { x: 20; y: 70 }
            }
        }

        // Windshield
        Shape {
            anchors.fill: parent
            ShapePath {
                strokeWidth: 0
                fillColor: "#211C30"
                PathMove { x: 38; y: 38 }
                PathLine { x: 45; y: 24 }
                PathLine { x: 65; y: 24 }
                PathLine { x: 72; y: 38 }
                PathLine { x: 38; y: 38 }
            }
        }

        // Headlights (front)
        Rectangle {
            x: 24; y: 42
            width: 14; height: 4; radius: 1
            color: root.accent; opacity: 0.9
        }
        Rectangle {
            x: 72; y: 42
            width: 14; height: 4; radius: 1
            color: root.accent; opacity: 0.9
        }

        // Left taillight (rear)
        Rectangle {
            x: 18; y: 53
            width: 10; height: 6; radius: 2
            color: root.brakeState ? "#FF4466" : "#661122"
            opacity: root.brakeState ? 1.0 : 0.6
        }
        Rectangle {
            x: 18; y: 53
            width: 10; height: 6; radius: 2
            color: "#FF4466"
            opacity: root.brakeState ? 0.4 : 0
        }

        // Right taillight (rear)
        Rectangle {
            x: 82; y: 53
            width: 10; height: 6; radius: 2
            color: root.brakeState ? "#FF4466" : "#661122"
            opacity: root.brakeState ? 1.0 : 0.6
        }
        Rectangle {
            x: 82; y: 53
            width: 10; height: 6; radius: 2
            color: "#FF4466"
            opacity: root.brakeState ? 0.4 : 0
        }

        // Left rear turn signal
        Rectangle {
            x: 22; y: 55
            width: 6; height: 3; radius: 1
            color: "#FFCC00"
            opacity: root.leftSignal && root.leftSignalBlink ? 1.0 : 0.15
        }

        // Right rear turn signal
        Rectangle {
            x: 82; y: 55
            width: 6; height: 3; radius: 1
            color: "#FFCC00"
            opacity: root.rightSignal && root.rightSignalBlink ? 1.0 : 0.15
        }

        // Left wheel with tread pattern
        Item {
            x: 8; y: 58
            width: 12; height: 16

            Rectangle {
                anchors.fill: parent
                radius: 2
                color: "#0A0A12"
            }

            Repeater {
                model: 5
                delegate: Rectangle {
                    x: 1
                    y: (index * 3 + root.tireSpin * 16) % 16 - 3
                    width: 10; height: 2
                    radius: 1
                    color: "#2A2A3A"
                }
            }
        }

        // Right wheel with tread pattern
        Item {
            x: 90; y: 58
            width: 12; height: 16

            Rectangle {
                anchors.fill: parent
                radius: 2
                color: "#0A0A12"
            }

            Repeater {
                model: 5
                delegate: Rectangle {
                    x: 1
                    y: (index * 3 + root.tireSpin * 16) % 16 - 3
                    width: 10; height: 2
                    radius: 1
                    color: "#2A2A3A"
                }
            }
        }

        // Bottom bar (exhaust/diffuser)
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 64
            width: 26; height: 4; radius: 2
            color: "#3a4354"
        }

        // Particle effects (debris behind wheels)
        Repeater {
            model: 6
            delegate: Rectangle {
                property real life: ((index / 6 + root.animProgress * 2) % 1)
                property bool isLeft: index < 3

                x: isLeft ? 8 : 92
                y: 62 + life * 20
                width: 2 + life * 3
                height: 2 + life * 3
                radius: width / 2
                color: "#AEA6C5"
                opacity: Math.abs(root.speed) > 5 ? (1 - life) * 0.6 : 0
            }
        }

        // Extra particles when braking
        Repeater {
            model: 4
            delegate: Rectangle {
                property real life: ((index / 4 + root.animProgress * 3) % 1)
                property bool isLeft: index < 2

                x: (isLeft ? 8 : 92) + (Math.random() - 0.5) * 6
                y: 64 + life * 15
                width: 1.5 + life * 2
                height: 1.5 + life * 2
                radius: width / 2
                color: "#886644"
                opacity: root.brakeState ? (1 - life) * 0.8 : 0
            }
        }
    }

    // Headlight beam illumination (on top of car and road)
    Item {
            visible: root.lightBeam

            // Left beam cone (shortened top edge to y: 110)
            Shape {
                anchors.fill: parent
                opacity: 0.15
                ShapePath {
                    strokeWidth: 0
                    fillColor: root.accent

                    PathMove { x: 150; y: 145 }
                    PathLine { x: 136; y: 110 } // Shortened from y: 95
                    PathLine { x: 160; y: 110 } // Shortened from y: 95
                    PathLine { x: 158; y: 145 }
                }
            }

            // Right beam cone (shortened top edge to y: 110)
            Shape {
                anchors.fill: parent
                opacity: 0.15
                ShapePath {
                    strokeWidth: 0
                    fillColor: root.accent

                    PathMove { x: 206; y: 145 }
                    PathLine { x: 204; y: 110 } // Shortened from y: 95
                    PathLine { x: 228; y: 110 } // Shortened from y: 95
                    PathLine { x: 214; y: 145 }
                }
            }
        }

    // Item {
    //     visible: root.lightBeam

    //     // Left beam cone
    //     Shape {
    //         anchors.fill: parent
    //         opacity: 0.13
    //         ShapePath {
    //             strokeWidth: 0
    //             fillColor: root.accent
    //             PathMove { x: 226; y: 208 } // (149, 137) * 1.52
    //             PathLine { x: 217; y: 182 } // (143, 120) * 1.52
    //             PathLine { x: 247; y: 182 } // (163, 120) * 1.52
    //             PathLine { x: 240; y: 208 } // (158, 137) * 1.52
    //         }
    //     }

    //     // Right beam cone
    //     Shape {
    //         anchors.fill: parent
    //         opacity: 0.13
    //         ShapePath {
    //             strokeWidth: 0
    //             fillColor: root.accent
    //             PathMove { x: 291; y: 208 } // (192, 137) * 1.52
    //             PathLine { x: 284; y: 182 } // (187, 120) * 1.52
    //             PathLine { x: 314; y: 182 } // (207, 120) * 1.52
    //             PathLine { x: 305; y: 208 } // (201, 137) * 1.52
    //         }
    //     }
    // }
}


// import QtQuick
// import QtQuick.Shapes

// Item {
//     id: root

//     // Scaled parent dimensions (360x240 -> 547x365)
//     width: 547
//     height: 365
//     clip: true

//     property real speed: 0
//     property color accent: "#A88BFF"
//     property real animProgress: 0
//     property real tireSpin: 0
//     property bool brakeState: false
//     property bool leftSignal: false
//     property bool rightSignal: false
//     property bool leftSignalBlink: false
//     property bool rightSignalBlink: false
//     property string driveMode: "DRIVE"
//     property bool lightBeam: true
//     property real auraPulse: 0

//     Rectangle {
//         anchors.fill: parent
//         gradient: Gradient {
//             GradientStop { position: 0.0; color: "#201A2D" }
//             GradientStop { position: 0.55; color: "#18141F" }
//             GradientStop { position: 0.551; color: "#14111A" }
//             GradientStop { position: 1.0; color: "#100D14" }
//         }
//     }

//     Repeater {
//         model: 24
//         delegate: Item {
//             property real starSeed: index * 37.0
//             property real sx: (starSeed * 13.37) % 1
//             property real sy: (starSeed * 7.91) % 1
//             x: sx * root.width
//             y: sy * (root.height * 0.55)
//             width: 3
//             height: 3

//             Rectangle {
//                 anchors.centerIn: parent
//                 width: 2.3
//                 height: 2.3
//                 radius: 1
//                 color: "#7fa9b0"
//                 opacity: 0.3 + (sx * 0.5)
//             }
//         }
//     }

//     Rectangle {
//         y: parent.height * 0.55
//         width: parent.width
//         height: 1.5
//         color: root.accent
//         opacity: 0.3
//     }

//     // Road surface
//     Shape {
//         anchors.fill: parent
//         ShapePath {
//             strokeWidth: 0
//             fillColor: "#0a0e16"
//             PathMove { x: root.width * 0.42; y: root.height * 0.55 }
//             PathLine { x: root.width * 0.58; y: root.height * 0.55 }
//             PathLine { x: root.width * 1.2;  y: root.height }
//             PathLine { x: root.width * -0.2; y: root.height }
//             PathLine { x: root.width * 0.42; y: root.height * 0.55 }
//         }
//     }

//     // Road edge lines
//     Shape {
//         anchors.fill: parent
//         opacity: 0.45
//         ShapePath {
//             strokeWidth: 3
//             strokeColor: root.accent
//             fillColor: "transparent"
//             PathMove { x: root.width * 0.42; y: root.height * 0.55 }
//             PathLine { x: root.width * -0.2; y: root.height }
//         }
//     }

//     Shape {
//         anchors.fill: parent
//         opacity: 0.45
//         ShapePath {
//             strokeWidth: 3
//             strokeColor: root.accent
//             fillColor: "transparent"
//             PathMove { x: root.width * 0.58; y: root.height * 0.55 }
//             PathLine { x: root.width * 1.2; y: root.height }
//         }
//     }

//     // Road dashes
//     Repeater {
//         model: 8
//         delegate: Rectangle {
//             property real t: (index / 8 + root.animProgress) % 1
//             y: root.height * (0.55 + t * 0.45)
//             x: root.width / 2 - width / 2
//             width: 4.5 + t * 12
//             height: 6 + t * 36
//             radius: 1.5
//             color: "#dfe7f0"
//             opacity: t * 0.9
//         }
//     }

//     // Main timer - road animation + tire spin
//     Timer {
//         interval: 24
//         running: true
//         repeat: true
//         onTriggered: {
//             var rate = 0.003 + (Math.abs(root.speed) / 260) * 0.06
//             root.animProgress = (root.animProgress + rate) % 1
//             root.tireSpin = (root.tireSpin + rate * 3) % 1
//             root.auraPulse = (root.auraPulse + 0.04 + rate * 2) % (2 * Math.PI)
//         }
//     }

//     // Drive mode aura
//     Item {
//         anchors.horizontalCenter: parent.horizontalCenter
//         anchors.bottom: parent.bottom
//         anchors.bottomMargin: 103 // 68 * 1.52
//         width: 213; height: 152   // 140x100 * 1.52

//         Rectangle {
//             anchors.centerIn: parent
//             width: 152; height: 91
//             radius: 45
//             color: root.accent
//             opacity: root.driveMode === "REDLINE" ? 0.08 : 0.04
//             scale: root.driveMode === "REDLINE" ? 1 + Math.sin(root.auraPulse * 2.5) * 0.06
//                  : root.driveMode === "SPORT" ? 1 + Math.sin(root.auraPulse * 1.5) * 0.03
//                  : 1
//         }
//     }

//     Item {
//         id: car
//         anchors.horizontalCenter: parent.horizontalCenter
//         anchors.bottom: parent.bottom
//         anchors.bottomMargin: 114 // 75 * 1.52
//         width: 110
//         height: 70
//         transformOrigin: Item.Bottom
//         scale: 1.29 // 0.85 * 1.52 (Scales body, headlights, wheels, and particle origin smoothly together)

//         // Ambient underglow
//         Rectangle {
//             anchors.horizontalCenter: parent.horizontalCenter
//             y: 60
//             width: 60; height: 16
//             radius: 8
//             color: root.accent
//             opacity: root.brakeState ? 0.12 : 0.06
//         }

//         Rectangle {
//             anchors.horizontalCenter: parent.horizontalCenter
//             y: 62
//             width: 40; height: 10
//             radius: 5
//             color: root.accent
//             opacity: root.brakeState ? 0.08 : 0.03
//         }

//         // Car body
//         Shape {
//             anchors.fill: parent
//             ShapePath {
//                 strokeWidth: 0
//                 fillColor: "#40386A"
//                 PathMove { x: 20; y: 70 }
//                 PathLine { x: 25; y: 40 }
//                 PathLine { x: 40; y: 20 }
//                 PathLine { x: 70; y: 20 }
//                 PathLine { x: 85; y: 40 }
//                 PathLine { x: 90; y: 70 }
//                 PathLine { x: 20; y: 70 }
//             }
//         }

//         // Windshield
//         Shape {
//             anchors.fill: parent
//             ShapePath {
//                 strokeWidth: 0
//                 fillColor: "#211C30"
//                 PathMove { x: 38; y: 38 }
//                 PathLine { x: 45; y: 24 }
//                 PathLine { x: 65; y: 24 }
//                 PathLine { x: 72; y: 38 }
//                 PathLine { x: 38; y: 38 }
//             }
//         }

//         // Headlights (front)
//         Rectangle {
//             x: 24; y: 42
//             width: 14; height: 4; radius: 1
//             color: root.accent; opacity: 0.9
//         }
//         Rectangle {
//             x: 72; y: 42
//             width: 14; height: 4; radius: 1
//             color: root.accent; opacity: 0.9
//         }

//         // Left taillight (rear)
//         Rectangle {
//             x: 18; y: 53
//             width: 10; height: 6; radius: 2
//             color: root.brakeState ? "#FF4466" : "#661122"
//             opacity: root.brakeState ? 1.0 : 0.6
//         }
//         Rectangle {
//             x: 18; y: 53
//             width: 10; height: 6; radius: 2
//             color: "#FF4466"
//             opacity: root.brakeState ? 0.4 : 0
//         }

//         // Right taillight (rear)
//         Rectangle {
//             x: 82; y: 53
//             width: 10; height: 6; radius: 2
//             color: root.brakeState ? "#FF4466" : "#661122"
//             opacity: root.brakeState ? 1.0 : 0.6
//         }
//         Rectangle {
//             x: 82; y: 53
//             width: 10; height: 6; radius: 2
//             color: "#FF4466"
//             opacity: root.brakeState ? 0.4 : 0
//         }

//         // Left rear turn signal
//         Rectangle {
//             x: 22; y: 55
//             width: 6; height: 3; radius: 1
//             color: "#FFCC00"
//             opacity: root.leftSignal && root.leftSignalBlink ? 1.0 : 0.15
//         }

//         // Right rear turn signal
//         Rectangle {
//             x: 82; y: 55
//             width: 6; height: 3; radius: 1
//             color: "#FFCC00"
//             opacity: root.rightSignal && root.rightSignalBlink ? 1.0 : 0.15
//         }

//         // Left wheel with tread pattern
//         Item {
//             x: 8; y: 58
//             width: 12; height: 16

//             Rectangle {
//                 anchors.fill: parent
//                 radius: 2
//                 color: "#0A0A12"
//             }

//             Repeater {
//                 model: 5
//                 delegate: Rectangle {
//                     x: 1
//                     y: (index * 3 + root.tireSpin * 16) % 16 - 3
//                     width: 10; height: 2
//                     radius: 1
//                     color: "#2A2A3A"
//                 }
//             }
//         }

//         // Right wheel with tread pattern
//         Item {
//             x: 90; y: 58
//             width: 12; height: 16

//             Rectangle {
//                 anchors.fill: parent
//                 radius: 2
//                 color: "#0A0A12"
//             }

//             Repeater {
//                 model: 5
//                 delegate: Rectangle {
//                     x: 1
//                     y: (index * 3 + root.tireSpin * 16) % 16 - 3
//                     width: 10; height: 2
//                     radius: 1
//                     color: "#2A2A3A"
//                 }
//             }
//         }

//         // Bottom bar (exhaust/diffuser)
//         Rectangle {
//             anchors.horizontalCenter: parent.horizontalCenter
//             y: 64
//             width: 26; height: 4; radius: 2
//             color: "#3a4354"
//         }

//         // Particle effects (debris behind wheels)
//         Repeater {
//             model: 6
//             delegate: Rectangle {
//                 property real life: ((index / 6 + root.animProgress * 2) % 1)
//                 property bool isLeft: index < 3

//                 x: isLeft ? 8 : 92
//                 y: 62 + life * 20
//                 width: 2 + life * 3
//                 height: 2 + life * 3
//                 radius: width / 2
//                 color: "#AEA6C5"
//                 opacity: Math.abs(root.speed) > 5 ? (1 - life) * 0.6 : 0
//             }
//         }

//         // Extra particles when braking
//         Repeater {
//             model: 4
//             delegate: Rectangle {
//                 property real life: ((index / 4 + root.animProgress * 3) % 1)
//                 property bool isLeft: index < 2

//                 x: (isLeft ? 8 : 92) + (Math.random() - 0.5) * 6
//                 y: 64 + life * 15
//                 width: 1.5 + life * 2
//                 height: 1.5 + life * 2
//                 radius: width / 2
//                 color: "#886644"
//                 opacity: root.brakeState ? (1 - life) * 0.8 : 0
//             }
//         }
//     }

//     Item {
//         visible: root.lightBeam

//         // Left beam cone
//         Shape {
//             anchors.fill: parent
//             opacity: 0.13
//             ShapePath {
//                 strokeWidth: 0
//                 fillColor: root.accent
//                 PathMove { x: 236; y: 198 }
//                 PathLine { x: 227; y: 172 }
//                 PathLine { x: 257; y: 172 }
//                 PathLine { x: 250; y: 198 }
//             }
//         }

//         // Right beam cone
//         Shape {
//             anchors.fill: parent
//             opacity: 0.13
//             ShapePath {
//                 strokeWidth: 0
//                 fillColor: root.accent
//                 PathMove { x: 301; y: 198 }
//                 PathLine { x: 294; y: 172 }
//                 PathLine { x: 324; y: 172 }
//                 PathLine { x: 315; y: 198 }
//             }
//         }
//     }
// }
