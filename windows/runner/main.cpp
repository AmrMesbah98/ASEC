#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <csignal>
#include <cstdio>
#include <cstring>
#include <cwchar>
#include <exception>

#include "flutter_window.h"
#include "utils.h"

// ── NATIVE CRASH RECORDER (05/11/2026) ─────────────────────────────────────
// A crash inside a DLL (Firebase, the video player, Flutter) kills ASEC
// before any Dart code can report it. This writes WHAT crashed — exception
// code and the DLL it happened in — to %LOCALAPPDATA%\ASEC\native_crash.txt.
// The next start sends it with the crash report (CrashTracker), then deletes
// it. Windows Error Reporting still runs afterwards as before.
static wchar_t g_crash_file[MAX_PATH] = L"";

static void WriteCrashLine(const char* text) {
  if (g_crash_file[0] == L'\0') return;
  HANDLE f = ::CreateFileW(g_crash_file, GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS,
                           FILE_ATTRIBUTE_NORMAL, nullptr);
  if (f == INVALID_HANDLE_VALUE) return;
  DWORD written = 0;
  ::WriteFile(f, text, static_cast<DWORD>(strlen(text)), &written, nullptr);
  ::FlushFileBuffers(f);
  ::CloseHandle(f);
}

static void StampNow(char* out, size_t size) {
  SYSTEMTIME t;
  ::GetLocalTime(&t);
  _snprintf_s(out, size, _TRUNCATE, "%04d-%02d-%02d %02d:%02d:%02d", t.wYear, t.wMonth, t.wDay,
              t.wHour, t.wMinute, t.wSecond);
}

static void ModuleNameOf(HMODULE module, char* out, size_t size) {
  strncpy_s(out, size, "unknown", _TRUNCATE);
  if (module == nullptr) return;
  char path[MAX_PATH] = "";
  if (::GetModuleFileNameA(module, path, MAX_PATH) > 0) {
    const char* slash = strrchr(path, '\\');
    strncpy_s(out, size, slash != nullptr ? slash + 1 : path, _TRUNCATE);
  }
}

static HMODULE ModuleAt(const void* address) {
  HMODULE module = nullptr;
  if (!::GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                                GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                            static_cast<LPCSTR>(address), &module)) {
    return nullptr;
  }
  return module;
}

// An unhandled C++ exception (0xE06D7363) is always raised from
// KERNELBASE.dll, which says nothing. The exception record also carries WHO
// threw it (the DLL), its C++ type and — for a std::exception — its message
// (e.g. a Firebase error). Read with the MSVC x64 throw layout, guarded so a
// surprise can never crash the recorder itself. No C++ objects in here
// (required by __try).
static void DescribeCppException(const EXCEPTION_RECORD* rec, char* thrower, size_t thrower_size,
                                 char* type_name, size_t type_size, char* message,
                                 size_t message_size) {
  strncpy_s(thrower, thrower_size, "unknown", _TRUNCATE);
  type_name[0] = '\0';
  message[0] = '\0';
  if (rec->ExceptionCode != 0xE06D7363 || rec->NumberParameters < 4) return;
  const ULONG_PTR object = rec->ExceptionInformation[1];
  const ULONG_PTR throw_info = rec->ExceptionInformation[2];
  const ULONG_PTR base = rec->ExceptionInformation[3];
  ModuleNameOf(reinterpret_cast<HMODULE>(base), thrower, thrower_size);
  __try {
    if (throw_info == 0 || base == 0) return;
    // ThrowInfo: attributes, pmfnUnwind, pForwardCompat, pCatchableTypeArray (RVAs).
    const int* ti = reinterpret_cast<const int*>(throw_info);
    const int* types = reinterpret_cast<const int*>(base + static_cast<ULONG_PTR>(ti[3]));
    const int count = types[0];
    for (int i = 0; i < count && i < 16; i++) {
      // CatchableType: properties, pType (RVA), mdisp, pdisp, vdisp, size, copy.
      const int* ct = reinterpret_cast<const int*>(base + static_cast<ULONG_PTR>(types[1 + i]));
      // TypeDescriptor: vftable pointer, spare pointer, then the decorated name.
      const char* name = reinterpret_cast<const char*>(base + static_cast<ULONG_PTR>(ct[1])) + 16;
      if (i == 0) strncpy_s(type_name, type_size, name, _TRUNCATE);
      if (strcmp(name, ".?AVexception@std@@") == 0 && object != 0) {
        const std::exception* e =
            reinterpret_cast<const std::exception*>(object + static_cast<ULONG_PTR>(static_cast<LONG_PTR>(ct[2])));
        const char* what = e->what();
        if (what != nullptr) strncpy_s(message, message_size, what, _TRUNCATE);
        break;
      }
    }
  } __except (EXCEPTION_EXECUTE_HANDLER) {
  }
}

