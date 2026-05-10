#!/bin/bash
# libprobe - System capability scanner
# https://github.com/Ieatkidsfr/libprobe

VERSION="0.2.0"
VERBOSE=0

# Parse flags
for arg in "$@"; do
    case $arg in
        --verbose|-v) VERBOSE=1 ;;
        --help|-h)
            echo "Usage: libprobe [--verbose|-v] [--help|-h]"
            echo "  --verbose, -v   Show errors and extra debug info"
            echo "  --help, -h      Show this help message"
            exit 0
            ;;
    esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Verbose logger
vlog() { [ "$VERBOSE" -eq 1 ] && echo -e "  ${BLUE}[debug]${NC} $*"; }

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

# Detect platform early — everything else uses this
detect_platform() {
    local uname
    uname=$(uname -s)
    case "$uname" in
        Linux*)   PLATFORM="linux" ;;
        Darwin*)  PLATFORM="macos" ;;
        FreeBSD*) PLATFORM="freebsd" ;;
        OpenBSD*) PLATFORM="openbsd" ;;
        NetBSD*)  PLATFORM="netbsd" ;;
        *)        PLATFORM="unknown" ;;
    esac
    export PLATFORM
    vlog "Platform detected: $PLATFORM"
}

# Cache ldconfig output once at startup
cache_ldconfig() {
    if [ "$PLATFORM" = "linux" ]; then
        LDCONFIG_CACHE=$(ldconfig -p 2>/dev/null)
        vlog "ldconfig cache built (${#LDCONFIG_CACHE} bytes)"
    elif [ "$PLATFORM" = "freebsd" ] || [ "$PLATFORM" = "openbsd" ] || [ "$PLATFORM" = "netbsd" ]; then
        LDCONFIG_CACHE=$(ldconfig -r 2>/dev/null)
        vlog "ldconfig -r cache built"
    else
        LDCONFIG_CACHE=""
    fi
    export LDCONFIG_CACHE
}

# Cross-platform library check using cached ldconfig
lib_check() {
    local libname=$1
    case "$PLATFORM" in
        macos)
            find /usr/local/lib /opt/homebrew/lib /usr/lib 2>/dev/null -name "${libname}*" | grep -q .
            ;;
        freebsd|openbsd|netbsd)
            echo "$LDCONFIG_CACHE" | grep -q "$libname" || \
            find /usr/local/lib /usr/lib 2>/dev/null -name "${libname}*" | grep -q .
            ;;
        *)
            echo "$LDCONFIG_CACHE" | grep -q "$libname"
            ;;
    esac
}

# Basic check — just pass/fail
check() {
    local name=$1
    local cmd=$2
    vlog "check: $name -> $cmd"
    if $cmd &>/dev/null 2>&1; then
        echo -e "${GREEN}[✓]${NC} $name"
    else
        echo -e "${RED}[✗]${NC} $name"
    fi
}

# Check with version number — avoids double subshell where possible
checkv() {
    local name=$1
    local bin=$2
    local verflag=${3:---version}
    vlog "checkv: $name -> $bin $verflag"
    if command -v "$bin" &>/dev/null; then
        local raw
        raw=$("$bin" $verflag 2>&1 | head -1)
        # Extract version using bash parameter expansion instead of grep -oE
        local ver="${raw##* }"
        ver="${ver%%[^0-9.]*}"
        if [ -n "$ver" ]; then
            echo -e "${GREEN}[✓]${NC} $name ${BLUE}($ver)${NC}"
        else
            echo -e "${GREEN}[✓]${NC} $name"
        fi
    else
        echo -e "${RED}[✗]${NC} $name"
    fi
}

