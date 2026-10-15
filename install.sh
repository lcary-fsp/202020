#!/bin/bash
# Compiles lookaway.swift to ~/bin/lookaway and schedules it every 20 min via launchd.
# Uninstall: launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/local.lookaway.plist
#            rm ~/Library/LaunchAgents/local.lookaway.plist ~/bin/lookaway
set -euo pipefail
cd "$(dirname "$0")"

INTERVAL=1200
BIN="$HOME/bin/lookaway"
PLIST="$HOME/Library/LaunchAgents/local.lookaway.plist"

mkdir -p "$HOME/bin" "$HOME/Library/LaunchAgents"
swiftc -O lookaway.swift -o "$BIN"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>local.lookaway</string>
  <key>ProgramArguments</key><array><string>$BIN</string></array>
  <key>StartInterval</key><integer>$INTERVAL</integer>
  <key>ProcessType</key><string>Background</string>
</dict>
</plist>
EOF

launchctl bootout "gui/$(id -u)" "$PLIST" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"

echo "Installed. Current state:"
"$BIN" --status
