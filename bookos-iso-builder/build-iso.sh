#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Google Book OS — Automated ISO Builder (bookworm amd64)
# Target: Bootable Live/Install ISO for VirtualBox & x86_64 PCs
# ==============================================================================

WORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_ISO="${WORK_DIR}/google-book-os-bookworm-amd64.iso"

if [[ $EUID -ne 0 ]]; then
  echo "[ERROR] Vui long chay script voi quyen root: sudo ./build-iso.sh"
  exit 1
fi

echo "[1/5] Kiem tra cong cu bien dich live-build & keyring..."
MISSING_PKGS=()
for bin in lb debootstrap xorriso mksquashfs; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    MISSING_PKGS+=(live-build debootstrap xorriso squashfs-tools isolinux syslinux-common)
    break
  fi
done
if ! dpkg -s debian-archive-keyring >/dev/null 2>&1; then
  MISSING_PKGS+=(debian-archive-keyring ca-certificates curl)
fi
if [[ ${#MISSING_PKGS[@]} -gt 0 ]]; then
  echo "Dang cai dat: ${MISSING_PKGS[*]}..."
  apt-get update -y
  apt-get install -y "${MISSING_PKGS[@]}"
fi

supports_chroot_mknod() {
  local dir="$1"
  mkdir -p "$dir" 2>/dev/null || return 1
  if command -v findmnt >/dev/null 2>&1; then
    local opts
    opts="$(findmnt -n -o OPTIONS --target "$dir" 2>/dev/null || true)"
    if echo ",$opts," | grep -qE ',(nodev|noexec),'; then
      return 1
    fi
  fi
  local probe_dev="$dir/.bookos-mknod-test"
  local probe_sh="$dir/.bookos-exec-test.sh"
  rm -f "$probe_dev" "$probe_sh"
  if ! mknod "$probe_dev" c 1 3 2>/dev/null; then
    rm -f "$probe_dev"
    return 1
  fi
  rm -f "$probe_dev"
  printf '#!/bin/sh\nexit 0\n' > "$probe_sh"
  chmod +x "$probe_sh"
  if ! "$probe_sh" 2>/dev/null; then
    rm -f "$probe_sh"
    return 1
  fi
  rm -f "$probe_sh"
  return 0
}

BUILD_DIR="$WORK_DIR"
CLEANUP_STAGING=0

if ! supports_chroot_mknod "$WORK_DIR"; then
  echo "[WARN] Thu muc $WORK_DIR bi mount 'nodev/noexec' hoac han che tao device node (thuong gap tren GitHub Codespaces /workspaces)."
  STAGING_DIR="/var/tmp/bookos-build"
  if supports_chroot_mknod "$STAGING_DIR"; then
    echo "[INFO] Tu dong chuyen thu muc bien dich tam sang $STAGING_DIR..."
    rm -rf "$STAGING_DIR"
    mkdir -p "$STAGING_DIR"
    cp -a "$WORK_DIR/auto" "$WORK_DIR/config" "$STAGING_DIR/"
    BUILD_DIR="$STAGING_DIR"
    CLEANUP_STAGING=1
  elif [[ "${BOOKOS_IN_DOCKER:-0}" != "1" ]] && command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    echo "[INFO] Container hien tai chan mknod; chuyen sang Docker --privileged voi Dockerfile.builder..."
    cd "$WORK_DIR"
    docker build -f Dockerfile.builder -t bookos-builder .
    docker run --rm --privileged -e BOOKOS_IN_DOCKER=1 -v "$WORK_DIR:/out" bookos-builder \
      bash -c "./build-iso.sh && cp -f google-book-os-*.iso* build.log /out/"
    exit 0
  else
    echo "=================================================================="
    echo "[LOI MOI TRUONG] Ca '$WORK_DIR' va '/var/tmp' deu khong ho tro mknod/chroot (container khong co CAP_MKNOD)."
    echo "Cach khac phuc nhanh nhat:"
    echo "  1) Push repo len GitHub va chay GitHub Actions (.github/workflows/build-bookos-iso.yml) — mien phi, co VM day du quyen!"
    echo "  2) Hoac chay tren may ao Linux / Ubuntu / WSL2 / Docker --privileged."
    echo "=================================================================="
    exit 1
  fi
fi

cleanup_staging() {
  if [[ "$CLEANUP_STAGING" -eq 1 && -d "$BUILD_DIR" ]]; then
    rm -rf "$BUILD_DIR" || true
  fi
}
trap cleanup_staging EXIT

cd "$BUILD_DIR"
chmod +x auto/config config/hooks/live/*.hook.chroot
chmod +x config/includes.chroot/usr/local/bin/*.sh || true

echo "[2/5] Don dep build cache cu..."
lb clean --purge || true

echo "[3/5] Khoi tao cau hinh live-build (bookworm)..."
lb config

echo "[4/5] Bat dau bien dich rootfs, Chrome, Networkd & DeepSeek AI (10-25 phut)..."
lb build 2>&1 | tee build.log
if [[ "$BUILD_DIR" != "$WORK_DIR" && -f "build.log" ]]; then
  cp -f build.log "$WORK_DIR/build.log"
fi

echo "[5/5] Dong goi file ISO va tinh SHA256..."
if [[ -f "live-image-amd64.hybrid.iso" ]]; then
  mv live-image-amd64.hybrid.iso "$OUT_ISO"
  sha256sum "$OUT_ISO" > "${OUT_ISO}.sha256"
  echo "=================================================================="
  echo "[THANH CONG] Da xuat file ISO: $OUT_ISO"
  echo "Checksum SHA256: $(cat "${OUT_ISO}.sha256")"
  echo "Hay chay ./virtualbox-setup.sh de nap ISO vao VirtualBox va test ngay."
  echo "=================================================================="
else
  echo "[ERROR] Khong tim thay file ISO dau ra. Kiem tra build.log"
  exit 1
fi
