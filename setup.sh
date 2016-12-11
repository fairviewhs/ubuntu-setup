#!/bin/bash

# Text formatting variable definitions
# shellcheck disable=SC2034
{
  RESET=$(tput sgr0)
  RED=$(tput setaf 1)
  GREEN=$(tput setaf 2)
  YELLOW=$(tput setaf 3)
  BLUE=$(tput setaf 4)
  PURPLE=$(tput setaf 5)
  CYAN=$(tput setaf 6)
  BOLD=$(tput bold)
  LINE=$(tput sgr 0 1)
}

echo "${GREEN}Upgrading software packages...$RESET"
sudo apt-get -qq update
sudo apt-get -y upgrade

# Install and configure git; install curl
sudo apt-get -y install git curl
echo "${GREEN}Checking git settings...$RESET"
if [[ $(git config --global user.name) = "" ]]; then
  read -p "Enter your name: " -r gitname
  git config --global user.name "$gitname"
fi
if [[ $(git config --global user.email) = "" ]]; then
  read -p "Enter the email you use for GitHub or are planning to use: " -r gitemail
  git config --global user.email "$gitemail"
fi

# Set git aliases, color to auto, and credential cache to one hour
git config --global alias.s status
git config --global alias.ci commit
git config --global color.ui auto
git config --global credential.helper 'cache --timeout=3600'

# Prompt to install Atom editor (optional, but recommended)
if [[ ! $(command -v atom) ]]; then
  read -p "Do you want to install the Atom editor? " -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo add-apt-repository ppa:webupd8team/atom
    sudo apt-get -qq update
    sudo apt-get -y install atom
    apm install merge-conflicts tabs-to-spaces linter linter-rubocop linter-scss-lint linter-erb
  fi
fi

# Install node.js for an execjs runtime
if [[ ! $(command -v node) ]]; then
  echo "${GREEN}Installing node.js...$RESET"
  curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
  sudo apt-get -y install nodejs
fi

# Install and set up postgresql:
# https://wiki.postgresql.org/wiki/Apt
if [[ ! $(command -v psql) ]]; then
  echo "${GREEN}Setting up PostgreSQL...$RESET"
  if [[ ! -a "/etc/apt/sources.list.d/pgdg.list" ]]; then
    sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  fi
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  sudo apt-get -qq update
  sudo apt-get -y install postgresql-9.5 pgadmin3 libpq-dev

  # Create user with the same name as the current user to access postgresql database
  read -p "Enter the password you want to use for the PostgreSQL database: " -r psqlpass
  sudo -u postgres psql -c "CREATE USER $(whoami) WITH PASSWORD '$psqlpass'; ALTER USER $(whoami) CREATEDB;"

  # Create development and test databases for the fhs-rails application
  createdb --owner="$(whoami)" --template=template0 --lc-collate=C --echo fhs_development
  createdb --owner="$(whoami)" --template=template0 --lc-collate=C --echo fhs_test
fi

# Install other miscellaneous packages for Ruby/Rails
sudo apt-get -y install libyaml-dev libxslt1-dev libxml2-dev libsqlite3-dev python-software-properties libmagickwand-dev

# Install ruby and required packages
echo "${GREEN}Setting up Ruby...$RESET"
sudo apt-get -y install ruby-full

# Make gems be installed locally by default
if ! grep -q 'gem -user-install' ~/.gemrc; then
  echo 'gem: --user-install' >> ~/.gemrc
fi

if ! grep -q 'PATH='\"'$PATH:$(ruby -rubygems -e '\''puts Gem.user_dir'\'')/bin'\" ~/.profile; then
  {
    echo
    echo 'if which ruby >/dev/null && which gem >/dev/null; then'
    echo '  PATH='\"'$PATH:$(ruby -rubygems -e '\''puts Gem.user_dir'\'')/bin'\"
    echo 'fi'
  } >> ~/.profile
  PATH="$PATH:$(ruby -rubygems -e 'puts Gem.user_dir')/bin"
fi

read -p "Do you want to clone and setup the Fairview site repository (a new fork will be created if needed)? " -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  read -p "Enter your GitHub username: " -r GH_USER
  STATUS="401"
  while [[ $STATUS != "200" ]]; do
    read -s -p "Enter GitHub password for $GH_USER: " -r GH_PW
    echo
    STATUS=$(curl -isS https://api.github.com -u "$GH_USER:$GH_PW" | head -n 1 | cut -d$' ' -f2)
    if [[ $STATUS != "200" ]]; then
      echo "${RED}Could not authenticate, got status code $STATUS, try again$RESET"
    fi
  done

  echo "${GREEN}Authenticated successfully, now setting up the repository...$RESET"
  curl -s -u "$GH_USER:$GH_PW" -X POST https://api.github.com/repos/fairviewhs/fhs-rails/forks  > /dev/null
  sleep 60
  git clone https://"$GH_USER:$GH_PW@github.com/$GH_USER/fhs-rails.git"
  git remote add upstream https://github.com/fairviewhs/fhs-rails.git
  cd fhs-rails || exit
  gem install bundler
  bundle install
  cp config/secrets.yml.sample config/secrets.yml
  cp config/database.yml.sample config/database.yml
  rake db:setup > /dev/null
fi

echo "${GREEN}Setup has completed.$RESET"
echo "${BLUE}Note: you must reboot for everything to work properly.$RESET"

read -p "Would you like to reboot now? " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
  reboot
fi
