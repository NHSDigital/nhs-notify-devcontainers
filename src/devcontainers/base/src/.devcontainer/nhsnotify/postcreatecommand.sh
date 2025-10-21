#!/bin/bash
CURRENT_DIR=$(pwd)

echo "copying defaults"
echo "getting nhse repo template"
echo "Cloning $REPO into $DEST"

REPO=https://github.com/NHSDigital/nhs-notify-repository-template.git
DEST=$HOME/nhsengland/repository-template
CURRENT_TIMESTAMP=$(date +%Y%m%d%H%M%S)
CHECKOUT_BRANCH="devcontainer-base"
UPDATE_BRANCH="updating-the-default-files-$CURRENT_TIMESTAMP"

mkdir -p $DEST
echo "created destination directory $DEST"
echo "Cloning repository from $REPO to $DEST"
git clone -b $CHECKOUT_BRANCH $REPO $DEST
echo "cloned repository $REPO branch $CHECKOUT_BRANCH to $DEST"

CURRENT_BRANCH=$(git symbolic-ref --short HEAD)
echo "current branch is $CURRENT_BRANCH"
git switch -C $UPDATE_BRANCH

\cp -r --update=none $DEST/docs ./
\cp -rf $DEST/scripts ./
\cp -f $DEST/Makefile ./
\cp -f $DEST/.tool-versions ./
\cp --update=none $DEST/VERSION ./
\cp -f $DEST/.editorconfig ./
\cp -f $DEST/.gitattributes ./
\cp -f $DEST/.gitignore ./
\cp -f $DEST/.gitleaksignore ./


echo "$REPO template complete"

echo "reload shell"
source ~/.zshrc
echo "reloaded shell"

echo "running make config"
make config
echo "make config complete"

cd $CURRENT_DIR

echo "sorting certs"
sudo cp -r --update=none /home/ca-certificates/. /usr/local/share/ca-certificates
sudo update-ca-certificates
echo "sorted certs"


echo "configuring ohmyzsh"
echo 'export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"' >> ~/.zshrc
sed -i "/plugins=/c\plugins=(git ssh-agent sudo terraform dirhistory)" ~/.zshrc
cat ~/.zshrc
echo "configured ohmyzsh"

echo "adding gpg tty to zshrc"
echo 'export GPG_TTY=$(tty)' >> ~/.zshrc
echo "added gpg tty to zshrc"
