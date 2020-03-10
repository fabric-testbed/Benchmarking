mkdir -p /zoo
mkdir -p /kafka
mkfs.ext4 -E nodiscard /dev/nvme0n1
mkfs.ext4 -E nodiscard /dev/nvme1n1
mount /dev/nvme0n1 /zoo
mount /dev/nvme1n1 /kafka
