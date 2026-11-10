#include "flutter_window.h"

#include <intrin.h>

#include <cstring>

#include <optional>
#include <string>
#include <variant>

#include <flutter/standard_method_codec.h>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // SCREEN CAPTURE PROTECTION: screenshots, screen recordings and screen
  // sharing show this window as black (Windows 10 2004+; older versions fall
  // back to WDA_MONITOR, which does the same for most capture tools).
  // Starts protected; the Control centre switch can lift it.
  ApplyScreenProtection(true);

  screen_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "asec/screen_protection",
      &flutter::StandardMethodCodec::GetInstance());
  screen_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "setEnabled") {
          bool on = true;
          if (const auto* value = std::get_if<bool>(call.arguments())) {
            on = *value;
          }
          ApplyScreenProtection(on);
          result->Success();
        } else if (call.method_name() == "integrity") {
          // lib/core/settings/app_integrity.dart
          flutter::EncodableList issues;
          BOOL remote = FALSE;
          ::CheckRemoteDebuggerPresent(::GetCurrentProcess(), &remote);
          if (::IsDebuggerPresent() || remote) {
            issues.push_back(flutter::EncodableValue(std::string("debugger")));
          }
          result->Success(flutter::EncodableValue(issues));
        } else if (call.method_name() == "cpuInfo") {
          // lib/core/settings/device_specs.dart (06/11/2026). Old CPUs without
          // BMI2 crash in Firebase's Firestore code (0xc000001d) — this says
          // which PCs those are.
          flutter::EncodableMap info;
          int r[4] = {0, 0, 0, 0};
          char brand[49] = {0};
          __cpuid(r, static_cast<int>(0x80000000u));
          if (static_cast<unsigned int>(r[0]) >= 0x80000004u) {
            for (int i = 0; i < 3; i++) {
              __cpuid(r, static_cast<int>(0x80000002u + static_cast<unsigned int>(i)));
              memcpy(brand + i * 16, r, 16);
            }
          }
          __cpuid(r, 0);
          const int max_leaf = r[0];
          __cpuid(r, 1);
          const bool avx = (r[2] & (1 << 28)) != 0;
          bool avx2 = false;
          bool bmi1 = false;
          bool bmi2 = false;
          if (max_leaf >= 7) {
            __cpuidex(r, 7, 0);
            bmi1 = (r[1] & (1 << 3)) != 0;
            avx2 = (r[1] & (1 << 5)) != 0;
            bmi2 = (r[1] & (1 << 8)) != 0;
          }
          SYSTEM_INFO si;
          ::GetNativeSystemInfo(&si);
          MEMORYSTATUSEX mem;
          mem.dwLength = sizeof(mem);
          double ram_gb = 0;
          if (::GlobalMemoryStatusEx(&mem)) {
            ram_gb = static_cast<double>(mem.ullTotalPhys) / (1024.0 * 1024.0 * 1024.0);
          }
          info[flutter::EncodableValue("cpu")] = flutter::EncodableValue(std::string(brand));
          info[flutter::EncodableValue("avx")] = flutter::EncodableValue(avx);
          info[flutter::EncodableValue("avx2")] = flutter::EncodableValue(avx2);
          info[flutter::EncodableValue("bmi1")] = flutter::EncodableValue(bmi1);
          info[flutter::EncodableValue("bmi2")] = flutter::EncodableValue(bmi2);
          info[flutter::EncodableValue("cores")] =
              flutter::EncodableValue(static_cast<int32_t>(si.dwNumberOfProcessors));
          info[flutter::EncodableValue("ram_gb")] = flutter::EncodableValue(ram_gb);
          result->Success(flutter::EncodableValue(info));
        } else {
          result->NotImplemented();
        }
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::ApplyScreenProtection(bool on) {
  if (on) {
    if (!::SetWindowDisplayAffinity(GetHandle(), 0x00000011 /* WDA_EXCLUDEFROMCAPTURE */)) {
      ::SetWindowDisplayAffinity(GetHandle(), WDA_MONITOR);
    }
  } else {
    ::SetWindowDisplayAffinity(GetHandle(), WDA_NONE);
  }
}

void FlutterWindow::OnDestroy() {
  screen_channel_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
