#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

release_base_url="${TPM453_RELEASE_BASE_URL:-}"
manifest_out="${1:-$repo_root/bin-release-manifest.tsv}"

variants=(lts stable mainline release rc edge)

if [[ -z "$release_base_url" ]]; then
  cat >&2 <<'EOF'
missing TPM453_RELEASE_BASE_URL

Set it to the public HTTPS directory where you will host the built packages, e.g.:
  export TPM453_RELEASE_BASE_URL="https://example.com/linux-tpm453/releases"

Then re-run:
  ./make-bin-manifest-from-artifacts.sh
EOF
  exit 2
fi

tmp="$(mktemp)"
cleanup() { rm -f "$tmp"; }
trap cleanup EXIT

printf '# variant\tpkgver\tpkgrel\trelease_base_url\tkernel_asset\tkernel_sha256\theaders_asset\theaders_sha256\n' >"$tmp"

for variant in "${variants[@]}"; do
  dir="$repo_root/$variant"
  pkgbuild="$dir/PKGBUILD"
  artifacts="$dir/artifacts"

  if [[ ! -f "$pkgbuild" ]]; then
    printf 'missing PKGBUILD: %s\n' "$pkgbuild" >&2
    exit 1
  fi
  if [[ ! -d "$artifacts" ]]; then
    printf 'missing artifacts dir (build first): %s\n' "$artifacts" >&2
    exit 1
  fi

  pkgbase="$(bash -lc "source '$pkgbuild'; printf '%s' \"\$pkgbase\"")"
  pkgver="$(bash -lc "source '$pkgbuild'; printf '%s' \"\$pkgver\"")"
  pkgrel="$(bash -lc "source '$pkgbuild'; printf '%s' \"\$pkgrel\"")"

  kernel_pkg=( "$artifacts/${pkgbase}-${pkgver}-${pkgrel}-"*.pkg.tar.zst )
  headers_pkg=( "$artifacts/${pkgbase}-headers-${pkgver}-${pkgrel}-"*.pkg.tar.zst )

  if [[ ! -f "${kernel_pkg[0]:-}" ]]; then
    printf '[%s] missing kernel package in %s\n' "$variant" "$artifacts" >&2
    exit 1
  fi
  if [[ ! -f "${headers_pkg[0]:-}" ]]; then
    printf '[%s] missing headers package in %s\n' "$variant" "$artifacts" >&2
    exit 1
  fi

  kernel_asset="$(basename "${kernel_pkg[0]}")"
  headers_asset="$(basename "${headers_pkg[0]}")"
  kernel_sha256="$(sha256sum "${kernel_pkg[0]}" | awk '{print $1}')"
  headers_sha256="$(sha256sum "${headers_pkg[0]}" | awk '{print $1}')"

  printf '%s\t%s\t%s\t%s/%s-%s-%s\t%s\t%s\t%s\t%s\n' \
    "$variant" \
    "$pkgver" \
    "$pkgrel" \
    "$release_base_url" \
    "$pkgbase" \
    "$pkgver" \
    "$pkgrel" \
    "$kernel_asset" \
    "$kernel_sha256" \
    "$headers_asset" \
    "$headers_sha256" \
    >>"$tmp"
done

mv -f "$tmp" "$manifest_out"
printf 'wrote %s\n' "$manifest_out"
