#!/bin/bash

### Run without sudo, otherwise it

### Also automate git setup? https://kbroman.org/github_tutorial/pages/first_time.html
### How to maintain dwm config and customization in git https://dwm.suckless.org/customisation/patches_in_git/

### OPTIONS AND VARS ###
suckless_dirs=(~/.local/src/dwm ~/.local/src/dmenu ~/.local/src/st)

# Update, upgrade and install dwm/dmenu/st dependencies and other
sudo apt update && sudo apt upgrade -y && sudo apt install -y xorg xserver-xorg build-essential libx11-dev libxft-dev libxinerama-dev compton git
#sudo apt install -y neovim curl chromium nmap net-tools

# Create necessary directories
mkdir -p ~/.local/src ~/.config

# Clone suckless software repos
git clone git://git.suckless.org/dwm ~/.local/src/dwm
git clone git://git.suckless.org/st ~/.local/src/st
git clone git://git.suckless.org/dmenu ~/.local/src/dmenu

# Create patches directories
mkdir ~/.local/src/dwm/patches ~/.local/src/dmenu/patches ~/.local/src/st/patches

# Download dwm patches
wget https://dwm.suckless.org/patches/fullgaps/dwm-fullgaps-6.4.diff -P ~/.local/src/dwm/patches
wget https://dwm.suckless.org/patches/alpha/dwm-alpha-20230401-348f655.diff -P ~/.local/src/dwm/patches
wget https://dwm.suckless.org/patches/actualfullscreen/dwm-actualfullscreen-20211013-cb3f58a.diff -P ~/.local/src/dwm/patches

# Download st patches
wget https://st.suckless.org/patches/alpha/st-alpha-20220206-0.8.5.diff -P ~/.local/src/st/patches
wget https://st.suckless.org/patches/delkey/st-delkey-20201112-4ef0cbd.diff -P ~/.local/src/st/patches

# Download dmenu patches
#wget https://tools.suckless.org/dmenu/patches/alpha/dmenu-alpha-20230110-5.2.diff -P ~/.local/src/dmenu/patches
#wget https://tools.suckless.org/dmenu/patches/border/dmenu-border-20201112-1a13d04.diff -P ~/.local/src/dmenu/patches
#wget https://tools.suckless.org/dmenu/patches/center/dmenu-center-5.2.diff -P ~/.local/src/dmenu/patches

# Function to apply patches
apply_patches() {
    local src_dir=$1
    cd $src_dir || exit 1
    for patch in patches/*.diff; do
        patch -p1 < "$patch"
    done
}

# Apply patches to dwm, dmenu and st
apply_patches ~/.local/src/dwm
apply_patches ~/.local/src/st
#apply_patches ~/.local/src/dmenu

# Function to build and install suckless software
make_install() {
	local src_dir=$1
	cd $src_dir || exit 1
	make
	sudo make install
}

# Make and install each suckless software
for dir in "${suckless_dirs[@]}"; do
    make_install "$dir"
done

echo "Initial setup complete. Create a ~/.xinitrc file and launch dwm with startx."

######
### dmenu patches need work
######
