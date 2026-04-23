#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
variants=("$@")

if [[ ${#variants[@]} -eq 0 ]]; then
  variants=(lts stable mainline release rc edge)
fi

for variant in "${variants[@]}"; do
  dir="$repo_root/$variant"

  if [[ ! -d "$dir" ]]; then
    printf 'missing variant dir: %s\n' "$dir" >&2
    exit 1
  fi

  (
    cd "$dir"
    updpkgsums
    makepkg --printsrcinfo > .SRCINFO
  )
done

