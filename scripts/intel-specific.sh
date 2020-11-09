#!/bin/bash

export PrefixPath=/usr
export LibPath=/usr/lib/x86_64-linux-gnu
export nproc=20
export WrkDir=`pwd`
#!/bin/bash
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'

http_proxy="http://proxy-jf.intel.com:911/"
https_proxy="https://proxy-jf.intel.com:911/"
ftp_proxy="ftp://proxy-jf.intel.com:911/"
socks_proxy="socks://proxy-jf.intel.com:1080/"

#Media Packages
LIBDRM_COMMIT_ID=libdrm-2.4.99
LIBVA_COMMIT_ID=6456e003dfb45c2df5f785cdcbc21b07302c08ec
GMMLIB_COMMIT_ID=d7a0586104096f3e2241e2a773c6bc41a9e2c422
MEDIA_COMMIT_ID=intel-media-20.2.pre3
MSDK_COMMIT_ID=intel-mediasdk-20.1.1
#Gstreamer Packages
GST_COMMIT_ID=33557f8db1971198f06f42034b077a736269018a
GST_ORC_COMMIT_ID=5f5b9b1208b3dfcce50c415ad0272d816ea4e308
GST_BASE_COMMIT_ID=02602dd63c7cd6d08e4f9052f8de971fe43090c7
GST_GOOD_COMMIT_ID=6fba2e3dd35a24bc881cc8b8ea35da186f290f34
GST_BAD_COMMIT_ID=610e477565b13ca300d03d95d21857187d00b84a
GST_UGLY_COMMIT_ID=bef9a9b318ab7032ea5a0d9c045ebb6dbb266545
GST_VAAPI_COMMIT_ID=1c5f32b5cd0ba48f12201565f76aa550733e544a
#Graphics Packages
WAYLAND_COMMIT_ID=1.18.0
WAYLAND_PROTOCOL_COMMIT_ID=1.20
WESTON_COMMIT_ID=8.0.0
MESA_COMMIT_ID=20.0
#MESON Package
MESON_UPGRADE_VERSION=0.49.0
#QEMU Package
QEMU_VERSION=qemu-4.2.0
#i915 Firmware Packages
DMC_FIRMWARE_VERSION=2_06
GUC_FIRMWARE_VERSION=45.0.0
HUC_FIRMWARE_VERSION=7.0.12
#SNA Driver Internal
SNA_COMMIT_ID=dev_ww25_2020
XSERVER_COMMIT_ID=headless
#KERNEL DEB PACKAGE
KERNEL_VERSION=2678

function setup_intel_proxy()
{
	echo -e ${YELLOW}
	read -p "Do you want to setup network proxy? [y/n]" res
	if [ x$res = xy ]; then
		echo "Acquire::http::Proxy \"$http_proxy\";" | sudo tee -a /etc/apt/apt.conf.d/proxy.conf
		echo "Acquire::https::Proxy \"$https_proxy\";" | sudo tee -a /etc/apt/apt.conf.d/proxy.conf
		echo "Acquire::ftp::Proxy \"$ftp_proxy\";" | sudo tee -a /etc/apt/apt.conf.d/proxy.conf
		echo "Acquire::socks::Proxy \"$socks_proxy\";" | sudo tee -a /etc/apt/apt.conf.d/proxy.conf
		echo "http_proxy="$http_proxy | sudo tee -a /etc/wgetrc
		echo "https_proxy="$https_proxy | sudo tee -a /etc/wgetrc
		echo "ftp_proxy="$ftp_proxy | sudo tee -a /etc/wgetrc
		echo "http_proxy="$http_proxy | sudo tee -a /etc/environment
		echo "https_proxy="$https_proxy | sudo tee -a /etc/environment
		echo "ftp_proxy="$ftp_proxy | sudo tee -a /etc/environment
		echo "socks_proxy="$socks_proxy | sudo tee -a /etc/environment
		echo "HTTP_PROXY="$http_proxy | sudo tee -a /etc/environment
		echo "HTTPS_PROXY="$https_proxy | sudo tee -a /etc/environment
		echo "FTP_PROXY="$ftp_proxy | sudo tee -a /etc/environment
		echo "SOCKS_PROXY="$socks_proxy | sudo tee -a /etc/environment

		echo "export GIT_PROXY_COMMAND=~/bin/git_proxy_command" | sudo tee -a ~/.bashrc
		echo "if ! [ -x $GIT_PROXY_COMMAND ]; then" | sudo tee -a ~/.bashrc
		echo "    printf "#!/bin/sh\nconnect-proxy -s \$@\n" > $GIT_PROXY_COMMAND" | sudo tee -a ~/.bashrc
		echo "    chmod + $GIT_PROXY_COMMAND" | sudo tee -a ~/.bashrc
		echo "fi" | sudo tee -a ~/.bashrc

		sudo mkdir ~/bin
		echo "exec socat stdio SOCKS:proxy01.png.intel.com:$1:$2" | sudo tee -a ~/bin/git_proxy_command
		sudo chmod 777 ~/bin/*

		read -p "Do you want to replace the ~/.gitconfig [y/n]" res
		if [ x$res = xy ]; then
			sudo cp gitconfig ~/.gitconfig
		fi
		echo -e "${GREEN}DONE. Please refresh the environments.${NC}"
		exit 0

        fi
	echo -e ${NC}
}

function check_network(){
	echo "Network checking"
        wget --timeout=3 --tries=1 https://github.com/projectceladon/ -q -O /dev/null
        if [ $? -ne 0 ]; then
		echo -e "${RED}access https://github.com/projectceladon/ failed!"
                echo -e "Network not responding. Please make sure proxy are set!${NC}"
                exit -1
	else
		echo -e "${GREEN}Network check passed${NC}"
	fi
}


setup_intel_proxy

