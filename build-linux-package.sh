#!/bin/bash

checaInstalacao() {
echo "Checando instalação de '$programa'"
if [[ -z `which $programa` ]]; then
	echo "[x] $programa não está instalado"
	exit -1
else
	echo "[*] $programa está instalado"
fi
}

instala() {
sudo usermod -a -G lxd $USER
snapcraft
}

programas=(snap snapcraft)
for programa in ${programas[*]}; do
	checaInstalacao
done

instala
