// App-bundle roles of the nas-on-click binary, chosen by the NOCRole key in Info.plist.
//
// "launcher" (one bundle per share in the NAS folder): a double-click writes a request
//   file named after the share and starts the background job, which mounts the share
//   and opens it. Going through the job means macOS asks for network-volume access
//   once, not once per icon.
// "installer" (the setup app that is handed out): starts the bundled install.sh in its
//   own session and quits; install.sh then shows its windows through this binary.
// "helper" (inside the installed app folder): only used for dialogs and notifications,
//   so they carry the app's name and icon.

import AppKit
import Foundation

enum Roles {
  static var info: [String: Any] { Bundle.main.infoDictionary ?? [:] }

  static func launcher() -> Int32 {
    guard let share = info["NOCShare"] as? String, !share.isEmpty, !share.contains("/"), !share.hasPrefix("."),
          let requestDir = info["NOCRequestDir"] as? String, requestDir.hasPrefix("/"),
          let label = info["NOCAgentLabel"] as? String, !label.isEmpty
    else { return 1 }

    try? FileManager.default.createDirectory(atPath: requestDir, withIntermediateDirectories: true)
    let request = requestDir + "/" + share
    FileManager.default.createFile(atPath: request, contents: nil)

    let kick = Process()
    kick.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    kick.arguments = ["kickstart", "gui/\(getuid())/\(label)"]
    var started = false
    do { try kick.run(); kick.waitUntilExit(); started = kick.terminationStatus == 0 } catch { started = false }
    if started { return 0 }

    // The background job is missing or disabled: say so instead of doing nothing.
    try? FileManager.default.removeItem(atPath: request)
    _ = UI.dialog(["--title", (info["NOCTitle"] as? String) ?? "NAS",
                   "--message", (info["NOCAgentError"] as? String) ?? "The background task is not running.",
                   "--style", "caution", "--button", (info["NOCOK"] as? String) ?? "OK"])
    return 1
  }

  static func installer() -> Int32 {
    guard let script = Bundle.main.path(forResource: "install", ofType: "sh") else { return 1 }
    var attr: posix_spawnattr_t?
    posix_spawnattr_init(&attr)
    posix_spawnattr_setflags(&attr, Int16(POSIX_SPAWN_SETSID))
    var files: posix_spawn_file_actions_t?
    posix_spawn_file_actions_init(&files)
    posix_spawn_file_actions_addopen(&files, 0, "/dev/null", O_RDONLY, 0)
    posix_spawn_file_actions_addopen(&files, 1, "/dev/null", O_WRONLY, 0)
    posix_spawn_file_actions_addopen(&files, 2, "/dev/null", O_WRONLY, 0)
    var env = ProcessInfo.processInfo.environment
    env["NOC_UI"] = Bundle.main.executablePath
    let envp = env.map { strdup("\($0.key)=\($0.value)") } + [nil]
    let argv = [strdup("/bin/bash"), strdup(script), nil]
    var pid: pid_t = 0
    let rc = posix_spawn(&pid, "/bin/bash", &files, &attr, argv, envp)
    argv.forEach { free($0) }
    envp.forEach { free($0) }
    posix_spawn_file_actions_destroy(&files)
    posix_spawnattr_destroy(&attr)
    return rc == 0 ? 0 : 1
  }
}
