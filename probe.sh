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

# Check with version number
checkv() {
    local name=$1
    local cmd=$2
    local vercmd=$3
    if eval "$cmd" &>/dev/null; then
        local ver
        ver=$(eval "$vercmd" 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+[\.0-9]*' | head -1)
        if [ -n "$ver" ]; then
            echo -e "${GREEN}[✓]${NC} $name ${BLUE}($ver)${NC}"
        else
            echo -e "${GREEN}[✓]${NC} $name"
        fi
    else
        echo -e "${RED}[✗]${NC} $name"
    fi
}

# Check library with version via pkg-config or lib_check
checklib() {
    local name=$1
    local pkgname=$2
    local libname=$3
    local ver=""
    if pkg-config --exists "$pkgname" 2>/dev/null; then
        ver=$(pkg-config --modversion "$pkgname" 2>/dev/null)
        echo -e "${GREEN}[✓]${NC} $name ${BLUE}($ver)${NC}"
    elif lib_check "$libname"; then
        echo -e "${GREEN}[✓]${NC} $name"
    else
        echo -e "${RED}[✗]${NC} $name"
    fi
}

# Detect platform early — everything else uses this
detect_platform() {
    PLATFORM="unknown"
    case "$(uname -s)" in
        Linux*)   PLATFORM="linux" ;;
        Darwin*)  PLATFORM="macos" ;;
        FreeBSD*) PLATFORM="freebsd" ;;
        OpenBSD*) PLATFORM="openbsd" ;;
        NetBSD*)  PLATFORM="netbsd" ;;
        *)        PLATFORM="unknown" ;;
    esac
    export PLATFORM
}

# Cross-platform library check
lib_check() {
    local libname=$1
    case "$PLATFORM" in
        macos)
            find /usr/local/lib /opt/homebrew/lib /usr/lib 2>/dev/null -name "${libname}*" | grep -q .
            ;;
        freebsd|openbsd|netbsd)
            ldconfig -r 2>/dev/null | grep -q "$libname" || find /usr/local/lib /usr/lib 2>/dev/null -name "${libname}*" | grep -q .
            ;;
        *)
            ldconfig -p 2>/dev/null | grep -q "$libname"
            ;;
    esac
}

# OS Detection
detect_os() {
    echo -e "${YELLOW}== OS ==${NC}"
    echo "  Platform: $PLATFORM"
    case "$PLATFORM" in
        linux)
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                echo "  Name: $NAME"
                echo "  Version: ${VERSION_ID:-unknown}"
                echo "  ID: $ID"
            fi
            ;;
        macos)
            echo "  Name: macOS"
            echo "  Version: $(sw_vers -productVersion 2>/dev/null || echo unknown)"
            ;;
        freebsd|openbsd|netbsd)
            echo "  Name: $(uname -s)"
            echo "  Version: $(uname -r)"
            ;;
    esac
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
    checkv "OpenGL" "command -v glxinfo" "glxinfo | grep 'OpenGL version'"
    checkv "Vulkan" "command -v vulkaninfo" "vulkaninfo | grep 'Vulkan Instance Version'"
    checklib "SDL2" "sdl2" "libSDL2"
    checklib "SFML" "sfml-all" "libsfml"
    checklib "Allegro5" "allegro-5" "liballegro"
    checklib "Raylib" "raylib" "libraylib"
    checklib "Mesa (libGL)" "gl" "libGL"
    checklib "EGL" "egl" "libEGL"
    echo ""
}

# Audio libraries
detect_audio() {
    echo -e "${YELLOW}== Audio Libraries ==${NC}"
    checklib "ALSA" "alsa" "libasound"
    checkv "PulseAudio" "command -v pulseaudio || command -v pactl" "pulseaudio --version"
    checkv "PipeWire" "command -v pipewire" "pipewire --version"
    check "CoreAudio (macOS)" "[ \"$PLATFORM\" = 'macos' ]"
    check "OSS (BSD)" "[ -c /dev/dsp ] || [ -c /dev/audio ]"
    checklib "SDL2 Mixer" "SDL2_mixer" "libSDL2_mixer"
    checklib "OpenAL" "openal" "libopenal"
    checklib "PortAudio" "portaudio-2.0" "libportaudio"
    echo ""
}

# Languages
detect_languages() {
    echo -e "${YELLOW}== Languages & Runtimes ==${NC}"
    checkv "Python3" "command -v python3" "python3 --version"
    checkv "Python2" "command -v python2" "python2 --version"
    checkv "Rust (cargo)" "command -v cargo" "cargo --version"
    checkv "C (gcc)" "command -v gcc" "gcc --version"
    checkv "C++ (g++)" "command -v g++" "g++ --version"
    checkv "Clang" "command -v clang" "clang --version"
    checkv "Go" "command -v go" "go version"
    checkv "Java" "command -v java" "java -version 2>&1"
    checkv "Node.js" "command -v node" "node --version"
    checkv "Ruby" "command -v ruby" "ruby --version"
    checkv "Lua" "command -v lua || command -v lua5.4 || command -v lua5.3" "lua -v 2>&1 || lua5.4 -v 2>&1 || lua5.3 -v 2>&1"
    echo ""
}

# Game/multimedia frameworks
detect_frameworks() {
    echo -e "${YELLOW}== Game & Multimedia Frameworks ==${NC}"
    checkv "FFmpeg" "command -v ffmpeg" "ffmpeg -version"
    checkv "GStreamer" "command -v gst-launch-1.0" "gst-launch-1.0 --version"
    checklib "libVLC" "libvlc" "libvlc"
    check "Dear ImGui headers" "[ -f /usr/include/imgui.h ] || [ -f /usr/local/include/imgui.h ]"
    checklib "Box2D" "box2d" "libBox2D"
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
    detect_platform
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
