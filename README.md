# libprobe


A lightweight system capability scanner for any Linux environment. Works headless, in a terminal, or on a full desktop.

Detects what graphics, audio, languages, and frameworks your system can run — useful when moving drives between machines or setting up a new environment.

## Install

**curl** (most common):
```bash
curl -fsSL https://raw.githubusercontent.com/Ieatkidsfr/libprobe/main/install.sh | bash
```

**wget** (if curl isn't available):
```bash
wget -qO- https://raw.githubusercontent.com/Ieatkidsfr/libprobe/main/install.sh | bash
```

**git** (clone the whole repo):
```bash
git clone https://github.com/Ieatkidsfr/libprobe
cd libprobe
chmod +x probe.sh
sudo cp probe.sh /usr/local/bin/libprobe
```

**Manual** (no internet tools at all):
Download `probe.sh`, make it executable and run it:
```bash
chmod +x probe.sh
./probe.sh
```

> curl and wget are not always available on minimal systems. The git and manual methods work anywhere git is installed or you can transfer files manually.

## Usage

```bash
libprobe
```

## What it detects

- OS and kernel info
- Display server (X11, Wayland, headless)
- Graphics libraries (OpenGL, Vulkan, SDL2, SFML, Allegro, Raylib)
- Audio libraries (ALSA, PulseAudio, PipeWire, OpenAL)
- Languages and runtimes (Python, Rust, C, Go, Java, Node, Lua...)
- Game and multimedia frameworks
- Terminal capabilities

## License

GPL-3.0


# Future updates (Not 100%)

Coming soon!
