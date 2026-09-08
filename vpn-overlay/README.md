# XConnect Zero Trust topology declarations

This directory is the GitOps source for reviewed, non-sensitive XConnect Zero
Trust network declarations. It describes intended environment topology, public
service endpoints, immutable release pins, cloud sizing, and verification
requirements. It does not contain Terraform resources, host configuration, or
credentials.

## Ownership boundary

| Repository | Owns |
| --- | --- |
| `iac_modules` | Reusable Terraform modules and their module-local validation. |
| `playbooks` | OS-level Xray, WireGuard, Gateway, and controlled-client roles. |
| `gitops/vpn-overlay` | Environment topology and non-sensitive deployment intent. |

Vault is the only source for signing material, enrollment credentials, VLESS
credentials, and device private keys. XConnect Zero Accounts remains the
runtime source of truth for devices, networks, policies, and signed configs.

## Environments

`uat/xconnect-lab.json` is the canonical disposable UAT declaration for the
XConnect Zero → Gateway → One WireGuard-over-VLESS closure. It pins the two
AWS Spot node shapes and release artifacts, while the workflow injects secrets
only at runtime.
