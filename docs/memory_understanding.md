# Investigating Memory Leaks

See https://bbs.archlinux.org/viewtopic.php?id=274520

Check: df -h

Check: systemd-cgtop -m

Here is /proc/meminfo:

MemTotal: 11661120 kB
MemFree: 4492528 kB
MemAvailable: 4827168 kB
Buffers: 7168 kB
Cached: 492884 kB
SwapCached: 53476 kB
Active: 1933584 kB
Inactive: 1633784 kB
Active(anon): 1515468 kB
Inactive(anon): 1572420 kB
Active(file): 418116 kB
Inactive(file): 61364 kB
Unevictable: 1608 kB
Mlocked: 1608 kB
SwapTotal: 10485756 kB
SwapFree: 9583944 kB
Dirty: 0 kB
Writeback: 0 kB
AnonPages: 3007104 kB
Mapped: 375728 kB
Shmem: 20572 kB
KReclaimable: 173560 kB
Slab: 428120 kB
SReclaimable: 173560 kB
SUnreclaim: 254560 kB
KernelStack: 19264 kB
PageTables: 46832 kB
NFS_Unstable: 0 kB
Bounce: 0 kB
WritebackTmp: 0 kB
CommitLimit: 16316316 kB
Committed_AS: 10692612 kB
VmallocTotal: 34359738367 kB
VmallocUsed: 52660 kB
VmallocChunk: 0 kB
Percpu: 12544 kB
HardwareCorrupted: 0 kB
AnonHugePages: 530432 kB
ShmemHugePages: 0 kB
ShmemPmdMapped: 0 kB
FileHugePages: 75776 kB
FilePmdMapped: 0 kB
CmaTotal: 0 kB
CmaFree: 0 kB
HugePages_Total: 0
HugePages_Free: 0
HugePages_Rsvd: 0
HugePages_Surp: 0
Hugepagesize: 2048 kB
Hugetlb: 0 kB
DirectMap4k: 6448844 kB
DirectMap2M: 5468160 kB
DirectMap1G: 1048576 kB
And here is free -h:

               total        used        free      shared  buff/cache   available

Mem: 11Gi 6.2Gi 4.3Gi 19Mi 658Mi 4.6Gi
Swap: 9Gi 879Mi 9.1Gi
Also smem -tk as good measure:

PID User Command Swap USS PSS RSS
1235 kirottu /bin/sh /usr/bin/startx /us 640.0K 8.0K 12.0K 504.0K
1301 kirottu xinit /usr/bin/startplasma- 240.0K 8.0K 12.0K 548.0K
1552 kirottu /usr/lib/bluetooth/obexd 904.0K 12.0K 22.0K 1.0M
1473 kirottu /usr/bin/touchegg 2.4M 32.0K 71.0K 1.7M
1315 kirottu /usr/bin/startplasma-x11 4.7M 20.0K 73.0K 2.4M
13964 kirottu /usr/lib/xdg-permission-sto 564.0K 52.0K 74.0K 1.3M
1374 kirottu /usr/lib/dconf-service 612.0K 152.0K 188.0K 1.5M
6817 kirottu /usr/lib/at-spi-bus-launche 696.0K 400.0K 430.0K 1.8M
1471 kirottu /usr/bin/gmenudbusmenuproxy 4.5M 364.0K 432.0K 3.0M
13952 kirottu /usr/lib/xdg-document-porta 2.3M 424.0K 447.0K 1.7M
3349 kirottu /usr/lib/kf5/kioslave5 /usr 1.9M 284.0K 449.0K 2.8M
1456 kirottu /usr/bin/xembedsniproxy 4.5M 388.0K 457.0K 3.0M
1551 kirottu /usr/lib/kf5/kscreen_backen 2.5M 424.0K 487.0K 2.9M
1344 kirottu /usr/bin/plasma_session 4.1M 428.0K 489.0K 2.9M
14046 kirottu /usr/lib/xdg-desktop-portal 5.4M 432.0K 505.0K 3.4M
1458 kirottu /usr/bin/kaccess 5.5M 544.0K 638.0K 3.6M
1234 kirottu /usr/bin/kwalletd5 --pam-lo 5.3M 644.0K 725.0K 3.7M
1322 kirottu /usr/bin/dbus-daemon --sess 668.0K 980.0K 1.1M 2.3M
13930 kirottu /usr/lib/xdg-desktop-portal 3.7M 1.1M 1.3M 3.1M
1470 kirottu /usr/lib/DiscoverNotifier 24.1M 1.3M 1.6M 6.0M
1378 kirottu /usr/bin/kglobalaccel5 5.9M 1.4M 1.6M 5.6M
1699 kirottu /usr/lib/baloorunner 4.7M 1.3M 1.6M 6.1M
1222 kirottu /usr/lib/systemd/systemd -- 1.9M 1.2M 2.0M 4.4M
76384 kirottu /usr/bin/fish 796.0K 1.7M 2.6M 7.3M
20508 kirottu /usr/bin/fish 1.3M 1.9M 2.7M 5.6M
1364 kirottu /usr/lib/kactivitymanagerd 5.5M 2.1M 2.7M 8.3M
1428 kirottu /usr/bin/ksmserver 4.7M 2.1M 2.8M 9.0M
1631 kirottu /usr/lib/kdeconnectd 7.0M 2.4M 2.8M 7.5M
1606 kirottu /usr/bin/wireplumber 3.8M 3.3M 3.5M 5.8M
77753 kirottu /usr/bin/fish 0 2.7M 3.7M 8.9M
77923 kirottu ssh Kirottu@lish-frankfurt. 0 3.3M 4.0M 7.8M
7432 kirottu /usr/lib/librewolf/librewol 12.6M 2.2M 4.5M 21.7M
1535 kirottu /usr/bin/ksystemstats 2.7M 4.5M 4.9M 8.8M
1605 kirottu /usr/bin/pipewire 4.3M 7.0M 7.4M 8.8M
1360 kirottu /usr/bin/kded5 14.5M 9.2M 10.8M 19.6M
20490 kirottu /usr/bin/alacritty 49.7M 10.9M 12.1M 17.9M
6839 kirottu /usr/lib/librewolf/librewol 10.9M 14.6M 18.6M 69.6M
78494 kirottu /usr/lib/librewolf/librewol 1.6M 11.9M 19.1M 81.8M
78457 kirottu /usr/lib/librewolf/librewol 1.6M 12.0M 19.2M 82.0M
78514 kirottu /usr/lib/librewolf/librewol 1.6M 12.1M 19.4M 82.5M
1607 kirottu /usr/bin/pipewire-pulse 16.7M 19.5M 19.9M 21.6M
1302 kirottu /usr/lib/Xorg :0 -nolisten 52.1M 24.9M 26.6M 31.5M
77247 kirottu /usr/lib/librewolf/librewol 1.6M 24.4M 29.2M 94.7M
78606 kirottu python /usr/bin/smem -tk 0 29.2M 29.3M 31.8M
76367 kirottu /usr/bin/alacritty 7.9M 35.0M 42.5M 106.5M
1474 kirottu /usr/bin/nextcloud --backgr 59.1M 41.5M 44.2M 59.1M
77735 kirottu /usr/bin/alacritty 0 43.2M 51.4M 117.3M
75885 kirottu /usr/lib/librewolf/librewol 22.6M 44.0M 53.9M 174.9M
76126 kirottu /usr/bin/corectrl 9.7M 52.0M 66.2M 149.4M
77671 kirottu /usr/lib/librewolf/librewol 1.7M 58.8M 75.3M 219.9M
76440 kirottu /usr/lib/librewolf/librewol 3.2M 76.6M 86.6M 206.5M
77118 kirottu /usr/lib/librewolf/librewol 1.7M 81.1M 91.8M 216.3M
77567 kirottu /usr/lib/librewolf/librewol 1.7M 87.0M 103.4M 245.6M
76670 kirottu /usr/lib/librewolf/librewol 1.7M 92.8M 103.8M 231.3M
74449 kirottu /usr/bin/krunner 12.9M 88.6M 104.0M 193.3M
7085 kirottu /usr/lib/librewolf/librewol 21.6M 100.5M 106.6M 170.9M
1363 kirottu /usr/bin/kwin_x11 45.4M 108.0M 113.8M 144.7M
1460 kirottu /usr/bin/plasmashell 67.6M 119.9M 129.8M 181.6M
76567 kirottu /usr/lib/librewolf/librewol 1.7M 148.7M 159.9M 286.4M
6702 kirottu /usr/lib/librewolf/librewol 115.8M 343.4M 361.5M 521.5M
7125 kirottu /usr/lib/librewolf/librewol 80.9M 376.9M 384.2M 451.6M
76501 kirottu /usr/lib/librewolf/librewol 2.0M 822.2M 834.2M 963.0M