# Check library — single pkg-config call, falls back to lib_check
checklib() {
    local name=$1
    local pkgname=$2
    local libname=$3
    vlog "checklib: $name (pkg=$pkgname, lib=$libname)"
    local ver
    # Combined exists+version in one call
    ver=$(pkg-config --modversion "$pkgname" 2>/dev/null)
    if [ -n "$ver" ]; then
        echo -e "${GREEN}[✓]${NC} $name ${BLUE}($ver)${NC}"
    elif lib_check "$libname"; then
        echo -e "${GREEN}[✓]${NC} $name"
    else
        echo -e "${RED}[✗]${NC} $name"
    fi
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
            local macver
            macver=$(sw_vers -productVersion 2>/dev/null)
            echo "  Version: ${macver:-unknown}"
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
    [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && echo -e "${YELLOW}[!]${NC} Running headless"
    echo ""
}

# Graphics libraries
detect_graphics() {
    echo -e "${YELLOW}== Graphics Libraries ==${NC}"
    checkv "OpenGL" "glxinfo" "--version"
    checkv "Vulkan" "vulkaninfo" "--version"
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
    checkv "PulseAudio" "pulseaudio" "--version"
    checkv "PipeWire" "pipewire" "--version"
    if [ "$PLATFORM" = "macos" ]; then
        echo -e "${GREEN}[✓]${NC} CoreAudio (macOS)"
    else
        echo -e "${RED}[✗]${NC} CoreAudio (not available)"
    fi
    [ -c /dev/dsp ] || [ -c /dev/audio ] && echo -e "${GREEN}[✓]${NC} OSS (BSD)" || echo -e "${RED}[✗]${NC} OSS (BSD)"
    checklib "SDL2 Mixer" "SDL2_mixer" "libSDL2_mixer"
    checklib "OpenAL" "openal" "libopenal"
    checklib "PortAudio" "portaudio-2.0" "libportaudio"
    echo ""
}

# Languages
detect_languages() {
    echo -e "${YELLOW}== Languages & Runtimes ==${NC}"
    checkv "Python3" "python3" "--version"
    checkv "Python2" "python2" "--version"
    checkv "Rust (cargo)" "cargo" "--version"
    checkv "C (gcc)" "gcc" "--version"
    checkv "C++ (g++)" "g++" "--version"
    checkv "Clang" "clang" "--version"
    checkv "Go" "go" "version"
    checkv "Java" "java" "-version"
    checkv "Node.js" "node" "--version"
    checkv "Ruby" "ruby" "--version"
    checkv "Lua" "lua" "-v"
    echo ""
}

# Game/multimedia frameworks
detect_frameworks() {
    echo -e "${YELLOW}== Game & Multimedia Frameworks ==${NC}"
    checkv "FFmpeg" "ffmpeg" "-version"
    checkv "GStreamer" "gst-launch-1.0" "--version"
    checklib "libVLC" "libvlc" "libvlc"
    [ -f /usr/include/imgui.h ] || [ -f /usr/local/include/imgui.h ] && \
        echo -e "${GREEN}[✓]${NC} Dear ImGui headers" || \
        echo -e "${RED}[✗]${NC} Dear ImGui headers"
    checklib "Box2D" "box2d" "libBox2D"
    echo ""
}

# Terminal capabilities
detect_terminal() {
    echo -e "${YELLOW}== Terminal ==${NC}"
    echo "  Term: ${TERM:-unknown}"
    local colors
    colors=$(tput colors 2>/dev/null)
    echo "  Colors: ${colors:-unknown}"
    if command -v tput &>/dev/null; then
        echo "  Size: $(tput cols)x$(tput lines)"
    fi
    echo '✓' | grep -q '✓' && \
        echo -e "${GREEN}[✓]${NC} Unicode support" || \
        echo -e "${RED}[✗]${NC} Unicode support"
    [ "$TERM" = "xterm-256color" ] || [ "$TERM" = "mlterm" ] && \
        echo -e "${GREEN}[✓]${NC} Sixel graphics" || \
        echo -e "${RED}[✗]${NC} Sixel graphics"
    echo ""
}

# Main
main() {
    detect_platform
    cache_ldconfig
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

main "$@"
