# Repository Structure

This repository combines Ansible playbooks with Kubernetes manifests and
automation scripts. Below is a short overview of the key directories.

| Directory | Purpose |
|-----------|---------|
| `playbooks` | Ansible playbooks and role definitions. |
| `apps` | Flux HelmRelease and Kustomize files for applications. |
| `clusters` | Kustomize overlays for different clusters referencing the `apps` definitions. |
| `helmfiles` | Sample [helmfile](https://github.com/helmfile/helmfile) declarations. |
| `helm` | Local Helm charts used in some playbooks. |
| `inventory` | Example inventories and group variables for Ansible. |
| `scripts` | Utility scripts such as cluster setup or secret management. |
| `sync` | Tasks for local host setup and testing. |
| `docs` | Additional documentation. |

See `docs/gpu-k8s-role.md` for an example walkthrough deploying a GPU-enabled
Kubernetes cluster.
