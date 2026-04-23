#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
upstream_root="/home/arian/linux-cachyos-src"
lsmod_source="/home/arian/kernel-tmp453-lts/lsmod-tmp453.txt"

variants=(
  "lts|linux-cachyos-lts|LTS|linux-tpm453-lts|Hardware-specific CachyOS LTS kernel for Acer TMP453-M class hardware|tag|cachyos-6.18.24-1|6.18.24|6.18.24|Signed CachyOS LTS release tag cachyos-6.18.24-1|6.18|24|1|1||bore"
  "stable|linux-cachyos|Stable|linux-tpm453-stable|Hardware-specific CachyOS stable kernel for Acer TMP453-M class hardware|commit|2a5a214aa4d81291700b74b09d882b1a09a9a257|7.0.1.r20260421.g2a5a214aa4d|7.0.1|7.0/fixes snapshot at 2a5a214aa4d|7.0|1|3|1||bore"
  "mainline|linux-cachyos|Mainline|linux-tpm453-mainline|Hardware-specific CachyOS mainline kernel for Acer TMP453-M class hardware|commit|a3418d70e282c6275d5eeccf0f019051666fa856|7.0.1.r20260423.ga3418d70e28|7.0.1|7.0/base snapshot at a3418d70e28 with EEVDF|7.0|1|3|1||eevdf"
  "release|linux-cachyos|Release|linux-tpm453-release|Hardware-specific CachyOS release-channel kernel for Acer TMP453-M class hardware|tag|cachyos-7.0.1-3|7.0.1|7.0.1|Signed CachyOS release tag cachyos-7.0.1-3|7.0|1|3|1||bore"
  "rc|linux-cachyos-rc|RC|linux-tpm453-rc|Hardware-specific CachyOS release-candidate kernel for Acer TMP453-M class hardware|tag|cachyos-7.0-rc7-3|7.0.rc7|7.0-rc7|Signed CachyOS RC release tag cachyos-7.0-rc7-3|7.0|0|3|2|rc7|bore"
  "edge|linux-cachyos-rc|Edge|linux-tpm453-edge|Hardware-specific CachyOS edge-preview kernel for Acer TMP453-M class hardware|commit|7e6c35d1ea6da4fa14a9db2e71d5835ca9636f19|7.0.1.r20260423.g7e6c35d1ea6|7.0.1|7.0/cachy snapshot at 7e6c35d1ea6 with EEVDF|7.0|1|3|1||eevdf"
)

