# infosystem
A shell based information management system (2010-2015)

git and easy install under construction

You can watch an intro here: 
http://msoon.kochab.uberspace.de/infosystem_intro.webm (better download)

##Install

we need the following tools:

git, bc, wget, sqlite3, sed, awk, curl


and some editor like vim or nano defined in $EDITOR

export EDITOR="/usr/bin/vim"
in ~/.bashrc

git clone https://github.com/msooon/infosystem.git 

cd infosystem

edit files: config and install.sh

as superuser: ./install.sh

as normal user: source config

sqlite3 $database < infosystem.sql

