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

# Set git alias for status and color to auto
git config --global alias.s status
git config --global color.ui auto

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
if [[ $(node -v | grep -q "No such file or directory") ]]; then
  sudo add-apt-repository ppa:chris-lea/node.js
fi
sudo apt-get -qq update
sudo apt-get -y upgrade
sudo apt-get -y install libyaml-dev libxslt1-dev libxml2-dev libsqlite3-dev curl python-software-properties nodejs

# Install rvm, ruby, and required packages
if [[ ! $(command -v ruby) ]]; then
  echo $GREEN"Starting installation of rvm..."$RESET
  curl -L https://get.rvm.io | bash -s stable
  source ~/.rvm/scripts/rvm
  echo "source ~/.bash_profile" >> ~/.bashrc
  rvm get head --autolibs=3
  rvm requirements
  rvm install 2.0.0 --with-openssl-dir=$HOME/.rvm/usr
  rvm use --default 2.0.0
  rvm reload
fi

exit 0
