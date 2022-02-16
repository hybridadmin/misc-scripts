#! /usr/bin/env bash
set -e

UBUNTU_VERSION=$(cat /etc/os-release | grep "_ID" | cut -d '"' -f2)
GENIE_VERSION=$( curl -s https://api.github.com/repos/arkane-systems/genie/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")' | sed 's/^v//g')

GENIE_FILE="systemd-genie_${GENIE_VERSION}_amd64"
GENIE_FILE_PATH="/tmp/${GENIE_FILE}.deb"
GENIE_DIR_PATH="/tmp/${GENIE_FILE}"

function download_deb_package() {
        rm -f "${GENIE_FILE_PATH}"
        pushd /tmp

        wget --content-disposition \
          "https://github.com/arkane-systems/genie/releases/download/v${GENIE_VERSION}/systemd-genie_${GENIE_VERSION}_amd64.deb"
        popd
}

function install_from_deb() {
        # install systemd-genie from downloaded deb
        download_deb_package
        sudo dpkg -i "${GENIE_FILE_PATH}"
        rm -rf "${GENIE_FILE_PATH}"
}

function install_from_repo() {
        sudo curl -fsSL https://arkane-systems.github.io/wsl-transdebian/apt/wsl-transdebian.gpg -o /etc/apt/trusted.gpg.d/wsl-transdebian.gpg
        sudo chmod a+r /etc/apt/trusted.gpg.d/wsl-transdebian.gpg

sudo tee -a /etc/apt/sources.list.d/wsl-transdebian.list > /dev/null << EOL
deb https://arkane-systems.github.io/wsl-transdebian/apt/ $(lsb_release -cs) main
deb-src https://arkane-systems.github.io/wsl-transdebian/apt/ $(lsb_release -cs) main
EOL

        sudo apt update && sudo apt install -y systemd-genie
}

function install_dependencies() {
        sudo apt-get update
        wget --content-disposition \
          "https://packages.microsoft.com/config/ubuntu/${UBUNTU_VERSION}/packages-microsoft-prod.deb"

        sudo dpkg -i packages-microsoft-prod.deb
        rm packages-microsoft-prod.deb

        sudo apt-get install apt-transport-https
        sudo apt-get update
        sudo apt-get install -y \
          daemonize dbus policykit-1 systemd util-linux systemd-container dotnet-runtime-5.0 lsb-release

        sudo rm -f /usr/sbin/daemonize
        sudo ln -s /usr/bin/daemonize /usr/sbin/daemonize
}

function configure_shell_profile(){
        if [[ "$SHELL" =~ (zsh) ]]; then
                PROFILE_FILE="/etc/zsh/zprofile"
        else
                PROFILE_FILE="/etc/profile"
        fi

        echo -e "if [[ ! -v INSIDE_GENIE ]]; then\n\t exec /usr/bin/genie -s\nfi" | sudo tee -a $PROFILE_FILE > /dev/null

        if [ -d "/mnt/c" ]; then
sudo tee /mnt/c/ProgramData/Microsoft/Windows/Start\ Menu/Programs/Startup/start-wsl-genie2.bat > /dev/null << EOL
start /wait /min wsl genie -i
start /wait /min diskpart /s c:\ProgramData\mount-disk.bat
start /wait /min wsl --mount \\.\PHYSICALDRIVE1 --bare
start /wait /min wsl --user root mount /home/meister/data-vol
EOL

sudo tee -a /mnt/c/ProgramData/mount-disk.bat > /dev/null << EOL
select vdisk file=C:\ProgramData\wsl-disks\wsl-data-dsk.vhdx
attach vdisk
EOL
        fi
}

function main() {
        install_dependencies

	STATUS_CODE=$(curl -v -I https://arkane-systems.github.io/wsl-transdebian/apt | grep HTTP | awk '{print $2}')
	if [ -n $STATUS_CODE ] && [[ $STATUS_CODE == 301 || $STATUS_CODE == 200 ]] ; then
        	install_from_repo
	else
		install_from_deb
	fi
        configure_shell_profile
}

main
