#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
aur_root="$repo_root/aur-out"
ssh_key="${AUR_SSH_KEY:-/home/arian/.ssh/id_rsa}"
ssh_config_file="${AUR_SSH_CONFIG_FILE:-/dev/null}"
git_user_name="${AUR_GIT_NAME:-ArianDEXaPY}"
git_user_email="${AUR_GIT_EMAIL:-arianabb.me@gmail.com}"
git_signing_key="${AUR_GPG_KEY:-BC6B09171C9D8831B51473EC64FB6F539CEC932A}"

if [[ $# -lt 1 ]]; then
  printf 'usage: %s <variant>...\n' "${0##*/}" >&2
  exit 2
fi

for variant in "$@"; do
  repo="$aur_root/linux-tpm453-$variant"
  pkgname="linux-tpm453-$variant"
  commit_msg="Initial TPM453 ${variant} package"
  staged_files=()

  if [[ ! -d "$repo" ]]; then
    printf 'missing repo: %s\n' "$repo" >&2
    exit 1
  fi

  git -C "$repo" config user.name "$git_user_name"
  git -C "$repo" config user.email "$git_user_email"
  git -C "$repo" config user.signingkey "$git_signing_key"
  git -C "$repo" config commit.gpgsign true
  git -C "$repo" config tag.gpgsign true
  git -C "$repo" config gpg.program gpg

  if git -C "$repo" rev-parse --verify HEAD >/dev/null 2>&1; then
    commit_msg="Refresh TPM453 ${variant} package"
  fi

  if git -C "$repo" remote get-url origin >/dev/null 2>&1; then
    git -C "$repo" remote set-url origin "ssh://aur@aur.archlinux.org/${pkgname}.git"
  else
    git -C "$repo" remote add origin "ssh://aur@aur.archlinux.org/${pkgname}.git"
  fi

  for file in PKGBUILD .SRCINFO README.md HARDWARE.md build-on-server.sh config lsmod-tpm453.txt .gitignore; do
    [[ -e "$repo/$file" ]] && staged_files+=("$file")
  done

  git -C "$repo" add "${staged_files[@]}"

  if git -C "$repo" diff --cached --quiet; then
    printf '[%s] nothing new to commit\n' "$pkgname"
  else
    git -C "$repo" commit -S -m "$commit_msg"
  fi

  GIT_SSH_COMMAND="ssh -F ${ssh_config_file} -i ${ssh_key} -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new" \
    git -C "$repo" push -u origin master
done
