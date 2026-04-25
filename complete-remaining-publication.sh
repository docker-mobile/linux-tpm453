#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
remote_host="${1:-103.21.248.26}"
github_owner="${2:-docker-mobile}"
github_repo="${3:-linux-tpm453}"
remote_user="${TPM453_REMOTE_USER:-root}"
ssh_key="${TPM453_SSH_KEY:-/home/arian/.ssh/id_rsa}"
ssh_config_file="${TPM453_SSH_CONFIG_FILE:-/dev/null}"
remote_workdir="${TPM453_REMOTE_WORKDIR:-/root/linux-tpm453}"
queue_script="${remote_workdir}/run-build-remaining.sh"
log_path="${remote_workdir}/build-remaining.log"

variants=(mainline release rc edge)

ssh_base=(
  ssh
  -F "$ssh_config_file"
  -i "$ssh_key"
  -o IdentitiesOnly=yes
  -o StrictHostKeyChecking=accept-new
  "${remote_user}@${remote_host}"
)

printf '[wait] watching remote queue on %s\n' "$remote_host"
while "${ssh_base[@]}" "pgrep -f '$queue_script' >/dev/null"; do
  "${ssh_base[@]}" "tail -n 3 '$log_path' 2>/dev/null || true"
  sleep 20
done

printf '[sync] pulling remote artifacts\n'
"$repo_root/sync-remote-artifacts.sh" "$remote_host" "${variants[@]}"

printf '[sign] signing remaining variants\n'
"$repo_root/sign-artifacts.sh" "${variants[@]}"

printf '[release] publishing remaining GitHub releases\n'
"$repo_root/publish-github-releases.sh" "$github_owner" "$github_repo" "${variants[@]}"

printf '[aur] publishing -bin AUR packages\n'
"$repo_root/publish-bin-aur-from-github.sh" "$github_owner" "$github_repo"

printf '[done] remaining publication complete\n'
