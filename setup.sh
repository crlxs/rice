#!/bin/sh

### Options and variables ###

dwm_dependencies="xorg xserver-xorg dbus-x11 build-essential libx11-dev libxft-dev libxinerama-dev"
my_packages="curl ripgrep unzip git zsh chromium compton feh fonts-noto-color-emoji nmap net-tools"

#NVIM requires v0.10 or > for lazyvim/primeagenlike xperience. Instead of installing through apt which has old versions, I am installing directly from the nvim github, see function nvim_install.

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

nvim_intall () {
	cd $USER_HOME/.local/bin
	wget https://github.com/neovim/neovim/releases/download/stable/nvim.appimage
	chmod u+x nvim.appimage
	mv nvim.appimage nvim
}

### The actual script ###

# Update, upgrade and install
sudo apt update && sudo apt upgrade -y && sudo apt install -y $dwm_dependencies $my_packages

# Create ~/ directories, $USER_HOME/.dotfiles is the bare git repo dir.
mkdir -p $USER_HOME/.dotfiles $USER_HOME/.config $USER_HOME/.local/src $USER_HOME/.local/share $USER_HOME/.local/bin

# nvim install
nvim_install

# Clone my forks of dwm, dmenu and st and install them
git clone https://github.com/crlxs/dwm $USER_HOME/.local/src/dwm
git clone https://github.com/crlxs/dmenu $USER_HOME/.local/src/dmenu
git clone https://github.com/crlxs/st $USER_HOME/.local/src/st

for dir in "${suckless_dirs[@]}"; do
        make_install "$dir"
done

# Change default shell to zsh
chsh -s $(which zsh)

# Setup git ssh
git_setup

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

# Rm old files in ~/
rm $HOME/.bash* $HOME/.profile
