# Revision 1 package and reproducible recipe

Revision 1 packages prplMesh 6.0.1 for stock OpenWrt UCI/nl80211 on the
Xiaomi/Redmi AX6S (`mediatek/mt7622`, `aarch64_cortex-a53`). The service is
disabled after installation and the shipped configuration contains only
placeholders. The package uses the hostapd control sockets already provided by
OpenWrt and does not install or replace `wpad`, `hostapd`, or
`wpa_supplicant`.

## Files

- `package/prplmesh-stock/Makefile` pins prplMesh and hostapd source inputs;
- `package/prplmesh-stock/patches/100-stock-platform.patch` adds the stock
  OpenWrt UCI/nl80211 platform path;
- `package/prplmesh-stock/patches/110-stock-wifi-hardening.patch` contains the
  bounded radio-profile and parser corrections;
- `package/prplmesh-stock/files/610-hostapd_cli_ujail_permission.patch` is the
  OpenWrt hostapd control-socket compatibility patch;
- the tested AX6S binary, its checksum, and its payload manifest are assets of
  the [latest GitHub release](https://github.com/krotname/openwrt-prplmesh-easymesh/releases/latest).

## Build

Use the official OpenWrt 25.12.5 `mediatek/mt7622` SDK:

```text
openwrt-sdk-25.12.5-mediatek-mt7622_gcc-14.3.0_musl.Linux-x86_64.tar.zst
SHA-256: 0bd25a391256dbe9ad1f9c6f313364b1f9eddcc0e280c829d644034981ad8306
```

On a Linux builder with Bash, Git, GNU Make, `zstd`, `unshare`, and the normal
OpenWrt SDK prerequisites installed:

```sh
./scripts/build-revision-1.sh openwrt-sdk-25.12.5-mediatek-mt7622_gcc-14.3.0_musl.Linux-x86_64.tar.zst build-output 2
```

The script checks the SDK hash, obtains the exact feed revisions pinned by the
SDK, downloads all source archives, then disables networking for compilation.
The package recipe separately verifies the prplMesh archive, hostapd archive,
unmodified `wpa_ctrl.c`, and patched `wpa_ctrl.c` hashes.

## Verify

```sh
./scripts/verify-revision-1.sh build-output/openwrt-sdk-* prplmesh-stock-6.0.1-r1.apk SHA256SUMS prplmesh-stock-6.0.1-r1.files.sha256
```

Verification checks the release SHA-256, APK integrity, package name, version,
architecture, exact disabled template configuration, required payload, absence
of replacement Wi-Fi daemons, and every extracted-file hash.

## Install on the matching target

Download all three assets from the
[latest GitHub release](https://github.com/krotname/openwrt-prplmesh-easymesh/releases/latest)
and compare the APK against `SHA256SUMS`. Copy it to the AX6S, then
install it from its upload directory with `apk --network=no --allow-untrusted
add ./prplmesh-stock-6.0.1-r1.apk`. Edit `/etc/config/prplmesh`: replace every
SSID and password placeholder, confirm `br-lan`, `wl0-ap0`, and `wl1-ap0`
against the local OpenWrt configuration, and only then set `enabled` to `1`,
commit UCI, enable the init service, and start it. Do not install this binary on
another architecture or OpenWrt release.
