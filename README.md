# Island

A notch-based productivity hub for macOS. Hover your MacBook's notch and get a todo list, a script runner, a dev-folder cleanup tool, and a live system monitor — no other app to open, mostly no mouse required.

Built for personal use and a few friends. Free, open source, unsigned.

## Features

- **Home** — a dashboard: today's date, a browsable month calendar, pending todos, and quick CPU/memory/reclaimable stats, all in one glance.
- **Todo** — quick-capture list. Add, check off, delete. Persists across restarts.
- **Script Runner** — save shell commands you run often, each with an icon (auto-picked from the command, or choose your own). Run and stop them (SIGTERM, then SIGKILL after a grace period), import an existing `.sh` file, set a working directory, and see live status. A pulsing indicator shows on the collapsed notch while something's running.
- **Dev Cleanup** — scans a chosen folder (default `~/code`) plus Xcode DerivedData for `node_modules`, build caches, `.next`, `Pods`, and similar regenerable junk. Shows reclaimable size, moves selected items to **Trash** (never a permanent delete), and persists scan results across restarts.
- **System Monitor** — CPU, memory, and storage usage, plus how much space Cleanup could reclaim right now.
- **Keyboard-first** — every action has a global shortcut: toggle the notch, jump to any tab, quick-add a todo, run/stop a specific script. All fully customizable in the in-app Settings tab (powered by [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)).
- **Launch at Login** — toggle in Settings; Island starts automatically on boot.

## Install

**One line (recommended)** — paste into Terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/Arjun-Bhandari/Island/main/scripts/install.sh | bash
```

It downloads the latest release into `/Applications`, clears the quarantine flag (so the unsigned build isn't blocked), and opens Island.

**Manual** — download `Island.zip` from [Releases](https://github.com/Arjun-Bhandari/Island/releases/latest) and unzip it. Because the build is unsigned, macOS blocks the first launch: open **System Settings → Privacy & Security** and click **Open Anyway** (on macOS 14 you can also right-click the app → Open). If Island isn't in Applications, the welcome tour offers to move it there for you.

On first launch a short welcome tour walks through the features and keyboard shortcuts and lets you turn on Launch at Login. Replay it any time from **Settings → Welcome tour**.

**Quitting** — **Settings → Quit Island**, or press **⌘Q** while the notch is open.

Requires macOS 14 (Sonoma) or later.

## Development

Built with Swift Package Manager — no Xcode project file, no Xcode required to build.

```bash
swift build              # debug build
swift run                # build + run
swift test               # unit tests
```

### Dependencies

- [DynamicNotchKit](https://github.com/MrKai77/DynamicNotchKit) — the notch overlay window and hover state
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) — customizable global hotkeys

### Project layout

```
Sources/Island/
├── IslandApp.swift          # @main, app lifecycle
├── Notch/                   # notch overlay, tab switcher, Home dashboard, calendar, settings
├── Onboarding/              # first-launch welcome tour window
├── Modules/
│   ├── Todo/
│   ├── ScriptRunner/
│   ├── DevCleanup/
│   └── SystemMonitor/
├── Shortcuts/                # KeyboardShortcuts.Name definitions
└── Shared/                   # Persistence, LoginItem, AppInstaller
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

- Unsigned build — Gatekeeper blocks the first manual launch (see Install above; the one-line installer avoids this).
- No auto-update; check [Releases](https://github.com/Arjun-Bhandari/Island/releases) for new versions.
- Dev Cleanup's scan is a manual/background process, not a filesystem watcher — reclaimable size can drift between scans.

## License

Personal project, shared as-is for friends and anyone who finds it useful.
