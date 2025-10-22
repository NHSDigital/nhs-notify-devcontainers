#! /bin/bash

pwd
ls -la
echo "Installing APT packages from packages.txt"
apt-get update
echo "Packages to be installed:"
cat packages.txt
echo "Starting APT packages installation"
apt-get --install-suggests --install-recommends -y install < packages.txt
echo "APT packages installation complete"