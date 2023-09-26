#!/usr/bin/env bash

function detect_package_manager()
{
  declare -A osInfo;
  osInfo[/etc/redhat-release]=yum
  osInfo[/etc/debian_version]=apt-get
  osInfo[/etc/SuSE-release]=zypper
  osInfo[/etc/arch-release]=pacman
  osInfo[/etc/gentoo-release]=emerge
  osInfo[/etc/alpine-release]=apk

  for f in ${!osInfo[@]}
  do
      if [[ -f $f ]];then
          echo ${osInfo[$f]}
      fi
  done
}


# Check the distribution name and version
DISTRO=$(cat /etc/os-release | grep -w NAME | cut -d= -f2 | tr -d '"')
FULL_VERSION=$(cat /etc/os-release | grep -w VERSION_ID | cut -d= -f2 | tr -d '"')
ubuntu_version=$(grep -oP '(?<=VERSION_ID=")[0-9]+' /etc/os-release)

#Check package manager
PKGM=$(detect_package_manager)


# Install the packages according to the distribution
case $DISTRO in
  Ubuntu|Debian)
    echo "Detected Debian-based distribution"
    # Update the package lists
    sudo apt update
    sudo apt install python3-pip -y
    sudo apt install python3-venv -y
    ;;
  Fedora|CentOS|RedHat)
    echo "Detected RedHat-based distribution"
    # Check if yum is available, and use it if available
    if command -v yum &> /dev/null; then
        sudo yum update
        sudo yum install -y python3-pip
    else
        # Use dnf if yum is not available
        sudo dnf update
        sudo dnf install -y python3-pip
    fi
    ;;
  SLES)
  echo "Detected RedHat-based distribution"
    # Update the package lists
    sudo zypper update
    # Install the packages
    sudo zypper install -y python3 python3-pip
    ;;
  *)
    # Unsupported distribution
    echo "Sorry, this script does not support $DISTRO $FULL_VERSION."
    exit 1
    ;;
esac


# Install pipx using pip
python3 -m pip install --user pipx
python3 -m pipx ensurepath

# Verify pipx installation
pipx --version
