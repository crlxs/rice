#!/bin/bash

### Options and variables ###

USER_HOME=$(eval echo ~${SUDO_USER:-$USER})

dwm_dependencies="xorg xserver-xorg dbus-x11 build-essential libx11-dev libxft-dev libxinerama-dev"
my_packages="curl git zsh neovim chromium compton feh fonts-noto-color-emoji nmap net-tools"

suckless_dirs=($USER_HOME/.local/src/dwm $USER_HOME/.local/src/dmenu $USER_HOME/.local/src/st)


### Functions ###

# Welcome message (May use whiptail in the future, the typical grey with bluebackground dialog box/menu)
welcomemsg () {
	echo -e "\n\e[31mHello! This script will automatically install my custom Linux desktop environment + my dotfiles.\nYou can also choose to only install the dotfiles for purely shell environments.\e[0m\n"

}

choices () {
	echo -e "\e[32mDo you want to install the full environment(wm + dotfiles) or just the dotfiles?\e[0m"
	select choice in "Full" "Dotfiles" "Exit"; do
		case $choice in
			Full ) echo "You selected full"; fullinstall; break;;
			Dotfiles ) echo "You selected Dotfiles"; dotfilesinstall; break;;
			Exit ) exit;;
		esac
	done
}

fullinstall () {
	echo "This is the fullinstall function."
}

dotfilesinstall () {
	echo -e "\e[32mDo you want to just clone the dotfiles or init the repository (requires setting up git)?\e[0m"
	select choice in "Clone" "Init" "Exit"; do
		case $choice in
			Clone ) echo "You selected clone"; break;;
			Init ) echo "You selected init"; break;;
			Exit) exit;;
		esac
	done
}


### The actual script ###

welcomemsg || error "User exited."

choices || error "User exited."
