#!/bin/bash
CURRENT_DIR=$(pwd)


echo 'export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"' >> ~/.zshrc
sed -i "/plugins=/c\plugins=(git ssh-agent sudo terraform dirhistory)" ~/.zshrc
cat ~/.zshrc

echo "copying defaults"
echo "getting nhse repo template"
echo "Cloning $REPO into $DEST"

REPO=https://github.com/NHSDigital/nhs-notify-repository-template.git
DEST=$HOME/nhsengland/repository-template
UPDATE_BRANCH=updating-the-default-files

mkdir -p $DEST
echo "created destination directory $DEST"
echo "Cloning repository from $REPO to $DEST"
git clone $REPO $DEST
echo "cloned repository $REPO to $DEST"

CURRENT_BRANCH=$(git symbolic-ref --short HEAD)
echo "current branch is $CURRENT_BRANCH"
git switch -C $UPDATE_BRANCH

\cp -rf $DEST/scripts ./scripts
\cp -f $DEST/Makefile ./
\cp -f $DEST/.tool-versions ./

git add .
git commit -m "Update default files from $REPO" || echo "No changes to commit"

git switch $CURRENT_BRANCH
git merge $UPDATE_BRANCH -m "Merge default files from $REPO"
echo "$REPO template complete"

echo "adding gpg tty to zshrc"
echo 'export GPG_TTY=$(tty)' >> ~/.zshrc
echo "added gpg tty to zshrc"

echo "running make config"
source ~/.zshrc
echo "sourced .zshrc"
make config
echo "make config complete"

cd $CURRENT_DIR

echo "sorting certs"
sudo cp -nr /home/ca-certificates/. /usr/local/share/ca-certificates
sudo update-ca-certificates
echo "sorted certs"
