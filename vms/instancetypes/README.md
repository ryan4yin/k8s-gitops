# Instance Types

We borrow the good ideas of two upstream conventions while keeping the names legible for
this homelab:

- [KubeVirt common-instancetypes](https://github.com/kubevirt/common-instancetypes) —
  grouping types into _series_ by vCPU:memory ratio and CPU placement, and treating
  **memory overcommit as an orthogonal axis** instead of baking it into a size.
- [GCP machine types](https://cloud.google.com/compute/docs/machine-resource) — the
  `<type>-<size>` shape, where the type names the ratio (their `standard` is 1:4,
  `highcpu` is 1:2, ...).

## Naming

    <type>-<vcpu>vcpu-<mem>gb[-<flag>...]

- `<type>` — the vCPU:memory ratio:

  | type       | ratio | note                                                         |
  | ---------- | ----- | ------------------------------------------------------------ |
  | `tiny`     | 1:1   | small / shared-ish                                           |
  | `highcpu`  | 1:2   |                                                              |
  | `standard` | 1:4   |                                                              |
  | `highmem`  | 1:8   | add when needed                                              |
  | `mixed`    | any   | deliberate non-standard ratio (e.g. a host-constrained size) |

- `<vcpu>vcpu-<mem>gb` — the exact size, readable straight from the name.
- flags (orthogonal):
  - `-dedicated` — `dedicatedCPUPlacement` + `isolateEmulatorThread` (pinned pCPUs)
  - `-ocNN` — overcommit memory by `NN`% (the pod requests `(100-NN)`% of guest RAM)

## Deliberate differences from upstream

1. **No hugepages** — the static 1G pool was replaced by THP, and hugepages cannot be
   overcommitted. None of our types use it, so the upstream hugepage series (`cx` / `m` /
   `n` / `rt`) are not shipped.
2. **No `nano/small/large/xlarge` ladder** — the size is spelled out instead.
3. **No per-guest-OS preferences** — we almost only run NixOS; a single `virtio`
   preference is used.

## Overcommit

`-ocNN` only changes the _scheduling reservation_, not what the guest actually uses — a
Linux guest fills its RAM with page cache regardless. Use it only where the real usage is
known to be low, and never on the control plane; `youko` (22 GiB) sizes its VMs for real
memory.
