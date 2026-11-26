#!/usr/bin/env bash
# ==============================================================================
# Google Book OS — Android-Style Navigation Action Handler (Touch & Mouse)
# Duoc goi tu thanh Dock Tint2 hoac phan mem cam ung
# ==============================================================================

ACTION="${1:-home}"

case "$ACTION" in
  back)
    # Gui phim Alt+Left de quay lai trang truoc trong Chrome / File Manager
    xdotool key --clearmodifiers alt+Left
    ;;
  home)
    # Thu nho tat ca cua so ve man hinh chinh / Launcher kieu ChromeOS
    xdotool key --clearmodifiers Super_L+d
    ;;
  overview)
    # Hien thi danh sach cua so dang mo (Recent Apps) kieu Android Overview
    rofi -show window -show-icons -theme-str 'window {width: 55%; border-radius: 14px;}'
    ;;
  deepseek)
    # Mo cua so DeepSeek AI (Chat, Planner, Janus Image)
    google-chrome-stable --app=http://127.0.0.1:11435 &
    ;;
  chrome)
    google-chrome-stable --start-maximized --no-first-run --enable-features=TouchpadOverscrollHistoryNavigation &
    ;;
  *)
    echo "Usage: $0 {back|home|overview|deepseek|chrome}"
    exit 1
    ;;
esac
