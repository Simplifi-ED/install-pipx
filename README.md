A bash script to install pipx on diffrent linux distros.
============================

> [!NOTE] 
The script check if python 3.7 is already installed otherwise it will install the specified version. Also, if os openssl version less than 1.0.2 , script will auto install openssl version 3 before compile python3.

## Make file executable
```
chmod +x install.sh
```

## Install without compile
```
./install.sh
```

## Install with compile(latest python version)
```
./install.sh --latest
```

## Install with compile(special python version)
```
./install.sh -v 3.10.6
```

## Only install python3
```
.install.sh --nopip
```

## Compile with custom param
```
./install.sh --latest --enable-optimizations
```
