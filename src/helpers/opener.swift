// Folder launcher and small utilities for nas-on-click.
//
// As a launcher (no arguments): each icon in the NAS folder is a copy of this program
// with its own Info.plist. A double-click writes a request file named after the share
// and starts the background job, which mounts the share and opens it in Finder.
// Going through the job means macOS asks for network-volume access once, not per icon.
//
//   opener --hide-extension PATH
//       Hides the ".app" extension of a launcher.
//   opener --verify-manifest MANIFEST SIGNATURE KEYS PRODUCT CURRENT-VERSION
//       Verifies an update manifest (Ed25519) and prints
//       version<TAB>file<TAB>sha256<TAB>size<TAB>notes
//       Exit 0: newer version available, 3: not newer, 1: invalid.

import CryptoKit
import Foundation

let args = CommandLine.arguments

func fail(_ code: Int32 = 1) -> Never { exit(code) }

// MARK: - Version comparison (MAJOR.MINOR.PATCH)

func parseVersion(_ s: String) -> [Int]? {
  let parts = s.split(separator: ".", omittingEmptySubsequences: false)
  guard parts.count == 3 else { return nil }
  var out: [Int] = []
  for p in parts {
    guard !p.isEmpty, p.count <= 6, p.allSatisfy({ $0.isASCII && $0.isNumber }), let n = Int(p) else { return nil }
    out.append(n)
  }
  return out
}

func isNewer(_ a: [Int], than b: [Int]) -> Bool {
  for i in 0..<3 where a[i] != b[i] { return a[i] > b[i] }
  return false
}

// MARK: - Manifest verification

func verifyManifest(manifestPath: String, signaturePath: String, keysPath: String,
                    product: String, current: String) -> Never {
  guard let manifest = FileManager.default.contents(atPath: manifestPath), manifest.count <= 65536,
        let sigText = try? String(contentsOfFile: signaturePath, encoding: .utf8),
        let signature = Data(base64Encoded: sigText.trimmingCharacters(in: .whitespacesAndNewlines)),
        signature.count == 64,
        let keysText = try? String(contentsOfFile: keysPath, encoding: .utf8)
  else { fail() }

  // Any trusted key may sign. Lines starting with # are comments.
  var trusted = false
  for line in keysText.split(whereSeparator: \.isNewline) {
    let t = line.trimmingCharacters(in: .whitespaces)
    if t.isEmpty || t.hasPrefix("#") { continue }
    guard let raw = Data(base64Encoded: t), raw.count == 32,
          let key = try? Curve25519.Signing.PublicKey(rawRepresentation: raw) else { continue }
    if key.isValidSignature(signature, for: manifest) { trusted = true; break }
  }
  guard trusted else { fail() }

  // Only now is the content parsed.
  guard let obj = try? JSONSerialization.jsonObject(with: manifest) as? [String: Any],
        obj["product"] as? String == product,
        let version = obj["version"] as? String, let newV = parseVersion(version),
        let curV = parseVersion(current.trimmingCharacters(in: .whitespacesAndNewlines)),
        let file = obj["file"] as? String,
        file.range(of: "^[A-Za-z0-9._-]{1,100}\\.tar\\.gz$", options: .regularExpression) != nil,
        !file.hasPrefix("."),
        let sha = obj["sha256"] as? String,
        sha.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil,
        let size = obj["size"] as? Int, size > 0, size <= 52_428_800
  else { fail() }

  guard isNewer(newV, than: curV) else { fail(3) }

  // Release notes are shown in a dialog: keep them short and on one line.
  var notes = (obj["notes"] as? String) ?? ""
  notes = String(notes.unicodeScalars.map { CharacterSet.controlCharacters.contains($0) ? " " : Character($0) })
  if notes.count > 300 { notes = String(notes.prefix(300)) + "…" }

  print([version, file, sha, String(size), notes].joined(separator: "\t"))
  exit(0)
}

// MARK: - Launcher

func runLauncher() -> Never {
  let info = Bundle.main.infoDictionary ?? [:]
  guard let share = info["NOCShare"] as? String, !share.isEmpty, !share.contains("/"), !share.hasPrefix("."),
        let requestDir = info["NOCRequestDir"] as? String, requestDir.hasPrefix("/"),
        let label = info["NOCAgentLabel"] as? String, !label.isEmpty
  else { fail() }

  try? FileManager.default.createDirectory(atPath: requestDir, withIntermediateDirectories: true)
  let request = requestDir + "/" + share
  FileManager.default.createFile(atPath: request, contents: nil)

  let kick = Process()
  kick.executableURL = URL(fileURLWithPath: "/bin/launchctl")
  kick.arguments = ["kickstart", "gui/\(getuid())/\(label)"]
  var started = false
  do { try kick.run(); kick.waitUntilExit(); started = kick.terminationStatus == 0 } catch { started = false }
  if started { exit(0) }

  // The background job is missing or disabled: say so instead of doing nothing.
  try? FileManager.default.removeItem(atPath: request)
  let title = (info["NOCTitle"] as? String) ?? "NAS"
  let message = (info["NOCAgentError"] as? String) ?? "The background task is not running."
  let dialog = Process()
  dialog.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
  // Text goes through printenv: "system attribute" garbles non-ASCII letters.
  dialog.arguments = ["-e", "display dialog (do shell script \"printenv NOC_MSG\") with title (do shell script \"printenv NOC_TITLE\") buttons {(do shell script \"printenv NOC_OK\")} default button 1 with icon caution"]
  var env = ProcessInfo.processInfo.environment
  env["NOC_MSG"] = message
  env["NOC_TITLE"] = title
  env["NOC_OK"] = (info["NOCOK"] as? String) ?? "OK"
  dialog.environment = env
  try? dialog.run()
  dialog.waitUntilExit()
  exit(1)
}

// MARK: - Entry point

if args.count == 3 && args[1] == "--hide-extension" {
  try? FileManager.default.setAttributes([.extensionHidden: true], ofItemAtPath: args[2])
  exit(0)
}
if args.count == 7 && args[1] == "--verify-manifest" {
  verifyManifest(manifestPath: args[2], signaturePath: args[3], keysPath: args[4], product: args[5], current: args[6])
}
runLauncher()
