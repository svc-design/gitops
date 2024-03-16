#!/bin/sh

check_not_empty() {
  if [[ -z $1 ]]; then
    echo "Error: $2 is empty. Please provide a value."
    exit 1
  fi
}

function run()
{

  # 检查参数是否为空
  check_not_empty "$1" "cluster" && local cluster=$1
  check_not_empty "$2" "namespace" && local namespace=$2
  check_not_empty "$3" "secret" && local secret=$3

  kubectl config set-context --current --namespace $namespace
  echo $cluster $namespace $secret
  kubectl get secret $secret -n $namespace --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode || true
}
