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

function install_python()
{   
    PYDIR=$HOME/opt/python-3.10.6
    export PATH=$PYDIR/bin:$PATH
    export CPPFLAGS="-I$PYDIR/include $CPPFLAGS"

    mkdir -p $PYDIR/src
    cd $PYDIR/src

    # openssl
    wget https://www.openssl.org/source/openssl-1.1.1l.tar.gz
    tar zxf openssl-1.1.1l.tar.gz
    cd openssl-1.1.1l
    ./config --prefix=$PYDIR
    make
    make install

    # python
    wget https://www.python.org/ftp/python/3.10.6/Python-3.10.6.tar.xz
    tar xf Python-3.10.6.tar.xz
    cd Python-3.10.6
    ./configure --prefix=$PYDIR
    make
    make install
    cd Python-3.10.6
    sudo ./configure --enable-optimizations --prefix=$PYDIR
    sudo make install
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/local/bin/python3.10 0
    #sudo ln -sf /usr/bin/python3.10 /usr/bin/python3 
    python3 -V

    cd /opt
    sudo rm -f Python-3.10.12.tgz
}


# Check the distribution name and version
DISTRO=$(cat /etc/os-release | grep -w NAME | cut -d= -f2 | tr -d '"')
FULL_VERSION=$(cat /etc/os-release | grep -w VERSION_ID | cut -d= -f2 | tr -d '"')
ubuntu_version=$(grep -oP '(?<=VERSION_ID=")[0-9]+' /etc/os-release)

#Check package manager
PKGM=$(detect_package_manager)


# Install the packages according to the distribution
case $DISTRO in
  Ubuntu)
    echo "Detected Ubuntu distribution"
    if [ "$ubuntu_version" != "18" ] && [ "$ubuntu_version" != "20" ] && [ "$ubuntu_version" != "22" ]; then
        install_python
    else
        # Update the package lists
        sudo apt update -y
        sudo apt install python3-pip -y
        sudo apt install python3-venv -y
        fi
    ;;
  Debian)
    echo "Detected Debian-based distribution"
    # Update the package lists
    sudo apt update
    sudo apt install python3-pip -y
    sudo apt install python3-venv -y
    ;;
  Fedora|CentOS|"CentOS Linux"|RedHat)
    echo "Detected RedHat-based distribution"
    # Check if yum is available, and use it if available
    if command -v yum &> /dev/null; then
        sudo yum update -y
        sudo yum install -y python3-pip
    else
        # Use dnf if yum is not available
        sudo dnf update -y
        sudo dnf install -y python3-pip
    fi
    ;;
  SLES)
  echo "Detected SUSE-based distribution"
    # Update the package lists
    sudo zypper update -y
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
