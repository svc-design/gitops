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

`uat/xconnect-transport-lab.json` is the first-stage, control-plane-free
four-node WireGuard-over-VLESS validation declaration. It is intentionally
separate from `uat/xconnect-lab.json`: it establishes the Gateway/Linux/
Windows/macOS runtime and transport baseline before Accounts enrollment,
signed configuration, policy and ACK are introduced. It declares only role,
version-independent topology, Spot shape, TTL and non-sensitive addresses.
Runtime private keys, disposable TLS material, VLESS identities and rendered
peer files are generated on protected nodes or runners and never enter GitOps.

`uat/xconnect-lab.json` is the canonical disposable UAT declaration for the
XConnect Zero → Gateway → One WireGuard-over-VLESS closure. It pins the two
AWS Spot node shapes and release artifacts, while the workflow injects secrets
only at runtime. The Gateway and controlled-client each have a one-hour maximum
runtime. `spec.node_observation.mode: until-expiry` directs the default
automation to retain both nodes for observation through their absolute
`expires_at` after CI validation succeeds. `release_on_failure: true` permits
earlier release when validation fails. AWS Spot capacity interruption can still
terminate either node before expiry.

## Desktop acceptance stage

`spec.desktop_validation` declares an optional, operator-run macOS (`darwin`)
and Windows stage after the Linux check. It is disabled by default. To enable
a reviewed run, set `enabled` and supply one or two exact public IPv4 `/32`
source addresses in `ingress_cidrs`; never use a broad network or `0.0.0.0/0`.
Only Gateway TCP 443 is exposed to those sources. SSH and public WireGuard UDP
remain closed to desktops. Without an explicitly requested desktop window,
the deployment must not activate this optional ingress.

The window is at most 20 minutes and remains inside the existing one-hour
Spot lease. The public handoff contains only endpoint/instance metadata,
device/network identifiers, the Gateway public key and the disposable CA
certificate. Invitation tokens, VLESS credentials, owner identity and private
keys must never be included in that artifact or this repository.

Gateway v0.1.4 fixes formal Accounts device-session renewal; the release is
built by the Gateway project's own CI and downloaded by deployment. Desktop
acceptance requires independent local sync/runtime, exact-peer handshake,
private ping and exact-run HTTP checks. A Linux pass or a Gateway peer count
does not certify either desktop.
