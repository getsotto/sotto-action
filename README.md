# Sotto Setup

Installs the [Sotto](https://github.com/getsotto/sotto) CLI - end-to-end encrypted secret sync
for developer teams - and puts it on `PATH`.

> [!WARNING]
> Sotto is pre-1.0 and has not had a third-party cryptographic audit. It works end to end, but
> should not yet be trusted with critical production secrets. See
> [SECURITY.md](https://github.com/getsotto/sotto/blob/main/SECURITY.md).

This action **only installs the binary**. It does not decrypt, export, or otherwise touch secret
values. Secret use stays entirely under your workflow's control via `sotto run --` or
`sotto export`, using a machine token from `sotto token create` (see
[the Sotto README](https://github.com/getsotto/sotto#github-actions)).

## Quick start

Install the merged v1.1 implementation by its full commit SHA:

```yaml
name: CI

on:
  push:
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0
      - name: Install Sotto
        uses: getsotto/sotto-action@543d1af56ac81d1f1511d88c3d269106e8513a28 # merged v1.1 implementation
        with:
          sotto-version: v0.4.0

      - name: Run tests with Sotto
        run: sotto run -- npm test
        env:
          SOTTO_SERVER: ${{ vars.SOTTO_SERVER }}
          SOTTO_TOKEN: ${{ secrets.SOTTO_TOKEN }}
```

Set the repository variable `SOTTO_SERVER` for a self-hosted Sotto server. Leave it unset to use
the hosted instance. `sotto-version` is **required** and must be an exact release, so a new Sotto
release can never silently change your CI's behaviour.

## Inputs and outputs

### Inputs

| Input | Required | Description |
| --- | --- | --- |
| `sotto-version` | Yes | Exact CLI release in `vX.Y.Z` form. Floating, partial, and prerelease values are rejected. |

### Outputs

The inputs and outputs below describe the merged v1.1 implementation used in these examples. A
mutable ref such as `@v1` may point to an older action until the release workflow moves it.

Give the step an `id` to use the resolved installation details in later steps:

```yaml
- uses: getsotto/sotto-action@543d1af56ac81d1f1511d88c3d269106e8513a28 # merged v1.1 implementation
  id: sotto
  with:
    sotto-version: v0.4.0

- run: echo "installed ${{ steps.sotto.outputs.version }} for ${{ steps.sotto.outputs.target }}"
```

| Output | Description | macOS example | Windows example |
| --- | --- | --- | --- |
| `version` | Selected release tag | `v0.4.0` | `v0.4.0` |
| `target` | Resolved release target | `aarch64-apple-darwin` | `x86_64-pc-windows-msvc` |
| `binary-path` | Absolute installed binary path | `/Users/runner/work/_temp/sotto-bin/sotto` | `D:\a\_temp\sotto-bin\sotto.exe` |

## Pinning the action

The action ref and the CLI release are independent. The available ref styles are:

- `@v1` is a mutable major tag. Check its target before use because a major tag can lag the
  implementation documented here.
- `@vX.Y.Z` selects an exact numbered action release once that tag has been published.
- `@<40-character commit SHA>` provides the strongest workflow pinning and cannot move when a tag
  changes.

The examples use the full SHA `543d1af56ac81d1f1511d88c3d269106e8513a28`, which is the merged v1.1
implementation. For the strongest supply-chain guarantee, use a reviewed full SHA for the action
and an exact `sotto-version` for the CLI:

```yaml
- uses: getsotto/sotto-action@543d1af56ac81d1f1511d88c3d269106e8513a28 # merged v1.1 implementation
  with:
    sotto-version: v0.4.0
```

To inspect the current action commit before pinning, resolve it explicitly and fail if GitHub
returns no ref:

```sh
action_sha="$(git ls-remote https://github.com/getsotto/sotto-action.git refs/heads/main | awk 'NF { print $1; exit }')"
test -n "$action_sha" || { echo "error: could not resolve the action commit" >&2; exit 1; }
printf '%s\n' "$action_sha"
```

Review the resolved commit before copying it into a workflow. Do not use a short SHA.

## Security model

The merged v1.1 implementation is deliberately small and fails closed:

- It rejects missing, floating, partial, or prerelease CLI versions before downloading anything.
- It downloads the selected archive, its checksum manifest, and their Sigstore bundles.
- Signature verification is mandatory. A missing or invalid bundle fails the job rather than falling
  back to a checksum-only install.
- It verifies the bundles against Sotto's tagged release workflow, then verifies the archive checksum
  and the installed binary's reported version.
- It installs cosign from a pinned action commit, rather than trusting a floating installer ref.
- It never reads, decrypts, exports, or logs secret values. Only later workflow steps use
  `SOTTO_SERVER` and `SOTTO_TOKEN`.

The action supports x86_64 and ARM64 Linux, x86_64 and ARM64 macOS, and x86_64 Windows. See
[SECURITY.md](https://github.com/getsotto/sotto/blob/main/SECURITY.md) for Sotto's release and
verification model.

## Examples

### Linux, macOS, and Windows matrix

```yaml
name: Sotto smoke test

on: [push, pull_request]

jobs:
  smoke:
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0
      - uses: getsotto/sotto-action@543d1af56ac81d1f1511d88c3d269106e8513a28 # merged v1.1 implementation
        with:
          sotto-version: v0.4.0
      - run: sotto --version
```

### Windows PowerShell

```yaml
jobs:
  windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0
      - uses: getsotto/sotto-action@543d1af56ac81d1f1511d88c3d269106e8513a28 # merged v1.1 implementation
        with:
          sotto-version: v0.4.0
      - name: Run a command with Sotto
        shell: pwsh
        run: sotto run -- powershell -NoProfile -Command "Write-Output 'Sotto is ready'"
        env:
          SOTTO_SERVER: ${{ vars.SOTTO_SERVER }}
          SOTTO_TOKEN: ${{ secrets.SOTTO_TOKEN }}
```

### Reusable workflow

Define the installation once and call it from other workflows:

```yaml
# .github/workflows/sotto.yml
name: Sotto

on:
  workflow_call:
    inputs:
      sotto-version:
        required: true
        type: string
    secrets:
      SOTTO_TOKEN:
        required: true

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0
      - uses: getsotto/sotto-action@543d1af56ac81d1f1511d88c3d269106e8513a28 # merged v1.1 implementation
        with:
          sotto-version: ${{ inputs.sotto-version }}
      - run: sotto run -- npm test
        env:
          SOTTO_SERVER: ${{ vars.SOTTO_SERVER }}
          SOTTO_TOKEN: ${{ secrets.SOTTO_TOKEN }}
```

Call it from a workflow in the same repository and pass only the secret the callee declares:

```yaml
jobs:
  ci:
    uses: ./.github/workflows/sotto.yml
    with:
      sotto-version: v0.4.0
    secrets:
      SOTTO_TOKEN: ${{ secrets.SOTTO_TOKEN }}
```

## Versioning

This action is tagged independently of the `sotto` CLI's own version (`v0.1.0`, `v0.2.0`, ...).
The action ref and `sotto-version: v0.4.0` are two unrelated version numbers. The moving major
tag is updated only after the exact action release has passed the full test matrix and been
published by the release workflow. Manually pushing tags bypasses the workflow and is not a
supported release path. Maintainers should follow [RELEASING.md](RELEASING.md).

## Licence

Licensed under the [Apache License, Version 2.0](LICENSE).
