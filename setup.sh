#!/bin/bash

### Options and variables ###

USER_HOME=$(eval echo ~${SUDO_USER:-$USER})

dwm_dependencies="xorg xserver-xorg dbus-x11 build-essential libx11-dev libxft-dev libxinerama-dev"
my_packages="curl ripgrep fd-find unzip git zsh chromium compton feh xwallpaper fonts-noto-color-emoji nmap net-tools curl tcpdump"

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

nvim_install () {
        cd $USER_HOME/.local/bin
        wget https://github.com/neovim/neovim/releases/download/stable/nvim.appimage
        chmod u+x nvim.appimage
        mv nvim.appimage nvim
}

suckless_install () {
	# Clone my forks of dwm, dmenu and st and install them
	git clone https://github.com/crlxs/dwm $USER_HOME/.local/src/dwm
	git clone https://github.com/crlxs/dmenu $USER_HOME/.local/src/dmenu
	git clone https://github.com/crlxs/st $USER_HOME/.local/src/st

	make_install() {
		local src_dir=$1
		cd $src_dir || exit 1
		make
		make install
	}

	for dir in "${suckless_dirs[@]}"; do
		make_install "$dir"
	done
}

git_ssh () {
	# This is bad because it doesn't check if config already exists or not, but should be fine for freshly installed hosts.
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

dotfiles_setup () {
	# Clone dotfiles repo
	git clone --bare git@github.com:crlxs/dotfiles $HOME/.dotfiles

	# Define alias for current shell. It exists in .config/shell/aliasrc, leaving this clarity tho.
	#alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

	# Checkout the actual contet from the bare git repo into $HOME
	git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME checkout
	# If any error appear regarding untracked files, delete them.

	# Set the flag showUntrackedFiles to no on this specific (local) repository:
	git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME config --local status.showUntrackedFiles no

	# Set upstream
	git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME push --set-upstream origin master

	# Pull
	git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME pull
}

fullinstall () {
	# Update, upgrade and install dependencies/packages.
	sudo apt update && sudo apt upgrade -y && sudo apt install -y $dwm_dependencies $my_packages

	# Create ~/ directories, $USER_HOME/.dotfiles is the bare git repo directory.
	mkdir -p $USER_HOME/.dotfiles $USER_HOME/.config $USER_HOME/.local/src $USER_HOME/.local/share $USER_HOME/.local/bin

	# nvim_install
	nvim_install

	# suckless_install
	suckless_install

	# Setup git ssh
	git_ssh
	
	# dotfiles bare git repo setup
	dotfiles_setup

	# nvim_install
	nvim_install

	# Change default shell to zsh
	chsh -s $(which zsh)

	# rm old files in ~/
	rm $HOME/.bash* $HOME/.profile
}

### The actual script ###

welcomemsg || error "User exited."

choices || error "User exited."
