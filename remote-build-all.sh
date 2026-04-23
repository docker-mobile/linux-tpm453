#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
remote_host="${1:-}"
shift || true

if [[ -z "$remote_host" ]]; then
  printf 'usage: %s <remote_host> [build-on-server args...]\n' "${0##*/}" >&2
  exit 2
fi

variants=(lts stable mainline release rc edge)

for variant in "${variants[@]}"; do
  printf '\n==> remote build: %s\n' "$variant"
  "$repo_root/remote-build.sh" "$remote_host" "$variant" "$@"
done

