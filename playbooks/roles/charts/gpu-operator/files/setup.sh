#!/bin/bash
helm upgrade --install gpu-operator nvidia/gpu-operator \
  --namespace gpu-operator \
  --create-namespace \
  --set nodeSelector.kubernetes.io/gpu="true" \
  --set driver.enabled=true \
  --set toolkit.enabled=true \
  --set devicePlugin.enabled=true \
  --set operator.runtimeClass="nvidia-container-runtime" \
  --set operator.defaultRuntime=containerd \
  --set containerRuntime.socketPath=/var/snap/microk8s/common/run/containerd.sock
