# linux-tpm453

Monorepo for Acer TMP453-M specific kernel package variants intended for AUR publishing.

Package matrix:
- `lts`: long-term support base, built from `linux-cachyos-lts`
- `stable`: current released stable base, built from `linux-cachyos`
- `mainline`: current released mainline base, built from `linux-cachyos`
- `release`: release-channel package, built from `linux-cachyos`
- `rc`: release-candidate base, built from `linux-cachyos-rc`
- `edge`: bleeding-edge preview base, built from a pinned `7.0/cachy` source snapshot

Notes:
- All variants share the same TPM453 hardware profile, local module list, and practical removable-media support.
- Source-package repos are pinned to exact release tarballs or exact source snapshots and are intended to carry full `sha256sums`.

Generate or refresh all variant directories:

```bash
./generate-variants.sh
```

Export standalone AUR-ready repos:

```bash
./prepare-aur-repos.sh
```

That creates `aur-out/linux-tpm453-*` directories, each with its own `PKGBUILD`, `.SRCINFO`, and supporting files.

Refresh all pinned source hashes and `.SRCINFO` files:

```bash
./refresh-sha256sums.sh
```

Generate `-bin` variants after server builds are uploaded and you have real asset URLs plus sha256 values:

```bash
cp bin-release-manifest.example.tsv bin-release-manifest.tsv
./generate-bin-variants.sh
```

Build on a remote Arch host (key-based SSH) and keep your laptop out of the loop:

```bash
./remote-build.sh 103.21.248.26.sslip.io stable --syncdeps
```

Build the full matrix sequentially on the remote host:

```bash
./remote-build-all.sh 103.21.248.26 --syncdeps
```

If the remote host is not Arch but has Docker, the repo will fall back to an Arch Linux
container automatically via `docker-build.sh`.

After you have `*/artifacts/*.pkg.tar.zst` locally (or after pulling them back from the server),
publish them to GitHub Releases:

```bash
./sign-artifacts.sh
./publish-github-releases.sh YOUR_GITHUB_USER linux-tpm453
```

Then generate a real manifest with complete sha256sums:

```bash
export TPM453_RELEASE_BASE_URL="https://github.com/YOUR_GITHUB_USER/linux-tpm453/releases/download"
./make-bin-manifest-from-artifacts.sh
./generate-bin-variants.sh
```

Or run the end-to-end `-bin` publication path after release assets are uploaded:

```bash
./publish-bin-aur-from-github.sh YOUR_GITHUB_USER linux-tpm453
```
