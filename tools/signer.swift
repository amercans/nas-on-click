// Release signing tool for nas-on-click (maintainer only, never shipped).
//
//   swift tools/signer.swift keygen                 create a signing key in the login Keychain
//   swift tools/signer.swift pubkey                 print the public key (for keys/update-keys.txt)
//   swift tools/signer.swift sign FILE              print a base64 Ed25519 signature of FILE
//   swift tools/signer.swift backup PATH            write the private key to PATH (mode 600)
//                                                   for an offline backup
//   swift tools/signer.swift restore PATH           import a backup into the Keychain
//   swift tools/signer.swift protect                re-store an existing key so that macOS asks
//                                                   before every use
//
// Keys stored by this tool trust no application: every signature needs your confirmation.
//
// Add "--key-file PATH" before the command to use a key file instead of the Keychain
// (used by the test suite).

import CryptoKit
import Foundation
import Security

let service = "nas-on-click.release-signing"
let account = "ed25519"

func die(_ msg: String) -> Never {
  FileHandle.standardError.write((msg + "\n").data(using: .utf8)!)
  exit(1)
}

var args = Array(CommandLine.arguments.dropFirst())
var keyFile: String?
if args.count >= 2 && args[0] == "--key-file" { keyFile = args[1]; args.removeFirst(2) }
guard let command = args.first else { die("usage: signer.swift [--key-file PATH] keygen|pubkey|sign FILE|backup PATH|restore PATH") }

func keychainRead() -> Data? {
  let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service,
                          kSecAttrAccount as String: account, kSecReturnData as String: true]
  var out: AnyObject?
  guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess else { return nil }
  return out as? Data
}

func keychainWrite(_ data: Data) {
  var q: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service,
                          kSecAttrAccount as String: account, kSecValueData as String: data,
                          kSecAttrLabel as String: "nas-on-click release signing key"]
  // An access list with no trusted applications: macOS asks before any program reads the key.
  var access: SecAccess?
  if SecAccessCreate("nas-on-click release signing key" as CFString, [] as CFArray, &access) == errSecSuccess, let a = access {
    q[kSecAttrAccess as String] = a
  }
  let status = SecItemAdd(q as CFDictionary, nil)
  guard status == errSecSuccess else { die("could not store the key in the Keychain (status \(status))") }
}

func writeSecret(_ data: Data, to path: String) {
  guard !FileManager.default.fileExists(atPath: path) else { die("refusing to overwrite \(path)") }
  guard FileManager.default.createFile(atPath: path, contents: data.base64EncodedData(),
                                       attributes: [.posixPermissions: 0o600]) else { die("could not write \(path)") }
}

func loadKey() -> Curve25519.Signing.PrivateKey {
  let raw: Data?
  if let f = keyFile {
    raw = (try? String(contentsOfFile: f, encoding: .utf8)).flatMap { Data(base64Encoded: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
  } else {
    raw = keychainRead()
  }
  guard let r = raw, let key = try? Curve25519.Signing.PrivateKey(rawRepresentation: r) else { die("no signing key found; run keygen first") }
  return key
}

switch command {
case "keygen":
  let key = Curve25519.Signing.PrivateKey()
  if let f = keyFile { writeSecret(key.rawRepresentation, to: f) } else {
    guard keychainRead() == nil else { die("a signing key already exists in the Keychain") }
    keychainWrite(key.rawRepresentation)
  }
  print(key.publicKey.rawRepresentation.base64EncodedString())
case "pubkey":
  print(loadKey().publicKey.rawRepresentation.base64EncodedString())
case "sign":
  guard args.count == 2, let data = FileManager.default.contents(atPath: args[1]) else { die("sign FILE") }
  guard let sig = try? loadKey().signature(for: data) else { die("signing failed") }
  print(sig.base64EncodedString())
case "backup":
  guard args.count == 2 else { die("backup PATH") }
  writeSecret(loadKey().rawRepresentation, to: args[1])
  print("Private key written to \(args[1]). Move it to offline storage and delete this copy.")
case "restore":
  guard args.count == 2, keyFile == nil,
        let text = try? String(contentsOfFile: args[1], encoding: .utf8),
        let raw = Data(base64Encoded: text.trimmingCharacters(in: .whitespacesAndNewlines)),
        (try? Curve25519.Signing.PrivateKey(rawRepresentation: raw)) != nil else { die("restore PATH (a backup written by this tool)") }
  guard keychainRead() == nil else { die("a signing key already exists in the Keychain") }
  keychainWrite(raw)
  print("Key restored to the Keychain.")
case "protect":
  guard keyFile == nil, let raw = keychainRead() else { die("no key in the Keychain") }
  let del: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service,
                            kSecAttrAccount as String: account]
  guard SecItemDelete(del as CFDictionary) == errSecSuccess else { die("could not replace the key") }
  keychainWrite(raw)
  print("Key re-stored; macOS will now ask before each use.")
default:
  die("unknown command \(command)")
}
