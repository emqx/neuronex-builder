# EMQX NeuronEX builder

## Introduction

EMQX NeuronEX builder is a tool to build NeuronEX install packages and container images include amd64 and arm64 support.


## package

1. NeuronEX amd64 rpm/deb/tar.gz install package
2. NeuronEX arm64 rpm/deb/tar.gz install package
3. NeuronEX amd64 container image
4. NeuronEX arm64 container image


## Usage

1. Standard NeuronEX install package;
2. Customized NeuronEX install package;
3. Standard or Customized building is depends on the tag schema you make and push to this repo.

## Tag Schema

### How to build a Standard NeuronEX install package

1. emqx/neuronex-go repo already has the same tag as 3.7.0
2. the tag must be X.Y.Z-[alpha|beta|rc].N, e.g. 3.7.0-alpha.1, `-[alpha|beta|rc].N` is optional
3. make a same tag in this repo and push it
4. the package will be built automatically, available at [neuronex-builder releases](https://github.com/emqx/neuronex-builder/releases)
5. the container image will be available at [emqx/neuronex](https://hub.docker.com/r/emqx/neuronex)

### How to build a Customized NeuronEX install package

1. to set the all dependency package version in version file and neuronex_version file
2. commit the version file and neuronex_version file, then push it
3. make a custom tag in this repo and push it, e.g. 3.7.0-customer_flag
4. the custom tag must be X.Y.Z-customer_flag-[alpha|beta|rc].N, e.g. 3.7.0-customname20251001-alpha.1, `-[alpha|beta|rc].N` is optional
4. the package will be built automatically, available at [neuronex-builder releases](https://github.com/emqx/neuronex-builder/releases)
5. the container image will be available at [emqx/neuronex](https://hub.docker.com/r/emqx/neuronex)