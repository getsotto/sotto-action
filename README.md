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
    sotto-version: v0.3.0

- run: sotto run -- npm test
  env:
    SOTTO_TOKEN: ${{ secrets.SOTTO_TOKEN }}
```

`sotto-version` is **required** - there is no implicit "latest", so a new Sotto release can never
silently change your CI's behaviour. Pin it the same way you'd pin any other tool version.

Works across `ubuntu-latest`, `macos-latest`, and `windows-latest` runners: internally this
reuses [`install.sh`](https://github.com/getsotto/sotto/blob/main/install.sh) (Linux/macOS) and
[`install.ps1`](https://github.com/getsotto/sotto/blob/main/install.ps1) (Windows) - the same
checksum- and Sigstore-verified installers documented in
[SECURITY.md](https://github.com/getsotto/sotto/blob/main/SECURITY.md), not a separate
reimplementation.

## Versioning

This action is tagged independently of the `sotto` CLI's own version (`v0.1.0`, `v0.2.0`, ...) -
`sotto-action@v1` and `sotto-version: v0.3.0` are two unrelated version numbers. See
[getsotto/sotto#67](https://github.com/getsotto/sotto/issues/67) for why.
