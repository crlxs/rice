#!/bin/bash

### Options and variables ###


### Functions ###

welcomemsg () {
	echo -e "\e[32mHello! This script will automatically install my custom Linux desktop environment + my dotfiles, you can also choose to only install the dotfiles for a non-graphical experience!\e[0m"

}

choice () {
	echo "Do you wish to install the full environment(wm + dotfiles) or just the dotfiles?"
	select choice in "Full" "Dotfiles" "Exit"; do
		case $choice in
			Full ) echo "You selected full"; break;;
			Dotfiles ) echo "You selected Dotfiles"; break;;
			Exit ) exit;;
		esac
	done
}

### The actual script ###

# Welcome message (May use whiptail in the future, the typical grey with bluebackground dialog box/menu)
welcomemsg || error "User exited."

choice || error "User exited."
