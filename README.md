# Google Book OS — Huong dan Bien dich ISO & Chay tren VirtualBox

## 1. Kien truc he dieu hanh
- **Nen tang:** Debian 12 (Bookworm) Minimal + Xorg + Openbox & Tint2
- **Trinh duyet chinh:** Google Chrome Stable (Che do cua so toi da kieu ChromeOS)
- **Phim tat Windows:** Alt+Tab, Alt+F4, Ctrl+C/V/X, Ctrl+Shift+T, Phim Windows (Launcher), Win+D (Home)
- **Dieu huong Android:** Thanh Navigation Bar 3 nut (Back, Home, Overview) tren thanh Dock duoi cung
- **Mang co day:** Chi bat `systemd-networkd` cho Ethernet (`eth*`, `en*`) & USB-LAN; chan kernel module Wi-Fi/Bluetooth trong `/etc/modprobe.d/bookos-no-wireless.conf`
- **DeepSeek AI cuc bo:** Ollama (`deepseek-r1:1.5b`) cho Chat & Lap ke hoach + DeepSeek `Janus-Pro-1B-OnDemand` cho Tao anh offline tai cong `127.0.0.1:11435` (phim tat `Alt+D`).

## 2. Bien dich file .iso
### Cach A — Tren Ubuntu / Debian Linux truc tiep:
```bash
chmod +x build-iso.sh
sudo ./build-iso.sh
```

### Cach B — Tren Windows / macOS bang Docker Desktop:
```bash
docker build -f Dockerfile.builder -t bookos-builder .
mkdir -p out
docker run --rm --privileged -v "$(pwd)/out:/out" bookos-builder bash -c "./build-iso.sh && cp google-book-os-*.iso* /out/"
```

## 3. Khoi tao va test tren VirtualBox
Chay script tu dong hoac tao VM thu cong voi thong so:
- **Type / Version:** Linux / Debian (64-bit)
- **RAM:** Toi thieu 4 GB (Khuyen nghi 4 GB de chay DeepSeek cuc bo)
- **Display:** VMSVGA, Video Memory 128MB
- **Network:** Adapter 1 NAT hoac Bridged, Adapter Type Intel PRO/1000 MT Desktop (82540EM), Cable Connected = ON

```bash
chmod +x virtualbox-setup.sh
./virtualbox-setup.sh ./google-book-os-bookworm-amd64.iso
```
