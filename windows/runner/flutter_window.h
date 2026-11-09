#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <shellapi.h>
#include <dwmapi.h>

#include <memory>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  void SetMiniMode(bool enable);
  void ShowTrayIcon();
  void HideTrayIcon();
  void MinimizeToTray();
  void RestoreFromTray();

  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // Channel to dispatch hardware media keys & Bluetooth AVRCP actions to Dart.
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> media_channel_;

  bool is_mini_mode_ = false;
  bool close_to_tray_ = false;
  RECT normal_rect_ = {0};
  LONG_PTR normal_style_ = 0;
  LONG_PTR normal_ex_style_ = 0;
  NOTIFYICONDATA nid_ = {0};
  bool tray_icon_active_ = false;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
