#!/bin/bash

set -e
trap 'echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR
renice 10 $$ &>/dev/null

level="$1"

# make sure level is one of the expected values
case "$level" in
    09)
        lastpart="01"
        ;;
    10)
        lastpart="01"
        ;;
    11)
        lastpart="04"
        ;;
    12)
        lastpart="09"
        ;;
    *)
        echo "please specify the level of detail you want to download, available levels are 09, 10, 11 and 12"
        exit 1
        ;;
esac


dir="/usr/local/share/openfreemap_offline"
mountpoint="${dir}/mnt"

release="v0.1"
release_url="https://github.com/wiedehopf/openfreemap_offline/releases/download/${release}"

mkdir -p "$mountpoint"
cd "$dir"

image="${dir}/tiles.${level}.btrfs"

if [[ -f "${image}" ]]; then
    echo "skipping image download, ${image} already downloaded"
else
    echo "downloading ${image} in parts, this will take a while"

    files=()

    for part in $(seq -w "00" "$lastpart"); do
        file="tiles.${level}.btrfs.zst.part${part}"
        wget --compression=none -c "${release_url}/${file}"
        files+=("$file")
    done

    echo "decompressing downloaded data, this will take a while"

    cat "${files[@]}" | zstd -d -c -v -o "${image}.tmp"
    mv "${image}.tmp" "${image}"
    rm -f "${files[@]}"
fi

if mount | grep -qs "$mountpoint"; then
    umount "$mountpoint"
fi

cat > /usr/lib/systemd/system/openfreemap_offline.service << EOF
[Unit]
Description=openfreemap offline map tiles
Documentation=https://github.com/wiedehopf/openfreemap_offline

[Service]
ExecStart=/usr/bin/mount -v -t btrfs ${image} ${mountpoint}
ExecStop=/usr/bin/umount -v ${mountpoint}
Type=oneshot
RemainAfterExit=true

[Install]
WantedBy=default.target
EOF

systemctl enable openfreemap_offline.service
systemctl restart openfreemap_offline.service

# download styles, one of them wasn't included in the big downloads
for style in liberty positron bright dark fiord; do
    if ! wget -q -O "${mountpoint}/${style}" "${release_url}/${style}"; then
        echo "ERROR downloading ${release_url}/${style}"
    fi
done

echo "-----------------"
echo "all done, please rerun the tar1090 install script or restart the container serving the tar1090 map, after that the offline map should be available"

