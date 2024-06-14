# INFRA SETUP custom

**Welcome**, the digital custom infra setup.

## Setting-Up

|Tested OS|
|---------|
|Ubuntu-24-04-lts|

### Disk partitioning
- you can partition your disks using parted and mkfs
eg to partition disk into 2 parts:
``` shell
sudo parted /dev/sda

(parted) mklabel gpt
Warning: The existing disk label on /dev/sda will be destroyed and all data on this disk will be lost. Do you want to continue?
Yes/No? Yes
(parted) mkpart primary xfs 0% 50%
(parted) mkpart primary xfs 50% 100%
(parted) quit
```
then
``` shell
lsblk
# these are the partitions that were created
sudo mkfs.xfs /dev/sda1
sudo mkfs.xfs /dev/sda2
lsblk -f
```
> Important: Ensure the disks' file-system type you want to use are configured as xfs or scsi.

If you have existing partitions and you want to set the file-system type, you can use fstransform..
eg.
``` shell
lsblk -f
sudo apt-get install fstransform xfsprogs
sudo fstransform /dev/mmcblk0p2 xfs # assuming disk path is /dev/sda
```