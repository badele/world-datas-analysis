#!/usr/bin/env sh

# Distribution detection
if [ -f /etc/os-release ]; then
	. /etc/os-release
	OS=$ID
else
	echo "Impossible de détecter la distribution."
	exit 1
fi

###############################################################################
# Distribution installation
###############################################################################

install_ubuntu() {
	sudo apt-get update
	sudo apt-get install -y git curl xz-utils docker.io docker-compose-v2 just

	systemctl enable docker
	systemctl start docker
}

install_arch() {
	sudo pacman -Sy --noconfirm git curl xz docker docker-compose just

	systemctl enable docker
	systemctl start docker
}

install_alpine() {
	apk add --no-cache bash sudo openrc git curl xz docker docker-compose just

	rc-update add docker boot
	service docker start
}

###############################################################################
# Main
###############################################################################
case "$OS" in
ubuntu)
	install_ubuntu
	;;
arch)
	install_arch
	;;
alpine)
	install_alpine
	;;
*)
	echo "Not suported distribution"
	exit 1
	;;
esac
