#include "flutter_window.h"

#include <optional>
#include <string>

#include "flutter/generated_plugin_registrant.h"
#include "resource.h"

namespace {
constexpr int kHotkeyMediaPlayPause = 1001;
constexpr int kHotkeyMediaNext = 1002;
constexpr int kHotkeyMediaPrev = 1003;
constexpr int kHotkeyMediaStop = 1004;

constexpr UINT kWM_TrayIcon = WM_USER + 101;
constexpr UINT kTrayIconId = 1;

constexpr UINT kTrayCmdRestore = 2001;
constexpr UINT kTrayCmdPlayPause = 2002;
constexpr UINT kTrayCmdNext = 2003;
constexpr UINT kTrayCmdPrev = 2004;
constexpr UINT kTrayCmdExit = 2005;
}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

void FlutterWindow::ShowTrayIcon() {
  if (tray_icon_active_) return;
  HWND hwnd = GetHandle();
  if (!hwnd) return;

  memset(&nid_, 0, sizeof(NOTIFYICONDATA));
  nid_.cbSize = sizeof(NOTIFYICONDATA);
  nid_.hWnd = hwnd;
  nid_.uID = kTrayIconId;
  nid_.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
  nid_.uCallbackMessage = kWM_TrayIcon;
  nid_.hIcon = LoadIcon(GetModuleHandle(nullptr), MAKEINTRESOURCE(IDI_APP_ICON));
  if (!nid_.hIcon) {
    nid_.hIcon = LoadIcon(nullptr, IDI_APPLICATION);
  }
  wcscpy_s(nid_.szTip, L"Euphony Music");
  Shell_NotifyIcon(NIM_ADD, &nid_);
  tray_icon_active_ = true;
}

void FlutterWindow::HideTrayIcon() {
  if (!tray_icon_active_) return;
  Shell_NotifyIcon(NIM_DELETE, &nid_);
  tray_icon_active_ = false;
}

void FlutterWindow::MinimizeToTray() {
  ShowTrayIcon();
  HWND hwnd = GetHandle();
  if (hwnd) {
    ShowWindow(hwnd, SW_HIDE);
  }
}

void FlutterWindow::RestoreFromTray() {
  HWND hwnd = GetHandle();
  if (hwnd) {
    ShowWindow(hwnd, SW_RESTORE);
    SetForegroundWindow(hwnd);
  }
}

