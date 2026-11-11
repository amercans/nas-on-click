// Sleep watcher for nas-on-click.
//
//   sleepwatch AGENT-SCRIPT AGENT-LABEL
//
// Before the Mac sleeps, runs "AGENT-SCRIPT sleep" (which unmounts the NAS shares) and
// waits for it, so macOS never shows "server connections interrupted" after waking.
// IOKit power notifications are used because they also arrive for the sleep that
// follows a dark wake (Power Nap), unlike workspace notifications.
// After waking it only nudges the background job, which drops dead mounts; nothing is
// mounted automatically.

import Foundation
import IOKit
import IOKit.pwr_mgt

// iokit_common_msg(x) == 0xE0000000 | x; the C macros are not imported into Swift.
let msgCanSystemSleep: UInt32 = 0xE000_0270
let msgSystemWillSleep: UInt32 = 0xE000_0280
let msgSystemHasPoweredOn: UInt32 = 0xE000_0300

let args = CommandLine.arguments
guard args.count == 3, args[1].hasPrefix("/"), !args[2].isEmpty else { exit(1) }
let agentScript = args[1]
let agentLabel = args[2]

var rootPort: io_connect_t = 0

func run(_ path: String, _ arguments: [String], wait: Bool) {
  let p = Process()
  p.executableURL = URL(fileURLWithPath: path)
  p.arguments = arguments
  do { try p.run() } catch { return }
  if wait { p.waitUntilExit() }
}

let callback: IOServiceInterestCallback = { _, _, messageType, argument in
  switch messageType {
  case msgCanSystemSleep:
    IOAllowPowerChange(rootPort, Int(bitPattern: argument))
  case msgSystemWillSleep:
    run("/bin/bash", [agentScript, "sleep"], wait: true)
    IOAllowPowerChange(rootPort, Int(bitPattern: argument))
  case msgSystemHasPoweredOn:
    run("/bin/launchctl", ["kickstart", "gui/\(getuid())/\(agentLabel)"], wait: false)
  default:
    break
  }
}

var notifyPort: IONotificationPortRef?
var notifier: io_object_t = 0
rootPort = IORegisterForSystemPower(nil, &notifyPort, callback, &notifier)
guard rootPort != 0, let port = notifyPort else { exit(1) }
CFRunLoopAddSource(CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource(port).takeUnretainedValue(), .defaultMode)
CFRunLoopRun()
