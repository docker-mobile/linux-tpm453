#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

owner="${1:-}"
repo="${2:-}"
shift $(( $# > 1 ? 2 : $# ))

if [[ -z "$owner" || -z "$repo" ]]; then
  printf 'usage: %s <github_owner> <github_repo> [variant...]\n' "${0##*/}" >&2
  exit 2
fi

variants=("$@")
if [[ ${#variants[@]} -eq 0 ]]; then
  variants=(lts stable mainline release rc edge)
fi

for variant in "${variants[@]}"; do
  pkgbuild="$repo_root/$variant/PKGBUILD"
  artifacts="$repo_root/$variant/artifacts"

  if [[ ! -f "$pkgbuild" ]]; then
    printf 'missing PKGBUILD: %s\n' "$pkgbuild" >&2
    exit 1
  fi
  if [[ ! -d "$artifacts" ]]; then
    printf 'missing artifacts dir: %s\n' "$artifacts" >&2
    exit 1
  fi

  pkgbase="$(bash -lc "source '$pkgbuild'; printf '%s' \"\$pkgbase\"")"
  pkgver="$(bash -lc "source '$pkgbuild'; printf '%s' \"\$pkgver\"")"
  pkgrel="$(bash -lc "source '$pkgbuild'; printf '%s' \"\$pkgrel\"")"
  tag="${pkgbase}-${pkgver}-${pkgrel}"

  shopt -s nullglob
  assets=(
    "$artifacts/${pkgbase}-${pkgver}-${pkgrel}-"*.pkg.tar.zst
    "$artifacts/${pkgbase}-${pkgver}-${pkgrel}-"*.pkg.tar.zst.sig
    "$artifacts/${pkgbase}-headers-${pkgver}-${pkgrel}-"*.pkg.tar.zst
    "$artifacts/${pkgbase}-headers-${pkgver}-${pkgrel}-"*.pkg.tar.zst.sig
  )
  shopt -u nullglob
  if [[ ${#assets[@]} -eq 0 ]]; then
    printf '[%s] no package assets found in %s\n' "$variant" "$artifacts" >&2
    exit 1
  fi

  if gh release view "$tag" --repo "${owner}/${repo}" >/dev/null 2>&1; then
    gh release upload "$tag" "${assets[@]}" --clobber --repo "${owner}/${repo}"
  else
    gh release create "$tag" "${assets[@]}" \
      --title "$tag" \
      --notes "Binary artifacts for ${pkgbase} ${pkgver}-${pkgrel}" \
      --repo "${owner}/${repo}"
  fi

  printf '%s -> https://github.com/%s/%s/releases/tag/%s\n' \
    "$variant" "$owner" "$repo" "$tag"
done
