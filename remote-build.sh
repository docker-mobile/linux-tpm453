#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

remote_host="${TPM453_REMOTE_HOST:-}"
remote_user="${TPM453_REMOTE_USER:-root}"
ssh_key="${TPM453_SSH_KEY:-/home/arian/.ssh/id_rsa}"
ssh_config_file="${TPM453_SSH_CONFIG_FILE:-/dev/null}"
remote_workdir="${TPM453_REMOTE_WORKDIR:-/root/linux-tpm453}"

if [[ $# -lt 2 ]]; then
  printf 'usage: %s <remote_host> <variant> [--syncdeps]\n' "${0##*/}" >&2
  printf 'example: %s 103.21.248.26.sslip.io stable --syncdeps\n' "${0##*/}" >&2
  exit 2
fi

remote_host="$1"
variant="$2"
shift 2

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
  --delete
  --exclude .git
  --exclude aur-out
  --exclude '*/artifacts'
  --exclude '*/cache'
  --exclude '*/pkg'
  --exclude '*/src'
  --exclude '*.pkg.tar.*'
  --exclude '*.tar.gz'
  --exclude '*.sig'
)

printf '[remote] syncing repo to %s:%s\n' "$remote_host" "$remote_workdir"
"${ssh_base[@]}" "mkdir -p '$remote_workdir'"
"${rsync_base[@]}" "$repo_root/" "${remote_user}@${remote_host}:${remote_workdir}/"

remote_args=()
for arg in "$@"; do
  printf -v quoted '%q' "$arg"
  remote_args+=("$quoted")
done

printf '[remote] building variant: %s\n' "$variant"
"${ssh_base[@]}" "
  set -e
  cd '$remote_workdir'
  if command -v makepkg >/dev/null 2>&1; then
    cd '$remote_workdir/$variant'
    ./build-on-server.sh ${remote_args[*]}
  elif command -v docker >/dev/null 2>&1; then
    ./docker-build.sh '$variant' ${remote_args[*]}
  else
    echo 'neither makepkg nor docker is available on the remote host'
    exit 1
  fi
"

printf '[remote] syncing artifacts back from %s\n' "$remote_host"
mkdir -p "$repo_root/$variant/artifacts"
"${rsync_base[@]}" "${remote_user}@${remote_host}:${remote_workdir}/${variant}/artifacts/" "$repo_root/$variant/artifacts/"

printf '[remote] done. artifacts are on the server under:\n'
printf '  %s/%s/artifacts\n' "$remote_workdir" "$variant"
printf '[remote] local copy updated at:\n'
printf '  %s/%s/artifacts\n' "$repo_root" "$variant"