// The DLLs on the crashing thread's stack, nearest first (who called whom).
static void StackModules(char* out, size_t size) {
  out[0] = '\0';
  __try {
    void* frames[48] = {};
    const USHORT n = ::RtlCaptureStackBackTrace(0, 48, frames, nullptr);
    char last[MAX_PATH] = "";
    int listed = 0;
    for (USHORT i = 0; i < n && listed < 12; i++) {
      char name[MAX_PATH];
      ModuleNameOf(ModuleAt(frames[i]), name, sizeof(name));
      if (strcmp(name, last) == 0) continue;
      strncpy_s(last, sizeof(last), name, _TRUNCATE);
      if (listed > 0) strncat_s(out, size, " <- ", _TRUNCATE);
      strncat_s(out, size, name, _TRUNCATE);
      listed++;
    }
  } __except (EXCEPTION_EXECUTE_HANDLER) {
  }
}

static LONG WINAPI OnNativeCrash(EXCEPTION_POINTERS* info) {
  char module_name[MAX_PATH] = "unknown";
  unsigned long long offset = 0;
  DWORD code = 0;
  char thrower[MAX_PATH] = "";
  char type_name[256] = "";
  char message[512] = "";
  if (info != nullptr && info->ExceptionRecord != nullptr) {
    code = info->ExceptionRecord->ExceptionCode;
    void* address = info->ExceptionRecord->ExceptionAddress;
    HMODULE module = ModuleAt(address);
    if (module != nullptr) {
      ModuleNameOf(module, module_name, sizeof(module_name));
      offset = reinterpret_cast<unsigned long long>(address) -
               reinterpret_cast<unsigned long long>(module);
    }
    DescribeCppException(info->ExceptionRecord, thrower, sizeof(thrower), type_name,
                         sizeof(type_name), message, sizeof(message));
  }
  char stack[1024];
  StackModules(stack, sizeof(stack));
  char when[32];
  StampNow(when, sizeof(when));
  char text[2560];
  if (code == 0xE06D7363) {
    _snprintf_s(text, sizeof(text), _TRUNCATE,
                "Native crash at %s\nException code: 0x%08lx (unhandled C++ exception)\n"
                "THROWN BY: %s\nC++ type: %s\nMessage: %s\nStack: %s\nThread: %lu\n",
                when, code, thrower, type_name[0] ? type_name : "?", message[0] ? message : "(none)",
                stack, ::GetCurrentThreadId());
  } else {
    _snprintf_s(text, sizeof(text), _TRUNCATE,
                "Native crash at %s\nException code: 0x%08lx\nIn module: %s + 0x%llx\nStack: %s\nThread: %lu\n",
                when, code, module_name, offset, stack, ::GetCurrentThreadId());
  }
  WriteCrashLine(text);
  return EXCEPTION_CONTINUE_SEARCH;
}

static void OnAbort(int) {
  char when[32];
  StampNow(when, sizeof(when));
  char text[256];
  _snprintf_s(text, sizeof(text), _TRUNCATE,
              "Native crash at %s\nabort() called (a plugin hit a fatal error)\nThread: %lu\n", when,
              ::GetCurrentThreadId());
  WriteCrashLine(text);
}

static void InstallCrashRecorder() {
  wchar_t base[MAX_PATH] = L"";
  const DWORD n = ::GetEnvironmentVariableW(L"LOCALAPPDATA", base, MAX_PATH);
  if (n == 0 || n >= MAX_PATH) return;
  wchar_t dir[MAX_PATH];
  swprintf_s(dir, MAX_PATH, L"%ls\\ASEC", base);
  ::CreateDirectoryW(dir, nullptr);
  swprintf_s(g_crash_file, MAX_PATH, L"%ls\\native_crash.txt", dir);
  ::SetUnhandledExceptionFilter(OnNativeCrash);
  signal(SIGABRT, OnAbort);
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  InstallCrashRecorder();

  // ONE ASEC AT A TIME (06/11/2026, from ENGX). Two ASEC.exe at once
  // crash: Firebase's C++ SDK keeps local files only one process may lock.
  // Opening ASEC again brings the open window to the front instead; if
  // the old one is still closing, wait for it.
  HANDLE single = ::CreateMutexW(nullptr, TRUE, L"Local\\ASEC_SingleInstance");
  if (single != nullptr && ::GetLastError() == ERROR_ALREADY_EXISTS) {
    HWND open = ::FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", L"ASEC");
    if (open != nullptr) {
      if (::IsIconic(open)) ::ShowWindow(open, SW_RESTORE);
      ::SetForegroundWindow(open);
      ::CloseHandle(single);
      return EXIT_SUCCESS;
    }
    const DWORD waited = ::WaitForSingleObject(single, 10000);
    if (waited != WAIT_OBJECT_0 && waited != WAIT_ABANDONED) {
      ::CloseHandle(single);
      return EXIT_SUCCESS;
    }
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 760);
  if (!window.Create(L"ASEC", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  if (single != nullptr) {
    ::ReleaseMutex(single);
    ::CloseHandle(single);
  }
  return EXIT_SUCCESS;
}
