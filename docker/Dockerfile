FROM ubuntu:focal
MAINTAINER Joko Sastriawan
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get -y upgrade \
 && apt-get -y install tzdata \
 && apt-get -y install apt-utils \
 && apt-get -y install build-essential \
	git devscripts libfdt-dev libpixman-1-dev libssl-dev \
	bison flex kernel-package vim socat libsdl1.2-dev libsdl2-dev \ 
	libspice-server-dev autoconf libtool \
	python-dev liblzma-dev libc6-dev libegl1-mesa-dev \
	libepoxy-dev libdrm-dev libgbm-dev wget lz4 \
	libegl1-mesa-dev libgtk2.0-dev libusb-1.0-0-dev \
	device-tree-compiler texinfo python3-sphinx libaio-dev \ 
	libattr1-dev libbrlapi-dev libcap-dev libcap-ng-dev \ 
	libcurl4-gnutls-dev gnutls-dev libgtk-3-dev libvte-2.91-dev \
	libiscsi-dev libncursesw5-dev libvirglrenderer-dev \
	libnuma-dev librados-dev librbd-dev libsasl2-dev \
	libseccomp-dev librdmacm-dev libibverbs-dev libibumad-dev \
 	libusbredirparser-dev libssh-dev libxen-dev nettle-dev \
	uuid-dev xfslibs-dev libjpeg-dev libpmem-dev \
	gcc-s390x-linux-gnu gcc-alpha-linux-gnu net-tools \
	libc6.1-dev-alpha-cross gcc-powerpc64-linux-gnu rsync libelf-dev \
  uuid-dev nasm acpidump iasl mtools dosfstools unzip pkg-config \
 && apt-get clean
#ENTRYPOINT ["/bin/bash", "-c", "cd /build/docker; ./build-docker.sh"]
