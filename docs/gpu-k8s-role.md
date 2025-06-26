# GPU Kubernetes Role

This document describes how to use the `gpu-k8s` role to deploy a simple Kubernetes cluster with NVIDIA GPU support.

## Overview

The role performs four main tasks:

1. **Create the Kubernetes cluster** using [sealos](https://github.com/labring/sealos). It runs the provided `sealos run` command to bootstrap the master and worker nodes.
2. **Install NVIDIA drivers and the NVIDIA container toolkit** on the target hosts so that Kubernetes can access GPU resources.
3. **Verify the cluster state** after initialization, displaying the `sealos` version and the current Kubernetes nodes.
4. **Verify GPU access** by deploying the official NVIDIA device plugin and running a small CUDA workload.

When `sealos_version` is set to `latest` (the default), the role automatically
fetches the most recent stable release from GitHub. The Kubernetes image tag is
controlled separately via `kubernetes_version`, which defaults to `v1.25.16` but
can be overridden to any compatible release.


The following command is used to create the cluster (example with one master and one worker):

```bash
REGISTRY=$(playbooks/roles/vhosts/gpu-k8s/files/get_labring_registry.sh)
sealos run \
  ${REGISTRY}/kubernetes:<kubernetes_version> \
  ${REGISTRY}/cilium:<cilium_version> \
  ${REGISTRY}/helm:<helm_version> \
  --masters 172.16.11.120 \
  --nodes 172.16.11.152 \
  --env '{}' \
  --cmd "kubeadm init --skip-phases=addon/kube-proxy"
```

By default the role runs the command as root. Set `root_mode` to `false` to
deploy in rootless mode, which adds `--user` and `--pk` options pointing to the
SSH key for `ssh_user`. In rootless mode the host running Sealos must have
`newuidmap` and `newgidmap` installed (typically provided by the `uidmap`
package) along with the `fuse-overlayfs` binary to enable user namespaces.

If deploying with a non-root user the command also requires `--user` and
`--pk` options pointing to the user's SSH key. The host running Sealos must have
`newuidmap` and `newgidmap` installed (typically provided by the `uidmap` package) 
along with the `fuse-overlayfs` binary to enable user namespaces.


After the cluster is running the role installs the NVIDIA device plugin and runs a test pod to ensure `nvidia-smi` works inside the cluster.

## Usage

Add the role to your playbook along with the `ssh-trust` role which configures passwordless access from the ops host to the cluster nodes. The `gpu-k8s` role automatically pulls in the `common` role so you do not need to list it separately:

```yaml
- hosts: all
  roles:
    - ssh-trust
    - gpu-k8s
```



Set `root_mode` to `false` if you want the playbook to operate as this user
instead of root, enabling rootless deployment of the cluster.


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

You can also specify hostnames and let the role look up the IPs:

```yaml
- hosts: all
  vars:
    masters:
      - "k8s-1"
    nodes:
      - "k8s-2"
      - "k8s-3"
  roles:
    - ssh-trust
    - gpu-k8s
```

The playbook expects at least one master and one node. You can provide the
addresses directly via `master_ips` and `node_ips`, or give hostnames in the
`masters` and `nodes` variables. When hostnames are used, the role will look up
their `ansible_host` values from the inventory to obtain the IPs. Up to three
masters can be specified.


Run the playbook with your inventory that contains the master and node IP addresses.


```bash
ansible-playbook -i inventory/hosts/all playbooks/demo_gpu_k8s.yml
```

The final step prints the output of `nvidia-smi` from inside a Kubernetes pod, confirming that the GPU is available.
