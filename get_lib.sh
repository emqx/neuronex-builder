#!/usr/bin/env bash

set -euo pipefail

[ "${DEBUG:-0}" -eq 1 ] && set -x

BUILD_PATH=${BUILD_PATH:-../_build/neuronex}

# ensure dir
cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")"

EKUIPER_PRIVATE_REPO="emqx/ekuiper"

## github token
GIT_TOKEN=${GIT_TOKEN:-""}
NEURON_V=${NEURON_V:-""}
EKUIPER_V=${EKUIPER_V:-""}
DASHBOARD_V=${DASHBOARD_V:-""}
EKUIPER_REPO=${EKUIPER_REPO:-$EKUIPER_PRIVATE_REPO}
NEURON_PRIV_REPO=${NEURON_PRIV_REPO:-"emqx/neuron"}
CUSTOMER_NAME=${CUSTOMER_NAME:-""}

ekuiper_version=$(cat ./version | grep ekuiper | awk '{print $2}')
neuron_version=$(cat ./version | grep neuron | awk '{print $2}')
dashboard_version=$(cat ./version | grep dashboard | awk '{print $2}')
datalayers_version=$(cat ./version | grep datalayers | awk '{print $2}')
neuronex_ai_version=$(cat ./version | grep ai | awk '{print $2}')
neuronex_version=${NEURONEX_V:-""}
if [ -n "$NEURON_V" ]; then
  neuron_version=$NEURON_V
fi

if [ -n "$EKUIPER_V" ]; then
  ekuiper_version=$EKUIPER_V
fi

if [ -n "$DASHBOARD_V" ]; then
  dashboard_version=$DASHBOARD_V
fi

ekuiper_architecture=""
neuron_architecture=""
is_not_arm=true
neuronex_architecture=""
case $(uname -m) in
    x86_64)
        ekuiper_architecture="amd64"
        neuron_architecture="amd64"
        neuronex_architecture="amd64"
        datalayers_architecture="amd64"
        is_not_arm=true
    ;;
    aarch64)
        ekuiper_architecture="arm64"
        neuron_architecture="arm64"
        neuronex_architecture="arm64"
        datalayers_architecture="arm64"
        is_not_arm=true
    ;;
    arm*)
        ekuiper_architecture="arm"
        neuron_architecture="armhf"
        is_not_arm=false
    ;;
    *)
        echo "Unsupported architecture $(uname -m). Only x86_64, arm64 and armhf are supported."
        exit 1
esac

# get ekuiper okg
ekuiper_public_url="https://github.com/lf-edge/ekuiper/releases/download/${ekuiper_version}/kuiper-${ekuiper_version}-linux-${ekuiper_architecture}-full.tar.gz"
ekuiper_private_build="kuiper-${ekuiper_version}-linux-${ekuiper_architecture}-ex.tar.gz"
ekuiper_private_file=$(find ./ -name "${ekuiper_private_build}")

mkdir -p ${BUILD_PATH}/software/ekuiper
if [ "$EKUIPER_REPO" !=  "$EKUIPER_PRIVATE_REPO" ]; then
  if [ -z "$ekuiper_public_file" ]; then
    curl -k --silent --show-error -L -o /tmp/ekuiper.tar.gz ${ekuiper_public_url}
    tar -zxf /tmp/ekuiper.tar.gz --strip-components 1 -C ${BUILD_PATH}/software/ekuiper
    rm /tmp/ekuiper.tar.gz
  fi
elif [ -n "$ekuiper_private_file" ]; then
  cp ${ekuiper_private_build} /tmp/ekuiper.tar.gz
  tar -zxf /tmp/ekuiper.tar.gz --strip-components 1 -C ${BUILD_PATH}/software/ekuiper
  rm /tmp/ekuiper.tar.gz
elif [ -n "$CUSTOMER_NAME" ]; then
  ./gh_dl_release.sh ${GIT_TOKEN} ${EKUIPER_PRIVATE_REPO} kuiper-${CUSTOMER_NAME}-${ekuiper_version}-linux-${ekuiper_architecture}-ex.tar.gz ${ekuiper_version}
  tar -zxf kuiper-${CUSTOMER_NAME}-${ekuiper_version}-linux-${ekuiper_architecture}-full.tar.gz --strip-components 1 -C ${BUILD_PATH}/software/ekuiper
  rm kuiper-${CUSTOMER_NAME}-${ekuiper_version}-linux-${ekuiper_architecture}-full.tar.gz
else
  ./gh_dl_release.sh ${GIT_TOKEN} ${EKUIPER_PRIVATE_REPO} kuiper-${ekuiper_version}-linux-${ekuiper_architecture}-ex.tar.gz ${ekuiper_version}
  tar -zxf kuiper-${ekuiper_version}-linux-${ekuiper_architecture}-ex.tar.gz --strip-components 1 -C ${BUILD_PATH}/software/ekuiper
  rm kuiper-${ekuiper_version}-linux-${ekuiper_architecture}-ex.tar.gz
fi

rm -rf ${BUILD_PATH}/software/ekuiper/etc/mgmt
cp init.json ${BUILD_PATH}/software/ekuiper/data/
cp -r ${BUILD_PATH}/software/ekuiper/plugins ${BUILD_PATH}/data/ekuiper/
cp -r ${BUILD_PATH}/software/ekuiper/data ${BUILD_PATH}/data/ekuiper/

