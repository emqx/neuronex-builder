#!/bin/bash

dnf update -y
dnf install epel-release -y
dnf install jq -y
dnf install ffmpeg -y
dnf install python3 -y
dnf install rsync -y
dnf install rpm-build -y
echo "installation finished"
