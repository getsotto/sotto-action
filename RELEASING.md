# Releasing Sotto Setup

Action releases use exact `v1.x.y` tags that the release workflow treats as immutable. The moving
`v1` tag is a convenience pointer for users who want compatible updates without changing their
workflow. The initial bootstrap release used `v1` directly; `v1.1.0` is the first numbered release
and there is no `v1.0.0` tag.

## Cutting a release

1. Merge the release changes to `main` and wait for its test workflow to pass.
2. Run the `release` workflow from `main` with the exact action version, for example `v1.1.0`.
3. Wait for its reused test matrix and release job to finish.
4. Confirm both tags resolve to the validated commit and the exact release is latest:

   ```sh
   git fetch --tags origin
   test "$(git rev-parse v1^{commit})" = "$(git rev-parse v1.1.0^{commit})"
   gh release view v1.1.0
   ```

The workflow creates the exact annotated tag and GitHub Release first. It verifies that release
exists before force-moving `v1`, then updates the existing `v1` release notes to name the exact
release it tracks. All release runs share one concurrency queue. GitHub keeps one active and one
pending run, so a newer pending dispatch can replace an older pending dispatch; version ordering
and git ancestry are checked before any run moves `v1`.

Rerunning the same version is safe when its exact tag already points to the workflow commit. Never
move an exact release tag or move `v1` manually. If a published release needs a fix, merge the fix
and release a higher patch version.
