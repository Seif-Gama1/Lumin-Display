# Digital Cluster

A Qt 6 / QML-based digital instrument cluster for an automotive dashboard. Simulates a real-time car instrument panel with animated gauges, driving modes, turn signals, warning indicators, tire pressure monitoring, and a 2D animated car-on-road visualization.

## Demo

https://github.com/user-attachments/assets/19d6e62f-7f10-42c1-8262-dfeb6ab9b15f

## Features

- **Speedometer** — octagonal gauge, 0–180 km/h, speed limit warning at 130 km/h
- **Tachometer** — octagonal gauge, 0–8000 RPM, redline at 85%
- **Driving modes** — IDLE, DRIVE, SPORT, REDLINE (each changes RPM/speed targets + accent color)
- **Transmission** — P, R, N, D with automatic gear calculation (1–6)
- **Animated car** — 2D top-down car on a perspective road with moving lane dashes, rotating tire treads, headlight beams, brake lights, turn signals, and debris particles
- **Drive mode aura** — pulsing glow behind the car, intensity changes per mode
- **Warning indicators** — 7 indicators (Check Engine, ABS, Oil, Battery, Handbrake, Doors, Seatbelt) with 500 ms flash
- **Light indicators** — Low Beam, High Beam, Fog Front, Fog Rear
- **TPMS** — Tire pressure monitoring for all 4 wheels with color-coded status
- **Info panels** — Range, Motor Temp, Fuel %, Weather, Distance to Destination, ETA
- **Background** — animated grid dots, radial glow matching drive mode color, horizon line, vignette
- **Simulation** — realistic RPM/speed interpolation with sinusoidal noise, fuel consumption, temperature, battery drain, odometer
- **Startup animation** — gauge sweep on load
- **12-hour digital clock** with AM/PM

## UI Overview

```
┌──────────────────────────────────────────────────────────┐
│  ┌──────────┐   ┌────────────────────┐   ┌────────────┐  │
│  │          │   │   ⏰ 12:45 PM       │   │            │  │
│  │ SPEEDO   │   │  ◀  GEAR  ▶        │   │ TACHOMETER │  │
│  │ 130 km/h │   │  ┌──────────────┐  │   │  5.2 x1000 │  │
│  │  ⬡⬡⬡⬡⬡  │   │  │ 🚗 ROAD    │  │   │  ⬡⬡⬡⬡⬡  │  │
│  │          │   │  └──────────────┘  │   │            │  │
│  ├──────────┤   │  ODO 125483 km     │   ├────────────┤  │
│  │ RANGE    │   │                    │   │ WEATHER    │  │
│  │ MOTOR    │   │  [IDLE][DRIVE]     │   │ DST        │  │
│  │ FUEL     │   │  [SPORT][REDLINE]  │   │ ETA        │  │
│  └──────────┘   └────────────────────┘   └────────────┘  │
│  ⚠️ ⚙️ ABS 💧 🔋 🅿 🚪 🔒  💡 🔦 🌫 🌫🔴           │
│  FL 2.2 FR 2.2 RL 2.3 RR 2.3                            │
└──────────────────────────────────────────────────────────┘
```

## Getting Started

### Prerequisites

- Qt 6.5 or later
- CMake 3.16+
- C++ compiler (GCC, Clang, MSVC)

### Build

```bash
# Configure
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=/path/to/Qt/6.x.x/gcc_64

# Build
cmake --build build

# Run
./build/appDigitalCluster
```

Or open `CMakeLists.txt` in Qt Creator and build/run from there.

## Controls

| Control | Action |
|---|---|
| Click **DRIVE** | Normal driving mode (80 km/h target) |
| Click **SPORT** | Performance mode (130 km/h target, faster aura pulse) |
| Click **REDLINE** | Max performance (180 km/h target, gauge redline glow) |
| Click **IDLE** | Parked mode (900 RPM, 0 km/h) |

Drive mode buttons work only when transmission is in **D**.

## Architecture

The project is pure QML/JavaScript with a minimal C++ entry point (`main.cpp` — 18 lines).

```
DigitalCluster/
├── main.cpp                  # C++ entry point
├── Main.qml                  # Root window (1280x720)
├── ClusterScreen.qml         # Main cluster layout + simulation
├── components/
│   ├── CircularGauge.qml     # Octagonal gauge (speedo/tacho)
│   ├── Background.qml        # Animated background
│   ├── CarOnRoad.qml         # 2D car + road animation
│   ├── MiniGauge.qml         # Small arc gauge
│   ├── IconInfoTile.qml      # Info tile with icon
│   ├── InfoTile.qml          # Simple info tile
│   ├── WarningIcon.qml       # Warning indicator
│   ├── LightIcon.qml         # Light status indicator
│   └── TPMSIcon.qml          # Tire pressure indicator
├── CMakeLists.txt
└── README.md
```

### Simulation

A 16 ms timer drives the simulation loop:
- RPM and speed interpolate toward targets with sinusoidal noise
- Fuel decreases proportionally to RPM
- Range = fuel × 5.3 km
- Engine/motor temperature responds to load
- Battery drains with RPM
- Distance and ETA update when moving
- Odometer accumulates continuously

### Key Properties

| Property | Type | Description |
|---|---|---|
| `driveMode` | string | IDLE / DRIVE / SPORT / REDLINE |
| `transmission` | string | P / R / N / D |
| `speed` | real | Current speed in km/h |
| `rpm` | real | Current RPM / 1000 |
| `lightLowBeam` | bool | Low beam headlights |
| `lightHighBeam` | bool | High beam headlights |
| `showMap` | bool | Toggle car view / map placeholder |

## Dependencies

- Qt 6.5+ (Quick, Quick Controls, Quick Shapes)
- CMake 3.16+
- No external libraries beyond Qt

## License

MIT
