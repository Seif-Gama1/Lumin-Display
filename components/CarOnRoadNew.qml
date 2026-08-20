import QtQuick

Item {
    id: root
    clip: true


    // =====================================================================
    // Public API (original property names preserved for drop-in replacement)
    // =====================================================================
    property real   speed: 0                    // km/h, >= 0
    property string driveMode: "D"              // NOTE: still unused - see notes
    property string transmission: "D"           // "P" | "R" | "N" | "D"
    property color  accent: "#3B82F6"

    property bool   leftSignal: false
    property bool   rightSignal: false
    property bool flashState: false // Dynamic boolean passed from cluster master clock

    property bool   lightLowBeam: false
    property bool   lightHighBeam: false
    property url    carSource: "qrc:/qt/qml/DigitalCluster/assets/tesla_model_s.png"

    // ---- Tuning knobs ---------------------------------------------------
    property real dashPitchMeters: 12.0     // real-world lane-marking pitch (3 m line + 9 m gap)
    property int  dashCount: 6             // dash slots kept alive along the road
    property int  streakCount: 10           // motion streaks outside the rails
    property real horizonFrac: -0.80       // Pushes vanishing point way up (near-overhead camera)
    property real roadNearHalfFrac: 0.62    // outer rail half-width at the bottom edge
    property real laneRatio: 0.36           // inner divider spread / outer rail spread
    property real roadDepth: 6.7            // far/near depth ratio (bigger = deeper road)
    property real maxPhaseRate: 7.0         // cycles/s clamp (~300 km/h) to avoid strobing

    readonly property bool isReversing: transmission.toUpperCase() === "R"
    readonly property bool hazard: leftSignal && rightSignal



    // In your 3D car tail-light / indicator shader or item:
    property real blinkLevel: ((leftSignal || rightSignal) && flashState) ? 1.0 : 0.0
    Behavior on blinkLevel { NumberAnimation { duration: 120 } } // Smooth fade if desired

    // =====================================================================
    // Speed smoothing
    // =====================================================================
    property real animatedSpeed: Math.max(0, speed)
    Behavior on animatedSpeed {
        NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
    }

    readonly property bool motionActive: animatedSpeed > 0.05

    // =====================================================================
    // Perspective model
    //
    //   z  = depth in "pitch units"; z = 1.0 maps to the bottom edge of the view
    //   s  = 1 / z  -> screen offset from the horizon is linear in s
    //   y  = horizonY + s * (bottomY - horizonY)
    //   half-width = nearHalfWidth * s        (straight rails, by construction)
    //
    // Because y ~ 1/z and z is linear in time, dashes crawl near the horizon
    // and accelerate as they reach the camera. That is the whole "realism" fix.
    // =====================================================================
    readonly property real vanishX:  width * 0.5
    readonly property real horizonY: height * horizonFrac
    readonly property real bottomY:  height                  // s == 1.0

    readonly property real sExit:    1.18                    // just past the bottom edge
    readonly property real zExit:    1.0 / sExit
    readonly property real zHorizon: roadDepth
    readonly property real sHorizon: 1.0 / zHorizon

    readonly property real dashLenZ: (zHorizon - zExit) / dashCount * 0.36
    readonly property real zStart:   zExit - dashLenZ        // wrap point (fully off-screen)
    readonly property real zRange:   zHorizon - zStart

    readonly property real streakLenZ: zRange / streakCount * 0.55

    function projY(s)      { return horizonY + s * (bottomY - horizonY) }
    function outerHalf(s)  { return width * roadNearHalfFrac * s }
    function laneHalf(s)   { return width * roadNearHalfFrac * laneRatio * s }

    function dashZ(i, ph)   { return zHorizon - (((i + ph) / dashCount)   % 1.0) * zRange }
    function streakZ(i, ph) { return zHorizon - (((i + ph) / streakCount) % 1.0) * zRange }

    function hash(i) { var x = Math.sin(i * 127.1 + 311.7) * 43758.5453; return x - Math.floor(x) }

    // =====================================================================
    // Motion clocks
    // One "phase" cycle == one dashPitchMeters of travel, so:
    //     rate [cycles/s] = (v m/s) / pitch = (v km/h) / (3.6 * pitch)
    // This is inversely proportional to duration, which is what makes 20 km/h
    // and 200 km/h both look right.
    // =====================================================================
    readonly property real phaseRate:
        Math.min(maxPhaseRate, animatedSpeed / (3.6 * Math.max(0.5, dashPitchMeters)))

    property real phase: 0.0
    property real streakPhase: 0.0
    property real vibPhase: 0.0
    property real prevSpeed: 0.0
    property real accelEst: 0.0             // km/h per second, low-pass filtered

    // Body vibration: high amplitude / low frequency at a crawl, low amplitude /
    // high frequency at speed. Continuous sine, so amplitude and frequency can
    // change mid-motion without any pop.
    readonly property real vibFreq: Math.min(9.0, 1.1 + animatedSpeed * 0.05)
    readonly property real vibAmp:  motionActive ? (2.3 * Math.exp(-200 / 85) + 0.30) : 0.0
    readonly property real carBob:  vibAmp * (Math.sin(vibPhase * 2 * Math.PI)
                                              + 0.32 * Math.sin(vibPhase * 2 * Math.PI * 2.37))

    // Weight transfer: car settles back under acceleration, forward under braking.
    readonly property real carPitch: {
        var a = accelEst
        var m = Math.min(5.0, Math.sqrt(Math.abs(a)) * 0.9)
        return a < 0 ? -m : m
    }

    property real carBaseOffset: isReversing ? 25 : 20
    Behavior on carBaseOffset { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }

    readonly property color dashColor: isReversing ? "#C084FC" : "#8A7BB0"
    readonly property color glowColor: isReversing ? "#E879F9" : accent

    FrameAnimation {
        id: clock
        running: root.motionActive
        onTriggered: {
            var dt = Math.min(frameTime, 0.05)          // guard against frame hitches
            var dir = root.isReversing ? -1.0 : 1.0

            root.phase       = (root.phase + dir * dt * root.phaseRate + 1.0) % 1.0
            root.streakPhase = (root.streakPhase
                                + dir * dt * root.phaseRate
                                  * (root.dashCount / Math.max(1, root.streakCount)) + 1.0) % 1.0
            root.vibPhase    = (root.vibPhase + dt * root.vibFreq) % 1.0

            var v = root.animatedSpeed
            var raw = (v - root.prevSpeed) / Math.max(dt, 0.001)
            root.accelEst = root.accelEst * 0.88 + raw * 0.12
            root.prevSpeed = v
        }
        onRunningChanged: if (!running) { root.accelEst = 0; root.prevSpeed = root.animatedSpeed }
    }

    // =====================================================================
    // 1. Horizon glow (opacity reacts to speed, so no per-frame repaint)
    // =====================================================================
    Canvas {
        id: horizonGlow
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative
        opacity: 0.55 + 0.45 * Math.min(1.0, root.animatedSpeed / 160)
        Behavior on opacity { NumberAnimation { duration: 300 } }

        property color c: root.glowColor
        onCChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            if (width <= 0 || height <= 0) return

            var g = ctx.createRadialGradient(root.vanishX, root.horizonY, 2,
                                             root.vanishX, root.horizonY, width * 0.40)
            g.addColorStop(0.0, Qt.rgba(c.r, c.g, c.b, 0.30))
            g.addColorStop(0.5, Qt.rgba(c.r, c.g, c.b, 0.09))
            g.addColorStop(1.0, Qt.rgba(c.r, c.g, c.b, 0.0))
            ctx.fillStyle = g
            ctx.fillRect(0, 0, width, height * 0.6)
        }
    }

    // =====================================================================
    // 2. Road surface + outer rails (fully static - painted once)
    // =====================================================================
    Canvas {
        id: roadCanvas
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        property bool rev: root.isReversing
        onRevChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            if (width <= 0 || height <= 0) return

            var yTop = root.projY(root.sHorizon)
            var yBot = root.projY(root.sExit)
            var hTop = root.outerHalf(root.sHorizon)
            var hBot = root.outerHalf(root.sExit)
            var vx   = root.vanishX

            // --- asphalt: subtle darkening toward the camera, for depth ---
            var surf = ctx.createLinearGradient(0, yTop, 0, yBot)
            surf.addColorStop(0.0, "rgba(30, 26, 48, 0.0)")
            surf.addColorStop(0.35, "rgba(24, 21, 40, 0.35)")
            surf.addColorStop(1.0, "rgba(14, 12, 26, 0.65)")
            ctx.fillStyle = surf
            ctx.beginPath()
            ctx.moveTo(vx - hTop, yTop)
            ctx.lineTo(vx + hTop, yTop)
            ctx.lineTo(vx + hBot, yBot)
            ctx.lineTo(vx - hBot, yBot)
            ctx.closePath()
            ctx.fill()

            // --- outer boundary rails ---
            var rail = ctx.createLinearGradient(0, yTop, 0, yBot)
            rail.addColorStop(0.0, "rgba(91, 78, 126, 0.05)")
            rail.addColorStop(0.25, "rgba(125, 110, 165, 0.55)")
            rail.addColorStop(1.0, rev ? "rgba(232, 121, 249, 0.95)"
                                       : "rgba(168, 139, 255, 0.95)")
            ctx.strokeStyle = rail
            ctx.lineCap = "round"

            // width tapers with distance: two strokes approximate a tapered rail
            ctx.lineWidth = 1.0
            ctx.beginPath()
            ctx.moveTo(vx - hTop, yTop); ctx.lineTo(vx - hBot, yBot)
            ctx.moveTo(vx + hTop, yTop); ctx.lineTo(vx + hBot, yBot)
            ctx.stroke()

            var midS = (root.sHorizon + root.sExit) * 0.35
            ctx.lineWidth = 3.0
            ctx.beginPath()
            ctx.moveTo(vx - root.outerHalf(midS), root.projY(midS)); ctx.lineTo(vx - hBot, yBot)
            ctx.moveTo(vx + root.outerHalf(midS), root.projY(midS)); ctx.lineTo(vx + hBot, yBot)
            ctx.stroke()
        }
    }

    // =====================================================================
    // 3. Motion streaks (only meaningful above ~55 km/h)
    // =====================================================================
    Item {
        id: streakLayer
        anchors.fill: parent
        visible: root.animatedSpeed > 55

        Repeater {
            model: root.streakCount
            delegate: Item {
                id: streak
                required property int index
                anchors.fill: parent

                readonly property real side: root.hash(index + 91) > 0.5 ? 1.0 : -1.0
                readonly property real lat:  1.10 + root.hash(index) * 0.70

                readonly property real zRaw:  root.streakZ(index, root.streakPhase)
                readonly property real zNear: Math.max(zRaw, root.zExit)
                readonly property real zFar:  zRaw + root.streakLenZ

                readonly property real sN: 1.0 / zNear
                readonly property real sF: 1.0 / zFar
                readonly property real yN: root.projY(sN)
                readonly property real yF: root.projY(sF)
                readonly property real xN: root.outerHalf(sN) * lat
                readonly property real xF: root.outerHalf(sF) * lat

                readonly property real nearness: (sN - root.sHorizon) / (1.0 - root.sHorizon)
                readonly property real fade:
                    Math.max(0, Math.min(1, nearness / 0.15))
                    * Math.max(0, Math.min(1, (root.animatedSpeed - 55) / 90))
                    * 0.42

                visible: zFar > root.zExit && fade > 0.01

                Rectangle {
                    antialiasing: true
                    color: root.accent
                    opacity: streak.fade
                    radius: height / 2
                    width: Math.hypot(streak.xN - streak.xF, streak.yF - streak.yN)
                    height: Math.max(1.0, Math.min(3.0, 2.6 * streak.sN))
                    x: root.vanishX + streak.side * (streak.xN + streak.xF) * 0.5 - width / 2
                    y: (streak.yN + streak.yF) * 0.5 - height / 2
                    rotation: streak.side * Math.atan2(streak.yF - streak.yN,
                                                       streak.xN - streak.xF) * 180 / Math.PI
                    transformOrigin: Item.Center
                }
            }
        }
    }

    // =====================================================================
    // 4. Dashed lane dividers - GPU-drawn Rectangles, not a per-frame Canvas
    // =====================================================================
    Item {
        id: dashLayer
        anchors.fill: parent

        Repeater {
            model: root.dashCount
            delegate: Item {
                id: dash
                required property int index
                anchors.fill: parent

                readonly property real zRaw:  root.dashZ(index, root.phase)
                readonly property real zNear: Math.max(zRaw, root.zExit)   // clip at the bottom edge
                readonly property real zFar:  zRaw + root.dashLenZ

                readonly property real sN: 1.0 / zNear
                readonly property real sF: 1.0 / zFar
                readonly property real yN: root.projY(sN)
                readonly property real yF: root.projY(sF)
                readonly property real hN: root.laneHalf(sN)
                readonly property real hF: root.laneHalf(sF)

                readonly property real nearness: (sN - root.sHorizon) / (1.0 - root.sHorizon)
                readonly property real fade:
                    Math.max(0, Math.min(1, nearness / 0.10))
                    * (0.30 + 0.60 * Math.pow(Math.max(0, Math.min(1, nearness)), 0.5))

                readonly property real len: Math.hypot(hN - hF, yF - yN)
                readonly property real thick: Math.max(1.2, Math.min(7.0, 6.5 * (sN + sF) * 0.5))
                readonly property real ang: Math.atan2(yF - yN, hN - hF) * 180 / Math.PI

                // fully past the bottom edge -> nothing to draw (no pop: it is off-screen)
                visible: zFar > root.zExit && fade > 0.01

                Rectangle {                          // left divider
                    antialiasing: true
                    color: root.dashColor
                    opacity: dash.fade
                    width: dash.len
                    height: dash.thick
                    radius: height / 2
                    x: root.vanishX - (dash.hN + dash.hF) * 0.5 - width / 2
                    y: (dash.yN + dash.yF) * 0.5 - height / 2
                    rotation: dash.ang
                    transformOrigin: Item.Center
                    Behavior on color { ColorAnimation { duration: 250 } }
                }

                Rectangle {                          // right divider (mirrored)
                    antialiasing: true
                    color: root.dashColor
                    opacity: dash.fade
                    width: dash.len
                    height: dash.thick
                    radius: height / 2
                    x: root.vanishX + (dash.hN + dash.hF) * 0.5 - width / 2
                    y: (dash.yN + dash.yF) * 0.5 - height / 2
                    rotation: -dash.ang
                    transformOrigin: Item.Center
                    Behavior on color { ColorAnimation { duration: 250 } }
                }
            }
        }
    }

    // =====================================================================
    // 5. Speed tunnel vignette
    // =====================================================================
    Item {
        anchors.fill: parent
        opacity: Math.min(1.0, root.animatedSpeed / 170) * 0.75
        Behavior on opacity { NumberAnimation { duration: 350 } }

        Rectangle {
            width: parent.width * 0.22
            height: parent.height
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#0B0A14" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
        Rectangle {
            anchors.right: parent.right
            width: parent.width * 0.22
            height: parent.height
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: "#0B0A14" }
            }
        }
    }

    // =====================================================================
    // 6. Vehicle
    // =====================================================================
    Item {
        id: carWrapper
        width: 100
        height: 155
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.carBaseOffset      // plain binding, never overwritten

        transformOrigin: Item.Center

        scale: 1.0 - Math.min(0.06, (root.animatedSpeed / 220) * 0.06)
        // rotation: root.carLean

        transform: Translate {
            // x: root.carShiftX
            y: root.carBob + root.carPitch
            Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }
        }

        Behavior on scale    { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }
        Behavior on rotation { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }

        // --- Ground glow / underglow (inside the wrapper so it follows the car) ---
        Canvas {
            id: shadowGlow
            width: parent.width * (1.35 + Math.min(0.25, root.animatedSpeed / 400))
            height: parent.height * 0.62
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -8
            z: -1
            renderStrategy: Canvas.Cooperative

            property color c: root.glowColor
            opacity: root.motionActive ? 0.55 : 0.25
            Behavior on opacity { NumberAnimation { duration: 300 } }

            onCChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Component.onCompleted: requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                if (width <= 0 || height <= 0) return
                var r = width / 2
                ctx.save()
                ctx.translate(width / 2, height / 2)
                ctx.scale(1.0, height / width)
                var g = ctx.createRadialGradient(0, 0, 0, 0, 0, r)
                g.addColorStop(0.00, Qt.rgba(c.r, c.g, c.b, 0.55))
                g.addColorStop(0.45, Qt.rgba(c.r, c.g, c.b, 0.22))
                g.addColorStop(1.00, Qt.rgba(c.r, c.g, c.b, 0.0))
                ctx.fillStyle = g
                ctx.beginPath()
                ctx.arc(0, 0, r, 0, Math.PI * 2)
                ctx.fill()
                ctx.restore()
            }
        }

        // =====================================================================
        // --- Low Beam Realistic Light Spot (Shortened) ---
        // =====================================================================
        Item {
            id: lowBeamGroup
            width: parent.width * 2.8
            height: 60 // Reduced container height (was 160)
            anchors.bottom: parent.top
            anchors.bottomMargin: -6 // Touches right under the bumper/light housing
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: root.lightLowBeam && !root.lightHighBeam ? 0.85 : 0.0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 250 } }

            Canvas {
                anchors.fill: parent
                renderStrategy: Canvas.Cooperative

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                Component.onCompleted: requestPaint()

                function drawLowBeamPool(ctx, originX, originY, poolX, poolY, poolRx, poolRy) {
                    ctx.save()

                    // 1. Soft Light Trap/Volumetric Light Beam (connecting headlight to ground pool)
                    ctx.beginPath()
                    ctx.moveTo(originX - 3, originY)
                    ctx.lineTo(poolX - poolRx * 0.85, poolY)
                    ctx.lineTo(poolX + poolRx * 0.85, poolY)
                    ctx.lineTo(originX + 3, originY)
                    ctx.closePath()

                    var beamGrad = ctx.createLinearGradient(0, originY, 0, poolY)
                    beamGrad.addColorStop(0.00, Qt.rgba(1.0, 1.0, 1.0, 0.75))
                    beamGrad.addColorStop(0.30, Qt.rgba(0.60, 0.88, 1.0, 0.25))
                    beamGrad.addColorStop(1.00, Qt.rgba(0.40, 0.80, 1.0, 0.05))
                    ctx.fillStyle = beamGrad
                    ctx.fill()

                    // 2. Projected Ground Elliptical Light Spot
                    ctx.translate(poolX, poolY)
                    ctx.scale(1.0, poolRy / poolRx) // Perspective squash for road surface

                    var spotGrad = ctx.createRadialGradient(0, 0, 0, 0, 0, poolRx)
                    spotGrad.addColorStop(0.00, Qt.rgba(0.95, 0.98, 1.00, 0.70))
                    spotGrad.addColorStop(0.35, Qt.rgba(0.55, 0.85, 1.00, 0.35))
                    spotGrad.addColorStop(0.70, Qt.rgba(0.35, 0.75, 0.98, 0.12))
                    spotGrad.addColorStop(1.00, Qt.rgba(0.35, 0.75, 0.98, 0.00))

                    ctx.fillStyle = spotGrad
                    ctx.beginPath()
                    ctx.arc(0, 0, poolRx, 0, Math.PI * 2)
                    ctx.fill()

                    ctx.restore()
                }

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    if (width <= 0 || height <= 0) return

                    // Headlight origins
                    var leftHL = width * 0.40
                    var rightHL = width * 0.60

                    // Adjusted projection parameters for a tighter beam drop:
                    var poolY = height * 0.22  // Brings the beam center closer to the bumper (was 0.35)
                    var poolRx = width * 0.20  // Slightly tighter horizontal spread (was 0.22)
                    var poolRy = height * 0.20 // Flattens the vertical aspect ratio (was 0.32)

                    drawLowBeamPool(ctx, leftHL, height, width * 0.38, poolY, poolRx, poolRy)
                    drawLowBeamPool(ctx, rightHL, height, width * 0.62, poolY, poolRx, poolRy)
                }
            }
        }

        // =====================================================================
        // --- High Beam (Identical Structure to Low Beam, Taller & Stronger) ---
        // =====================================================================
        Item {
            id: highBeamGroup
            width: parent.width * 3.8
            height: 80 // Keeps the tall height
            anchors.bottom: parent.top
            anchors.bottomMargin: -10
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: root.lightHighBeam ? 0.98 : 0.0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 250 } }

            Canvas {
                anchors.fill: parent
                renderStrategy: Canvas.Cooperative

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                Component.onCompleted: requestPaint()

                // Exact Low Beam drawing function with boosted alpha/intensity
                function drawHighBeamPool(ctx, originX, originY, poolX, poolY, poolRx, poolRy) {
                    ctx.save()

                    // 1. Volumetric Light Beam Cone (Connecting headlight to ground pool)
                    ctx.beginPath()
                    ctx.moveTo(originX - 4, originY)
                    ctx.lineTo(poolX - poolRx * 0.85, poolY)
                    ctx.lineTo(poolX + poolRx * 0.85, poolY)
                    ctx.lineTo(originX + 4, originY)
                    ctx.closePath()

                    var beamGrad = ctx.createLinearGradient(0, originY, 0, poolY)
                    beamGrad.addColorStop(0.00, Qt.rgba(1.0, 1.0, 1.0, 0.90))       // Boosted intensity (was 0.75)
                    beamGrad.addColorStop(0.30, Qt.rgba(0.60, 0.88, 1.0, 0.40))     // Boosted intensity (was 0.25)
                    beamGrad.addColorStop(1.00, Qt.rgba(0.40, 0.80, 1.0, 0.10))     // Boosted intensity (was 0.05)
                    ctx.fillStyle = beamGrad
                    ctx.fill()

                    // 2. Projected Ground Elliptical Light Spot (Exact Low Beam radial gradient profile)
                    ctx.translate(poolX, poolY)
                    ctx.scale(1.0, poolRy / poolRx) // Perspective squash matching low beam

                    var spotGrad = ctx.createRadialGradient(0, 0, 0, 0, 0, poolRx)
                    spotGrad.addColorStop(0.00, Qt.rgba(1.00, 1.00, 1.00, 0.95))     // Strong white core (was 0.70)
                    spotGrad.addColorStop(0.35, Qt.rgba(0.65, 0.90, 1.00, 0.55))     // Strong mid layer (was 0.35)
                    spotGrad.addColorStop(0.70, Qt.rgba(0.45, 0.82, 1.00, 0.22))     // Crisp outer edge "lock" (was 0.12)
                    spotGrad.addColorStop(1.00, Qt.rgba(0.35, 0.75, 0.98, 0.00))

                    ctx.fillStyle = spotGrad
                    ctx.beginPath()
                    ctx.arc(0, 0, poolRx, 0, Math.PI * 2)
                    ctx.fill()

                    ctx.restore()
                }

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    if (width <= 0 || height <= 0) return

                    var leftHL = width * 0.41
                    var rightHL = width * 0.59

                    // Scaled up for the tall 260px container
                    var poolY = height * 0.25  // Reaches further up the screen
                    var poolRx = width * 0.22  // Proportional horizontal spread
                    var poolRy = height * 0.22 // Proportional vertical aspect ratio

                    drawHighBeamPool(ctx, leftHL, height, width * 0.39, poolY, poolRx, poolRy)
                    drawHighBeamPool(ctx, rightHL, height, width * 0.61, poolY, poolRx, poolRy)
                }
            }
        }
        // --- Reverse backup lights ---
        Item {
            id: reverseBackupGlow
            width: parent.width * 1.20
            height: 58
            anchors.top: parent.bottom
            anchors.topMargin: 4
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: root.isReversing ? 0.80 : 0.0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 300 } }

            Canvas {
                id: reverseBeamsCanvas
                anchors.fill: parent
                renderStrategy: Canvas.Cooperative

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                Component.onCompleted: requestPaint()

                function beam(ctx, cx, cy, r, h) {
                    ctx.save()
                    ctx.translate(cx, cy)
                    ctx.scale(1.0, h / (r * 2))
                    var g = ctx.createRadialGradient(0, 0, 1, 0, 0, r)
                    g.addColorStop(0.00, Qt.rgba(1.00, 1.00, 1.00, 0.50))
                    g.addColorStop(0.25, Qt.rgba(0.90, 0.95, 1.00, 0.25))
                    g.addColorStop(0.65, Qt.rgba(0.85, 0.93, 1.00, 0.08))
                    g.addColorStop(1.00, Qt.rgba(0.85, 0.93, 1.00, 0.00))
                    ctx.fillStyle = g
                    ctx.beginPath()
                    ctx.arc(0, 0, r, 0, Math.PI * 2)
                    ctx.fill()
                    ctx.restore()
                }

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    if (width <= 0 || height <= 0) return
                    var r = width * 0.30
                    beam(ctx, width * 0.36, height * 0.30, r, height * 1.5)
                    beam(ctx, width * 0.64, height * 0.30, r, height * 1.5)
                }
            }
        }

        // =====================================================================
        // --- Turn Signal Flares (Updated Margins) ---
        // =====================================================================
        // Front Right
        Flare {
            active: root.rightSignal
            anchors.right: parent.right
            anchors.rightMargin: -7     // Decrease negative number to move towards center
            anchors.top: parent.top
            anchors.topMargin: -8
        }
        // Front Left
        Flare {
            active: root.leftSignal
            anchors.left: parent.left
            anchors.leftMargin: -7      // Decrease negative number to move towards center
            anchors.top: parent.top
            anchors.topMargin: -8
        }
        // =====================================================================
        // Rear Right
        Flare {
            active: root.rightSignal
            anchors.right: parent.right
            anchors.rightMargin: -3       // Decrease negative number to move towards center
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 19
            width: 32
            height: 36
            z: 1
            isRear: true
        }
        // Rear Left
        Flare {
            active: root.leftSignal
            anchors.left: parent.left
            anchors.leftMargin: -3       // Decrease negative number to move towards center
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 19
            width: 32
            height: 36
            z: 1
            isRear: true
        }

        // --- Vehicle image ---
        Image {
            id: carImage
            anchors.fill: parent
            source: root.carSource
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
        }
    }

    // =====================================================================
    // Shared blink clock - keeps left/right in sync for hazards
    // =====================================================================
    // SequentialAnimation {
    //     running: root.leftSignal || root.rightSignal
    //     loops: Animation.Infinite
    //     onRunningChanged: if (!running) root.blinkLevel = 0.0

    //     PropertyAction  { target: root; property: "blinkLevel"; value: 0.0 }
    //     NumberAnimation { target: root; property: "blinkLevel"; to: 1.0; duration: 150
    //                       easing.type: Easing.OutQuad }
    //     PauseAnimation  { duration: 210 }
    //     NumberAnimation { target: root; property: "blinkLevel"; to: 0.0; duration: 190
    //                       easing.type: Easing.InQuad }
    //     PauseAnimation  { duration: 230 }
    // }

    // =====================================================================
    // Realistic Anisotropic Lens Flare Component (blinker light)
    // =====================================================================
    component Flare: Item {
        id: fl
        property bool active: false
        property bool isRear: false
        property color glowColor: "#F59E0B"
        width: 40
        height: 46
        opacity: active ? root.blinkLevel * 0.95 : 0.0
        visible: opacity > 0.01

        Canvas {
            id: flareCanvas
            anchors.fill: parent
            renderStrategy: Canvas.Cooperative

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Component.onCompleted: requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                if (width <= 0 || height <= 0) return

                var cx = width / 2
                var cy = height / 2
                var maxR = Math.max(width, height) / 2

                ctx.save()
                ctx.translate(cx, cy)

                // Oval perspective squash (matches headlight lens contour)
                ctx.scale(1.0, height / width)

                var g = ctx.createRadialGradient(0, 0, 0, 0, 0, maxR)

                // 1. Hot Spot: White LED central light source
                g.addColorStop(0.00, Qt.rgba(1.0, 1.0, 0.9, 0.95))

                // 2. High-intensity Amber core bloom
                g.addColorStop(0.20, Qt.rgba(1.0, 0.65, 0.0, 0.80))

                // 3. Medium diffusion aura
                g.addColorStop(0.55, Qt.rgba(0.96, 0.55, 0.04, 0.35))

                // 4. Soft edge halo falloff
                g.addColorStop(0.85, Qt.rgba(0.96, 0.55, 0.04, 0.08))
                g.addColorStop(1.00, Qt.rgba(0.96, 0.55, 0.04, 0.00))

                ctx.fillStyle = g
                ctx.beginPath()
                ctx.arc(0, 0, maxR, 0, Math.PI * 2)
                ctx.fill()

                ctx.restore()
            }
        }
    }
}
