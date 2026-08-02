# Sotto Setup

Installs the [Sotto](https://github.com/getsotto/sotto) CLI - end-to-end encrypted secret sync
for developer teams - and puts it on `PATH`.

This action **only installs the binary**. It does not decrypt, export, or otherwise touch secret
values. Secret use stays entirely under your workflow's control via `sotto run --` or
`sotto export`, using a machine token from `sotto token create` (see
[the CI docs](https://github.com/getsotto/sotto#readme)).

## Quick start

Install an exact Sotto CLI release in a job:

```yaml
name: CI

on:
  push:
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Install Sotto
        uses: getsotto/sotto-action@v1.1.0
        with:
          sotto-version: v0.4.0

      - name: Run tests with Sotto
        run: sotto run -- npm test
        env:
          SOTTO_TOKEN: ${{ secrets.SOTTO_TOKEN }}
```

`sotto-version` is **required**. There is no implicit `latest`, so a new Sotto release can never
silently change your CI's behaviour. Pin the action ref and the CLI release independently.

## Pinning the action

The action supports three ref styles:

- `@v1` follows the latest validated v1 action release.
- `@v1.1.0` selects the exact numbered action release.
- `@<40-character commit SHA>` provides the strongest workflow pinning and cannot move when a tag
  changes.

For the strongest supply-chain guarantee, use a full commit SHA for the action and an exact
`sotto-version` for the CLI:

```yaml
- uses: getsotto/sotto-action@<commit-sha-for-v1.1.0>
  with:
    sotto-version: v0.4.0
```

Resolve the commit behind an exact action release before copying it into a workflow:

```sh
git ls-remote https://github.com/getsotto/sotto-action.git 'refs/tags/v1.1.0^{}' | cut -f1
```

Do not use a short SHA. Keep the release tag in a comment beside the full SHA so Dependabot or a
reviewer can identify the pinned action version.

## Security model

The action is deliberately small and fails closed:

- It rejects missing, floating, partial, or prerelease CLI versions before downloading anything.
- It downloads the selected archive, its checksum manifest, and their Sigstore bundles.
- It verifies the bundles against Sotto's tagged release workflow, then verifies the archive checksum
  and the installed binary's reported version.
- It installs cosign from a pinned action commit, rather than trusting a floating installer ref.
- It never reads, decrypts, exports, or logs secret values. Only later workflow steps use
  `SOTTO_TOKEN`.

The action supports x86_64 and ARM64 Linux, x86_64 and ARM64 macOS, and x86_64 Windows. See
[SECURITY.md](https://github.com/getsotto/sotto/blob/main/SECURITY.md) for Sotto's release and
verification model.

## Outputs

Give the step an `id` to use the resolved installation details in later steps:

```yaml
- uses: getsotto/sotto-action@v1.1.0
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
      - uses: getsotto/sotto-action@v1.1.0
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
      - uses: getsotto/sotto-action@v1.1.0
        with:
          sotto-version: v0.4.0
      - name: Run a command with Sotto
        shell: pwsh
        run: sotto run -- powershell -NoProfile -Command "Write-Output 'Sotto is ready'"
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
      - uses: getsotto/sotto-action@v1.1.0
        with:
          sotto-version: ${{ inputs.sotto-version }}
      - run: sotto run -- npm test
        env:
          SOTTO_TOKEN: ${{ secrets.SOTTO_TOKEN }}
```

Call it from a workflow in the same repository:

```yaml
jobs:
  ci:
    uses: ./.github/workflows/sotto.yml
    with:
      sotto-version: v0.4.0
    secrets: inherit
```

## Versioning

This action is tagged independently of the `sotto` CLI's own version (`v0.1.0`, `v0.2.0`, ...).
`sotto-action@v1` and `sotto-version: v0.4.0` are two unrelated version numbers. See
[getsotto/sotto#67](https://github.com/getsotto/sotto/issues/67) for why.

Use `getsotto/sotto-action@v1` to follow the latest validated v1 action release, or pin an exact
action release such as `getsotto/sotto-action@v1.1.0` for an immutable workflow dependency. The
`v1` convenience tag moves only after the exact release has passed the full test matrix and been
published by the release workflow. `v1.1.0` is the first numbered v1 action release; the initial
bootstrap release used `v1` directly, so there is no `v1.0.0` tag. Manually pushing tags bypasses
the workflow and is not a supported release path. Maintainers should follow
[RELEASING.md](RELEASING.md).
