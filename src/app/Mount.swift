// Mounting without putting the password on a command line.
//
//   nas-on-click mount --url smb://HOST/SHARE --user USER
//       Reads the password from stdin and mounts with NetFS, with all system UI
//       disabled (no login dialog, no "remember in Keychain"). Prints the mount point.
//       Exit 0 mounted, 77 authentication rejected, 1 other failure.
//
//   nas-on-click unmount PATH
//       Force-unmounts PATH with unmount(2). Unlike diskutil, it does not go through Disk
//       Arbitration, which can block for a long time on a server that is gone.
//       Exit 0 unmounted, 1 failure.

import Foundation
import NetFS

enum Mount {
  static let authFailed: Int32 = 77

  static func readSecret() -> String? {
    guard let data = try? FileHandle.standardInput.readToEnd(), var s = String(data: data, encoding: .utf8) else { return nil }
    if s.hasSuffix("\n") { s.removeLast() }
    return s
  }

  static func options(_ a: [String]) -> [String: String]? {
    var out: [String: String] = [:]
    var i = 0
    while i < a.count {
      guard a[i].hasPrefix("--"), i + 1 < a.count else { return nil }
      out[String(a[i].dropFirst(2))] = a[i + 1]
      i += 2
    }
    return out
  }

  static func mount(_ a: [String]) -> Int32 {
    guard let o = options(a), let urlText = o["url"], let user = o["user"],
          let url = URL(string: urlText), url.scheme == "smb", url.host != nil,
          let password = readSecret()
    else { return 64 }

    let openOptions = NSMutableDictionary()
    openOptions[kNAUIOptionKey] = kNAUIOptionNoUI
    let mountOptions = NSMutableDictionary()
    var points: Unmanaged<CFArray>?
    let rc = NetFSMountURLSync(url as CFURL, nil, user as CFString, password as CFString,
                               openOptions, mountOptions, &points)
    if rc == 0 {
      for p in (points?.takeRetainedValue() as? [String]) ?? [] { print(p) }
      return 0
    }
    FileHandle.standardError.write("mount failed: \(rc)\n".data(using: .utf8)!)
    // EAUTH: the server rejected the user name or password.
    if rc == EAUTH { return authFailed }
    return 1
  }

  static func forceUnmount(_ a: [String]) -> Int32 {
    guard a.count == 1, a[0].hasPrefix("/Volumes/") else { return 64 }
    if Darwin.unmount(a[0], MNT_FORCE) == 0 { return 0 }
    FileHandle.standardError.write("unmount failed: \(errno)\n".data(using: .utf8)!)
    return 1
  }
}
