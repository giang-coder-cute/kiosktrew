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

# Chay container voi --privileged de live-build mount proc/sys/dev trong chroot:
# docker build -f Dockerfile.builder -t bookos-builder .
# docker run --rm --privileged -v "$(pwd)/out:/out" bookos-builder bash -c "./build-iso.sh && cp google-book-os-*.iso* /out/"
CMD ["./build-iso.sh"]
