#1. Run setup.sh
#2. Configure git with ssh (https://kbroman.org/github_tutorial/pages/first_time.html). Prompt user to add key to github.com
#3. Clone dotfiles repo. (https://www.atlassian.com/git/tutorials/dotfiles)
#4. Set upstream for repo.


#!/bin/bash

### Options and variables ###

dwm_dependencies="xorg xserver-xorg dbus-x11 build-essential libx11-dev libxft-dev libxinerama-dev"
my_packages="curl git zsh neovim chromium compton fonts-noto-color-emoji nmap net-tools"

USER_HOME=$(eval echo ~${SUDO_USER:-$USER})
suckless_dirs=($USER_HOME/.local/src/dwm $USER_HOME/.local/src/dmenu $USER_HOME/.local/src/st)

### Functions ###
git_setup () {
	git config --global user.name "crlxs"
	git config --global user.email "belmontecarles@gmail.com"
	
	ssh-keygen -t rsa -C "belmontecarles@gmail.com"
	echo ~/.ssh/id_rsa.pub
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
git clone --bare git@github.com:crlxs/dotfilestest $HOME/.dotfiles

# Define alias for current shell
alias dotfiles='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

# Checkout the actual contet from the bare git repo into $HOME
dotfiles checkout
# If any error appear regarding untracked files, delete them.

# Set the flag showUntrackedFiles to no on this specific (local) repository:
dotfiles config --local status.showUntrackedFiles no

# Set upstream
dotfiles push --set-upstream origin master

# Rm old files in ~/
rm $HOME/.bash* $HOME/.profile
