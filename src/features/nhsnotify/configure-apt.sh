#! /bin/bash

pwd
ls -la
echo "Installing APT packages from packages.txt"
apt-get update
echo "Packages to be installed:"
cat packages.txt
echo "Starting APT packages installation"
cat packages.txt | xargs apt-get install -y --install-suggests --install-recommends
echo "APT packages installation complete"