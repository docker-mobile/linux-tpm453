# TPM453 Tuning Notes

This repo carries a TPM453-specific post-`localmodconfig` profile. The goal is not to merge whole foreign patch stacks together. The goal is to keep only the parts that materially help an Acer TMP453-M with:

- Intel Core i7-2670QM
- Intel HM77 AHCI SATA SSD
- Intel i915 graphics
- Qualcomm Atheros AR9462 Wi-Fi
- LUKS + dm-crypt + Btrfs root

## Sources reviewed

- CachyOS: `https://github.com/CachyOS/linux-cachyos`
- linux-tkg: `https://github.com/Frogging-Family/linux-tkg`
- linux-zen packaging: `https://gitlab.archlinux.org/archlinux/packaging/packages/linux-zen`
- Liquorix package sources: `https://github.com/damentz/liquorix-package`
- XanMod feature and release tree: `https://xanmod.org/`
- Arch kernel config: `https://gitlab.archlinux.org/archlinux/packaging/packages/linux/-/blob/main/config.x86_64`
- Fedora kernel config: `https://src.fedoraproject.org/rpms/kernel`
- openSUSE kernel config: `https://github.com/openSUSE/kernel-source`
- Clear Linux kernel config: `https://github.com/clearlinux-pkgs/linux`
- Debian kernel config: `https://salsa.debian.org/kernel-team/linux`

## Adopted for TPM453

- `PREEMPT`, `HZ_1000`, `NO_HZ_FULL`, native CPU tuning, and the aggressive non-debug build profile.
- `LRU_GEN` and `LRU_GEN_ENABLED`, matching the current zen/liquorix/tkg/xanmod direction.
- `INTEL_IDLE=y` for Sandy Bridge power-state handling.
- `ATH9K_BTCOEX_SUPPORT=y` for the AR9462 combo radio.
- `PCIEASPM_DEFAULT=y` rather than a more aggressive PCIe policy.
- `SATA_MOBILE_LPM_POLICY=0` to avoid mobile SATA link-power management becoming a latency or stability variable on this HM77 laptop.
- Built-in practical support needed on this machine even when not currently loaded:
  - `DM_CRYPT`
  - `DM_INTEGRITY`
  - `TRUSTED_KEYS`
  - `ENCRYPTED_KEYS`
  - `OVERLAY_FS`
  - `BLK_DEV_LOOP`
  - `USB_STORAGE`
  - `USB_UAS`
  - `EXFAT_FS`
  - `NTFS3_FS`
  - `SQUASHFS`
  - `CRYPTO_LZ4`
  - `CRYPTO_LZ4HC`

## Intentionally not adopted

- Whole Liquorix, XanMod, Zen, or TKG patch stacks. They overlap, diverge, and would make this repo harder to keep buildable.
- `PCIEASPM_PERFORMANCE`. Clear Linux is more aggressive here, but on this older laptop the safer shared default is the better balance.
- XanMod x86-64-v2/v3 package targeting. The i7-2670QM is best handled by `X86_NATIVE_CPU`, not by forcing a newer psABI tier.
- RT, `sched_ext`, and unrelated gaming patches. They are not part of the TPM453 reliability target.
- Legacy `NTFS_FS`; it is explicitly disabled so `NTFS3` remains the only retained NTFS path.

## Variant policy

- `lts`, `stable`, `release`, and `rc` keep BORE where the branch accepts it cleanly.
- `mainline` and `edge` stay on EEVDF where the upstream snapshot is the cleaner fit.
- `edge` keeps `LTO_NONE` because that branch is intended to stay distinct and buildable first, experimental second.
