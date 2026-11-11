// Native dialogs and notifications.
//
// The shell scripts call these instead of AppleScript so that every window and
// notification carries the app's own name and icon.
//
//   nas-on-click ui --title T --message M [--headline H] [--style note|caution|stop]
//                   [--button B]... [--timeout SECONDS]
//       Shows an alert; the first --button is the default (Return), the last one also
//       answers Escape. Prints the chosen button. Exit 0 chosen, 2 timed out.
//   nas-on-click ui ... --input [--default TEXT] [--secure]
//       Adds a text field (secure for passwords). The LAST button cancels: exit 1.
//       Otherwise prints the entered text.
//   nas-on-click progress --title T --status-file FILE
//       Shows a small progress window that follows the text of FILE.

import AppKit
import Foundation

enum UI {
  struct Options {
    var title = ""
    var headline: String?
    var message = ""
    var style = "note"
    var buttons: [String] = []
    var timeout: TimeInterval = 0
    var input = false
    var secure = false
    var defaultText = ""
  }

  static func parse(_ a: [String]) -> Options? {
    var o = Options()
    var i = 0
    func value() -> String? { i += 1; return i < a.count ? a[i] : nil }
    while i < a.count {
      switch a[i] {
      case "--title": guard let v = value() else { return nil }; o.title = v
      case "--headline": guard let v = value() else { return nil }; o.headline = v
      case "--message": guard let v = value() else { return nil }; o.message = v
      case "--style": guard let v = value() else { return nil }; o.style = v
      case "--button": guard let v = value() else { return nil }; o.buttons.append(v)
      case "--timeout": guard let v = value(), let t = TimeInterval(v) else { return nil }; o.timeout = t
      case "--default": guard let v = value() else { return nil }; o.defaultText = v
      case "--input": o.input = true
      case "--secure": o.input = true; o.secure = true
      default: return nil
      }
      i += 1
    }
    if o.buttons.isEmpty { o.buttons = ["OK"] }
    if o.input && o.buttons.count < 2 { return nil }
    return o
  }

  static func prepareApp() {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    app.activate(ignoringOtherApps: true)
  }

  static func dialog(_ args: [String]) -> Int32 {
    guard let o = parse(args) else { return 64 }
    prepareApp()

    let alert = NSAlert()
    alert.messageText = o.headline ?? o.title
    alert.informativeText = o.message
    switch o.style {
    case "stop": alert.alertStyle = .critical
    case "caution": alert.alertStyle = .warning
    default: alert.alertStyle = .informational
    }
    for title in o.buttons { alert.addButton(withTitle: title) }
    if o.buttons.count > 1 { alert.buttons.last?.keyEquivalent = "\u{1b}" }

    var field: NSTextField?
    if o.input {
      let f: NSTextField = o.secure ? NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 24))
                                    : NSTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 24))
      f.stringValue = o.defaultText
      alert.accessoryView = f
      alert.window.initialFirstResponder = f
      field = f
    }
    alert.window.level = .modalPanel
    if !o.title.isEmpty { alert.window.title = o.title }

    var timedOut = false
    if o.timeout > 0 {
      let timer = Timer(timeInterval: o.timeout, repeats: false) { _ in timedOut = true; NSApp.abortModal() }
      RunLoop.main.add(timer, forMode: .modalPanel)
    }
    let response = alert.runModal()
    if timedOut || response == .abort { return 2 }

    let index = response.rawValue - NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
    guard index >= 0, index < o.buttons.count else { return 2 }
    if o.input {
      if index == o.buttons.count - 1 { return 1 }
      print(field?.stringValue ?? "")
    } else {
      print(o.buttons[index])
    }
    return 0
  }

  /// nas-on-click progress --title T --status-file FILE
  /// A small floating window with the app icon, a spinner and the text of FILE, re-read
  /// twice a second. It closes when FILE is deleted (or after two hours at most).
  static func progress(_ args: [String]) -> Int32 {
    var title = "", file = ""
    var i = 0
    while i + 1 < args.count {
      switch args[i] {
      case "--title": title = args[i + 1]
      case "--status-file": file = args[i + 1]
      default: return 64
      }
      i += 2
    }
    guard file.hasPrefix("/") else { return 64 }
    prepareApp()

    let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 440, height: 116),
                        styleMask: [.titled], backing: .buffered, defer: false)
    panel.title = title
    panel.level = .floating
    panel.hidesOnDeactivate = false
    let content = NSView(frame: panel.contentRect(forFrameRect: panel.frame))
    let icon = NSImageView(frame: NSRect(x: 20, y: 26, width: 64, height: 64))
    icon.image = NSApp.applicationIconImage
    let label = NSTextField(wrappingLabelWithString: "")
    label.frame = NSRect(x: 100, y: 34, width: 300, height: 48)
    let spinner = NSProgressIndicator(frame: NSRect(x: 404, y: 50, width: 16, height: 16))
    spinner.style = .spinning
    spinner.controlSize = .small
    spinner.startAnimation(nil)
    [icon, label, spinner].forEach { content.addSubview($0) }
    panel.contentView = content
    panel.center()
    panel.orderFrontRegardless()

    let started = Date()
    let timer = Timer(timeInterval: 0.5, repeats: true) { _ in
      guard FileManager.default.fileExists(atPath: file), Date().timeIntervalSince(started) < 7200 else {
        NSApp.terminate(nil); return
      }
      if let text = try? String(contentsOfFile: file, encoding: .utf8) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if label.stringValue != t { label.stringValue = t }
      }
    }
    RunLoop.main.add(timer, forMode: .common)
    timer.fire()
    NSApp.run()
    return 0
  }
}
