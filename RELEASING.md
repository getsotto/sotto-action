# Releasing Sotto Setup

Action releases use immutable `v1.x.y` tags. The moving `v1` tag is a convenience pointer for
users who want compatible updates without changing their workflow.

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
release it tracks. All release runs share one concurrency queue, and both version ordering and git
ancestry are checked before the move, so overlapping or older dispatches cannot move `v1`
backwards.

Rerunning the same version is safe when its exact tag already points to the workflow commit. Never
move an exact release tag or move `v1` manually. If a published release needs a fix, merge the fix
and release a higher patch version.
