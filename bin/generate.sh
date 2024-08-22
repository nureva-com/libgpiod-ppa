#!/bin/bash
# Packages & Packages.gz
dpkg-scanpackages --multiversion . > Packages
gzip -k -f Packages

# Release, Release.gpg & InRelease
apt-ftparchive release . > Release
gpg --default-key "gpg-boost@nureva.com" -abs -o - Release > Release.gpg
gpg --default-key "gpg-boost@nureva.com" --clearsign -o - Release > InRelease