void FlutterWindow::SetMiniMode(bool enable) {
  HWND hwnd = GetHandle();
  if (!hwnd) return;

  if (enable && !is_mini_mode_) {
    GetWindowRect(hwnd, &normal_rect_);
    is_mini_mode_ = true;

    // Position mini player in bottom right of desktop work area
    RECT work_area;
    SystemParametersInfo(SPI_GETWORKAREA, 0, &work_area, 0);
    int mini_w = 380;
    int mini_h = 135;
    int x = work_area.right - mini_w - 24;
    int y = work_area.bottom - mini_h - 24;

    SetWindowPos(hwnd, HWND_TOPMOST, x, y, mini_w, mini_h, SWP_SHOWWINDOW);
  } else if (!enable && is_mini_mode_) {
    is_mini_mode_ = false;
    int w = normal_rect_.right - normal_rect_.left;
    int h = normal_rect_.bottom - normal_rect_.top;
    if (w < 900 || h < 600) {
      w = 1200;
      h = 760;
    }
    SetWindowPos(hwnd, HWND_NOTOPMOST, normal_rect_.left, normal_rect_.top, w, h, SWP_SHOWWINDOW);
  }
}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Set up native media & window management channel
  media_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "com.mhdni.euphony/desktop_media",
          &flutter::StandardMethodCodec::GetInstance());

  media_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        const std::string& method = call.method_name();
        if (method == "enterMiniPlayer") {
          SetMiniMode(true);
          result->Success();
        } else if (method == "exitMiniPlayer") {
          SetMiniMode(false);
          result->Success();
        } else if (method == "minimizeToTray") {
          MinimizeToTray();
          result->Success();
        } else if (method == "restoreFromTray") {
          RestoreFromTray();
          result->Success();
        } else if (method == "setCloseToTray") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (args) {
            auto it = args->find(flutter::EncodableValue("enabled"));
            if (it != args->end()) {
              close_to_tray_ = std::get<bool>(it->second);
            }
          }
          result->Success();
        } else {
          result->NotImplemented();
        }
      });

  // Register global hotkeys for media controls so media keys work even when
  // Euphony is minimized or running in the background.
  HWND hwnd = GetHandle();
  if (hwnd) {
    RegisterHotKey(hwnd, kHotkeyMediaPlayPause, 0, VK_MEDIA_PLAY_PAUSE);
    RegisterHotKey(hwnd, kHotkeyMediaNext, 0, VK_MEDIA_NEXT_TRACK);
    RegisterHotKey(hwnd, kHotkeyMediaPrev, 0, VK_MEDIA_PREV_TRACK);
    RegisterHotKey(hwnd, kHotkeyMediaStop, 0, VK_MEDIA_STOP);
  }

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  HideTrayIcon();

  HWND hwnd = GetHandle();
  if (hwnd) {
    UnregisterHotKey(hwnd, kHotkeyMediaPlayPause);
    UnregisterHotKey(hwnd, kHotkeyMediaNext);
    UnregisterHotKey(hwnd, kHotkeyMediaPrev);
    UnregisterHotKey(hwnd, kHotkeyMediaStop);
  }
  media_channel_ = nullptr;

  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_CLOSE: {
      if (close_to_tray_) {
        MinimizeToTray();
        return 0;
      }
      break;
    }
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_GETMINMAXINFO: {
      MINMAXINFO* info = reinterpret_cast<MINMAXINFO*>(lparam);
      if (is_mini_mode_) {
        info->ptMinTrackSize.x = 300;
        info->ptMinTrackSize.y = 100;
      } else {
        info->ptMinTrackSize.x = 900;
        info->ptMinTrackSize.y = 600;
      }
      return 0;
    }
    case kWM_TrayIcon: {
      if (lparam == WM_LBUTTONUP || lparam == WM_LBUTTONDBLCLK) {
        RestoreFromTray();
        return 0;
      } else if (lparam == WM_RBUTTONUP) {
        POINT pt;
        GetCursorPos(&pt);
        HMENU menu = CreatePopupMenu();
        InsertMenuW(menu, 0, MF_BYPOSITION | MF_STRING, kTrayCmdRestore, L"Open Euphony");
        InsertMenuW(menu, 1, MF_BYPOSITION | MF_SEPARATOR, 0, nullptr);
        InsertMenuW(menu, 2, MF_BYPOSITION | MF_STRING, kTrayCmdPlayPause, L"Play / Pause");
        InsertMenuW(menu, 3, MF_BYPOSITION | MF_STRING, kTrayCmdNext, L"Next Track");
        InsertMenuW(menu, 4, MF_BYPOSITION | MF_STRING, kTrayCmdPrev, L"Previous Track");
        InsertMenuW(menu, 5, MF_BYPOSITION | MF_SEPARATOR, 0, nullptr);
        InsertMenuW(menu, 6, MF_BYPOSITION | MF_STRING, kTrayCmdExit, L"Exit");

        SetForegroundWindow(hwnd);
        int cmd = TrackPopupMenu(menu, TPM_RETURNCMD | TPM_NONOTIFY, pt.x, pt.y, 0, hwnd, nullptr);
        DestroyMenu(menu);

        if (cmd == kTrayCmdRestore) {
          RestoreFromTray();
        } else if (cmd == kTrayCmdPlayPause && media_channel_) {
          media_channel_->InvokeMethod("playPause", nullptr);
        } else if (cmd == kTrayCmdNext && media_channel_) {
          media_channel_->InvokeMethod("next", nullptr);
        } else if (cmd == kTrayCmdPrev && media_channel_) {
          media_channel_->InvokeMethod("previous", nullptr);
        } else if (cmd == kTrayCmdExit) {
          HideTrayIcon();
          DestroyWindow(hwnd);
        }
        return 0;
      }
      break;
    }
    case WM_HOTKEY: {
      if (media_channel_) {
        switch (wparam) {
          case kHotkeyMediaPlayPause:
            media_channel_->InvokeMethod("playPause", nullptr);
            return 0;
          case kHotkeyMediaNext:
            media_channel_->InvokeMethod("next", nullptr);
            return 0;
          case kHotkeyMediaPrev:
            media_channel_->InvokeMethod("previous", nullptr);
            return 0;
          case kHotkeyMediaStop:
            media_channel_->InvokeMethod("stop", nullptr);
            return 0;
        }
      }
      break;
    }
    case WM_APPCOMMAND: {
      DWORD cmd = GET_APPCOMMAND_LPARAM(lparam);
      if (media_channel_) {
        switch (cmd) {
          case APPCOMMAND_MEDIA_PLAY_PAUSE:
            media_channel_->InvokeMethod("playPause", nullptr);
            return TRUE;
          case APPCOMMAND_MEDIA_PLAY:
            media_channel_->InvokeMethod("play", nullptr);
            return TRUE;
          case APPCOMMAND_MEDIA_PAUSE:
            media_channel_->InvokeMethod("pause", nullptr);
            return TRUE;
          case APPCOMMAND_MEDIA_NEXTTRACK:
            media_channel_->InvokeMethod("next", nullptr);
            return TRUE;
          case APPCOMMAND_MEDIA_PREVIOUSTRACK:
            media_channel_->InvokeMethod("previous", nullptr);
            return TRUE;
          case APPCOMMAND_MEDIA_STOP:
            media_channel_->InvokeMethod("stop", nullptr);
            return TRUE;
        }
      }
      break;
    }
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
