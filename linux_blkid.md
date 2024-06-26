hitzhangjie:
-----------------------------------------------------------------------------------
blkid outputs following: 

```
/dev/vda1: UUID="90ef4aea-f7fa-4c00-bb51-d990d5e5bd4d" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="0ab48ca3-01" 
/dev/vdb1: UUID="3322ff69-79d8-4757-bc6c-efe316d0298e" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="dfc83334-01" 
/dev/vdc: UUID="8d38d26b-4cd5-4f78-b781-35d391b68dae" BLOCK_SIZE="4096" TYPE="ext4"
```

how to know the differences btw vda1 vdb1 vdc? why vdc has know PARTUUID?

GitHub Copilot:
-----------------------------------------------------------------------------------
The identifiers vda1, vdb1, and vdc represent different block devices in your system. They could be different physical drives, different partitions on the same drive, or virtual drives. Here's what each part of the identifier means:

- vd: This stands for "virtual disk". This is a naming convention typically used for virtualized environments, such as virtual machines or containers.
- a, b, c: These letters represent the order of the drives. a is the first drive, b is the second, and so on.
- 1: This number represents the partition number on the drive. If there's no number, it usually means the entire disk is being used as a single partition.
- The PARTUUID is a unique identifier for a partition. It's generated when the partition is created and doesn't change even if the partition is moved to a different drive. The absence of a PARTUUID for vdc suggests that the entire disk (vdc) is being used as a single partition, rather than being divided into multiple partitions.