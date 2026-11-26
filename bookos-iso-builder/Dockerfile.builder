FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    live-build \
    debootstrap \
    debian-archive-keyring \
    xorriso \
    squashfs-tools \
    isolinux \
    syslinux-common \
    dosfstools \
    mtools \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /builder
COPY . /builder
RUN find /builder -type f \( -name "*.sh" -o -name "*.chroot" -o -path "*/auto/config" \) -exec sed -i 's/\r$//' {} + -exec chmod +x {} + || true

# Chay container voi --privileged de live-build mount proc/sys/dev trong chroot:
# docker build -f Dockerfile.builder -t bookos-builder .
# docker run --rm --privileged -v "$(pwd)/out:/out" bookos-builder bash -c "bash ./build-iso.sh && cp -f google-book-os-*.iso* /out/"
CMD ["bash", "./build-iso.sh"]
