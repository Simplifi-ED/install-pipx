#!/usr/bin/env bash

function install_python()
{   sudo apt-get install build-essential checkinstall -y
    sudo apt-get install libreadline-gplv2-dev libncursesw5-dev libssl-dev  \
      libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev -y

    #openssl
    cd /usr/local/src/
    sudo wget https://www.openssl.org/source/openssl-3.0.8.tar.gz
    sudo tar xzvf openssl-3.0.8.tar.gz
    cd openssl-3.0.8
    sudo ./config --prefix=/usr/local/ssl --openssldir=/usr/local/ssl shared zlib
    sudo make
    sudo make install
    
    sudo tee -a /etc/ld.so.conf.d/openssl-3.0.8.conf <<END
/usr/local/ssl/lib64
END
    sudo ldconfig -v
    sudo mv $(which openssl) $(which openssl).backup
    sudo tee -a /etc/profile.d/openssl.sh <<EOT
PATH=$PATH:/usr/local/ssl/bin
export PATH
EOT
    sudo chmod +x /etc/profile.d/openssl.sh
    source /etc/profile.d/openssl.sh
    echo $PATH
    openssl version -a


    # python
    sudo apt install build-essential libssl-dev zlib1g-dev libffi-dev -y
    cd /opt
    sudo wget https://www.python.org/ftp/python/3.10.6/Python-3.10.6.tar.xz
    sudo tar xf Python-3.10.6.tar.xz
    cd Python-3.10.6
    
    sudo ./configure --with-openssl-rpath=auto --with-openssl=/usr/local/ssl --enable-optimizations 
    sudo make
    sudo make install
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/local/bin/python3.10 0
    python3 -V

    cd /opt
    sudo rm -f Python-3.10.12.tgz
}


# Check the distribution name and version
DISTRO=$(cat /etc/os-release | grep -w NAME | cut -d= -f2 | tr -d '"')
FULL_VERSION=$(cat /etc/os-release | grep -w VERSION_ID | cut -d= -f2 | tr -d '"')


#Check package manager
PKGM=$(detect_package_manager)


# Install the packages according to the distribution
case $DISTRO in
  Ubuntu)
    echo "Detected Ubuntu distribution"
    ubuntu_version=$(grep -oP '(?<=VERSION_ID=")[0-9]+' /etc/os-release)
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
