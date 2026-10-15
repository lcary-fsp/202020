# lookaway

A small 20-20-20 reminder for macOS. Every 20 minutes it shows a native notification telling you to look at something 20 feet away for 20 seconds. It stays quiet while you're on a call or away from the computer.

## How it works

`lookaway.swift` compiles to one binary, and launchd runs it every 20 minutes. Each time it runs, it:

1. Checks whether any microphone is in use (CoreAudio) and stops if so.
2. Checks whether any camera is in use (CoreMediaIO) and stops if so.
3. Checks how long since the last keyboard or mouse input and stops if it's been more than 5 minutes.
4. Otherwise shows a silent notification through `osascript` and plays the sound with `afplay`.

It only uses Apple frameworks. There's no third-party code and nothing runs between checks.

## Install

Requires Xcode Command Line Tools (`xcode-select --install`).

```bash
./install.sh
```

The script compiles the binary to `~/bin/lookaway`, writes `~/Library/LaunchAgents/local.lookaway.plist` and loads it. It starts on its own after reboot.

## Commands

```bash
~/bin/lookaway --status                          # show mic, camera and idle state
launchctl kickstart gui/$(id -u)/local.lookaway  # run the scheduled job now
osascript -e 'display notification "test" with title "Look away"'  # test notifications
```

## Configuration

| Setting | File | Default |
|---|---|---|
| How often it checks (`INTERVAL`) | `install.sh` | 1200 seconds |
| Idle time before it skips (`idleLimitSeconds`) | `lookaway.swift` | 300 seconds |
| Sound (`soundName`) | `lookaway.swift` | "Pop" |
| Notification text | `notify()` in `lookaway.swift` | |

Run `./install.sh` again after any change.

## Troubleshooting

- **No notifications:** turn on notifications for Script Editor in System Settings → Notifications. Do Not Disturb and Focus modes also hide them.
- **Reminder skipped while you're not on a call:** if you use one device for both mic and audio (for example AirPods), playing audio through it can count as "in use".

## Uninstall

```bash
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/local.lookaway.plist
rm ~/Library/LaunchAgents/local.lookaway.plist ~/bin/lookaway
```
