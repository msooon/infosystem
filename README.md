# infosystem
A shell based information management system (2010-2015)

You can watch an intro here: 
http://msoon.kochab.uberspace.de/infosystem_intro.webm (better download)

##Install

we need the following tools:

git, bc, wget, sqlite3, sed, gawk, curl, surfraw (only for option -g)

and some editor like vim or nano defined in $EDITOR

export EDITOR="/usr/bin/vim" #or nano or something else
in ~/.bashrc

git clone https://github.com/msooon/infosystem.git 

cd infosystem

edit files: config and install.sh

chmod +x *.sh

as superuser: ./install.sh

###further notes
also helpful is:
echo "set completion-ignore-case On" >> ~/.inputrc

files and instructions for mobile use will follow.
