// Update manifest verification.
//
// A manifest is a small JSON document signed with Ed25519. The signature is checked
// against every trusted key before the JSON is even parsed; only then are the
// product, version, file name, checksum and size validated.

import CryptoKit
import Foundation

enum Manifest {
  static let maxManifestBytes = 65_536
  static let maxPackageBytes = 52_428_800

  struct Info {
    let version: String
    let file: String
    let sha256: String
    let size: Int
    let notes: String
  }

  enum Outcome {
    case newer(Info)
    case notNewer
    case invalid
  }

  /// MAJOR.MINOR.PATCH, digits only.
  static func parseVersion(_ s: String) -> [Int]? {
    let parts = s.split(separator: ".", omittingEmptySubsequences: false)
    guard parts.count == 3 else { return nil }
    var out: [Int] = []
    for p in parts {
      guard !p.isEmpty, p.count <= 6, p.allSatisfy({ $0.isASCII && $0.isNumber }), let n = Int(p) else { return nil }
      out.append(n)
    }
    return out
  }

  static func isNewer(_ a: [Int], than b: [Int]) -> Bool {
    for i in 0..<3 where a[i] != b[i] { return a[i] > b[i] }
    return false
  }

  /// Base64 public keys, one per line; blank lines and lines starting with # are ignored.
  static func trustedKeys(_ text: String) -> [Curve25519.Signing.PublicKey] {
    text.split(whereSeparator: \.isNewline).compactMap { line in
      let t = line.trimmingCharacters(in: .whitespaces)
      guard !t.isEmpty, !t.hasPrefix("#"), let raw = Data(base64Encoded: t), raw.count == 32 else { return nil }
      return try? Curve25519.Signing.PublicKey(rawRepresentation: raw)
    }
  }

  static func evaluate(manifest: Data, signature: Data, keys: [Curve25519.Signing.PublicKey],
                       product: String, installed: String, language: String = "en") -> Outcome {
    guard manifest.count <= maxManifestBytes, signature.count == 64,
          keys.contains(where: { $0.isValidSignature(signature, for: manifest) })
    else { return .invalid }

    guard let obj = try? JSONSerialization.jsonObject(with: manifest) as? [String: Any],
          obj["product"] as? String == product,
          let version = obj["version"] as? String, let newV = parseVersion(version),
          let curV = parseVersion(installed.trimmingCharacters(in: .whitespacesAndNewlines)),
          let file = obj["file"] as? String,
          file.range(of: "^[A-Za-z0-9][A-Za-z0-9._-]{0,99}\\.tar\\.gz$", options: .regularExpression) != nil,
          let sha = obj["sha256"] as? String,
          sha.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil,
          let size = obj["size"] as? Int, size > 0, size <= maxPackageBytes
    else { return .invalid }

    guard isNewer(newV, than: curV) else { return .notNewer }

    // Notes end up in a dialog: one line, no control characters, bounded length.
    // "notes" is English (read by every version); "notes_i18n" maps language codes to
    // translations, used when one exists for the user's language.
    var notes = ((obj["notes_i18n"] as? [String: Any])?[language] as? String) ?? (obj["notes"] as? String) ?? ""
    notes = String(notes.unicodeScalars.map { CharacterSet.controlCharacters.contains($0) ? " " : Character($0) })
    if notes.count > 300 { notes = String(notes.prefix(300)) + "…" }
    return .newer(Info(version: version, file: file, sha256: sha, size: size, notes: notes))
  }

  /// nas-on-click verify-manifest MANIFEST SIGNATURE KEYS PRODUCT INSTALLED-VERSION [LANGUAGE]
  /// Prints version<TAB>file<TAB>sha256<TAB>size<TAB>notes. Exit 0 newer, 3 not newer, 1 invalid.
  static func command(_ a: [String]) -> Int32 {
    guard a.count == 5 || a.count == 6,
          let manifest = FileManager.default.contents(atPath: a[0]),
          let sigText = try? String(contentsOfFile: a[1], encoding: .utf8),
          let signature = Data(base64Encoded: sigText.trimmingCharacters(in: .whitespacesAndNewlines)),
          let keysText = try? String(contentsOfFile: a[2], encoding: .utf8)
    else { return 1 }
    let language = a.count == 6 ? a[5] : "en"
    switch evaluate(manifest: manifest, signature: signature, keys: trustedKeys(keysText),
                    product: a[3], installed: a[4], language: language) {
    case .newer(let i):
      print([i.version, i.file, i.sha256, String(i.size), i.notes].joined(separator: "\t"))
      return 0
    case .notNewer: return 3
    case .invalid: return 1
    }
  }
}
