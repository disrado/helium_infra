FROM ubuntu:26.04

COPY installers/install_build_packages.sh /tmp/install_build_packages.sh
RUN chmod +x /tmp/install_build_packages.sh && /tmp/install_build_packages.sh

USER ubuntu

COPY installers/install_vcpkg.sh /tmp/install_vcpkg.sh
RUN chmod +x /tmp/install_vcpkg.sh && /tmp/install_vcpkg.sh
ENV VCPKG_ROOT=/home/ubuntu/vcpkg
