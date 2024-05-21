# dotfiles
This contains my personal configuration files for my GNU/Linux environments.

It is a bare repository (git init bare .), which means it is initialized without the .git directory since it isn't a working tree.

Based on this Atlassian tutorial ([Dotfiles: Best way to store in a bare git repository](https://www.atlassian.com/git/tutorials/dotfiles)).


## Moving files in ~/ to ~/.config.

For example, ~/.xinitrc ~/.zsh can be moved to ~/.config (or any other directory) by telling xinit and zsh where to find their respective rc files with environment variables: XINITRC for xinit and ZDOTDIR for zsh
