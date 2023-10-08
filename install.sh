#!/bin/bash

latest=0

no_pip=0

config_param=""

install_version=""

origin_path=$(pwd)

openssl_version="3.0.8"

# cancel centos alias
[[ -f /etc/redhat-release ]] && unalias -a

#######color code########
red="31m"
green="32m"
yellow="33m"
blue="36m"

color_echo() {
	echo -e "\033[$1${@:2}\033[0m"
}

#######get params#########
while [[ $# -gt 0 ]]; do
	KEY="$1"
	case $KEY in
	--nopip)
		no_pip=1
		color_echo $blue "only install python3..\n"
		;;
	--latest)
		latest=1
		;;
	-v | --version)
		install_version="$2"
		echo -e "prepare install python $(color_echo ${blue} "$install_version")..\n"
		shift
		;;
	*)
		config_param=$config_param" $KEY"
		;;
	esac
	shift # past argument or value
done
if [[ $latest == 1 || $install_version ]]; then
	IFS='.' read -r -a v_parts <<<"$install_version"
	major_v=${v_parts[0]}
	minor_v=${v_parts[1]}
	if [[ "$major_v" -lt 3 || ("$major_v" -eq 3 && "$minor_v" -lt 7) ]]; then
		color_echo $yellow "The provided python version should be 3.7.x or newer"
		exit 1
	else
		[[ $config_param ]] && echo "python3 compile command: $(color_echo $blue ./configure "$config_param")"
	fi
fi
#############################

check_python_version() {
	# Get the installed Python version
	python_version=$(python3 --version 2>&1)

	# Extract the Python version number
	python_version_number=$(echo "$python_version" | awk '{print $2}')

	# Split the version number into major and minor parts
	IFS='.' read -r -a version_parts <<<"$python_version_number"
	major_version=${version_parts[0]}
	minor_version=${version_parts[1]}
}

check_sys() {
	# check root user
	[ "$(id -u)" != "0" ] && {
		color_echo ${red} "Error: You must be root to run this script"
		exit 1
	}

	if [[ $(command -v apt-get) ]]; then
		package_manager='apt-get'
	elif [[ $(command -v dnf) ]]; then
		package_manager='dnf'
	elif [[ $(command -v yum) ]]; then
		package_manager='yum'
	elif [[ $(command -v zypper) ]]; then
		package_manager='zypper'
	else
		color_echo $red "OS not supported!"
		exit 1
	fi

	[[ -z $(echo "$PATH" | grep /usr/local/bin) ]] && {
		echo "export PATH=$PATH:/usr/local/bin" >>/etc/bashrc
		source /etc/bashrc
	}
}

common_dependent() {
	[[ $package_manager == 'apt-get' ]] && ${package_manager} update -y
	${package_manager} install wget -y
}

compile_dependent() {
	if [[ ${package_manager} == 'yum' || ${package_manager} == 'dnf' ]]; then
		${package_manager} groupinstall -y "Development tools"
		${package_manager} install -y tk-devel xz-devel gdbm-devel sqlite-devel bzip2-devel readline-devel zlib-devel openssl-devel libffi-devel
	elif [[ ${package_manager} == 'zypper' ]]; then
		${package_manager} install -y readline-devel sqlite3-devel libbz2-devel zlib-devel libopenssl-devel libffi-devel gcc make
	else
		${package_manager} install -y build-essential
		${package_manager} install -y uuid-dev tk-dev liblzma-dev libgdbm-dev libsqlite3-dev libbz2-dev libreadline-dev zlib1g-dev libncursesw5-dev libssl-dev libffi-dev
	fi
}

