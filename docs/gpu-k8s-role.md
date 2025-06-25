# GPU Kubernetes Role

This document describes how to use the `gpu-k8s` role to deploy a simple Kubernetes cluster with NVIDIA GPU support.

## Overview

The role performs four main tasks:

1. **Create the Kubernetes cluster** using [sealos](https://github.com/labring/sealos). It runs the provided `sealos run` command to bootstrap the master and worker nodes.
2. **Install NVIDIA drivers and the NVIDIA container toolkit** on the target hosts so that Kubernetes can access GPU resources.
3. **Verify the cluster state** after initialization, displaying the `sealos` version and the current Kubernetes nodes.
4. **Verify GPU access** by deploying the official NVIDIA device plugin and running a small CUDA workload.

When `sealos_version` is set to `latest` (the default), the role automatically
fetches the most recent stable release from GitHub.


The following command is used to create the cluster (example with one master and one worker):

```bash
sealos run \
  registry.cn-shanghai.aliyuncs.com/labring/kubernetes:<latest> \
  registry.cn-shanghai.aliyuncs.com/labring/cilium:<cilium_version> \
  registry.cn-shanghai.aliyuncs.com/labring/helm:<helm_version> \
  --masters 172.16.11.120 \
  --nodes 172.16.11.152 \
  --env '{}' \
  --cmd "kubeadm init --skip-phases=addon/kube-proxy"
```

After the cluster is running the role installs the NVIDIA device plugin and runs a test pod to ensure `nvidia-smi` works inside the cluster.

## Usage

Add the role to your playbook along with the `ssh-trust` role which configures passwordless access from the ops host to the cluster nodes:

```yaml
- hosts: all
  roles:
    - ssh-trust
    - gpu-k8s
```


Example playbook snippet defining the IP lists:

```yaml
- hosts: all
  vars:
    master_ips:
      - "172.16.11.120"
    node_ips:
      - "172.16.11.152"
  roles:
    - ssh-trust
    - gpu-k8s
```

The playbook expects `master_ips` and `node_ips` variables which are lists of IP addresses. Up to
three masters can be specified.


Run the playbook with your inventory that contains the master and node IP addresses.


```bash
ansible-playbook -i inventory/hosts/all playbooks/demo_gpu_k8s.yml
```

The final step prints the output of `nvidia-smi` from inside a Kubernetes pod, confirming that the GPU is available.
