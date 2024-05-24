#!/bin/bash

### Options and variables ###

USER_HOME=$(eval echo ~${SUDO_USER:-$USER})

dwm_dependencies="xorg xserver-xorg dbus-x11 build-essential libx11-dev libxft-dev libxinerama-dev"
my_packages="curl ripgrep unzip git zsh neovim chromium compton feh fonts-noto-color-emoji nmap net-tools"

suckless_dirs=($USER_HOME/.local/src/dwm $USER_HOME/.local/src/dmenu $USER_HOME/.local/src/st)


### Functions ###

# Welcome message (May use whiptail in the future, the typical grey with bluebackground dialog box/menu)
welcomemsg () {
	echo -e "\n\e[31mHello! This script will automatically install my custom Linux desktop environment + my dotfiles.\nYou can also choose to only install the dotfiles for purely shell environments.\e[0m\n"
}

choices () {
	echo -e "\e[32mInstall full environment(dwm/dmenu/st + dotfiles) or just the dotfiles?\e[0m"
	select choice in "Full" "Dotfiles" "Exit"; do
		case $choice in
			Full ) echo -e "You selected full.\n"; fullinstall; break;;
			Dotfiles ) echo -e "You selected Dotfiles.\n"; dotfilesinstall; break;;
			Exit ) exit;;
		esac
	done
}

fullinstall () {
	echo -e "This is the fullinstall function.\n"
}

dotfilesinstall () {
	echo -e "\e[32mFull dotfiles setup (configuring git) so you can push changes or simply clone?\e[0m"
	select choice in "Full" "Clone" "Exit"; do
		case $choice in
			Full ) echo -e "You selected full.\n"; break;;
			Clone ) echo -e "You selected clone.\n"; break;;
			Exit) exit;;
		esac
	done
}

git_ssh () {
	git config --global user.name "crlxs"
	git config --global user.email "140880473+crlxs@users.noreply.github.com"

	ssh-keygen -t rsa -C "140880473+crlxs@users.noreply.github.com"
        cat ~/.ssh/id_rsa.pub
	
	# Warning
	echo -e "\033[0;31mADD THE SSH KEY TO GITHUB.COM BEFORE PROCEDING.\n
	Press any key to continue when done.\033[0m"
	read -n 1 -s
	# Continue with the rest of your script
	echo "Continuing after confirmation."
	# Verify
	ssh -T git@github.com
}


### The actual script ###

welcomemsg || error "User exited."

choices || error "User exited."
