#!/usr/bin/env bash
# Khoi chay giao dien Google Book OS khi user 'bookos' dang nhap
tint2 &
feh --bg-fill /usr/share/backgrounds/bookos-wallpaper.jpg &

# Dam bao Ethernet duoc cap DHCP ngay
sudo systemctl start systemd-networkd || true

# Khoi chay Google Chrome lam moi truong lam viec chinh
exec google-chrome-stable --start-maximized --no-first-run --enable-features=TouchpadOverscrollHistoryNavigation
