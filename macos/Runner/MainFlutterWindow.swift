import Cocoa
import FlutterMacOS
import Security

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
    // 03/11/2026: DEBUG runs may be dragged down to phone size (360 x 600)
    // to test the mobile layouts; the release build keeps 1100 x 700.
    #if DEBUG
    let minimumContentSize = NSSize(width: 360, height: 600)
    #else
    let minimumContentSize = NSSize(width: 1100, height: 700)
    #endif

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
      } else if call.method == "stableId" {
        // lib/.../device_identity.dart (ported from ENGX v1.0.46): the
        // device id lives in the Keychain, which survives removing ASEC, so
        // a reinstall is not "another device" for the video lock.
        result(AsecDeviceId.get(seed: call.arguments as? String))
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

/// The app's device id in the Keychain (this Mac only, not synced). The
/// first call stores [seed] — the id the app already had — so members who
/// update keep their device; later calls, also after a reinstall, return
/// the stored one. Same as ios/Runner/AppDelegate.swift.
enum AsecDeviceId {
  private static let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: "com.asec.app.device",
    kSecAttrAccount as String: "device_id",
    kSecUseDataProtectionKeychain as String: true,
  ]

  static func get(seed: String?) -> String? {
    var read = query
    read[kSecReturnData as String] = true
    read[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    if SecItemCopyMatching(read as CFDictionary, &item) == errSecSuccess,
       let data = item as? Data, let id = String(data: data, encoding: .utf8), id.count >= 16 {
      return id
    }
    guard let id = seed, id.count >= 16 else { return nil }
    var add = query
    add[kSecValueData as String] = Data(id.utf8)
    add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    SecItemDelete(query as CFDictionary)
    return SecItemAdd(add as CFDictionary, nil) == errSecSuccess ? id : nil
  }
}
