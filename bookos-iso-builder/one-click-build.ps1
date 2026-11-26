# ==============================================================================
# Google Book OS — 1-Click Windows ISO Builder & VirtualBox Launcher
# Yeu cau: Docker Desktop dang chay tren Windows
# ==============================================================================
$ErrorActionPreference = "Stop"

Write-Host "[1/3] Build Docker ISO compiler image..." -ForegroundColor Cyan
docker build -f Dockerfile.builder -t bookos-builder .

New-Item -ItemType Directory -Force -Path ".\out" | Out-Null
Write-Host "[2/3] Dang bien dich file .ISO (mat 10-25 phut)..." -ForegroundColor Cyan
docker run --rm --privileged -v "${PWD}\out:/out" bookos-builder bash -c "./build-iso.sh && cp google-book-os-*.iso* /out/"

$isoFile = Get-ChildItem ".\out\*.iso" | Select-Object -First 1
if ($isoFile) {
  Write-Host "[3/3] Hoan tat! File ISO nam tai: $($isoFile.FullName)" -ForegroundColor Green
  Write-Host "Hay gan file nay vao VirtualBox (Debian 64-bit, RAM 4GB, VMSVGA, NIC NAT 82540EM)."
} else {
  Write-Error "Khong tim thay file ISO trong thu muc out\."
}
