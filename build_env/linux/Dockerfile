FROM ubuntu:26.04

RUN apt-get update && apt-get install -y \
    libc6-dev make dpkg-dev python3-pip ninja-build git curl zip unzip tar pkg-config \
    libx11-dev libxcursor-dev libxrandr-dev libxi-dev libxext-dev libxft-dev libxtst-dev \
    libgl1-mesa-dev libwayland-dev libxkbcommon-dev libegl1-mesa-dev \
    gcc-16 g++-16 \
    && pip install --break-system-packages cmake \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/microsoft/vcpkg /opt/vcpkg && /opt/vcpkg/bootstrap-vcpkg.sh
ENV VCPKG_ROOT=/opt/vcpkg