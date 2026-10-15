// lookaway: 20-20-20 reminder that stays quiet during calls.
// Run once per interval (launchd handles scheduling). Exits silently if the
// mic or camera is in use, or if you've been idle (away / screen locked).
//
//   lookaway           check and notify if appropriate
//   lookaway --status  print mic / camera / idle state and exit

import CoreAudio
import CoreGraphics
import CoreMediaIO
import Foundation

let idleLimitSeconds: Double = 300  // skip if no keyboard/mouse input for 5 min

func micInUse() -> Bool {
    let system = AudioObjectID(kAudioObjectSystemObject)
    var addr = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain)
    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(system, &addr, 0, nil, &size) == noErr else { return false }
    var ids = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
    guard AudioObjectGetPropertyData(system, &addr, 0, nil, &size, &ids) == noErr else { return false }

    for id in ids {
        // Only consider devices that have input streams (microphones).
        var streams = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain)
        var streamSize: UInt32 = 0
        AudioObjectGetPropertyDataSize(id, &streams, 0, nil, &streamSize)
        if streamSize == 0 { continue }

        var running = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var value: UInt32 = 0
        var valueSize = UInt32(MemoryLayout<UInt32>.size)
        if AudioObjectGetPropertyData(id, &running, 0, nil, &valueSize, &value) == noErr, value != 0 {
            return true
        }
    }
    return false
}

func cameraInUse() -> Bool {
    let system = CMIOObjectID(kCMIOObjectSystemObject)
    var addr = CMIOObjectPropertyAddress(
        mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
        mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
        mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
    var size: UInt32 = 0
    guard CMIOObjectGetPropertyDataSize(system, &addr, 0, nil, &size) == noErr else { return false }
    var ids = [CMIOObjectID](repeating: 0, count: Int(size) / MemoryLayout<CMIOObjectID>.size)
    var used: UInt32 = 0
    guard CMIOObjectGetPropertyData(system, &addr, 0, nil, size, &used, &ids) == noErr else { return false }

    for id in ids {
        var running = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeWildcard),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementWildcard))
        var value: UInt32 = 0
        var valueUsed: UInt32 = 0
        let valueSize = UInt32(MemoryLayout<UInt32>.size)
        if CMIOObjectGetPropertyData(id, &running, 0, nil, valueSize, &valueUsed, &value) == noErr, value != 0 {
            return true
        }
    }
    return false
}

func idleSeconds() -> Double {
    CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)
}

let soundName = "Pop"  // any name from /System/Library/Sounds or ~/Library/Sounds

func run(_ path: String, _ args: [String]) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: path)
    p.arguments = args
    try? p.run()
    p.waitUntilExit()
}

func notify() {
    // Notification is silent; play the sound directly so it doesn't depend on
    // Notification Center sound settings.
    run("/usr/bin/osascript", ["-e", "display notification \"Look at something 20 feet away for 20 seconds.\" with title \"Look away\""])
    let user = NSHomeDirectory() + "/Library/Sounds/\(soundName).aiff"
    let system = "/System/Library/Sounds/\(soundName).aiff"
    let sound = FileManager.default.fileExists(atPath: user) ? user : system
    run("/usr/bin/afplay", [sound])
}

let mic = micInUse()
let cam = cameraInUse()
let idle = idleSeconds()

if CommandLine.arguments.contains("--status") {
    print("mic in use:    \(mic)")
    print("camera in use: \(cam)")
    print("idle seconds:  \(Int(idle))")
    exit(0)
}

if mic || cam || idle > idleLimitSeconds { exit(0) }
notify()
