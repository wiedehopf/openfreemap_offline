# openfreemap_offline
Rarely updated, limited offline maps

Thanks to https://openfreemap.org/ for providing an easy download of the tiles.
This project removes higher zoom levels to make it more suitable for use on an raspberry pi with
sd-card or if you just don't care to download 85 GB.

Additionally some resources are included for it to be truly usabel offline.
The fonts are not included, the browser will use a fallback font.


## Install

Zoom level | Download size | Disk space required | during installation
10 | 4.1 GB | 5.1 GB | 10 GB
11 | 8.6 GB | 12.1 GB | 21 GB
12 | 19.5 GB | 29.5 GB | 50 GB

During installation, there also needs to be space for the download, so there is need for more
storage during that, see the table above.

```
sudo su -
wget https://raw.githubusercontent.com/wiedehopf/openfreemap_offline/refs/heads/master/install.sh
bash install.sh ZOOMLEVEL
```


## Uninstall

```
sudo su -
systemctl disable --now openfreemap_offline
rm /usr/local/share/openfreemap_offline -rf
```
