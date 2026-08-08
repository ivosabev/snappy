# Snappy

**Snappy** is a lightweight macOS menu-bar app that snaps windows to screen edges and corners as you drag them — a fast, native alternative to FancyZones-style layouts.

Drag any window toward an edge or corner, see a live preview overlay, and release to snap it into place.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-black)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License: MIT](https://img.shields.io/badge/License-MIT-blue)

## Features

- **Edge & corner snapping** — left/right halves, top/bottom thirds, and corner quadrants
- **Live overlay preview** while you drag
- **Menu-bar app** — runs quietly in the background (`LSUIElement`)
- **Customizable snap sizes** per zone
- **Adjustable edge thickness** for hot zones
- **Enable/disable** snapping from the menu
- **Native Swift / AppKit** — no Electron, no helpers

## Requirements

- macOS 13 Ventura or later
- Accessibility permission (required to move/resize other apps’ windows)

## Install

### Build from source

```bash
./build.sh
```

This builds a release binary, packages `Snappy.app`, codesigns it, and installs to `/Applications/Snappy.app`.

Then open it:

```bash
open /Applications/Snappy.app
```

### First launch

1. Open **System Settings → Privacy & Security → Accessibility**
2. Enable **Snappy**
3. Drag a window to a screen edge or corner to snap

## Usage

| Action | Result |
|--------|--------|
| Drag window to left/right edge | Half-screen snap |
| Drag to top/bottom edge | Horizontal band |
| Drag to a corner | Corner quadrant |
| Menu bar → Preferences | Tune zone sizes & edge thickness |
| Menu bar → Disable | Pause snapping without quitting |

## Development

```bash
swift build
swift build -c release
```

Project layout:

```
Sources/          AppKit app + snap engine
Resources/        App icon assets
Package.swift     Swift Package Manager manifest
Info.plist        Bundle metadata
build.sh          Release build + install
```

## License

[MIT](LICENSE) © Ivo Sabev
