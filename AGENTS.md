# Repository Guidelines

## Project Structure & Module Organization

This is a FluxCD GitOps repository for personal Kubernetes clusters. Cluster entrypoints
live in `clusters/<cluster-name>/`, where Flux `Kustomization` resources wire together
apps, infrastructure, and VM manifests. Reusable application manifests are under
`apps/base/`, with environment-specific overlays under `apps/overlays/`. Infrastructure
controllers and configuration live in `infra/controllers/`, `infra/pre-controllers/`,
`infra/configs/`, and `infra/namespaces/`. KubeVirt VM manifests and instance preferences
are in `vms/`. Utility scripts are in `scripts/` and root-level helper files such as
`Justfile` and `gen_kustomization.nu`.

## Build, Test, and Development Commands

- `just --list`: show available repository tasks.
- `just genks`: regenerate kustomization files via `gen_kustomization.nu`.
- `./scripts/validate.sh`: validate YAML, Flux resources, and every kustomize overlay with
  `yq`, `kustomize`, and `kubeconform`.
- `kustomize build <path> --load-restrictor=LoadRestrictionsNone`: inspect a single
  overlay before committing.

Prefer these local validation commands over cluster mutations. Do not run `kubectl apply`,
`helm upgrade`, or other remote-changing commands for this repo unless explicitly requested.

## Coding Style & Naming Conventions

Use YAML for Kubernetes resources and keep manifests small, explicit, and reviewable. Use
lowercase directory names with hyphens, matching existing patterns such as
`infra/controllers/base/cert-manager` and `clusters/k3s-prod-1`. Name resources
descriptively and consistently with their component, for example `helm-release.yaml`,
`helm-repo.yaml`, and `kustomization.yaml`. Markdown and general formatting follow
`.prettierrc.yaml`: no semicolons, double quotes, 90-character print width, and wrapped
prose.

## Testing Guidelines

There is no unit test suite; validation is manifest-focused. Run `./scripts/validate.sh`
before opening a PR or after changing any YAML. For focused edits, first run
`kustomize build` on the changed overlay, then run the full validation script. The
validation script skips Kubernetes `Secret` schema checks because SOPS metadata is present.

## Commit & Pull Request Guidelines

Follow the existing conventional commit style: `feat:`, `fix:`, `docs:`, or `chore:`,
optionally with a short component scope in the subject, such as
`chore: victoria-metrics - disable default vmrules`. PRs should describe the affected
cluster or component, summarize manifest changes, mention validation results, and call out
any operational risk, ordering requirement, or breaking change.

## Security & Configuration Tips

Never commit plaintext secrets. This repository uses SOPS and age; keep encrypted values in
place and use placeholders or documented secret references for examples. Be careful with
resources that have finalizers, CRDs, admission webhooks, PVs, or PVCs. Prefer Flux-driven
reconciliation and staged validation over manual cluster changes.
