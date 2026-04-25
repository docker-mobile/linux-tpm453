#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
manifest="${1:-$repo_root/bin-release-manifest.tsv}"

if [[ ! -f "$manifest" ]]; then
  printf 'missing manifest: %s\n' "$manifest" >&2
  printf 'copy %s and fill the real release URLs and sha256 values first\n' \
    "$repo_root/bin-release-manifest.example.tsv" >&2
  exit 1
fi

write_pkgbuild() {
  local target="$1"
  local variant="$2"
  local pkgver="$3"
  local pkgrel="$4"
  local release_base_url="$5"
  local kernel_asset="$6"
  local kernel_sha256="$7"
  local headers_asset="$8"
  local headers_sha256="$9"
  local source_pkg="linux-tpm453-${variant}"
  local bin_pkg="${source_pkg}-bin"

  cat > "$target/PKGBUILD" <<EOF
pkgbase="${bin_pkg}"
pkgname=("${bin_pkg}" "${bin_pkg}-headers")
pkgver=${pkgver}
pkgrel=${pkgrel}
pkgdesc="Prebuilt TPM453 ${variant} kernel package"
arch=('x86_64')
license=('GPL-2.0-only')
options=('!strip' '!debug')
depends=('coreutils' 'kmod' 'initramfs')
optdepends=('wireless-regdb: to set the correct wireless channels of your country'
            'linux-firmware: firmware images needed for some devices')
makedepends=('libarchive' 'zstd')
_release_base_url='${release_base_url}'
_kernel_asset='${kernel_asset}'
_headers_asset='${headers_asset}'
url="\${_release_base_url%/releases/download/*}"
source=(
  "\${_kernel_asset}::\${_release_base_url}/\${_kernel_asset}"
  "\${_headers_asset}::\${_release_base_url}/\${_headers_asset}"
)
noextract=(
  "\${_kernel_asset}"
  "\${_headers_asset}"
)
sha256sums=(
  '${kernel_sha256}'
  '${headers_sha256}'
)

_extract_pkg_payload() {
  local archive="\$1"
  local dst="\$2"

  install -dm755 "\$dst"
  bsdtar -xf "\$archive" -C "\$dst" \\
    --exclude .BUILDINFO \\
    --exclude .MTREE \\
    --exclude .PKGINFO \\
    --exclude .INSTALL
}

package_${bin_pkg}() {
  pkgdesc="Prebuilt TPM453 ${variant} kernel and modules"
  provides=(
    "${source_pkg}=\${pkgver}-\${pkgrel}"
    'VIRTUALBOX-GUEST-MODULES'
    'WIREGUARD-MODULE'
    'KSMBD-MODULE'
    'V4L2LOOPBACK-MODULE'
    'NTSYNC-MODULE'
    'VHBA-MODULE'
    'ADIOS-MODULE'
  )
  conflicts=("${source_pkg}")

  _extract_pkg_payload "\$srcdir/\${_kernel_asset}" "\$pkgdir"
}

package_${bin_pkg}-headers() {
  pkgdesc="Prebuilt headers for the TPM453 ${variant} kernel"
  depends=("${bin_pkg}=\${pkgver}-\${pkgrel}")
  provides=("${source_pkg}-headers=\${pkgver}-\${pkgrel}" 'LINUX-HEADERS')
  conflicts=("${source_pkg}-headers")

  _extract_pkg_payload "\$srcdir/\${_headers_asset}" "\$pkgdir"
}
EOF
}

while IFS=$'\t' read -r variant pkgver pkgrel release_base_url kernel_asset kernel_sha256 headers_asset headers_sha256; do
  [[ -z "${variant:-}" || "${variant:0:1}" == "#" ]] && continue

  target="$repo_root/${variant}-bin"
  mkdir -p "$target"

  write_pkgbuild "$target" "$variant" "$pkgver" "$pkgrel" \
    "$release_base_url" "$kernel_asset" "$kernel_sha256" "$headers_asset" "$headers_sha256"

  if [[ -f "$repo_root/$variant/HARDWARE.md" ]]; then
    cp "$repo_root/$variant/HARDWARE.md" "$target/HARDWARE.md"
  fi

  cat > "$target/README.md" <<EOF
# linux-tpm453-${variant}-bin

Binary TPM453 package variant for AUR publication.

This repo expects prebuilt artifacts hosted at:
\`${release_base_url}\`

Kernel asset:
\`${kernel_asset}\`

Headers asset:
\`${headers_asset}\`
EOF

  cat > "$target/.gitignore" <<'EOF'
pkg/
src/
*.pkg.tar.zst
*.pkg.tar.zst.sig
EOF

  (
    cd "$target"
    makepkg --printsrcinfo > .SRCINFO
  )
done < "$manifest"