---

62 1 737.8M 2.9G 3.1G 5.2G

With diagnosis being:

smem accounts for 5.2GB, the brunt of that going to librewolf
free shows 4.3GB free what matches the meminfo data
What can get you worried is that MemFree+Active+Inactive only accounts for 7.7GB, so we're looking for ~3GB that are not claimed by process memory.

This sounds eerily like https://bbs.archlinux.org/viewtopic.php?id=271247 so see whether you can reclaim that RAM from the GPU
https://bbs.archlinux.org/viewtopic.php … 9#p2004169 (best exit the graphical session, I assume librewolf is shuffling a lot of RAM into GTT)

Another advice is to echo to the cache to drop:

```
echo 3 | sudo tee -a /proc/sys/vm/drop_caches

```

I ran it and look at my cache:

08:54:34 darkvoid@DarkTower ~ → sudo smem -tk
PID User Command Swap USS PSS RSS
2716 root fusermount3 -o rw,nosuid,no 0 144.0K 160.0K 2.0M
2798 darkvoid bwrap --unshare-all --die-w 0 76.0K 160.0K 1.2M
2785 darkvoid bwrap --unshare-all --die-w 0 60.0K 163.0K 1.9M
2576 darkvoid dbus-broker --log 10 --cont 0 204.0K 289.0K 2.5M
911 rtkit /usr/lib/rtkit-daemon 0 296.0K 367.0K 3.3M
3154 darkvoid cat 0 308.0K 443.0K 4.8M
3155 darkvoid cat 0 308.0K 443.0K 4.8M
2575 darkvoid /usr/bin/dbus-broker-launch 0 284.0K 466.0K 3.6M
2316 darkvoid /usr/bin/dbus-broker-launch 0 356.0K 524.0K 3.8M
2393 darkvoid /bin/sh /usr/bin/niri-sessi 0 312.0K 536.0K 3.4M
2388 darkvoid /usr/lib/gdm-wayland-sessio 0 508.0K 609.0K 5.4M
2689 darkvoid /usr/lib/xdg-permission-sto 0 528.0K 627.0K 5.4M
2655 darkvoid /usr/lib/gvfsd-metadata 0 648.0K 781.0K 6.0M
2541 darkvoid /usr/lib/at-spi-bus-launche 0 668.0K 868.0K 7.2M
2777 darkvoid /usr/lib/at-spi2-registryd 0 732.0K 874.0K 6.8M
11702 root sudo smem -tk 0 116.0K 917.0K 2.9M
660 dbus /usr/bin/dbus-broker-launch 0 856.0K 1023.0K 4.2M
2317 darkvoid dbus-broker --log 11 --cont 0 948.0K 1.0M 3.2M
2618 darkvoid /usr/lib/gvfsd-fuse /run/us 0 784.0K 1.0M 6.5M
2519 darkvoid /usr/lib/geoclue-2.0/demos/ 0 864.0K 1.0M 7.3M
2708 darkvoid /usr/lib/xdg-document-porta 0 860.0K 1.1M 6.5M
3168 darkvoid /opt/vivaldi/vivaldi-bin -- 0 248.0K 1.1M 19.8M
664 root /usr/lib/boltd 0 1008.0K 1.2M 9.2M
3159 darkvoid /opt/vivaldi/chrome_crashpa 0 592.0K 1.2M 4.2M
424 root /usr/lib/systemd/systemd-us 0 1.0M 1.2M 5.4M
825 root /usr/lib/accounts-daemon 0 1.0M 1.2M 9.3M
11565 root systemd-userwork: waiting.. 0 1.0M 1.3M 5.8M
11566 root systemd-userwork: waiting.. 0 1.0M 1.3M 5.9M
9069 root systemd-userwork: waiting.. 0 1.0M 1.3M 5.9M
2521 darkvoid mako 0 1.1M 1.3M 7.9M
3157 darkvoid /opt/vivaldi/chrome_crashpa 0 784.0K 1.4M 4.4M
2427 darkvoid systemctl --user --wait sta 0 1.3M 1.6M 6.2M
431 systemd-timesync /usr/lib/systemd/systemd-ti 0 1.3M 1.8M 7.4M
812 root /usr/bin/gdm 0 1.6M 2.0M 11.4M
663 root /usr/lib/bluetooth/bluetoot 0 1.9M 2.0M 5.8M
2294 darkvoid (sd-pam) 0 2.0M 2.2M 4.1M
11700 root sudo smem -tk 0 980.0K 2.2M 9.3M
670 root /usr/lib/systemd/systemd-lo 0 1.8M 2.3M 7.8M
661 dbus dbus-broker --log 10 --cont 0 2.2M 2.3M 4.6M
2563 darkvoid xwayland-satellite :0 -list 0 976.0K 2.5M 6.3M
2583 darkvoid /usr/lib/gvfsd 0 1.9M 2.6M 10.1M
805 root /usr/bin/cupsd -l 0 2.2M 2.6M 8.3M
2504 darkvoid xwayland-satellite 0 1.0M 2.6M 6.4M
2675 darkvoid /usr/bin/pipewire-pulse 0 2.7M 3.0M 10.9M
1914 root gdm-session-worker [pam/gdm 0 2.4M 3.4M 11.5M
2311 darkvoid /usr/bin/gnome-keyring-daem 0 3.2M 3.4M 9.4M
685 polkitd /usr/lib/polkit-1/polkitd - 0 3.4M 3.8M 10.5M
8488 darkvoid nvim memory_understanding.m 0 1.4M 4.0M 10.6M
2799 darkvoid /usr/lib/glycin-loaders/2+/ 0 4.4M 4.4M 6.3M
2292 darkvoid /usr/lib/systemd/systemd -- 0 2.8M 4.6M 12.1M
5764 darkvoid /usr/bin/bash 0 4.7M 5.1M 10.5M
5157 darkvoid /usr/bin/bash 0 4.7M 5.1M 10.5M
5426 darkvoid /usr/bin/bash 0 4.7M 5.1M 10.5M
4789 darkvoid /usr/bin/bash 0 4.7M 5.1M 10.5M
3345 darkvoid /usr/bin/bash 0 5.0M 5.3M 10.7M
1005 root /usr/lib/upowerd 0 5.6M 5.8M 12.2M
2676 darkvoid /usr/lib/xdg-desktop-portal 0 5.1M 6.2M 18.5M
435 root /usr/lib/systemd/systemd-ud 0 5.7M 6.2M 11.8M
1 root /sbin/init 0 4.3M 6.2M 13.9M
847 root /usr/bin/wpa_supplicant -u 0 5.7M 6.3M 11.0M
2669 darkvoid /usr/bin/pipewire 0 5.6M 6.5M 14.0M
3166 darkvoid /opt/vivaldi/vivaldi-bin -- 0 196.0K 6.8M 65.5M
967 colord /usr/lib/colord 0 6.7M 7.3M 15.3M
2856 darkvoid /usr/lib/xdg-desktop-portal 0 6.1M 7.9M 27.0M
11039 darkvoid /opt/vivaldi/vivaldi-bin -- 0 5.5M 8.0M 77.4M
3227 darkvoid /opt/vivaldi/vivaldi-bin -- 0 5.2M 8.1M 60.2M
2674 darkvoid /usr/bin/wireplumber 0 9.3M 10.5M 21.6M
662 root /usr/bin/NetworkManager --n 0 9.2M 10.7M 26.2M
8506 darkvoid markdown-oxide 0 13.3M 13.3M 15.5M
666 root /usr/lib/iwd/iwd 0 13.7M 13.7M 15.5M
3165 darkvoid /opt/vivaldi/vivaldi-bin -- 0 828.0K 14.2M 65.5M
2500 darkvoid /usr/bin/niri --session 0 1.7M 14.3M 38.8M
2523 darkvoid /usr/bin/niri --session 0 2.1M 14.7M 39.2M
2525 darkvoid /usr/bin/nm-applet 0 10.2M 15.4M 41.5M
413 root /usr/lib/systemd/systemd-jo 0 12.0M 16.3M 25.5M
5985 darkvoid btop 0 16.5M 18.5M 27.9M
5370 darkvoid btop 0 16.6M 18.6M 27.9M
5650 darkvoid btop 0 16.6M 18.6M 28.0M
11029 ? ? 0 15.1M 19.5M 126.7M
11703 root python /usr/bin/smem -tk 0 18.7M 19.8M 27.4M
4287 darkvoid /opt/vivaldi/vivaldi-bin -- 0 14.3M 21.2M 79.8M
2527 darkvoid /usr/bin/python3 /usr/share 0 19.0M 21.8M 38.2M
2719 darkvoid /usr/lib/xdg-desktop-portal 0 20.6M 22.4M 41.8M
8541 darkvoid typos-lsp 0 22.6M 22.7M 24.9M
4448 darkvoid /opt/vivaldi/vivaldi-bin -- 0 20.0M 24.8M 143.5M
2808 darkvoid /bin/python /home/darkvoid/ 0 23.6M 29.6M 57.4M
2506 darkvoid Xwayland -rootless -force-x 0 30.4M 33.5M 53.2M
2565 darkvoid Xwayland :0 -listenfd 151 - 0 30.6M 33.7M 53.6M
9668 darkvoid /opt/vivaldi/vivaldi-bin -- 0 29.1M 34.5M 160.1M
3210 darkvoid /opt/vivaldi/vivaldi-bin -- 0 32.2M 42.6M 128.6M
4459 darkvoid /opt/vivaldi/vivaldi-bin -- 0 38.8M 44.5M 171.7M
9228 darkvoid /opt/vivaldi/vivaldi-bin -- 0 38.6M 45.1M 176.4M
813 root /usr/bin/containerd 0 47.6M 47.6M 49.2M
2499 darkvoid wpaperd 0 46.6M 47.8M 63.6M
5743 darkvoid alacritty 0 45.3M 51.4M 96.0M
5133 darkvoid alacritty 0 45.5M 51.5M 95.9M
3280 darkvoid /opt/vivaldi/vivaldi-bin -- 0 46.6M 52.9M 183.8M
2511 darkvoid /bin/python /usr/bin/ulaunc 0 43.2M 53.0M 92.3M
4768 darkvoid alacritty 0 47.6M 53.5M 97.7M
3783 darkvoid /opt/vivaldi/vivaldi-bin -- 0 48.1M 54.0M 184.3M
5399 darkvoid alacritty 0 48.1M 54.0M 98.4M
2496 darkvoid ashell 0 51.8M 57.8M 81.1M
3810 darkvoid /opt/vivaldi/vivaldi-bin -- 0 51.0M 58.0M 196.3M
3273 darkvoid alacritty 0 54.7M 61.5M 108.2M
3817 darkvoid /opt/vivaldi/vivaldi-bin -- 0 60.3M 66.7M 200.8M
2036 root /usr/bin/dockerd -H fd:// - 0 68.4M 68.6M 71.9M
2430 darkvoid /usr/bin/niri --session 0 52.1M 69.3M 137.0M
7486 darkvoid /opt/vivaldi/vivaldi-bin -- 0 69.1M 74.8M 190.0M
3993 darkvoid /opt/vivaldi/vivaldi-bin -- 0 91.5M 98.7M 238.9M
3837 darkvoid /opt/vivaldi/vivaldi-bin -- 0 93.5M 101.1M 236.1M
8553 darkvoid node /home/darkvoid/.local/ 0 80.9M 101.4M 125.6M
3238 darkvoid /opt/vivaldi/vivaldi-bin -- 0 102.4M 110.5M 248.8M
3949 darkvoid /opt/vivaldi/vivaldi-bin -- 0 103.9M 111.7M 256.7M
3981 darkvoid /opt/vivaldi/vivaldi-bin -- 0 115.3M 122.0M 265.2M
3999 darkvoid /opt/vivaldi/vivaldi-bin -- 0 114.9M 122.0M 267.3M
3971 darkvoid /opt/vivaldi/vivaldi-bin -- 0 116.1M 124.1M 270.9M
3554 darkvoid /opt/vivaldi/vivaldi-bin -- 0 118.0M 125.0M 269.4M
3942 darkvoid /opt/vivaldi/vivaldi-bin -- 0 118.2M 125.2M 269.6M
3953 darkvoid /opt/vivaldi/vivaldi-bin -- 0 119.2M 126.2M 271.0M
3932 darkvoid /opt/vivaldi/vivaldi-bin -- 0 123.8M 131.2M 275.9M
8507 darkvoid marksman server 0 140.7M 140.8M 144.9M
8489 darkvoid nvim --embed memory_underst 0 139.4M 142.0M 149.2M
4011 darkvoid /opt/vivaldi/vivaldi-bin -- 0 166.2M 172.0M 304.0M
3208 darkvoid /opt/vivaldi/vivaldi-bin -- 0 154.3M 175.1M 274.8M
3784 darkvoid /opt/vivaldi/vivaldi-bin -- 0 169.2M 176.5M 317.7M
3147 darkvoid /opt/vivaldi/vivaldi-bin 0 249.4M 268.6M 406.4M
8525 darkvoid prosemd-lsp --stdio 0 342.0M 342.1M 345.7M
8612 darkvoid node /home/darkvoid/.local/ 0 783.4M 804.1M 829.1M

---

128 8 0 4.8G 5.2G 9.8G
08:58:37 darkvoid@DarkTower ~ → echo 3 | sudo tee -a /proc/sys/vm/drop_caches
3
08:58:40 darkvoid@DarkTower ~ → free
total used free shared buff/cache available
Mem: 130953652 8133892 122996972 214128 1102760 122819760
Swap: 65476604 0 65476604
08:58:51 darkvoid@DarkTower ~ → cat /proc/meminfo
MemTotal: 130953652 kB
MemFree: 123014332 kB
MemAvailable: 122837608 kB
Buffers: 500 kB
Cached: 1065888 kB
SwapCached: 0 kB
Active: 5315940 kB
Inactive: 191076 kB
Active(anon): 4657768 kB
Inactive(anon): 0 kB
Active(file): 658172 kB
Inactive(file): 191076 kB
Unevictable: 16 kB
Mlocked: 16 kB
SwapTotal: 65476604 kB
SwapFree: 65476604 kB
Zswap: 0 kB
Zswapped: 0 kB
Dirty: 1168 kB
Writeback: 0 kB
AnonPages: 4440728 kB
Mapped: 854380 kB
Shmem: 217392 kB
KReclaimable: 39768 kB
Slab: 218344 kB
SReclaimable: 39768 kB
SUnreclaim: 178576 kB
KernelStack: 20060 kB
PageTables: 74400 kB
SecPageTables: 3632 kB
NFS_Unstable: 0 kB
Bounce: 0 kB
WritebackTmp: 0 kB
CommitLimit: 130953428 kB
Committed_AS: 27081676 kB
VmallocTotal: 34359738367 kB
VmallocUsed: 580132 kB
VmallocChunk: 0 kB
Percpu: 8352 kB
HardwareCorrupted: 0 kB
AnonHugePages: 329728 kB
ShmemHugePages: 0 kB
ShmemPmdMapped: 0 kB
FileHugePages: 116736 kB
FilePmdMapped: 116736 kB
CmaTotal: 0 kB
CmaFree: 0 kB
Unaccepted: 0 kB
Balloon: 0 kB
HugePages_Total: 0
HugePages_Free: 0
HugePages_Rsvd: 0
HugePages_Surp: 0
Hugepagesize: 2048 kB
Hugetlb: 0 kB
DirectMap4k: 1126700 kB
DirectMap2M: 22032384 kB
DirectMap1G: 110100480 kB

## Install AMGgpuTop to see VRAM usage

See https://cprimozic.net/notes/posts/amdgpu_top-a-modern-radeontop-alternative/

```
cargo install amdgpu_top
```

and

```
modinfo amdgpu | grep -iE '(gart|gtt)'
modinfo radeon | grep -iE '(gart|gtt)'
```

### Check journalctl to see messages on VRAM

```
sudo journalctl -b | grep -iE '(gtt|gart|vram)'

```

or

```
sudo journalctl -b -1 | grep -iE '(gtt|gart|vram)'

```

### Others found stress-ng help to reset things

So maybe give it a shot

```
stress-ng --vm 1 --vm-bytes 31G

```

### Others tried this to get back memory

okay, i got it to work. i didn't have to use the targets, i just exited the window manager and ran

```
head -c 15000m /dev/zero | tail | sleep 20

```

from a shell without an x server running. the memory went down from 3 gigabytes to 300 megabytes.
thanks!
