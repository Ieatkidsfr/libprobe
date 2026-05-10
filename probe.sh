#!/bin/bash
# libprobe - System capability scanner
# https://github.com/Ieatkidsfr/libprobe

VERSION="0.1.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}"
    echo "  _ _ _                    _          "
    echo " | (_) |__ _ __  _ _ ___ | |__  ___  "
    echo " | | | '_ \ '_ \| '_/ _ \| '_ \/ -_) "
    echo " |_|_|_.__/ .__/|_| \___/|_.__/\___| "
    echo "          |_|                          "
    echo -e "${NC}"
    echo "libprobe v$VERSION - System Capability Scanner"
    echo "============================================"
    echo ""
}

check() {
    local name=$1
    local cmd=$2
    if eval "$cmd" &>/dev/null; then
        echo -e "${GREEN}[✓]${NC} $name"
    else
        echo -e "${RED}[✗]${NC} $name"
    fi
}

# OS Detection
detect_os() {
    echo -e "${YELLOW}== OS ==${NC}"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "  Name: $NAME"
        echo "  Version: $VERSION_ID"
        echo "  ID: $ID"
    fi
    echo "  Kernel: $(uname -r)"
    echo "  Arch: $(uname -m)"
    echo ""
}

# Display detection
detect_display() {
    echo -e "${YELLOW}== Display ==${NC}"
    if [ -n "$DISPLAY" ]; then
        echo -e "${GREEN}[✓]${NC} X11 display available ($DISPLAY)"
    else
        echo -e "${RED}[✗]${NC} No X11 display"
    fi
    if [ -n "$WAYLAND_DISPLAY" ]; then
        echo -e "${GREEN}[✓]${NC} Wayland display available ($WAYLAND_DISPLAY)"
    else
        echo -e "${RED}[✗]${NC} No Wayland display"
    fi
    if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
        echo -e "${YELLOW}[!]${NC} Running headless"
    fi
    echo ""
}

# Graphics libraries
detect_graphics() {
    echo -e "${YELLOW}== Graphics Libraries ==${NC}"
    check "OpenGL (glxinfo)" "command -v glxinfo"
    check "Vulkan (vulkaninfo)" "command -v vulkaninfo"
    check "SDL2" "pkg-config --exists sdl2 2>/dev/null || ldconfig -p | grep -q libSDL2"
    check "SFML" "pkg-config --exists sfml-all 2>/dev/null || ldconfig -p | grep -q libsfml"
    check "Allegro5" "pkg-config --exists allegro-5 2>/dev/null || ldconfig -p | grep -q liballegro"
    check "Raylib" "pkg-config --exists raylib 2>/dev/null || ldconfig -p | grep -q libraylib"
    check "Mesa" "ldconfig -p | grep -q libGL"
    check "EGL" "ldconfig -p | grep -q libEGL"
    echo ""
}

# Audio libraries
detect_audio() {
    echo -e "${YELLOW}== Audio Libraries ==${NC}"
    check "ALSA" "ldconfig -p | grep -q libasound"
    check "PulseAudio" "command -v pulseaudio || command -v pactl"
    check "PipeWire" "command -v pipewire"
    check "SDL2 Mixer" "ldconfig -p | grep -q libSDL2_mixer"
    check "OpenAL" "ldconfig -p | grep -q libopenal"
    check "PortAudio" "ldconfig -p | grep -q libportaudio"
    echo ""
}

# Languages
detect_languages() {
    echo -e "${YELLOW}== Languages & Runtimes ==${NC}"
    check "Python3" "command -v python3"
    check "Python2" "command -v python2"
    check "Rust (cargo)" "command -v cargo"
    check "C (gcc)" "command -v gcc"
    check "C++ (g++)" "command -v g++"
    check "Clang" "command -v clang"
    check "Go" "command -v go"
    check "Java" "command -v java"
    check "Node.js" "command -v node"
    check "Ruby" "command -v ruby"
    check "Lua" "command -v lua || command -v lua5.4 || command -v lua5.3"
    echo ""
}

# Game/multimedia frameworks
detect_frameworks() {
    echo -e "${YELLOW}== Game & Multimedia Frameworks ==${NC}"
    check "FFmpeg" "command -v ffmpeg"
    check "GStreamer" "command -v gst-launch-1.0"
    check "libVLC" "ldconfig -p | grep -q libvlc"
    check "Dear ImGui headers" "[ -f /usr/include/imgui.h ]"
    check "Box2D" "ldconfig -p | grep -q libBox2D"
    echo ""
}

# Terminal capabilities
detect_terminal() {
    echo -e "${YELLOW}== Terminal ==${NC}"
    echo "  Term: ${TERM:-unknown}"
    echo "  Colors: $(tput colors 2>/dev/null || echo unknown)"
    if command -v tput &>/dev/null; then
        echo "  Size: $(tput cols)x$(tput lines)"
    fi
    check "Unicode support" "echo '✓' | grep -q '✓'"
    check "Sixel graphics" "[ \"$TERM\" = 'xterm-256color' ] || [ \"$TERM\" = 'mlterm' ]"
    echo ""
}

# Main
main() {
    print_header
    detect_os
    detect_display
    detect_graphics
    detect_audio
    detect_languages
    detect_frameworks
    detect_terminal
    echo -e "${BLUE}Scan complete.${NC}"
}

main
