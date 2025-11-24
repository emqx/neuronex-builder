#!/bin/bash

set -e -x -u
export PKG_PATH=${PKG_PATH:-"_packages"}

case $(uname -m) in
    aarch64)
       exit 0
    ;;
    arm*)
       exit 0
esac

if dpkg --help >/dev/null 2>&1; then
    dpkg -i $PKG_PATH/*.deb
    [ "$(dpkg -l |grep neuronex |awk '{print $1}')" = "ii" ]
    neuronex start
    sleep 1
    if ! curl 127.0.0.1:8085  >/dev/null 2>&1; then echo "neuronex start failed"; exit 1; fi
    dpkg -r neuronex
    [ "$(dpkg -l |grep neuronex |awk '{print $1}')" = "rc" ]
    dpkg -P neuronex
    [ -z "$(dpkg -l |grep neuronex)" ]
fi

if rpm --help >/dev/null 2>&1; then
    rpm -ivh $PKG_PATH/*.rpm
    [ ! -z $(rpm -q neuronex | grep -o neuronex) ]
    neuronex start
    sleep 1
    if ! curl 127.0.0.1:8085  >/dev/null 2>&1; then echo "neuronex start failed"; exit 1; fi
    rpm -e neuronex
    [ "$(rpm -q neuronex)" == "package neuronex is not installed" ]
fi
