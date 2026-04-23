#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
signing_key="${AUR_GPG_KEY:-BC6B09171C9D8831B51473EC64FB6F539CEC932A}"

variants=("$@")
if [[ ${#variants[@]} -eq 0 ]]; then
  variants=(lts stable mainline release rc edge)
fi

for variant in "${variants[@]}"; do
  artifacts="$repo_root/$variant/artifacts"

  if [[ ! -d "$artifacts" ]]; then
    printf 'missing artifacts dir: %s\n' "$artifacts" >&2
    exit 1
  fi

  shopt -s nullglob
  packages=( "$artifacts"/*.pkg.tar.zst )
  shopt -u nullglob

  if [[ ${#packages[@]} -eq 0 ]]; then
    printf '[%s] no package files found in %s\n' "$variant" "$artifacts" >&2
    exit 1
  fi

  for pkg in "${packages[@]}"; do
    gpg --batch --yes --local-user "$signing_key" --detach-sign --output "${pkg}.sig" "$pkg"
  done

  printf '[%s] signed %d package files\n' "$variant" "${#packages[@]}"
done

