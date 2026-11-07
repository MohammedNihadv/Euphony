#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"

namespace {
constexpr int kHotkeyMediaPlayPause = 1001;
constexpr int kHotkeyMediaNext = 1002;
constexpr int kHotkeyMediaPrev = 1003;
constexpr int kHotkeyMediaStop = 1004;
}  // namespace

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

  // Set up native media channel for hardware media keys (keyboard, Bluetooth AVRCP)
  media_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "com.mhdni.euphony/desktop_media",
          &flutter::StandardMethodCodec::GetInstance());

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

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
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
    case WM_GETMINMAXINFO: {
      MINMAXINFO* info = reinterpret_cast<MINMAXINFO*>(lparam);
      info->ptMinTrackSize.x = 900;
      info->ptMinTrackSize.y = 600;
      return 0;
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