profile_snippet="$(mktemp)"
cat > "$profile_snippet" <<'EOF'
_apply_tpm453_profile() {
    echo "Applying TPM453 hardware profile..."
    scripts/config \
        -d GENERIC_CPU \
        -d MZEN4 \
        -e X86_NATIVE_CPU \
        -e CACHY \
        -e SCHED_BORE \
        -e LTO_CLANG_THIN \
        -d LTO_NONE \
        -d LTO_CLANG_FULL \
        -d LTO_CLANG_THIN_DIST \
        -d AUTOFDO_CLANG \
        -d AUTOFDO_PROFILE_ACCURATE \
        -d PROPELLER_CLANG \
        -d PREEMPT_DYNAMIC \
        -e PREEMPT \
        -d PREEMPT_VOLUNTARY \
        -d PREEMPT_LAZY \
        -d PREEMPT_NONE \
        -d HZ_100 \
        -d HZ_250 \
        -d HZ_300 \
        -d HZ_500 \
        -d HZ_600 \
        -d HZ_750 \
        -e HZ_1000 \
        --set-val HZ 1000 \
        -d HZ_PERIODIC \
        -d NO_HZ_IDLE \
        -e NO_HZ_FULL_NODEF \
        -e NO_HZ_FULL \
        -e NO_HZ \
        -e NO_HZ_COMMON \
        -e CONTEXT_TRACKING \
        -d CONTEXT_TRACKING_FORCE \
        -d CC_OPTIMIZE_FOR_PERFORMANCE \
        -e CC_OPTIMIZE_FOR_PERFORMANCE_O3 \
        -d CPU_FREQ_DEFAULT_GOV_SCHEDUTIL \
        -e CPU_FREQ_DEFAULT_GOV_PERFORMANCE \
        -d TRANSPARENT_HUGEPAGE_MADVISE \
        -e TRANSPARENT_HUGEPAGE_ALWAYS \
        -d NUMA \
        -d AMD_NUMA \
        -d X86_64_ACPI_NUMA \
        -d ACPI_NUMA \
        -d NUMA_BALANCING \
        -d NUMA_BALANCING_DEFAULT_ENABLED \
        -d NUMA_KEEP_MEMINFO \
        -d USE_PERCPU_NUMA_NODE_ID \
        -d RUST \
        -d DEBUG_INFO \
        -e EFI \
        -e EFI_STUB \
        -e EFI_PARTITION \
        -e ATA \
        -e SCSI \
        -e SCSI_MOD \
        -e BLK_DEV_SD \
        -e SATA_AHCI \
        -m BLK_DEV_SR \
        -e BLK_DEV_DM \
        -e DM_CRYPT \
        -e BTRFS_FS \
        -e EXT4_FS \
        -e FAT_FS \
        -e VFAT_FS \
        -m EXFAT_FS \
        -m NTFS3_FS \
        -m ISO9660_FS \
        -m UDF_FS \
        -e FUSE_FS \
        -e DRM \
        -e DRM_SIMPLEDRM \
        -e DRM_I915 \
        -e FB \
        -e FRAMEBUFFER_CONSOLE \
        -e INPUT_EVDEV \
        -e KEYBOARD_ATKBD \
        -e SERIO_I8042 \
        -e HID_GENERIC \
        -e USB_HID \
        -m USB_STORAGE \
        -m USB_UAS \
        -e USB_XHCI_HCD \
        -e USB_EHCI_HCD \
        -m TUN \
        -m WIREGUARD \
        -m CIFS \
        -d SYSCTL_EXCEPTION_TRACE \
        -d PM_TRACE \
        -d KPROBES_ON_FTRACE \
        -d FTRACE \
        -d FUNCTION_TRACER \
        -d FUNCTION_GRAPH_TRACER \
        -d STACK_TRACER \
        -d SCHED_TRACER \
        -d HWLAT_TRACER \
        -d OSNOISE_TRACER \
        -d TIMERLAT_TRACER \
        -d MMIOTRACE \
        -d BLK_DEV_IO_TRACE
}
EOF

cleanup() {
    rm -f "$profile_snippet"
}
trap cleanup EXIT

