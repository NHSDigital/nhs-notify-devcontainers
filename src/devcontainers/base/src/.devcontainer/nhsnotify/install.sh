#!/bin/bash

cp ./postcreatecommand.sh /postcreatecommand.sh
cp ./poststartcommand.sh /poststartcommand.sh
cp ./welcome.sh /welcome.sh
cp ./Makefile ~/Makefile

cp ~/.zshrc /.zshrc
rm -Rf /.asdf
git clone https://github.com/asdf-vm/asdf.git /.asdf;
chmod +x /.asdf/asdf.sh;
echo '. /.asdf/asdf.sh' >> /.zshrc
echo '. /.asdf/completions/asdf.bash' >> /.zshrc
sed -i "/plugins=/c\plugins=(git ssh-agent sudo terraform dirhistory zsh-autosuggestions)" /.zshrc

cat /.zshrc

cp /.zshrc ~/.zshrc
source ~/.zshrc
mkdir -p /zsh/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions /zsh/plugins/zsh-autosuggestions


mdir -p /nhsengland/repository-template
https://github.com/nhs-england-tools/repository-template.git /nhsengland/repository-template