# get neuron pkg
neuron_url="https://github.com/${NEURON_PRIV_REPO}/releases/download/${neuron_version}/neuron-${neuron_version}-linux-${neuron_architecture}.tar.gz"
neuron_private_build="neuron-${neuron_version}-linux-${neuron_architecture}.tar.gz"
neuron_private_file=$(find ./ -name "${neuron_private_build}")

mkdir -p ${BUILD_PATH}/software/neuron
if [ -z "$NEURON_PRIV_REPO" ]; then
  if [ -z "$neuron_private_file" ]; then
    curl -k --silent --show-error -L -o /tmp/neuron.tar.gz ${neuron_url}
  else
    cp ${neuron_private_build} /tmp/neuron.tar.gz
  fi
  tar -zxf /tmp/neuron.tar.gz --strip-components 1 -C ${BUILD_PATH}/software/neuron
  rm /tmp/neuron.tar.gz
else
  ./gh_dl_release.sh ${GIT_TOKEN} ${NEURON_PRIV_REPO} neuron-${neuron_version}-linux-${neuron_architecture}.tar.gz ${neuron_version}
  tar -zxf neuron-${neuron_version}-linux-${neuron_architecture}.tar.gz --strip-components 1 -C ${BUILD_PATH}/software/neuron
  rm neuron-${neuron_version}-linux-${neuron_architecture}.tar.gz
fi

cp -r ${BUILD_PATH}/software/neuron/persistence ${BUILD_PATH}/data/neuron/
mv ${BUILD_PATH}/software/neuron/persistence ${BUILD_PATH}/software/neuron/persistence_default
ln -s ../../data/neuron/persistence ${BUILD_PATH}/software/neuron/persistence
ln -s ../../../data/neuron/plugins/system ${BUILD_PATH}/software/neuron/plugins/system
ln -s ../../../data/neuron/plugins/custom ${BUILD_PATH}/software/neuron/plugins/custom
cp neuron.json ${BUILD_PATH}/software/neuron/config/neuron.json
rm -rf  ${BUILD_PATH}/software/neuron/dist

# get neuronex-dashboard pkg
neuronex_dashboard_private_build="neuronex-dashboard-${dashboard_version}.tgz"
neuronex_dashboard_private_file=$(find ./ -name "${neuronex_dashboard_private_build}")

mkdir -p ${BUILD_PATH}/web/common
if [ -z "$neuronex_dashboard_private_file" ]; then
  ./gh_dl_release.sh ${GIT_TOKEN} emqx/neuronex-dashboard neuronex-dashboard-${dashboard_version}.tgz ${dashboard_version}
  mv neuronex-dashboard-${dashboard_version}.tgz /tmp/neuronex-dashboard.tgz
else
  cp ${neuronex_dashboard_private_build} /tmp/neuronex-dashboard.tgz
fi
tar -zxf /tmp/neuronex-dashboard.tgz --strip-components 1 -C ${BUILD_PATH}/web/common
rm /tmp/neuronex-dashboard.tgz

datalayers_private_build="datalayers-${datalayers_version}-${datalayers_architecture}.tar.gz"
datalayers_url="https://docs.datalayers.cn/public/tar/${datalayers_private_build}"

if [ "$is_not_arm" = true ]; then
    mkdir -p ${BUILD_PATH}/software/datalayers
    curl -k --silent --show-error -L -o /tmp/datalayers.tar.gz ${datalayers_url}
    tar -zxf /tmp/datalayers.tar.gz --strip-components 2 -C ${BUILD_PATH}/software/datalayers
    rm /tmp/datalayers.tar.gz
fi

# 从 github repo api 获取最新 neuronex-ai 版本
if [ "${DEPLOY_METHOD:-}" = "ai" ]; then
    mkdir -p ${BUILD_PATH}/software/neuronex-ai
    NEURONEX_AI_REPO="emqx/neuronex-ai"

    ./gh_dl_release.sh ${GIT_TOKEN} ${NEURONEX_AI_REPO} neuronex-ai-${neuronex_ai_version}.tar.gz ${neuronex_ai_version}
    tar -zxf neuronex-ai-${neuronex_ai_version}.tar.gz --strip-components 1 -C ${BUILD_PATH}/software/neuronex-ai
    rm neuronex-ai-${neuronex_ai_version}.tar.gz
    
    # 删除 ${BUILD_PATH}/software/neuronex-ai/packages/doc_search/docs 目录下所有以 _assets 和 assets 为名的目录
    if [ -d "${BUILD_PATH}/software/neuronex-ai/packages/doc_search/docs" ]; then
        find ${BUILD_PATH}/software/neuronex-ai/packages/doc_search/docs -type d -name "_assets" -exec rm -rf {} +
        find ${BUILD_PATH}/software/neuronex-ai/packages/doc_search/docs -type d -name "assets" -exec rm -rf {} +
    fi
    
fi


# get neuronex-go pkg
if [ -n "${neuronex_version}" ]; then
  mkdir -p /tmp/neuronex/
  ./gh_dl_release.sh ${GIT_TOKEN} emqx/neuronex-go neuronex-${neuronex_version}-linux-${neuronex_architecture}.tar.gz ${neuronex_version}
  mv neuronex-${neuronex_version}-linux-${neuronex_architecture}.tar.gz /tmp/neuronex.tar.gz

  tar -zxf /tmp/neuronex.tar.gz --strip-components 1 -C /tmp/neuronex/
  cp /tmp/neuronex/bin/neuronex ${BUILD_PATH}/bin/
  rm /tmp/neuronex.tar.gz
  rm -rf /tmp/neuronex/
fi
