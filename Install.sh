#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Checking build requirements and dependencies..."

# Function to check if command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}ERROR: $1 not found${NC}"
        return 1
    else
        echo -e "${GREEN}✓${NC} Found $1"
        return 0
    fi
}

# Function to check version
check_version() {
    local cmd=$1
    local min_version=$2
    local version_cmd=$3
    
    if ! command -v "$cmd" &> /dev/null; then
        return 1
    fi
    
    local version=$($version_cmd 2>/dev/null | head -n1)
    echo -e "${GREEN}✓${NC} Found $cmd: $version"
    return 0
}

# Check CMake
if ! check_command "cmake"; then
    echo -e "${YELLOW}Install CMake:${NC}"
    echo "  Ubuntu/Debian: sudo apt install cmake"
    echo "  Arch: sudo pacman -S cmake"
    echo "  Fedora: sudo dnf install cmake"
    exit 1
fi

CMAKE_VERSION=$(cmake --version | head -n1 | grep -oE '[0-9]+\.[0-9]+' | head -n1)
CMAKE_MAJOR=$(echo $CMAKE_VERSION | cut -d. -f1)
CMAKE_MINOR=$(echo $CMAKE_VERSION | cut -d. -f2)
if [ "$CMAKE_MAJOR" -lt 3 ] || ([ "$CMAKE_MAJOR" -eq 3 ] && [ "$CMAKE_MINOR" -lt 16 ]); then
    echo -e "${RED}ERROR: CMake 3.16 or higher required (found $CMAKE_VERSION)${NC}"
    exit 1
fi

# Check C++ compiler
if ! check_command "g++" && ! check_command "clang++"; then
    echo -e "${YELLOW}Install C++ compiler:${NC}"
    echo "  Ubuntu/Debian: sudo apt install build-essential"
    echo "  Arch: sudo pacman -S base-devel"
    echo "  Fedora: sudo dnf install gcc-c++"
    exit 1
fi

# Check Qt6
QT6_FOUND=false
if pkg-config --exists Qt6Core 2>/dev/null; then
    QT6_VERSION=$(pkg-config --modversion Qt6Core)
    echo -e "${GREEN}✓${NC} Found Qt6: $QT6_VERSION"
    QT6_FOUND=true
elif [ -f "/usr/lib/x86_64-linux-gnu/cmake/Qt6/Qt6Config.cmake" ] || [ -f "/usr/lib64/cmake/Qt6/Qt6Config.cmake" ]; then
    echo -e "${GREEN}✓${NC} Found Qt6 (via CMake)"
    QT6_FOUND=true
fi

if [ "$QT6_FOUND" = false ]; then
    echo -e "${RED}ERROR: Qt6 not found${NC}"
    echo -e "${YELLOW}Install Qt6:${NC}"
    echo "  Ubuntu/Debian: sudo apt install qt6-base-dev qt6-base-dev-tools"
    echo "  Arch: sudo pacman -S qt6-base"
    echo "  Fedora: sudo dnf install qt6-qtbase-devel"
    exit 1
fi

# Check KDE Frameworks
KF6_FOUND=true
for framework in CoreAddons Config KIO; do
    if pkg-config --exists "KF6${framework}" 2>/dev/null; then
        VERSION=$(pkg-config --modversion "KF6${framework}")
        echo -e "${GREEN}✓${NC} Found KF6::${framework}: $VERSION"
    elif [ -f "/usr/lib/x86_64-linux-gnu/cmake/KF6${framework}/KF6${framework}Config.cmake" ] || \
         [ -f "/usr/lib64/cmake/KF6${framework}/KF6${framework}Config.cmake" ]; then
        echo -e "${GREEN}✓${NC} Found KF6::${framework} (via CMake)"
    else
        echo -e "${RED}ERROR: KF6::${framework} not found${NC}"
        KF6_FOUND=false
    fi
done

if [ "$KF6_FOUND" = false ]; then
    echo -e "${YELLOW}Install KDE Frameworks 6:${NC}"
    echo "  Ubuntu/Debian: sudo apt install libkf6coreaddons-dev libkf6config-dev libkf6kio-dev"
    echo "  Arch: sudo pacman -S kf6-coreaddons kf6-config kf6-kio"
    echo "  Fedora: sudo dnf install kf6-kcoreaddons-devel kf6-kconfig-devel kf6-kio-devel"
    exit 1
fi

# Check ECM
if pkg-config --exists ECM 2>/dev/null || \
   [ -f "/usr/share/ECM/cmake/ECMConfig.cmake" ] || \
   [ -f "/usr/lib/x86_64-linux-gnu/cmake/ECM/ECMConfig.cmake" ]; then
    echo -e "${GREEN}✓${NC} Found ECM"
else
    echo -e "${YELLOW}WARNING: ECM not found (may be included in KDE Frameworks)${NC}"
fi

# Check required source files
REQUIRED_FILES=(
    "CMakeLists.txt"
    "plugins/providers/nextcloudprovider.cpp"
    "plugins/providers/nextcloudprovider.h"
    "plugins/providers/nextcloudprovider.json"
    "plugins/providers/potdprovider.h"
    "plugins/providers/plasma_potd_export.h"
)

MISSING_FILES=()
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -ne 0 ]; then
    echo -e "${RED}ERROR: Missing required files:${NC}"
    for file in "${MISSING_FILES[@]}"; do
        echo "  - $file"
    done
    exit 1
fi

echo -e "${GREEN}✓${NC} All required source files found"

# Check sudo access (will be needed for installation)
if ! sudo -n true 2>/dev/null; then
    echo -e "${YELLOW}Note: sudo access will be required for installation${NC}"
fi

echo ""
echo -e "${GREEN}All requirements satisfied. Starting build...${NC}"
echo ""

# 1. Pulisci tutto (anche da /usr/local)
sudo rm -f /usr/lib/qt6/plugins/potd/plasma_potd_nextcloudprovider.so
sudo rm -f /usr/lib/qt6/plugins/potd/nextcloudprovider.json
sudo rm -f /usr/local/lib/qt6/plugins/potd/plasma_potd_nextcloudprovider.so
sudo rm -f /usr/local/lib/qt6/plugins/potd/nextcloudprovider.json

# 2. Ricompila e installa
mkdir -p build
cd build
rm -rf *
cmake ..
make -j$(nproc)
sudo make install

# 3. Verifica che sia in /usr/lib (non /usr/local)
ls -la /usr/lib/qt6/plugins/potd/ | grep nextcloud

# 4. Riavvia Plasma
killall plasmashell && kstart plasmashell