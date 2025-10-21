#!/bin/bash

cp ./postcreatecommand.sh /postcreatecommand.sh
cp ./poststartcommand.sh /poststartcommand.sh
cp ./welcome.sh /welcome.sh
cp ./Makefile /Makefile

#ource ~/.zshrc
echo "go is at $(which go)"
echo 'install asdf via go'
go install github.com/asdf-vm/asdf/cmd/asdf@v0.18.0
