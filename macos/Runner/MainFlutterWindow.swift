import Cocoa
import FlutterMacOS

// Window sizing ported from manger_plus/macos/Runner/MainFlutterWindow.swift.
class MainFlutterWindow: NSWindow {
  /// `asec/screen_protection` — the Control centre's "Block screenshots".
  private var screenChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()

    // OPENING SIZE
    // MainMenu.xib opens at 800x600, which is too small for the admin console
    // (side rail + members table + results charts). Open at a real desktop
    // size instead.
    let defaultSize = NSSize(width: 1440, height: 900)

    // MINIMUM SIZE
    //
    // The window can't be made smaller than this — narrower or shorter and
    // the desktop layouts (home page, admin tables) would have to squeeze.
    //
    // `contentMinSize`, not `minSize`: `minSize` includes the title bar, so the
    // number would not be the width Flutter's LayoutBuilder actually sees.
    // 25/10/2026: one minimum for debug and release, big enough for the
    // home page to show everything without scrolling. Fits a 1366 x 768
    // laptop screen.
    let minimumContentSize = NSSize(width: 1100, height: 700)

    var windowFrame = self.frame
    windowFrame.size = defaultSize

    // Centre on whichever screen the window opened on, so it does not start
    // half off-screen on a laptop display.
    if let screen = self.screen ?? NSScreen.main {
      let visible = screen.visibleFrame
      windowFrame.origin = NSPoint(
        x: visible.midX - defaultSize.width / 2,
        y: visible.midY - defaultSize.height / 2
      )
    }

    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.contentMinSize = minimumContentSize

    RegisterGeneratedPlugins(registry: flutterViewController)

    // SCREEN CAPTURE PROTECTION: screenshots, screen recordings and screen
    // sharing leave this window out (it captures as empty / black).
    // Starts protected; the Control centre switch can lift it
    // (lib/core/settings/screen_protection.dart).
    self.sharingType = .none
    let channel = FlutterMethodChannel(
      name: "asec/screen_protection",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "setEnabled" {
        let on = (call.arguments as? Bool) ?? true
        self?.sharingType = on ? .none : .readOnly
        result(nil)
      } else if call.method == "integrity" {
        // lib/core/settings/app_integrity.dart
        result(MainFlutterWindow.debuggerAttached() ? ["debugger"] : [String]())
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    screenChannel = channel

    super.awakeFromNib()
  }

  /// True while a debugger (lldb, Xcode) is attached to the app.
  static func debuggerAttached() -> Bool {
    var info = kinfo_proc()
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    var size = MemoryLayout<kinfo_proc>.stride
    let rc = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
    return rc == 0 && (info.kp_proc.p_flag & P_TRACED) != 0
  }
}
