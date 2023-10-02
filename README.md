> [!NOTE] 
The script check if python3.7 is already installed otherwise it install will the specified version

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
