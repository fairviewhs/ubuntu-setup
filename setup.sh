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

# Set git user name and email if not set
sudo apt-get -y install git
echo $GREEN"Checking git settings..."$RESET
if [[ $(git config --global user.name) = "" ]]; then
  read -p "Enter github account name: " gitname
  git config --global user.name "$gitname"
fi
if [[ $(git config --global user.email) = "" ]]; then
  read -p "Enter the email you use for GitHub or are planning to use: " gitemail
  git config --global user.email "$gitemail"
fi

# Set git aliases, color to auto, and credential cache to one hour
git config --global alias.s status
git config --global alias.ci commit
git config --global color.ui auto
git config --global credential.helper 'cache --timeout=3600'

# Update using apt-get and install packages required for ruby/rails, etc.
echo $GREEN"Upgrading software packages..."$RESET
sudo apt-get -qq update
sudo apt-get -y upgrade

# Prompt to install Atom editor (optional, but recommended)
if [[ ! $(command -v atom) ]]; then
  read -p "Do you want to install the Atom editor? " -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    sudo add-apt-repository ppa:webupd8team/atom
    sudo apt-get -qq update
    sudo apt-get -y install atom
    apm install merge-conflicts tabs-to-spaces
    # TODO: decide on replacement for atom-lint
  fi
fi

# Install node.js for an execjs runtime
if [[ ! $(command -v node) ]]; then
  echo $GREEN"Installing node.js..."$RESET

  curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
  sudo apt-get -y install nodejs
fi

# Install and set up postgresql:
# http://wiki.postgresql.org/wiki/Apt
if [[ ! $(command -v psql) ]]; then
  echo $GREEN"Setting up PostgreSQL..."$RESET

  if [[ ! -a "/etc/apt/sources.list.d/pgdg.list" ]]; then
    sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  fi
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  sudo apt-get -qq update
  sudo apt-get -y install postgresql-9.5 pgadmin3 libpq-dev

  # Create user with the same name as the current user to access postgresql database
  read -p "Enter the password you want to use for the PostgreSQL database: " psqlpass
  sudo -u postgres psql -c "CREATE USER $(whoami) WITH PASSWORD '$psqlpass'; ALTER USER $(whoami) CREATEDB;"

  # Create development and test databases for the fhs-rails application
  createdb --owner="$(whoami)" --template=template0 --lc-collate=C --echo fhs_development
  createdb --owner="$(whoami)" --template=template0 --lc-collate=C --echo fhs_test
fi

# Install other miscellaneous packages for Ruby/Rails
sudo apt-get -y install curl libyaml-dev libxslt1-dev libxml2-dev libsqlite3-dev python-software-properties libmagickwand-dev

# Install ruby and required packages
echo $GREEN"Setting up Ruby..."$RESET
sudo apt-get -y install ruby-full
if [[ ! $(grep 'gem: --user-install' ~/.gemrc) ]]; then
  echo 'gem: --user-install' >> ~/.gemrc
fi
if [[ ! $(grep 'PATH="$(ruby -rubygems -e puts Gem.user_dir)/bin:$PATH"' ~/.profile) ]]; then
  echo 'if which ruby >/dev/null && which gem >/dev/null; then' >> ~/.profile
  echo '  PATH="$(ruby -rubygems -e 'puts Gem.user_dir')/bin:$PATH"' >> ~/.profile
  echo 'fi' >> ~/.profile
  PATH="$(ruby -rubygems -e 'puts Gem.user_dir')/bin:$PATH"
  #source ~/.profile
fi

read -p "Do you want to clone and setup the Fairview site repository (a new fork will be created if needed)? " -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  read -s -p "Enter password for $(git config --global user.name)": PW
  echo
  curl -s -u "$(git config --global user.name):$PW" https://api.github.com/user  > /dev/null
  curl -s -u "$(git config --global user.name):$PW" -X POST https://api.github.com/repos/fairviewhs/fhs-rails/forks  > /dev/null
  sleep 60
  git clone https://"$(git config --global user.name):$PW@github.com/$(git config --global user.name)/fhs-rails.git"
  cd fhs-rails
  gem install bundler
  bundle install
  cp config/secrets.yml.sample config/secrets.yml
  cp config/database.yml.sample config/database.yml
  rake db:setup
fi
