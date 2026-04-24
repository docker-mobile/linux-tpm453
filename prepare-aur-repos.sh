#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
out_root="$repo_root/aur-out"
mapfile -t variants < <(
    find "$repo_root" -mindepth 1 -maxdepth 1 -type d \
        ! -name aur-out \
        ! -name .git \
        -exec test -f '{}/PKGBUILD' ';' -print \
        | xargs -r -n1 basename \
        | sort
)

mkdir -p "$out_root"

for variant in "${variants[@]}"; do
    src="$repo_root/$variant"
    pkgname="linux-tpm453-$variant"
    dst="$out_root/$pkgname"
    files=(
        PKGBUILD
        .SRCINFO
        README.md
        HARDWARE.md
        .gitignore
        build-on-server.sh
        config
        lsmod-tpm453.txt
    )

    mkdir -p "$dst"

    for file in "${files[@]}"; do
        [[ -f "$src/$file" ]] || continue
        cp "$src/$file" "$dst/$file"
    done

    for patch in "$src"/*.patch; do
        [[ -f "$patch" ]] || continue
        cp "$patch" "$dst/$(basename "$patch")"
    done

    if [[ -f "$dst/build-on-server.sh" ]]; then
        chmod +x "$dst/build-on-server.sh"
    fi

    if [[ ! -d "$dst/.git" ]]; then
        git init "$dst" >/dev/null
        git -C "$dst" branch -m master >/dev/null 2>&1 || true
    fi
done
