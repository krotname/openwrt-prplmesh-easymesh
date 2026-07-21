#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$script_dir/.." && pwd)
package_dir="$repo_root/package/prplmesh-stock"

grep -qxF 'PKG_VERSION:=6.0.1' "$package_dir/Makefile"
grep -qxF 'PKG_RELEASE:=1' "$package_dir/Makefile"
grep -qxF 'PKG_HASH:=68602c7bdf521de1797c0e58e66bb45cf105726dfd5a75d8429038012e19a702' \
    "$package_dir/Makefile"
grep -qxF 'HOSTAPD_SOURCE_VERSION:=ca266cc24d8705eb1a2a0857ad326e48b1408b20' \
    "$package_dir/Makefile"
grep -qxF 'HOSTAPD_MIRROR_HASH:=59ac677093f524ff98588abd9f33805a336a6e929d6814222f0d784c854f2343' \
    "$package_dir/Makefile"

mapfile -t project_patches < <(find "$package_dir/patches" -maxdepth 1 \
    -type f -name '*.patch' -printf '%f\n' | sort)
[[ ${#project_patches[@]} -eq 2 ]]
[[ ${project_patches[0]} == 100-stock-platform.patch ]]
[[ ${project_patches[1]} == 110-stock-wifi-hardening.patch ]]

config="$package_dir/files/prplmesh.config"
grep -q "option enabled '0'" "$config"
[[ $(grep -c "option ssid 'REPLACE_WITH_SSID'" "$config") -eq 3 ]]
[[ $(grep -c "option key 'REPLACE_WITH_A_STRONG_PASSWORD'" "$config") -eq 2 ]]
[[ $(grep -c "option key_passphrase 'REPLACE_WITH_A_STRONG_PASSWORD'" "$config") -eq 1 ]]

if grep -ERInq \
    '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}|([0-9]{1,3}\.){3}[0-9]{1,3}' \
    "$package_dir"; then
    echo 'Recipe contains a concrete MAC or IPv4 address' >&2
    exit 1
fi

(cd "$repo_root" && sha256sum -c SOURCE-SHA256SUMS.txt)
printf 'REVISION_1_RECIPE=PASS\n'
