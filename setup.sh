#!/usr/bin/env bash


# Declaração de variáveis
PTH=$(pwd)
WKEY="-O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key"
WHQ="-NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources"


# Alterando repositório Stable para Testing
cp /etc/apt/sources.list /etc/apt/sources.listOLD
sed -i 's/bookworm/testing/g' /etc/apt/sources.list


# Atualização do sistema
printf "Preparando atualização do sistema...\n"
sleep 3
sudo apt-get update ; sudo apt-get upgrade -y -qq
echo " "


# Removendo travas do APT
sudo rm /var/lib/dpkg/lock-frontend
sudo rm /var/cache/apt/archives/lock


# Download de programas externos
echo " "
echo "Baixando e instalando pacotes externos. Isso pode levar alguns minutos."
sleep 2
cd ~
mkdir -p ./Downloads/apps
mkdir -p ./.appimages
cd $PTH
wget -c -P ./apps -i ./edeb.txt
wget -c -P ./apps -i ./eapp.txt
sudo apt install .apps/*.deb
sudo chmod -x *.AppImage
mv .apps/*.AppImage ~/.appimages
sudo apt --fix-broken install -y -qq
sudo apt update
printf "Concluído.\n\n"


# Remoção de programas via APT
printf "\nPreparando remoção de programas indesejáveis...\n"
sleep 5
while read pkgrm
do
  sudo apt remove --ignore-missing --auto-remove -y "$pkgrm"
done < "pkgrm.txt"
echo " "
printf "\nConcluído.\n"


# Instalação de programas pelo repositório APT
printf "Preparando instalação de programas..."
sleep 2
while read pkgin
do
  sudo apt install -y "$pkgin"
done < "pkgin.txt"
echo " "
printf "Concluído\n"


# Instalação de programas via Flatpak
printf "Preparando instalação de programas em Flatpak..."
while read pkgflat
do
  flatpak install -y "$pkgflat"
done < "pkgflat.txt"
echo " "
printf "Concluído.\n"


# Ativando Firewall
sudo ufw limit 22/tcp  
sudo ufw allow 80/tcp  
sudo ufw allow 443/tcp  
sudo ufw default deny incoming  
sudo ufw default allow outgoing
sudo ufw enable


# Ativando Fail2Ban
sudo cp jail.local /etc/fail2ban/
sudo systemctl enable fail2ban
sudo systemctl start fail2ban


# Instalação do WINE - Em revisÃo
echo " "
printf "Preparando a instalação e configuração do WINE...\n"
sleep 2
sudo dpkg --add-architecture i386
sudo mkdir -pm755 /etc/apt/keyrings
sudo wget "$WKEY"
sudo wget "$WHQ"
sudo apt update
sudo apt-key add winehq.key
sudo apt install --install-recommends winehq-stable wine-stable wine-stable-i386 wine-stable-amd64 -y
echo " "
printf "Concluído.\n"


# Instalação do EMACS
cd emacs-29.4 ./configure make sudo make install


# Criação de alias
cd ~
touch .bash_aliases
echo 'alias python="python3"
alias pip="pip3"
alias ain="sudo apt install"
alias arm="sudo apt remove"
alias ase="sudo apt search"
alias aup="sudo apt update && sudo apt upgrade -y && sudo apt dist-upgrade -y ; sudo apt autoclean ; sudo apt autoremove"
alias fin="flatpak install"
alias frm="flatpak remove"
alias fse="flatpak search"
alias fup="flatpak update"
alias kp="sudo kill"
alias kap="sudo killall"
alias kw="sudo xkill"
alias metad="exiftool"
alias metac="exiftool -all= -overwrite_original"' >> .bash_aliases
echo 'if [ -f ~/.bash_aliases ]; then
	. ~/.bash_aliases
fi' >> .bashrc
source ~/.bashrc


# Finalização
echo " "
printf "Inicializando atualização final\n"
sleep 3
sudo apt-get update ; sudo apt-get dist-upgrade -y
flatpak update
sudo apt-get autoclean
sudo apt-get autoremove -y
echo " "
printf "Concluído. Todas as etapas foram finalizadas.\nO dispositivo irá reiniciar em 10 segundos. Para cancelar: Ctrl + C"
sleep 10
reboot
