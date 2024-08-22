#!/bin/bash

# Packages & Packages.gz
dpkg-scanpackages --multiversion . > Packages
gzip -k -f Packages

# Release, Release.gpg & InRelease
apt-ftparchive release . > Release
gpg2 --default-key " gpg-github-ppa@nureva.com" -abs -o - Release > Release.gpg
gpg2 --default-key "gpg-github-ppa@nureva.com" --clearsign -o - Release > InRelease
