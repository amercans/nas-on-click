// nas-on-click: one binary for the folder launchers, the setup app, native dialogs,
// mounting, Keychain storage and update verification. See the comments in each file.

import Foundation

let arguments = Array(CommandLine.arguments.dropFirst())

func run() -> Int32 {
  guard let command = arguments.first else {
    switch Roles.info["NOCRole"] as? String {
    case "installer": return Roles.installer()
    case "launcher": return Roles.launcher()
    default: return 64
    }
  }
  let rest = Array(arguments.dropFirst())
  switch command {
  case "ui": return UI.dialog(rest)
  case "progress": return UI.progress(rest)
  case "mount": return Mount.mount(rest)
  case "unmount": return Mount.forceUnmount(rest)
  case "verify-manifest": return Manifest.command(rest)
  case "hide-extension":
    guard rest.count == 1 else { return 64 }
    return (try? FileManager.default.setAttributes([.extensionHidden: true], ofItemAtPath: rest[0])) != nil ? 0 : 1
  default:
    FileHandle.standardError.write("unknown command \(command)\n".data(using: .utf8)!)
    return 64
  }
}

exit(run())
