#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
image_name="${TPM453_DOCKER_IMAGE:-linux-tpm453-archbuild}"
variant="${1:-}"

if [[ -z "$variant" ]]; then
  printf 'usage: %s <variant> [build-on-server args...]\n' "${0##*/}" >&2
  exit 2
fi
shift || true

variant_dir="$repo_root/$variant"
if [[ ! -d "$variant_dir" ]]; then
  printf 'missing variant dir: %s\n' "$variant_dir" >&2
  exit 1
fi

mkdir -p "$repo_root/.docker-cache/pacman"

docker build -t "$image_name" -f "$repo_root/Dockerfile.archbuild" "$repo_root"

quoted_args=()
for arg in "$@"; do
  printf -v quoted '%q' "$arg"
  quoted_args+=("$quoted")
done

docker run --rm \
  -e TPM453_BUILD_JOBS="${TPM453_BUILD_JOBS:-$(nproc)}" \
  -v "$repo_root:/work" \
  -v "$repo_root/.docker-cache/pacman:/var/cache/pacman/pkg" \
  -w /work \
  "$image_name" \
  bash -lc "
    chown -R builder:builder /work
    su builder -c 'cd /work/$variant && ./build-on-server.sh ${quoted_args[*]}'
  "