download_package() {
	cd "$origin_path" || exit
	[[ $latest == 1 ]] && install_version=$(curl -s https://www.python.org/ | grep "downloads/release/" | egrep -o "Python [[:digit:]]+\.[[:digit:]]+\.[[:digit:]]" | sed s/"Python "//g)
	python_package="Python-$install_version.tgz"
	while :; do
		if [[ ! -e $python_package ]]; then
			wget https://www.python.org/ftp/python/"$install_version"/"$python_package"
			if [[ $? != 0 ]]; then
				color_echo ${red} "Fail download $python_package version python!"
				exit 1
			fi
		fi
		tar xzvf "$python_package"
		if [[ $? == 0 ]]; then
			break
		else
			rm -rf "$python_package" Python-"$install_version"
		fi
	done
	cd Python-"$install_version" || exit
}

update_openssl() {
	cd "$origin_path" || exit
	local version=$1
	wget --no-check-certificate https://www.openssl.org/source/openssl-"$version".tar.gz
	tar xzvf openssl-"$version".tar.gz
	cd openssl-"$version"
	./config --prefix=/usr/local/openssl shared zlib
	make && make install
	mv -f /usr/bin/openssl /usr/bin/openssl.old
	mv -f /usr/include/openssl /usr/include/openssl.old
	ln -s /usr/local/openssl/bin/openssl /usr/bin/openssl
	ln -s /usr/local/openssl/include/openssl /usr/include/openssl
	echo "/usr/local/openssl/lib" >>/etc/ld.so.conf
	ldconfig

	cd "$origin_path" && rm -rf openssl-$version*
}

# compile install python3
compileInstall() {
	compile_dependent

	local local_ssl_version=$(openssl version | awk '{print $2}' | tr -cd '[0-9]')

	if [[ $local_ssl_version -le 101 ]] || ([[ $latest == 1 ]] && [[ $local_ssl_version -lt 111 ]]); then
		update_openssl $openssl_version
		echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/openssl/lib" >>$HOME/.bashrc
		source $HOME/.bashrc
		download_package
		./configure --with-openssl=/usr/local/openssl $config_param
		make && make install
		sudo ln -sf /usr/local/bin/python3."$minor_version" /usr/bin/python3
	else
		download_package
		./configure "$config_param"
		make && make install
		sudo ln -sf /usr/local/bin/python3."$minor_version" /usr/bin/python3
	fi

	cd "$origin_path" && rm -rf Python-$install_version*
}

#online install python3
web_install() {
	if [[ ${package_manager} == 'yum' || ${package_manager} == 'dnf' ]]; then
		if ! type python3 >/dev/null 2>&1; then
			if [[ ${package_manager} == 'yum' ]]; then
				${package_manager} install epel-release -y
				${package_manager} install https://repo.ius.io/ius-release-el7.rpm -y
				${package_manager} install python36u -y
				[[ ! -e /bin/python3 ]] && ln -s /bin/python3.6 /bin/python3
			elif [[ ${package_manager} == 'dnf' ]]; then
				${package_manager} install python3 -y
			fi
		fi
	else
		if ! type python3 >/dev/null 2>&1; then
			${package_manager} install python3 -y
		fi
		${package_manager} install python3-distutils -y >/dev/null 2>&1
	fi
}

pip_install() {
	[[ $no_pip == 1 ]] && return
	py3_version=$(python3 -V | tr -cd '[0-9.]' | cut -d. -f2)
	if [[ $py3_version -gt 6 ]]; then
		python3 <(curl -sL https://bootstrap.pypa.io/get-pip.py)
	elif [[ $py3_version == 6 ]]; then
		python3 <(curl -sL https://bootstrap.pypa.io/pip/3.6/get-pip.py)
	else
		if [[ -z $(command -v pip) ]]; then
			if [[ ${package_manager} == 'apt-get' ]]; then
				apt-get install -y python3-pip
			fi
			[[ -z $(command -v pip) && $(command -v pip3) ]] && ln -s $(which pip3) /usr/bin/pip
		fi
	fi
}

pipx_install() {
	# Install pipx using pip
	python3 -m pip install -U pipx
	python3 -m pipx ensurepath

	#Reload Path
	if [ -f /etc/os-release ]; then
		# Read the content of the /etc/os-release file
		source /etc/os-release

		# Check if the ID variable contains "suse"
		if [[ "$ID" == *"suse"* ]]; then
			source /etc/profile
		else
			source "$HOME"/.bashrc
		fi
	fi
	# Verify pipx installation
	pipx --version
}

main() {
	check_python_version
	# Check if Python version is less than 3.7
	if [[ "$major_version" -lt 3 || ("$major_version" -eq 3 && "$minor_version" -lt 7) ]]; then
		color_echo $blue "Installing..."
		check_sys

		common_dependent

		if [[ $latest == 1 || $install_version ]]; then
			compileInstall
		else
			web_install
		fi
		
		pip_install
		pipx_install
	else
		color_echo $green "Already python 3.7.x or newer is installed."
		color_echo $blue "Procceeding to install pipx..."
		pip_install
		pipx_install
	fi

}

main
