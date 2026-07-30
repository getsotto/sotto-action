# Sotto Setup

Installs the [Sotto](https://github.com/getsotto/sotto) CLI - end-to-end encrypted secret sync
for developer teams - and puts it on `PATH`.

This action **only installs the binary**. It does not decrypt, export, or otherwise touch secret
values - that stays entirely under your workflow's control via `sotto run --` /
`sotto export`, using a machine token from `sotto token create` (see
[the CI docs](https://github.com/getsotto/sotto#readme)).

## Usage

```yaml
- uses: getsotto/sotto-action@v1
  with:
    sotto-version: v0.4.0

- run: sotto run -- npm test
  env:
    SOTTO_TOKEN: ${{ secrets.SOTTO_TOKEN }}
```

`sotto-version` is **required** - there is no implicit "latest", so a new Sotto release can never
silently change your CI's behaviour. Pin it the same way you'd pin any other tool version.

The action supports x86_64 and ARM64 Linux, x86_64 and ARM64 macOS, and x86_64 Windows.
Internally it downloads the archive for the selected release, verifies its checksum and Sigstore
signature, and checks that the installed binary reports the requested version. Signature
verification is mandatory: a missing or invalid bundle fails the job rather than falling back to
a checksum-only install. The verification identity is pinned to the selected tag of Sotto's
release workflow; see
[SECURITY.md](https://github.com/getsotto/sotto/blob/main/SECURITY.md) for the release model.

## Outputs

Give the step an `id` to use the resolved installation details in later steps:

```yaml
- uses: getsotto/sotto-action@v1
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

## Versioning

This action is tagged independently of the `sotto` CLI's own version (`v0.1.0`, `v0.2.0`, ...) -
`sotto-action@v1` and `sotto-version: v0.4.0` are two unrelated version numbers. See
[getsotto/sotto#67](https://github.com/getsotto/sotto/issues/67) for why.
