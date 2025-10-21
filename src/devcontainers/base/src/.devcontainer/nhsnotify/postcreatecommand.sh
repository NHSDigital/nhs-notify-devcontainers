#!/bin/bash
CURRENT_DIR=$(pwd)

echo 'install asdf via go'
go install github.com/asdf-vm/asdf/cmd/asdf@v0.18.0
echo 'export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"' >> ~/.zshrc
#git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
#echo 'source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh' >> ~/.zshrc
#sed -i "/plugins=/c\plugins=(git ssh-agent sudo terraform dirhistory zsh-autosuggestions)" ~/.zshrc
sed -i "/plugins=/c\plugins=(git ssh-agent sudo terraform dirhistory)" ~/.zshrc
cat ~/.zshrc


echo "installing asdf plugins"
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
echo 'eval "$(zoxide init zsh)"' >> ~/.zshrc
echo "zoxide plugin added"

cat ~/.zshrc

echo "copying defaults"
echo "getting nhse repo template"
echo "Cloning $REPO into $DEST"

REPO=https://github.com/NHSDigital/nhs-notify-repository-template.git
DEST=$HOME/nhsengland/repository-template

mkdir -p $DEST
echo "created destination directory $DEST"
echo "Cloning repository from $REPO to $DEST"
git clone $REPO $DEST
echo "cloned repository $REPO to $DEST"
git switch -C updating-the-default-files

\cp -rf $DEST/scripts ./scripts
\cp -f $DEST/Makefile ./
\cp -f $DEST/.tool-versions ./

git add .
git commit -m "Update default files from $REPO" || echo "No changes to commit"

git switch -
git merge updating-the-default-files -m "Merge default files from $REPO"
echo "$REPO template complete"

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
