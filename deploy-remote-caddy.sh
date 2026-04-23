#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

remote_host="${1:-}"
site_host="${2:-}"
remote_user="${TPM453_REMOTE_USER:-root}"
ssh_key="${TPM453_SSH_KEY:-/home/arian/.ssh/id_rsa}"
ssh_config_file="${TPM453_SSH_CONFIG_FILE:-/dev/null}"
remote_root="${TPM453_REMOTE_WEBROOT:-/srv/linux-tpm453}"

if [[ -z "$remote_host" || -z "$site_host" ]]; then
  printf 'usage: %s <remote_host> <site_host>\n' "${0##*/}" >&2
  printf 'example: %s 103.21.248.26 103.21.248.26.sslip.io\n' "${0##*/}" >&2
  exit 2
fi

ssh_base=(
  ssh
  -F "$ssh_config_file"
  -i "$ssh_key"
  -o IdentitiesOnly=yes
  -o StrictHostKeyChecking=accept-new
  "${remote_user}@${remote_host}"
)

read -r -d '' caddyfile <<EOF || true
${site_host} {
    root * ${remote_root}
    file_server browse
}
EOF

"${ssh_base[@]}" "mkdir -p '${remote_root}/releases'"
"${ssh_base[@]}" "cat > '${remote_root}/Caddyfile' <<'EOF'
${caddyfile}
EOF"

"${ssh_base[@]}" "docker rm -f linux-tpm453-caddy >/dev/null 2>&1 || true"
"${ssh_base[@]}" "docker run -d \
  --name linux-tpm453-caddy \
  --restart unless-stopped \
  -p 80:80 \
  -p 443:443 \
  -v '${remote_root}:/srv' \
  -v '${remote_root}/Caddyfile:/etc/caddy/Caddyfile:ro' \
  -v linux-tpm453-caddy-data:/data \
  -v linux-tpm453-caddy-config:/config \
  caddy:2 >/dev/null"

printf 'caddy deployed on https://%s/\n' "$site_host"

