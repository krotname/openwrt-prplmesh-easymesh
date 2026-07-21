#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 OPENWRT_SDK_ARCHIVE WORK_DIR [JOBS]" >&2
    exit 2
}

[[ $# -ge 2 && $# -le 3 ]] || usage

sdk_archive=$1
work_dir=$2
jobs=${3:-2}
sdk_sha256=0bd25a391256dbe9ad1f9c6f313364b1f9eddcc0e280c829d644034981ad8306
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$script_dir/.." && pwd)
package_dir="$repo_root/package/prplmesh-stock"

[[ -f "$sdk_archive" ]] || { echo "SDK archive not found: $sdk_archive" >&2; exit 1; }
[[ ! -e "$work_dir" ]] || { echo "WORK_DIR already exists: $work_dir" >&2; exit 1; }
[[ "$jobs" =~ ^[1-9][0-9]*$ ]] || { echo "JOBS must be a positive integer" >&2; exit 1; }

sdk_archive=$(readlink -f "$sdk_archive")
work_dir=$(readlink -m "$work_dir")
printf '%s  %s\n' "$sdk_sha256" "$sdk_archive" | sha256sum -c -

mkdir -p "$work_dir"
zstd -dc -- "$sdk_archive" | tar -xf - -C "$work_dir"
mapfile -t sdk_roots < <(find "$work_dir" -mindepth 1 -maxdepth 1 -type d -print)
[[ ${#sdk_roots[@]} -eq 1 ]] || { echo "Unexpected SDK archive layout" >&2; exit 1; }
sdk=${sdk_roots[0]}

cd "$sdk"
./scripts/feeds update base
for dependency in libjson-c libnl libubox openssl ubus uci; do
    ./scripts/feeds install -p base "$dependency"
done
cp -a -- "$package_dir" package/prplmesh-stock

make defconfig
sed -i -e '/^CONFIG_PACKAGE_prplmesh-stock=/d' \
       -e '/^# CONFIG_PACKAGE_prplmesh-stock is not set$/d' .config
printf 'CONFIG_PACKAGE_prplmesh-stock=m\n' >> .config
make defconfig
grep -qxF 'CONFIG_PACKAGE_prplmesh-stock=m' .config

make package/libjson-c/download \
     package/libnl/download \
     package/libubox/download \
     package/openssl/download \
     package/ubus/download \
     package/uci/download \
     package/prplmesh-stock/download

command -v unshare >/dev/null
unshare -n make -j"$jobs" package/prplmesh-stock/compile

mapfile -t artifacts < <(find bin/packages -type f \
    -name 'prplmesh-stock-6.0.1-r1.apk' -print | sort)
[[ ${#artifacts[@]} -eq 1 ]] || {
    echo "Expected one Revision 1 APK, got ${#artifacts[@]}" >&2
    exit 1
}

printf 'BUILD_NETWORK=disabled-during-compile\n'
printf 'ARTIFACT=%s\n' "${artifacts[0]}"
sha256sum "${artifacts[0]}"
