#!/bin/bash

set -e
trap 'echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR
renice 10 $$ &>/dev/null

dir="/usr/local/share/openfreemap_offline"
mountpoint="${dir}/mnt"

release="v0.1"
release_url="https://github.com/wiedehopf/openfreemap_offline/releases/download/${release}"

mkdir -p "$mountpoint"
cd "$dir"

image="${dir}/tiles.full.btrfs"

if [[ -f "${image}" ]]; then
    echo "skipping image download, ${image} already downloaded"
else
    echo "downloading ${image} this will take a while"
    # https://btrfs.openfreemap.com/files.txt
    # check here for which file to get
    url="https://btrfs.openfreemap.com/$(curl -sS https://btrfs.openfreemap.com/files.txt | grep 'areas/planet' | grep done | tail -n1 | sed -e 's/done/tiles.btrfs.gz/')"
    wget --compression=none -c "$url"
    echo "decompressing downloaded data, this will take a while"
    zstd -d --format=gzip tiles.btrfs.gz -c | dd of=tiles.btrfs bs=1M status=progress
    mv "tiles.btrfs" "${image}"
fi

if mount | grep -qs "{$mountpoint} "; then
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

# download and modify styles to use local resources
for style in liberty positron bright dark fiord; do
    wget -q -O "${mountpoint}/${style}" "https://tiles.openfreemap.org/styles/${style}"
    sed -i "${mountpoint}/${style}" \
        -e 's#https://tiles.openfreemap.org/planet#./planet#' \
        -e 's#https://tiles.openfreemap.org/sprites/ofm_f384/ofm#./resources/sprites/ofm#'
done

# load sprites

mkdir -p "${mountpoint}/resources/sprites"
cd "${mountpoint}/resources/sprites"

wget https://tiles.openfreemap.org/sprites/ofm_f384/ofm.json -O ofm.json
wget https://tiles.openfreemap.org/sprites/ofm_f384/ofm.png -O ofm.png

# load planet file
cd "${mountpoint}"
wget https://tiles.openfreemap.org/planet -O planet

jq < planet > planet.tmp '.tiles = ["./tiles/{z}/{x}/{y}.pbf"]'
mv planet.tmp planet


echo "-----------------"
echo "all done, please rerun the tar1090 install script or restart the container serving the tar1090 map, after that the offline map should be available"

