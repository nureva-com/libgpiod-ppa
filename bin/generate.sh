#!/bin/bash

# Packages & Packages.gz
dpkg-scanpackages --multiversion . > Packages
gzip -k -f Packages

# Release, Release.gpg & InRelease
apt-ftparchive release . > Release
gpg2 --default-key 8FEEDF80F3484CFE99E3BD1D416932846F1D3718 -abs -o - Release > Release.gpg
gpg2 --default-key 8FEEDF80F3484CFE99E3BD1D416932846F1D3718 --clearsign -o - Release > InRelease