write_variant_files() {
    local target="$1"
    local variant="$2"
    local channel="$3"
    local pkgname="$4"
    local template="$5"
    local source_lane="$6"

    cat > "$target/README.md" <<EOF
# ${pkgname}

Hardware-specific TPM453 package variant for AUR publication.

Channel: ${channel}
Upstream template: ${template}
Package name: ${pkgname}
Source lane: ${source_lane}

Build on a faster server:

\`\`\`bash
./build-on-server.sh --syncdeps
\`\`\`
EOF

    cat > "$target/HARDWARE.md" <<'EOF'
# Hardware Profile

Target machine:
- Acer TMP453-M
- Intel Core i7-2670QM
- Intel i915 graphics
- Intel HM77 AHCI SATA
- LUKS + device-mapper + Btrfs root
- Qualcomm Atheros AR9462 Wi-Fi
- Bluetooth via USB combo device
- HDA audio with Realtek ALC269
- USB UVC webcam

Practical support intentionally preserved:
- USB storage
- exFAT / NTFS3 / ISO9660 / UDF
- FUSE
- TUN / WireGuard
- CIFS
- KVM / zram / ntsync
EOF

    cat > "$target/build-on-server.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_dir"

export PKGDEST="${PKGDEST:-$repo_dir/artifacts}"
export SRCDEST="${SRCDEST:-$repo_dir/cache/sources}"
export SRCPKGDEST="${SRCPKGDEST:-$repo_dir/cache/srcpkgs}"
export TPM453_BUILD_JOBS="${TPM453_BUILD_JOBS:-$(nproc)}"

mkdir -p "$PKGDEST" "$SRCDEST" "$SRCPKGDEST"

if [[ "${1:-}" == "--syncdeps" ]]; then
  shift
  exec makepkg -s --noconfirm --cleanbuild "$@"
fi

exec makepkg --cleanbuild "$@"
EOF
    chmod +x "$target/build-on-server.sh"

    cat > "$target/.gitignore" <<'EOF'
artifacts/
cache/
pkg/
src/
srcpkgs/
*.pkg.tar.zst
*.pkg.tar.zst.sig
EOF
}

patch_pkgbuild() {
    local pkg="$1"
    local variant="$2"
    local desc="$3"
    local source_mode="$4"
    local source_ref="$5"
    local pkgver_override="$6"
    local source_kernelver="$7"
    local version_major="$8"
    local version_minor="$9"
    local version_tagrel="${10}"
    local release_pkgrel="${11}"
    local rcver="${12}"
    local cpu_scheduler="${13}"

    sed -i \
        -e "s|^: \"\\\${_cpusched:=.*}\"|: \"\\\${_cpusched:=${cpu_scheduler}}\"|" \
        -e 's|^: "${_localmodcfg:=.*}"|: "${_localmodcfg:=yes}"|' \
        -e 's|^: "${_localmodcfg_path:=.*}"|: "${_localmodcfg_path:="$startdir/lsmod-tpm453.txt"}"|' \
        -e 's|^: "${_use_current:=.*}"|: "${_use_current:=no}"|' \
        -e 's|^: "${_per_gov:=.*}"|: "${_per_gov:=yes}"|' \
        -e 's|^: "${_processor_opt:=.*}"|: "${_processor_opt:=native}"|' \
        -e 's|^: "${_use_llvm_lto:=.*}"|: "${_use_llvm_lto:=thin}"|' \
        -e 's|^: "${_use_lto_suffix:=.*}"|: "${_use_lto_suffix:=no}"|' \
        -e 's|^: "${_use_gcc_suffix:=.*}"|: "${_use_gcc_suffix:=no}"|' \
        "$pkg"

    sed -i \
        -e '/^  rust$/d' \
        -e '/^  rust-bindgen$/d' \
        -e '/^  rust-src$/d' \
        -e '/^  git$/d' \
        "$pkg"

    sed -i "s|^pkgdesc=.*$|pkgdesc='${desc}'|" "$pkg"
    sed -i 's|^_kernuname=.*$|_kernuname="${pkgver}-${_custom_kernsuffix}"|' "$pkg"
    sed -i "s|^_major=.*$|_major=${version_major}|" "$pkg"
    sed -i "s|^_minor=.*$|_minor=${version_minor}|" "$pkg"
    sed -i "s|^_tagrel=.*$|_tagrel=${version_tagrel}|" "$pkg"
    sed -i "s|^pkgrel=.*$|pkgrel=${release_pkgrel}|" "$pkg"
    sed -i "s|^pkgver=.*$|pkgver=${pkgver_override}|" "$pkg"

    if [[ -n "$rcver" ]]; then
        sed -i "s|^_rcver=.*$|_rcver=${rcver}|" "$pkg"
    fi

    perl -0pi -e "s/^pkgbase=.*\$/_custom_pkgbase=\"linux-tpm453-${variant}\"\n_custom_kernsuffix=\"\\\${_custom_pkgbase#linux-}\"\n\npkgbase=\"\\\$_custom_pkgbase\"/m" "$pkg"

    tmp="$(mktemp)"
    sed "/^_die() { error \"\\\$@\" ; exit 1; }\$/r $profile_snippet" "$pkg" > "$tmp"
    mv "$tmp" "$pkg"

    sed -i 's#make "${BUILD_FLAGS\[@\]}" LSMOD="${_localmodcfg_path}" localmodconfig#yes "" | make "${BUILD_FLAGS[@]}" LSMOD="${_localmodcfg_path}" localmodconfig >/dev/null#' "$pkg"

    perl -0pi -e 's~(\n    if \[ "\$_localmodcfg" = "yes" \]; then.*?\n    fi\n)~\1\n    _apply_tpm453_profile\n~s' "$pkg"
    if [[ "$cpu_scheduler" == "eevdf" ]]; then
        sed -i 's|        -e SCHED_BORE \\|        -d SCHED_BORE \\|' "$pkg"
    fi
    perl -0pi -e 's~echo "Rewrite configuration\.\.\."\n    make "\$\{BUILD_FLAGS\[\@\]\}" prepare\n    yes "" \| make "\$\{BUILD_FLAGS\[\@\]\}" config >/dev/null~echo "Rewrite configuration..."\n    make "\${BUILD_FLAGS[@]}" olddefconfig\n    make "\${BUILD_FLAGS[@]}" prepare~s' "$pkg"
    perl -0pi -e 's~build\(\) \{\n    cd "\$_srcname"\n    make "\$\{BUILD_FLAGS\[\@\]\}" -j"\$\(nproc\)" all~build() {\n    cd "\$_srcname"\n    local build_jobs="\${TPM453_BUILD_JOBS:-\$(nproc)}"\n    make "\${BUILD_FLAGS[@]}" -j"\${build_jobs}" all~s' "$pkg"
    perl -0pi -e 's~CFLAGS= CXXFLAGS= LDFLAGS= make "\$\{BUILD_FLAGS\[\@\]\}" "\$\{MODULE_FLAGS\[\@\]\}" -j\$\(nproc\) modules~CFLAGS= CXXFLAGS= LDFLAGS= make "\${BUILD_FLAGS[@]}" "\${MODULE_FLAGS[@]}" -j"\${build_jobs}" modules~s' "$pkg"
    perl -0pi -e 's~make "\$\{BUILD_FLAGS\[\@\]\}" KERNELDIR="\$srcdir/\$_srcname" -j\$\(nproc\) modules~make "\${BUILD_FLAGS[@]}" KERNELDIR="\$srcdir/\$_srcname" -j"\${build_jobs}" modules~s' "$pkg"

    case "$variant" in
        lts)
            sed -i "s|^_stable=.*$|_stable=${source_kernelver}|" "$pkg"
            sed -i "s|^_srctag=.*$|_srctag=${source_ref}|" "$pkg"
            sed -i 's|^_srcname=.*$|_srcname=${_srctag}|' "$pkg"
            ;;
        release)
            sed -i "s|^_srcname=.*$|_srcname=${source_ref}|" "$pkg"
            ;;
        rc)
            sed -i "s|^_stable=.*$|_stable=${source_kernelver}|" "$pkg"
            sed -i "s|^_srctag=.*$|_srctag=${source_ref}|" "$pkg"
            sed -i 's|^_srcname=.*$|_srcname=${_srctag}|' "$pkg"
            ;;
    esac

    if [[ "$source_mode" == "commit" ]]; then
        sed -i "s|^_srcname=.*$|_srcname=linux-${source_ref}|" "$pkg"
        sed -i "/^_kernuname=/c\\_source_kernelver=\"${source_kernelver}\"\\n_kernuname=\"\${_source_kernelver}-\${_custom_kernsuffix}\"" "$pkg"
        perl -0pi -e 's~source=\(\n.*?\n    "config"\)~source=(\n    "\${_srcname}.tar.gz::https://codeload.github.com/CachyOS/linux/tar.gz/'"${source_ref}"'"\n    "config")~s' "$pkg"

        if [[ "$variant" == "edge" ]]; then
            perl -0pi -e 's/^_rcver=.*\n//m; s/^\#_stable=.*\n//mg; s/^_stable=.*\n//m; s/^_srctag=.*\n//m' "$pkg"
        fi
    fi

    perl -0pi -e "s~(?:b2sums|sha256sums)=\\(.*?\\)~sha256sums=('SKIP'\\n        'SKIP'\\n        'SKIP'\\n        'SKIP')~s" "$pkg"
}

for row in "${variants[@]}"; do
    IFS='|' read -r variant template channel pkgname desc source_mode source_ref pkgver_override source_kernelver source_lane version_major version_minor version_tagrel release_pkgrel rcver cpu_scheduler <<<"$row"
    target="$repo_root/$variant"

    mkdir -p "$target"
    cp "$upstream_root/$template/PKGBUILD" "$target/PKGBUILD"
    cp "$upstream_root/$template/config" "$target/config"
    cp "$lsmod_source" "$target/lsmod-tpm453.txt"

    patch_pkgbuild "$target/PKGBUILD" "$variant" "$desc" "$source_mode" "$source_ref" "$pkgver_override" "$source_kernelver" "$version_major" "$version_minor" "$version_tagrel" "$release_pkgrel" "$rcver" "$cpu_scheduler"
    write_variant_files "$target" "$variant" "$channel" "$pkgname" "$template" "$source_lane"

    (
        cd "$target"
        makepkg --printsrcinfo > .SRCINFO
    )
done
