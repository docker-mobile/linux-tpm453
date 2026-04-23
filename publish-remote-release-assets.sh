#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

remote_host="${1:-}"
site_host="${2:-}"
shift $(( $# > 1 ? 2 : $# ))

remote_user="${TPM453_REMOTE_USER:-root}"
ssh_key="${TPM453_SSH_KEY:-/home/arian/.ssh/id_rsa}"
ssh_config_file="${TPM453_SSH_CONFIG_FILE:-/dev/null}"
remote_root="${TPM453_REMOTE_WEBROOT:-/srv/linux-tpm453/releases}"

if [[ -z "$remote_host" || -z "$site_host" ]]; then
  printf 'usage: %s <remote_host> <site_host> [variant...]\n' "${0##*/}" >&2
  exit 2
fi

variants=("$@")
if [[ ${#variants[@]} -eq 0 ]]; then
  variants=(lts stable mainline release rc edge)
fi

ssh_base=(
  ssh
  -F "$ssh_config_file"
  -i "$ssh_key"
  -o IdentitiesOnly=yes
  -o StrictHostKeyChecking=accept-new
  "${remote_user}@${remote_host}"
)

rsync_base=(
  rsync
  -e "ssh -F $ssh_config_file -i $ssh_key -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
  -a
)

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
  release_dir="${remote_root}/${pkgbase}-${pkgver}-${pkgrel}"

  "${ssh_base[@]}" "mkdir -p '$release_dir'"
  "${rsync_base[@]}" "$artifacts/" "${remote_user}@${remote_host}:${release_dir}/"

  printf '%s -> https://%s/releases/%s-%s-%s/\n' \
    "$variant" "$site_host" "$pkgbase" "$pkgver" "$pkgrel"
done

