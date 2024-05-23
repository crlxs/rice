#!/bin/bash

### Options and variables ###

dwm_dependencies="xorg xserver-xorg dbus-x11 build-essential libx11-dev libxft-dev libxinerama-dev"
my_packages="curl git zsh neovim chromium compton feh fonts-noto-color-emoji nmap net-tools"

USER_HOME=$(eval echo ~${SUDO_USER:-$USER})
suckless_dirs=($USER_HOME/.local/src/dwm $USER_HOME/.local/src/dmenu $USER_HOME/.local/src/st)

### Functions ###
git_setup () {
        git config --global user.name "crlxs"
        git config --global user.email "140880473+crlxs@users.noreply.github.com"

        ssh-keygen -t rsa -C "140880473+crlxs@users.noreply.github.com"
        cat ~/.ssh/id_rsa.pub
		# Warning
		echo -e "\033[0;31mADD THE SSH KEY TO GITHUB.COM BEFORE PROCEDING\033[0m"
		# Pause the script and wait for user input
		echo "Press any key to continue..."
		read -n 1 -s
		# Continue with the rest of your script
		echo "Continuing after user input..."
		# Verify
		ssh -T git@github.com
		
}

make_install() {
        local src_dir=$1
        cd $src_dir || exit 1
        make
        make install
}

### The actual script ###

# Update, upgrade and install
sudo apt update && sudo apt upgrade -y && sudo apt install -y $dwm_dependencies $my_packages

# Create ~/ directories, $USER_HOME/.dotfiles is the bare git repo dir.
mkdir -p $USER_HOME/.dotfiles $USER_HOME/.config $USER_HOME/.local/src $USER_HOME/.local/share $USER_HOME/.local/bin

# Clone my forks of dwm, dmenu and st
git clone https://github.com/crlxs/dwm $USER_HOME/.local/src/dwm
git clone https://github.com/crlxs/dmenu $USER_HOME/.local/src/dmenu
git clone https://github.com/crlxs/st $USER_HOME/.local/src/st

# Make and install each suckless software
for dir in "${suckless_dirs[@]}"; do
        make_install "$dir"
done

# Change default shell to zsh
chsh -s $(which zsh)

# Setup git ssh
git_setup

# clone your dotfiles repo
git clone --bare git@github.com:crlxs/dotfiles $HOME/.dotfiles

# Define alias for current shell
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

# Rm old files in ~/
rm $HOME/.bash* $HOME/.profile
