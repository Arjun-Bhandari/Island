# Island

A notch-based productivity hub for macOS. Hover your MacBook's notch and get a todo list, a script runner, a dev-folder cleanup tool, and a live system monitor — no other app to open, mostly no mouse required.

Built for personal use and a few friends. Free, open source, unsigned.

## Features

- **Home** — a dashboard: today's date, a browsable month calendar, pending todos, and quick CPU/memory/reclaimable stats, all in one glance.
- **Todo** — quick-capture list. Add, check off, delete. Persists across restarts.
- **Script Runner** — save shell commands you run often. Run and stop them (SIGTERM, then SIGKILL after a grace period), import an existing `.sh` file, set a working directory, and see live status. A pulsing indicator shows on the collapsed notch while something's running.
- **Dev Cleanup** — scans a chosen folder (default `~/code`) plus Xcode DerivedData for `node_modules`, build caches, `.next`, `Pods`, and similar regenerable junk. Shows reclaimable size, moves selected items to **Trash** (never a permanent delete), and persists scan results across restarts.
- **System Monitor** — CPU, memory, and storage usage, plus how much space Cleanup could reclaim right now.
- **Keyboard-first** — every action has a global shortcut: toggle the notch, jump to any tab, quick-add a todo, run/stop a specific script. All fully customizable in the in-app Settings tab (powered by [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)).
- **Launch at Login** — toggle in Settings; Island starts automatically on boot.

## Install

1. Download the latest release's zip from [Releases](https://github.com/Arjun-Bhandari/Island/releases/latest).
2. Unzip, move `Island.app` to `/Applications`.
3. **Right-click → Open** the first time (this build is unsigned, so Gatekeeper will warn once — click Open to confirm). After that, it opens normally.

Requires macOS 14 (Sonoma) or later.

## Development

Built with Swift Package Manager — no Xcode project file, no Xcode required to build.

```bash
swift build              # debug build
swift run                # build + run
```

### Dependencies

- [DynamicNotchKit](https://github.com/MrKai77/DynamicNotchKit) — the notch overlay window and hover state
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) — customizable global hotkeys

### Project layout

```
Sources/Island/
├── IslandApp.swift          # @main, app lifecycle
├── Notch/                   # notch overlay, tab switcher, Home dashboard, calendar, settings
├── Modules/
│   ├── Todo/
│   ├── ScriptRunner/
│   ├── DevCleanup/
│   └── SystemMonitor/
├── Shortcuts/                # KeyboardShortcuts.Name definitions
└── Shared/                   # Persistence, LoginItem
```

Each module follows the same shape: a `@Observable` store (state + persistence to JSON in `~/Library/Application Support/Island/`) and a SwiftUI view.

### Building a distributable `.app`

```bash
./scripts/build-app.sh
```

This builds a release binary, assembles `Island.app` with the icon and `Info.plist`, ad-hoc signs it (no Apple Developer account needed), and zips it to `dist/`.

## Landing page

The marketing site lives in [`site/`](site/) — see its own README for details.

## Known limitations

- Unsigned build — Gatekeeper warns on first launch (see Install above).
- No auto-update; check [Releases](https://github.com/Arjun-Bhandari/Island/releases) for new versions.
- Dev Cleanup's scan is a manual/background process, not a filesystem watcher — reclaimable size can drift between scans.

## License

Personal project, shared as-is for friends and anyone who finds it useful.
