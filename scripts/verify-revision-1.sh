#!/usr/bin/env bash
set -euo pipefail

[[ $# -eq 4 ]] || {
    echo "Usage: $0 SDK_DIR APK SHA256SUMS PAYLOAD_MANIFEST" >&2
    exit 2
}

sdk=$(readlink -f "$1")
apk_file=$(readlink -f "$2")
checksum_file=$(readlink -f "$3")
payload_manifest=$(readlink -f "$4")
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$script_dir/.." && pwd)
apk_tool="$sdk/staging_dir/host/bin/apk"

[[ -x "$apk_tool" ]] || { echo "OpenWrt apk tool not found: $apk_tool" >&2; exit 1; }
[[ -f "$checksum_file" && -f "$payload_manifest" ]] || {
    echo "Release manifests are missing" >&2
    exit 1
}

(cd "$(dirname -- "$apk_file")" && sha256sum -c "$checksum_file")
"$apk_tool" --network=no --allow-untrusted verify "$apk_file"

metadata=$("$apk_tool" adbdump "$apk_file")
grep -q '^  name: prplmesh-stock$' <<<"$metadata"
grep -q '^  version: 6\.0\.1-r1$' <<<"$metadata"
grep -q '^  arch: aarch64_cortex-a53$' <<<"$metadata"

extract_root=$(mktemp -d)
trap 'rm -rf -- "$extract_root"' EXIT
"$apk_tool" --network=no --allow-untrusted extract \
    --destination "$extract_root" "$apk_file" >/dev/null

cmp -s "$repo_root/package/prplmesh-stock/files/prplmesh.config" \
       "$extract_root/etc/config/prplmesh"
grep -q "option enabled '0'" "$extract_root/etc/config/prplmesh"
grep -q "option ssid 'REPLACE_WITH_SSID'" "$extract_root/etc/config/prplmesh"
grep -q "option key_passphrase 'REPLACE_WITH_A_STRONG_PASSWORD'" \
    "$extract_root/etc/config/prplmesh"

required=(
    opt/prplmesh/bin/beerocks_agent
    opt/prplmesh/bin/beerocks_controller
    opt/prplmesh/bin/beerocks_cli
    opt/prplmesh/bin/beerocks_fronthaul
    opt/prplmesh/bin/ieee1905_transport
    usr/lib/libbpl.so.6.0.1
    usr/lib/libbwl.so.6.0.1
)
for path in "${required[@]}"; do
    [[ -f "$extract_root/$path" ]] || { echo "Missing payload: $path" >&2; exit 1; }
done

if find "$extract_root" -type f -printf '%P\n' | \
    grep -Eq '(^|/)(wpad|hostapd|wpa_supplicant)([^/]*)$'; then
    echo "Package contains a forbidden replacement Wi-Fi daemon" >&2
    exit 1
fi

(cd "$extract_root" && find . -type f -print0 | LC_ALL=C sort -z | \
    xargs -0 sha256sum) | diff -u "$payload_manifest" -

printf 'REVISION_1_VERIFY=PASS\n'
