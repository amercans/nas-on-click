// Mounting and credentials without putting the password on a command line.
//
//   nas-on-click mount --url smb://HOST/SHARE --user USER
//       Reads the password from stdin and mounts with NetFS, with all system UI
//       disabled (no login dialog, no "remember in Keychain"). Prints the mount point.
//       Exit 0 mounted, 77 authentication rejected, 1 other failure.
//   nas-on-click keychain-set --service S --account A --label L
//       Reads the password from stdin and stores it as a generic Keychain item that
//       /usr/bin/security may read without a prompt (the scripts read it with
//       `security find-generic-password -w`, which prints to a pipe, not to argv).

import Foundation
import NetFS
import Security

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

  static func keychainSet(_ a: [String]) -> Int32 {
    guard let o = options(a), let service = o["service"], let account = o["account"],
          let label = o["label"], let password = readSecret(), !password.isEmpty
    else { return 64 }

    let base: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                               kSecAttrService as String: service,
                               kSecAttrAccount as String: account]
    // Existing item: replace the secret in place (keeps its access list).
    let update: [String: Any] = [kSecValueData as String: Data(password.utf8), kSecAttrLabel as String: label]
    let updated = SecItemUpdate(base as CFDictionary, update as CFDictionary)
    if updated == errSecSuccess { return 0 }
    if updated != errSecItemNotFound {
      FileHandle.standardError.write("keychain update: \(updated)\n".data(using: .utf8)!)
      return 1
    }

    var add = base
    add[kSecValueData as String] = Data(password.utf8)
    add[kSecAttrLabel as String] = label
    // Trusted readers: /usr/bin/security (used by the scripts) and this program.
    var apps: [SecTrustedApplication] = []
    var security: SecTrustedApplication?
    if SecTrustedApplicationCreateFromPath("/usr/bin/security", &security) == errSecSuccess, let s = security { apps.append(s) }
    var me: SecTrustedApplication?
    if SecTrustedApplicationCreateFromPath(nil, &me) == errSecSuccess, let m = me { apps.append(m) }
    var access: SecAccess?
    if SecAccessCreate(label as CFString, apps as CFArray, &access) == errSecSuccess, let acc = access {
      add[kSecAttrAccess as String] = acc
    }
    let status = SecItemAdd(add as CFDictionary, nil)
    if status != errSecSuccess {
      FileHandle.standardError.write("keychain: \(status)\n".data(using: .utf8)!)
      return 1
    }
    return 0
  }
}
