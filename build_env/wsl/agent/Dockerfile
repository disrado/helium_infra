FROM ubuntu:26.04

COPY installers/install_build_packages.sh /tmp/install_build_packages.sh
RUN chmod +x /tmp/install_build_packages.sh && /tmp/install_build_packages.sh

USER ubuntu

COPY --chown=ubuntu:ubuntu installers/install_vcpkg.sh /tmp/install_vcpkg.sh
RUN chmod +x /tmp/install_vcpkg.sh && /tmp/install_vcpkg.sh
ENV VCPKG_ROOT=/home/ubuntu/vcpkg

# pre-create so a fresh named volume mounted here inherits ubuntu ownership instead of root -
# Docker only seeds a new volume's content/ownership from the image on first mount.
RUN mkdir -p /home/ubuntu/.cache/vcpkg
