 #!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# --- Configuration ---
QNX_ENV_SCRIPT="$HOME/qnx800/qnxsdp-env.sh"
QT_QNX_INSTALL="/home/seif/workspace/qt_stuff/qt_abdelfattah/qt-qnx-install"
TOOLCHAIN_FILE="$HOME/qnx-aarch64.cmake"
HOST_QT_PATH="$HOME/Qt/6.10.2/gcc_64"
TARGET_IP="10.42.0.112"
TARGET_DEST="root@${TARGET_IP}:/opt/"
BINARY_NAME="appDigitalCluster"

# --- 1. Source QNX SDP Environment ---
if [ -f "$QNX_ENV_SCRIPT" ]; then
    echo "==> Sourcing QNX SDP Environment..."
    source "$QNX_ENV_SCRIPT"
else
    echo "Error: QNX SDP environment file not found at $QNX_ENV_SCRIPT"
    exit 1
fi


# --- 2. Ensure Safe Build Directory ---
BUILD_DIR="build"
if [ ! -d "$BUILD_DIR" ]; then
    echo "==> Creating build directory '$BUILD_DIR'..."
    mkdir -p "$BUILD_DIR"
fi

cd "$BUILD_DIR"
echo "==> Cleaning previous build artifacts in $(pwd)..."
rm -rf ./*


# --- 3. Run Qt CMake Configuration ---
echo "==> Configuring project with qt-cmake..."

"$QT_QNX_INSTALL/bin/qt-cmake" .. \
    -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
    -DCMAKE_PREFIX_PATH="$QT_QNX_INSTALL" \
    -DQT_HOST_PATH="$HOST_QT_PATH"
# --- 4. Build Project ---

echo "==> Building target executable using 10 parallel jobs..."
cmake --build . --parallel 10

# --- 5. Deploy to Target ---

if [ -f "$BINARY_NAME" ]; then
    echo "==> Deploying $BINARY_NAME to $TARGET_IP..."
    scp -O "$BINARY_NAME" "$TARGET_DEST"
    echo "==> Build and deployment completed successfully!"

else
    echo "Error: Executable $BINARY_NAME was not found after build!"
    exit 1
fi 