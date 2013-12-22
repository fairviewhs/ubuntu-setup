#!/bin/bash

# Text formatting variable definitions
RESET=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
PURPLE=$(tput setaf 5)
CYAN=$(tput setaf 6)
BOLD=$(tput bold)
LINE=$(tput sgr 0 1)

# Directory setup
mkdir -p ./installation/downloads

# Set git user name and email if not set
echo $GREEN"Updating git settings..."$RESET
if [[ $(git config --global user.name) = "" ]]; then
  read -p "Enter the name you want to appear for your git commits: " gitname
  git config --global user.name "$gitname"
fi
if [[ $(git config --global user.email) = "" ]]; then
  read -p "Enter the email you use for GitHub or are planning to use: " gitemail
  git config --global user.email "$gitemail"
fi

# Set git alias, color to auto, and credential cache
git config --global alias.s status
git config --global color.ui auto
git config credential.helper 'cache --timeout=900'

# Only run if sublime text is not installed
if [[ $(subl -v) = "" ]]; then
  echo $GREEN"Installing Sublime Text 2..."$RESET
  # Download Sublime Text 2
  if [[ $(getconf LONG_BIT) = "64" ]]; then
    echo $GREEN"Downloading 64 bit version of Sublime Text 2..."$RESET
    wget -c -O ./installation/downloads/st2.tar.bz2 "http://c758482.r82.cf2.rackcdn.com/Sublime%20Text%202.0.2%20x64.tar.bz2"
  else
    echo $GREEN"Downloading 32 bit version of Sublime Text 2..."$RESET
    wget -c -O ./installation/downloads/st2.tar.bz2 "http://c758482.r82.cf2.rackcdn.com/Sublime%20Text%202.0.2.tar.bz2"
  fi

  # Extract ST2
  echo $GREEN"Extracting..."$RESET
  sudo tar --overwrite -xvjf ./installation/downloads/st2.tar.bz2 -C /opt > /dev/null
  sudo rm -rf /opt/sublime-text-2/
  sudo mv /opt/Sublime\ Text\ 2/ /opt/sublime-text-2/
  sudo ln -sf /opt/sublime-text-2/sublime_text /usr/bin/subl
  sudo ln -sf /opt/sublime-text-2/sublime_text /usr/bin/sublime

  # Open ST2 to create config folder and load settings from the files folder
  subl &
  cp -f ./files/Preferences.sublime-settings ~/.config/sublime-text-2/Packages/User/Preferences.sublime-settings

  # Output package control installation command and instructions
  echo $GREEN$BOLD"  Open the 'View' menu and click on 'Show Console' in Sublime Text. Then enter the following command to install Package Control:"$RESET
  cat ./output-snippets/package-control.txt
  echo $GREEN"After entering the command, please exit Sublime Text again. When ready, press [Enter] to continue."$RESET
  read
fi

# Update using apt-get and install packages required for ruby/rails, etc.
echo $GREEN"Updating software..."$RESET
sudo apt-get -qq update
sudo apt-get -y upgrade

# Install node.js
if [[ ! $(command -v node) ]]; then
  sudo add-apt-repository ppa:chris-lea/node.js
  sudo apt-get -y install nodejs
fi

# Install and set up postgresql:
# http://wiki.postgresql.org/wiki/Apt
if [[ ! $(command -v psql) ]]; then
  if [[ ! -a "/etc/apt/sources.list.d/pgdg.list" ]]; then
    sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ squeeze-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  fi
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  sudo apt-get -qq update
  sudo apt-get -y install postgresql-9.3 pgadmin3 libpq-dev

  read -p "Enter the password you want to use for the PostgreSQL database: " psqlpass
  sudo -u postgres psql -c "CREATE USER $(whoami) WITH PASSWORD '$psqlpass'; ALTER USER $(whoami) CREATEDB;"
  createdb --owner=$(whoami) --template=template0 --lc-collate=C --echo fhs_development
  createdb --owner=$(whoami) --template=template0 --lc-collate=C --echo fhs_test
fi

# Install miscellaneous other packages for Ruby/Rails
sudo apt-get -y install curl libyaml-dev libxslt1-dev libxml2-dev libsqlite3-dev python-software-properties libmagickwand-dev

# Install rvm, ruby, and required packages
if [[ ! $(command -v ruby) ]]; then
  echo $GREEN"Starting installation of rvm..."$RESET
  curl -L https://get.rvm.io | bash -s stable
  source ~/.rvm/scripts/rvm
  if [[ ! $(grep "source ~/.bash_profile" ~/.bashrc) ]]; then
    echo "source ~/.bash_profile" >> ~/.bashrc
  fi
  rvm get head --autolibs=3
  rvm requirements
  rvm install 2.0.0 --with-openssl-dir=$HOME/.rvm/usr
  rvm use --default 2.0.0
  rvm reload
fi

exit 0
