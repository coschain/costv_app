import 'package:costv_android/event/base/event_bus_help.dart';
import 'package:costv_android/event/video_small_windows_event.dart';
import 'package:flutter/material.dart';

class OverlayVideoSmallWindowsUtils {
//  static const channelVideoSmallWindows = 'com.contentos.plugin/video_small_windows';
//  static const videoSmallWindowsOpenWindows = "open_windows";
//  static const videoSmallWindowsCloseWindows = "close_windows";
//  static const videoSmallWindowsOpenVideoDetails = "open_video_details";

//  static const platformSdk =
//      const MethodChannel(channelVideoSmallWindows);

  static OverlayVideoSmallWindowsUtils? _instance;

  factory OverlayVideoSmallWindowsUtils() => _getInstance();

  static OverlayVideoSmallWindowsUtils get instance => _getInstance();

  OverlayVideoSmallWindowsUtils._();

  static OverlayVideoSmallWindowsUtils _getInstance() {
    if (_instance == null) {
      _instance = OverlayVideoSmallWindowsUtils._();
    }
    return _instance!;
  }

  OverlayEntry? _overlayEntry;

  bool _isShow = false;

  showVideoSmallWindow(BuildContext context, Widget child) {
    _isShow = true;
    _overlayEntry = OverlayEntry(builder: (context) {
      return child;
    });
    Overlay.of(context).insert(_overlayEntry!);
    EventBusHelp.getInstance().fire(VideoSmallWindowsEvent(VideoSmallWindowsEvent.statusSmallWindowsShow));
  }

  removeVideoSmallWindow() {
    if (_isShow) {
      _overlayEntry?.remove();
    }
    EventBusHelp.getInstance().fire(VideoSmallWindowsEvent(VideoSmallWindowsEvent.statusSmallWindowsClose));
    _isShow = false;
  }

  bool checkIsShowWindow() {
    return _isShow;
  }
}
