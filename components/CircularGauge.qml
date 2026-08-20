import QtQuick 2.15

Item {
    id: root
    width: 380
    height: 380

    // --- Inputs & Controls ---
    property real value: 0
    property real maxValue: 180
    property var tickValues: [0, 45, 90, 135, 180]
    property int decimals: 0
    property string unit: "km/h"
    property string bottomLabel: ""

    // --- Colors & Styling ---
    property color accentColor: "#A88BFF"
    property color trackColor: "#342E47"
    property color outerTrackColor: Qt.rgba(0.66, 0.55, 1.0, 0.22)
    property color panelColor: "#091211"
    property color borderColor: "#3B3552"

    property color labelColor: "#AEA6C5"
    property color valueColor: "#F7F5FF"
    property color redlineColor: "#FF3366"

    property real redlineStartValue: 220

    // --- Derived Properties & Geometry ---
    readonly property real redlineProgress: maxValue > 0 ? Math.max(0, Math.min(1, redlineStartValue / maxValue)) : 0

    // Smoothed value tracking for live sensor feeds
    property real smoothValue: value
    Behavior on smoothValue {
        SmoothedAnimation {
            velocity: 120
            maximumEasingTime: 150
        }
    }

    // Startup Animation
    property real startupPhase: 0
    property bool startupDone: false

    NumberAnimation on startupPhase {
        id: startupAnim
        from: 0.0
        to: 1.0
        duration: 500
        easing.type: Easing.OutCubic
        running: false
        onFinished: {
            root.startupDone = true
            activeCanvas.requestPaint()
        }
    }

    readonly property real cx: width / 2
    readonly property real cy: height / 2 - 10
    readonly property real vr: 128
    readonly property real tubeWidth: 18

    readonly property real outerSpacing: 12
    readonly property real outerWidth: 4
    readonly property real outerRadius: vr + tubeWidth / 2 + outerSpacing + outerWidth / 2

    readonly property var angles: [
        247.5, 202.5, 157.5, 112.5, 67.5, 22.5, 337.5, 292.5
    ]

    function vpos(angleDeg, r) {
        var a = angleDeg * Math.PI / 180;
        return { x: cx + r * Math.cos(a), y: cy - r * Math.sin(a) };
    }

    readonly property var verts: {
        var arr = [];
        for (var i = 0; i < 8; i++) arr.push(vpos(angles[i], vr));
        return arr;
    }

    readonly property var outerVerts: {
        var arr = [];
        for (var i = 0; i < 8; i++) arr.push(vpos(angles[i], outerRadius));
        return arr;
    }

    // Cache edge lengths to prevent redundant Math.sqrt calculations during paint
    readonly property var cachedEdgeLens: {
        var arr = [];
        for (var i = 0; i < 7; i++) {
            var a = verts[i], b = verts[i + 1];
            var dx = b.x - a.x, dy = b.y - a.y;
            arr.push(Math.sqrt(dx * dx + dy * dy));
        }
        return arr;
    }

    readonly property real totalLen: {
        var s = 0;
        for (var i = 0; i < cachedEdgeLens.length; i++) s += cachedEdgeLens[i];
        return s;
    }

    readonly property real progress: {
        if (maxValue <= 0) return 0;
        return Math.min(1.0, Math.max(0, smoothValue) / maxValue);
    }

    readonly property real minorStep: {
        if (tickValues.length < 2 || maxValue <= 0) return 10;
        var step = (tickValues[1] - tickValues[0]) / 5;
        return step > 0 ? step : 10;
    }

    function pointAt(d) {
        var acc = 0;
        for (var i = 0; i < 7; i++) {
            var len = cachedEdgeLens[i];
            if (acc + len >= d) {
                var t = (len > 0) ? (d - acc) / len : 0;
                var a = verts[i], b = verts[i + 1];
                return { x: a.x + t * (b.x - a.x), y: a.y + t * (b.y - a.y) };
            }
            acc += len;
        }
        return verts[7];
    }

    property real currentMinorTickValue: Number.NaN

    onSmoothValueChanged: {
        updateCurrentMinorTick();
        activeCanvas.requestPaint();
    }

    onStartupPhaseChanged: activeCanvas.requestPaint()
    onMaxValueChanged: { updateCurrentMinorTick(); requestFullRepaint(); }
    onTickValuesChanged: { updateCurrentMinorTick(); requestFullRepaint(); }
    onAccentColorChanged: activeCanvas.requestPaint()
    onTrackColorChanged: staticCanvas.requestPaint()
    onWidthChanged: requestFullRepaint()
    onHeightChanged: requestFullRepaint()
    onRedlineStartValueChanged: activeCanvas.requestPaint()

    function requestFullRepaint() {
        staticCanvas.requestPaint();
        activeCanvas.requestPaint();
    }

    function updateCurrentMinorTick() {
        var val = smoothValue;
        var step = minorStep;
        if (step > 0 && maxValue > 0) {
            var rounded = Math.round(val / step) * step;
            var isMajor = false;
            for (var i = 0; i < tickValues.length; i++) {
                if (Math.abs(rounded - tickValues[i]) < 0.001) {
                    isMajor = true;
                    break;
                }
            }
            var newMinor = isMajor ? Number.NaN : rounded;
            if (newMinor !== currentMinorTickValue) {
                currentMinorTickValue = newMinor;
                staticCanvas.requestPaint(); // Re-render minor ticks highlight only on step threshold change
            }
        } else {
            if (!isNaN(currentMinorTickValue)) {
                currentMinorTickValue = Number.NaN;
                staticCanvas.requestPaint();
            }
        }
    }

    Component.onCompleted: {
        startupAnim.start();
        requestFullRepaint();
    }

    // Helper drawing routine shared by segment painting
    function drawSegment(ctx, dStart, dEnd, startCap, endCap) {
        var segLen = dEnd - dStart;
        if (segLen <= 0.01) return;

        ctx.save();
        ctx.beginPath();
        var acc = 0;
        var started = false;

        for (var j = 0; j < 7; j++) {
            var len = root.cachedEdgeLens[j];
            var segStart = acc;
            var segEnd = acc + len;

            if (dEnd > segStart && dStart < segEnd) {
                var t0 = Math.max(0, (dStart - segStart) / len);
                var t1 = Math.min(1, (dEnd - segStart) / len);

                var a = root.verts[j], b = root.verts[j + 1];
                var p0 = { x: a.x + t0 * (b.x - a.x), y: a.y + t0 * (b.y - a.y) };
                var p1 = { x: a.x + t1 * (b.x - a.x), y: a.y + t1 * (b.y - a.y) };

                if (!started) {
                    ctx.moveTo(p0.x, p0.y);
                    started = true;
                }
                ctx.lineTo(p1.x, p1.y);
            }
            acc += len;
        }

        ctx.lineCap = startCap || "round";
        ctx.stroke();
        ctx.restore();
    }

    // =========================================================================
    // 1. STATIC CANVAS (Outer Ring, Track Background, & Minor Ticks)
    // Paints ONLY when setup/geometry/ticks change — 0 CPU load during live animation
    // =========================================================================
    Canvas {
        id: staticCanvas
        anchors.fill: parent
        antialiasing: true
        renderTarget: Canvas.Image
        renderStrategy: Canvas.Threaded

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.lineJoin = "round";

            // A. Outer Ring
            ctx.strokeStyle = root.outerTrackColor;
            ctx.lineWidth = root.outerWidth;
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.moveTo(outerVerts[0].x, outerVerts[0].y);
            for (var k = 1; k < 8; k++) ctx.lineTo(outerVerts[k].x, outerVerts[k].y);
            ctx.stroke();

            // B. Track Background
            ctx.strokeStyle = root.trackColor;
            ctx.lineWidth = root.tubeWidth;
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.moveTo(verts[0].x, verts[0].y);
            for (var i = 1; i < 8; i++) ctx.lineTo(verts[i].x, verts[i].y);
            ctx.stroke();

            // C. Minor Ticks
            if (root.minorStep > 0 && root.maxValue > 0) {
                ctx.lineCap = "round";
                for (var v = 0; v <= root.maxValue + 0.001; v += root.minorStep) {
                    var isMajor = false;
                    for (var m = 0; m < root.tickValues.length; m++) {
                        if (Math.abs(v - root.tickValues[m]) < 0.001) { isMajor = true; break; }
                    }
                    if (isMajor) continue;

                    var mp = v / root.maxValue;
                    var mpos = root.pointAt(mp * root.totalLen);
                    var mdx = mpos.x - root.cx;
                    var mdy = mpos.y - root.cy;
                    var mmag = Math.sqrt(mdx * mdx + mdy * mdy) || 1;
                    var mnx = mdx / mmag;
                    var mny = mdy / mmag;

                    var isCurrentTick = !isNaN(root.currentMinorTickValue) && Math.abs(v - root.currentMinorTickValue) < (root.minorStep / 2);
                    var tickOpacity = isCurrentTick ? 0.80 : 0.25;
                    var tickWidth = isCurrentTick ? 1.5 : 1.0;
                    var tickLen = isCurrentTick ? 5 : 3;

                    ctx.strokeStyle = Qt.rgba(0.7, 0.75, 0.9, tickOpacity);
                    ctx.lineWidth = tickWidth;

                    var sx = mpos.x - mnx * (root.tubeWidth / 2);
                    var sy = mpos.y - mny * (root.tubeWidth / 2);
                    var ex = sx - mnx * tickLen;
                    var ey = sy - mny * tickLen;

                    ctx.beginPath();
                    ctx.moveTo(sx, sy);
                    ctx.lineTo(ex, ey);
                    ctx.stroke();
                }
            }
        }
    }

    // =========================================================================
    // 2. DYNAMIC CANVAS (Active Progress Arc & Faux-Glow Redline)
    // Only re-draws active segments. Zero software blur overhead.
    // =========================================================================
    Canvas {
        id: activeCanvas
        anchors.fill: parent
        antialiasing: true
        renderTarget: Canvas.Image
        renderStrategy: Canvas.Threaded

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.lineJoin = "round";

            var effectiveProgress = root.startupDone ? root.progress : (root.progress * root.startupPhase);
            var totalD = effectiveProgress * root.totalLen;
            var redlineD = root.redlineProgress * root.totalLen;

            if (totalD <= 0.001) return;

            var normalD = Math.min(totalD, redlineD);
            var isPastRedline = totalD > redlineD;

            // --- Normal Zone Active Stroke ---
            if (normalD > 0) {
                // Outer soft halo (Pass 1)
                ctx.strokeStyle = Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12);
                ctx.lineWidth = root.tubeWidth + 12;
                root.drawSegment(ctx, 0, normalD, "round", isPastRedline ? "butt" : "round");

                // Inner core stroke (Pass 2)
                ctx.strokeStyle = root.accentColor;
                ctx.lineWidth = root.tubeWidth;
                root.drawSegment(ctx, 0, normalD, "round", isPastRedline ? "butt" : "round");
            }

            // --- Redline Zone Active Stroke (Faux-Glow Concentric Pass) ---
            if (isPastRedline) {
                // Faux Glow Pass 1: Wide low-opacity aura
                ctx.strokeStyle = Qt.rgba(1.0, 0.2, 0.4, 0.10);
                ctx.lineWidth = root.tubeWidth + 14;
                root.drawSegment(ctx, redlineD, totalD, "butt", "round");

                // Faux Glow Pass 2: Medium intensity mid-ring
                ctx.strokeStyle = Qt.rgba(1.0, 0.2, 0.4, 0.25);
                ctx.lineWidth = root.tubeWidth + 6;
                root.drawSegment(ctx, redlineD, totalD, "butt", "round");

                // Core Pass 3: Vivid Solid Redline Stroke
                ctx.strokeStyle = "#FF2A55";
                ctx.lineWidth = root.tubeWidth;
                root.drawSegment(ctx, redlineD, totalD, "butt", "round");
            }
        }
    }

    // --- Major Tick Labels ---
    Repeater {
        model: root.tickValues.length
        delegate: Text {
            property real tickValue: root.tickValues[index]
            property real tickProgress: root.maxValue > 0 ? tickValue / root.maxValue : 0
            property var pos: root.pointAt(tickProgress * root.totalLen)
            property real dx: pos.x - root.cx
            property real dy: pos.y - root.cy
            property real mag: Math.sqrt(dx * dx + dy * dy) || 1

            x: pos.x - dx / mag * 26 - width / 2
            y: pos.y - dy / mag * 26 - height / 2
            text: tickValue

            color: (tickValue >= root.redlineStartValue) ? root.redlineColor : root.labelColor
            font.pixelSize: 16
            font.bold: true
        }
    }

    // --- Center Value & Unit ---
    Text {
        id: centerValue
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -18

        text: root.smoothValue.toFixed(root.decimals)

        color: (root.smoothValue >= root.redlineStartValue) ? root.redlineColor : root.valueColor
        font.pixelSize: 78
        font.weight: Font.DemiBold
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.cy + 58
        text: root.unit
        color: root.labelColor
        font.pixelSize: 15
        font.weight: Font.Light
        font.letterSpacing: 1
    }

    // --- Bottom Label / Gear Display Box ---
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.cy + 138
        width: 74
        height: 46
        radius: 12
        color: root.panelColor
        border.color: root.bottomLabel !== "" ? root.borderColor : "transparent"
        border.width: 1
        visible: root.bottomLabel !== ""

        Text {
            anchors.centerIn: parent
            text: root.bottomLabel
            color: root.accentColor
            font.pixelSize: 26
            font.weight: Font.Bold
        }
    }
}
