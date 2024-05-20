#!/bin/bash

### Options and variables ###



### Functions ###
git_setup () {
	git config --global user.name "crlxs"
	git config --global user.email "belmontecarles@gmail.com"
	
	ssh-keygen -t rsa -C "belmontecarles@gmail.com"
	cat ~/.ssh/id_rsa.pub
}


### The actual script ###
