#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
remote_host="${1:-}"
shift || true

remote_user="${TPM453_REMOTE_USER:-root}"
ssh_key="${TPM453_SSH_KEY:-/home/arian/.ssh/id_rsa}"
ssh_config_file="${TPM453_SSH_CONFIG_FILE:-/dev/null}"
remote_workdir="${TPM453_REMOTE_WORKDIR:-/root/linux-tpm453}"

if [[ -z "$remote_host" ]]; then
  printf 'usage: %s <remote_host> [variant...]\n' "${0##*/}" >&2
  exit 2
fi

variants=("$@")
if [[ ${#variants[@]} -eq 0 ]]; then
  variants=(lts stable mainline release rc edge)
fi

for variant in "${variants[@]}"; do
  mkdir -p "$repo_root/$variant/artifacts"
  rsync \
    -e "ssh -F $ssh_config_file -i $ssh_key -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new" \
    -a \
    "${remote_user}@${remote_host}:${remote_workdir}/${variant}/artifacts/" \
    "$repo_root/$variant/artifacts/"
done

