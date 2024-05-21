#!/bin/bash

### Options and variables ###

dwm_dependencies="xorg xserver-xorg build-essential libx11-dev libxft-dev libxinerama-dev"
my_packages="curl git zsh neovim chromium compton fonts-noto-color-emoji nmap net-tools"

USER_HOME=$(eval echo ~${SUDO_USER:-$USER})

### Functions ###
git_setup () {
	git config --global user.name "crlxs"
	git config --global user.email "belmontecarles@gmail.com"
	
	ssh-keygen -t rsa -C "belmontecarles@gmail.com"
	cat ~/.ssh/id_rsa.pub
}

make_install() {
        local src_dir=$1
        cd $src_dir || exit 1
        make
        sudo make install
}

### The actual script ###

# Update, upgrade and install
sudo apt update && sudo apt upgrade -y && sudo apt install -y $dwm_dependencies $my_packages

# Create ~/ directories
mkdir -p $USER_HOME/.config $USER_HOME/.local/src $USER_HOME/.local/share $USER_HOME/.local/bin

# Clone my forks of dwm, dmenu and st
git clone https://github.com/crlxs/dwm $USER_HOME/.local/src/dwm
git clone https://github.com/crlxs/dmenu $USER_HOME/.local/src/dmenu
git clone https://github.com/crlxs/st $USER_HOME/.local/src/st

# Make and install each suckless software
for dir in "${suckless_dirs[@]}"; do
	make_install "$dir"
done

# Change default shell to zsh, copy basic .zshrc and add path for ~/.local/bin
chsh -s $(which zsh)
cp /etc/zsh/newuser.zshrc.recommended $USER_HOME/.zshrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> $USER_HOME/.zshrc
