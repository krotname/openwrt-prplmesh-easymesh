# Installing `prplmesh-stock` on OpenWrt

**[Russian version](install-ru.md)** · **[Release v1.0.0](https://github.com/krotname/openwrt-prplmesh-easymesh/releases/tag/v1.0.0)** · **[Reproducible build](revision-1.md)**

This guide installs the published package without replacing OpenWrt's existing
`wpad`, `hostapd` or `wpa_supplicant`. The package is disabled after
installation. Configure and validate it before the first start.

## 1. Compatibility gate

The v1.0.0 binary has been built and tested on this controller only:

| Item | Supported release binary |
|---|---|
| Router | Xiaomi/Redmi Router AX6S |
| OpenWrt target | `mediatek/mt7622` |
| Package architecture | `aarch64_cortex-a53` |
| Tested firmware | OpenWrt `25.12.5`, Linux `6.12.94` |
| Required AP control sockets | `/var/run/hostapd/wl0-ap0` and `/var/run/hostapd/wl1-ap0` |
| Default LAN bridge | `br-lan` |

OpenWrt 25.12 and newer use APK. OpenWrt 24.10 and older use OPKG, so the
published `.apk` cannot be installed there. Do not treat the presence of APK
on a development snapshot, or a matching CPU name on another router, as proof
of compatibility. Rebuild with the matching SDK and test the result instead.
See the official [OpenWrt APK guide](https://openwrt.org/docs/guide-user/additional-software/apk)
and [25.12 release notes](https://openwrt.org/releases/25.12/notes-25.12.0).

Use a wired management connection and keep physical recovery access while
performing the first start. Run these read-only checks:

```sh
ubus call system board
. /etc/os-release
printf 'release=%s target=%s\n' "$VERSION_ID" "$OPENWRT_BOARD"
apk --print-arch
uci show wireless
ls -l /var/run/hostapd/
uci -q get network.lan.device
```

Stop if the model, target, release or architecture differs. The current init
script also checks the two socket names shown in the table. If the LAN bridge,
wireless UCI sections or socket names differ, use the build recipe to make and
test a target-specific package; do not guess the mapping on a remote router.

## 2. Create and verify an off-device backup

Follow OpenWrt's official [backup and restore guide](https://openwrt.org/docs/guide-user/troubleshooting/backup_restore).
On the router:

```sh
umask 077
BACKUP="/tmp/backup-${HOSTNAME}-before-prplmesh-$(date +%Y%m%d-%H%M%S).tar.gz"
sysupgrade -b "$BACKUP"
tar -tzf "$BACKUP" >/dev/null
sha256sum "$BACKUP"
printf 'backup=%s\n' "$BACKUP"
```

Copy the printed path to another machine before continuing:

```sh
scp root@ROUTER_LAN_ADDRESS:/tmp/backup-ROUTER-before-prplmesh-TIMESTAMP.tar.gz .
tar -tzf backup-ROUTER-before-prplmesh-TIMESTAMP.tar.gz >/dev/null
sha256sum backup-ROUTER-before-prplmesh-TIMESTAMP.tar.gz
```

If a recent OpenSSH client cannot use the router's SCP server, repeat the copy
with `scp -O`, as noted in the OpenWrt guide. Compare the off-device SHA-256
with the value printed on the router. Do not continue if the archive cannot be
listed or the hashes differ. A backup left only under `/tmp` is not a recovery
copy.

## 3. Download and verify the package

The following commands pin the documented v1.0.0 artifact rather than an
unknown future `latest` release:

```sh
cd /tmp
wget -O prplmesh-stock-6.0.1-r1.apk \
  https://github.com/krotname/openwrt-prplmesh-easymesh/releases/download/v1.0.0/prplmesh-stock-6.0.1-r1.apk
wget -O SHA256SUMS \
  https://github.com/krotname/openwrt-prplmesh-easymesh/releases/download/v1.0.0/SHA256SUMS
sha256sum -c SHA256SUMS
```

Expected APK SHA-256 for v1.0.0:

```text
6d398614bac7c1c3a5ad42edaf0f9638ce9999e1ea9877e232e81b2bc0f99ddf
```

Do not use `--allow-untrusted` until the checksum reports `OK`.

## 4. Install, but do not start

Refresh only the configured package indexes and install the verified local
artifact. APK may obtain missing dependencies from the configured official
OpenWrt feeds:

```sh
cat /etc/apk/repositories.d/distfeeds.list
apk update
apk add --allow-untrusted ./prplmesh-stock-6.0.1-r1.apk
apk list -I 'prplmesh-stock'
uci -q get prplmesh.config.enabled
```

The last command must print `0`. If all dependencies are already installed and
an entirely offline installation is required, the tested alternative is:

```sh
apk --network=no --allow-untrusted add ./prplmesh-stock-6.0.1-r1.apk
```

Do not run `apk upgrade`; OpenWrt explicitly warns against blind package-wide
upgrades.

## 5. Map the local configuration

Inspect the real radio sections and hostapd sockets again, then edit
`/etc/config/prplmesh`:

```sh
uci show wireless
ubus list 'hostapd.*'
ls -l /var/run/hostapd/
vi /etc/config/prplmesh
```

Before enabling the service, verify all of the following:

- all three `REPLACE_WITH_SSID` values are replaced with the same intended
  SSID;
- `key_passphrase` and both BSS-profile `key` values are replaced with the
  intended passphrase;
- `backhaul_wire_iface` is the actual LAN bridge (`br-lan` in the tested
  build);
- `mandatory_interfaces` names the two real AP interfaces;
- each `wifi-device` section has the correct `hostap_iface`,
  `hostap_iface_steer_vaps`, `wireless_section` and `wireless_device` mapping;
- the 2.4/5 GHz profile uses the desired security policy and the 6 GHz profile
  uses SAE;
- `enabled` remains `0` while checking the file.

The public template deliberately contains no real SSID or passphrase. Do not
publish the configured file.

Run the local validation gate:

```sh
if grep -n 'REPLACE_WITH' /etc/config/prplmesh; then
    echo 'STOP: unresolved placeholders remain'
    exit 1
fi
test -S /var/run/hostapd/wl0-ap0
test -S /var/run/hostapd/wl1-ap0
uci -q show prplmesh
uci changes prplmesh
uci commit prplmesh
```

If either socket test fails, leave the service disabled. The packaged init
script will also refuse to start.

## 6. Controlled first start

Start only from the wired session:

```sh
uci set prplmesh.config.enabled='1'
uci commit prplmesh
/etc/init.d/prplmesh enable
/etc/init.d/prplmesh start
sleep 5
/etc/init.d/prplmesh status
ps w | grep -E '[i]eee1905_transport|[b]eerocks_(controller|agent)'
logread -e prplmesh | tail -n 100
```

Accept the deployment only if all of these are true:

- the wired management session and the normal LAN gateway remain reachable;
- `ieee1905_transport`, `beerocks_controller` and `beerocks_agent` remain
  running without a restart loop;
- the existing `wpad`/hostapd-managed APs remain up;
- each expected EasyMesh agent appears as a distinct active node;
- Ethernet, not a wireless repeater path, is reported for each wired agent;
- the exact SSID/security profile is correct on every intended band;
- unrelated wired clients and services on the shared LAN remain reachable.

These are deployment checks, not claims that 802.11r/FT, MLO or lossless
roaming is active. Test those features separately on every participating AP and
client.

## 7. Stop, remove or roll back

To stop the new service while retaining the package and configuration:

```sh
uci set prplmesh.config.enabled='0'
uci commit prplmesh
/etc/init.d/prplmesh stop
/etc/init.d/prplmesh disable
```

To uninstall it:

```sh
apk del prplmesh-stock
```

Check whether `/etc/config/prplmesh` was retained as a modified configuration
file. Delete it only if it is no longer needed. If the radios do not return to
their previous runtime state after stopping prplMesh, reload wireless from the
wired session:

```sh
wifi reload
```

The full `sysupgrade -r` restore path replaces system configuration and
requires a reboot. Use it only as a recovery operation, from the verified
off-device archive, following the official OpenWrt backup/restore procedure.
