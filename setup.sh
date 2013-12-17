#!/bin/bash

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

# Download Sublime Text 2
if [ `getconf LONG_BIT` = "64" ]
then
    echo $GREEN"Downloading 64 bit version of Sublime Text 2..."$RESET;
    wget -c -O ./installation/downloads/st2.tar.bz2 "http://c758482.r82.cf2.rackcdn.com/Sublime%20Text%202.0.2%20x64.tar.bz2";
else
    echo $GREEN"Downloading 32 bit version of Sublime Text 2..."$RESET;
    wget -c -O ./installation/downloads/st2.tar.bz2 "http://c758482.r82.cf2.rackcdn.com/Sublime%20Text%202.0.2.tar.bz2";
fi

# Extract ST2
echo $GREEN"Extracting..."$RESET;
sudo tar --overwrite -xvjf ./installation/downloads/st2.tar.bz2 -C /opt > /dev/null;
sudo mv /opt/Sublime\ Text\ 2/ /opt/sublime-text-2;
sudo ln -sf /opt/sublime-text-2/sublime_text /usr/bin/subl;
sudo ln -sf /opt/sublime-text-2/sublime_text /usr/bin/sublime;


# Output package control installation command
# cat ./output-snippets/package-control.txt

exit 0;
