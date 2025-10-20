#!/bin/bash

cp /.zshrc ~/.zshrc
cp -r /zsh/* ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
ls -la ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

cat ~/.zshrc
source ~/.zshrc
echo 'asdf setup complete'


echo 'copying defaults'

cp /nhsengland/repository-template/scripts ./scripts -r
cp /nhsengland/repository-template/Makefile ./
cp /nhsengland/repository-template/.tool-versions ./

make config
echo 'make config complete'

# jekyll --version && cd docs && bundle install
# echo 'jekyll setup complete'

#/welcome.sh