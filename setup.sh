#!/bin/bash

### Options and variables ###

dwm_dependencies="xorg xserver-xorg build-essential libx11-dev libxft-dev libxinerama-dev"
my_packages="curl git zsh neovim chromium compton fonts-noto-color-emoji nmap net-tools"

### Functions ###
git_setup () {
	git config --global user.name "crlxs"
	git config --global user.email "belmontecarles@gmail.com"
	
	ssh-keygen -t rsa -C "belmontecarles@gmail.com"
	cat ~/.ssh/id_rsa.pub
}


### The actual script ###

# Update, upgrade and install
sudo apt update && sudo apt upgrade -y && sudo apt install -y $dwm_dependencies $my_packages

# Create ~/ directories
mkdir -p ~/.config ~/.local/src ~/.local/share ~/.local/bin

# Clone my forks of dwm, dmenu and st
git clone https://github.com/crlxs/dwm.git ~/.local/src/dwm

