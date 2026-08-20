// import QtQuick

// Item {
//     id: root

//     property color glowColor: "#A88BFF"
//     property real glowOpacity: 0.045

//     Rectangle {
//         anchors.fill: parent
//         color: "#18151F"
//     }

//     Canvas {
//         id: gridCanvas
//         anchors.fill: parent
//         antialiasing: true

//         onPaint: {
//             var ctx = getContext("2d");
//             ctx.reset();

//             var spacing = 32;
//             ctx.fillStyle = Qt.rgba(0.55, 0.85, 0.9, 0.05);
//             var dotR = 1.1;

//             for (var y = spacing / 2; y < parent.height; y += spacing) {
//                 for (var x = spacing / 2; x < parent.width; x += spacing) {
//                     ctx.beginPath();
//                     ctx.arc(x, y, dotR, 0, 2 * Math.PI);
//                     ctx.fill();
//                 }
//             }
//         }
//     }

//     Canvas {
//         id: glowCanvas
//         anchors.fill: parent
//         antialiasing: true

//         onPaint: {
//             var ctx = getContext("2d");
//             ctx.reset();

//             var cx = parent.width / 2;
//             var cy = parent.height / 2;
//             var maxR = Math.max(parent.width, parent.height) * 0.65;

//             var grad = ctx.createRadialGradient(cx, cy, 0, cx, cy, maxR);
//             var c = root.glowColor;
//             grad.addColorStop(0.0, Qt.rgba(c.r, c.g, c.b, root.glowOpacity));
//             grad.addColorStop(0.5, Qt.rgba(c.r, c.g, c.b, root.glowOpacity * 0.35));
//             grad.addColorStop(1.0, Qt.rgba(c.r, c.g, c.b, 0.0));
//             ctx.fillStyle = grad;
//             ctx.fillRect(0, 0, parent.width, parent.height);
//         }
//     }

//     Canvas {
//             id: horizonCanvas
//             anchors.fill: parent
//             antialiasing: true

//             onPaint: {
//                 var ctx = getContext("2d");
//                 ctx.reset();

//                 var y = parent.height * 0.68; // Adjust height as desired
//                 var c = root.glowColor;

//                 var startX = parent.width * 0.33;
//                 var endX = parent.width * 0.67;
//                 var lineWidth = endX - startX;

//                 // Draw line only in the center stage region
//                 ctx.strokeStyle = Qt.rgba(c.r, c.g, c.b, 0.15);
//                 ctx.lineWidth = 1;
//                 ctx.beginPath();
//                 ctx.moveTo(startX, y);
//                 ctx.lineTo(endX, y);
//                 ctx.stroke();

//                 // Gradient glow contained to center region
//                 var grad = ctx.createLinearGradient(0, y - 50, 0, y);
//                 grad.addColorStop(0.0, Qt.rgba(c.r, c.g, c.b, 0.0));
//                 grad.addColorStop(1.0, Qt.rgba(c.r, c.g, c.b, 0.06));
//                 ctx.fillStyle = grad;
//                 ctx.fillRect(startX, y - 50, lineWidth, 50);
//             }
//         }

//     Canvas {
//         id: vignette
//         anchors.fill: parent
//         onPaint: {
//             var ctx = getContext("2d");
//             ctx.reset();
//             var cx = parent.width / 2;
//             var cy = parent.height / 2;
//             var maxR = Math.sqrt(cx * cx + cy * cy);
//             var grad = ctx.createRadialGradient(cx, cy, maxR * 0.55, cx, cy, maxR);
//             grad.addColorStop(0.0, Qt.rgba(0, 0, 0, 0.0));
//             grad.addColorStop(1.0, Qt.rgba(0, 0, 0, 0.55));
//             ctx.fillStyle = grad;
//             ctx.fillRect(0, 0, parent.width, parent.height);
//         }
//     }

//     onGlowColorChanged: {
//         glowCanvas.requestPaint();
//         horizonCanvas.requestPaint();
//     }
//     Component.onCompleted: {
//         gridCanvas.requestPaint();
//         glowCanvas.requestPaint();
//         horizonCanvas.requestPaint();
//         vignette.requestPaint();
//     }
// }


import QtQuick

Item {
    id: root

    property color glowColor: "#A88BFF"
    property real glowOpacity: 0.08

    Behavior on glowColor {
        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
    }

    // 1. Base Dark Ambient Fill
    Rectangle {
        anchors.fill: parent
        color: "#080B11"
    }

    // 2. Center Stage Ambient Glow
    Rectangle {
        anchors.centerIn: parent
        width: Math.max(parent.width, parent.height) * 1.1
        height: width
        radius: width / 2
        opacity: root.glowOpacity

        gradient: Gradient {
            GradientStop { position: 0.0; color: root.glowColor }
            GradientStop { position: 0.45; color: Qt.rgba(root.glowColor.r, root.glowColor.g, root.glowColor.b, 0.25) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // 3. Dot Grid Matrix
    Grid {
        id: gridMatrix
        anchors.centerIn: parent
        width: root.width
        height: root.height
        spacing: 32

        // Explicitly bind to root dimensions to prevent binding race condition during screen assignment
        readonly property int cols: Math.max(1, Math.ceil(root.width / 32) + 1)
        readonly property int rws: Math.max(1, Math.ceil(root.height / 32) + 1)

        columns: cols
        rows: rws
        opacity: 0.22

        Repeater {
            model: gridMatrix.cols * gridMatrix.rws
            Rectangle {
                width: 2
                height: 2
                radius: 1
                color: "#88AACC"
            }
        }
    }

    // 4. Edge Fade Overlay (Vignette that softens grid near borders)
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.6; color: "transparent" }
            GradientStop { position: 1.0; color: "#080B11" }
        }
    }

    // 5. Center Stage Horizon Glow & Line
    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.50
        width: parent.width * 0.38
        height: 60

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 50
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(root.glowColor.r, root.glowColor.g, root.glowColor.b, 0.12) }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1.5
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.2; color: Qt.rgba(root.glowColor.r, root.glowColor.g, root.glowColor.b, 0.4) }
                GradientStop { position: 0.5; color: Qt.rgba(root.glowColor.r, root.glowColor.g, root.glowColor.b, 0.8) }
                GradientStop { position: 0.8; color: Qt.rgba(root.glowColor.r, root.glowColor.g, root.glowColor.b, 0.4) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }
}
