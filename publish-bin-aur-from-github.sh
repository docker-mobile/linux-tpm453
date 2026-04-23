#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

github_owner="${1:-}"
github_repo="${2:-linux-tpm453}"

if [[ -z "$github_owner" ]]; then
  printf 'usage: %s <github_owner> [github_repo]\n' "${0##*/}" >&2
  exit 2
fi

export TPM453_RELEASE_BASE_URL="https://github.com/${github_owner}/${github_repo}/releases/download"

"$repo_root/make-bin-manifest-from-artifacts.sh"
"$repo_root/generate-bin-variants.sh"
"$repo_root/prepare-aur-repos.sh"
"$repo_root/publish-aur.sh" \
  lts-bin \
  stable-bin \
  mainline-bin \
  release-bin \
  rc-bin \
  edge-bin

