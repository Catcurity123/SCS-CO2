#### A. Storage refresher
###### 1. Storage Categories
(+) `Direct (local) attached Storage` - Storage on the EC2 Host, it is fast but if the disk, or hardware fails, the disk is lost and if the EC2 instance moves to a different host, the disk is lost. As this storage option is directly attached to the EC2 instance.
(+) `Network Attached Storage` - Volumes delivered over the network (EBS), which is highly resilient and is separated from the EC2 instance (but in the same AZ).
(+) `Ephemeral Storage` - Temporary storage
(+) `Persistent Storage` - Permanently storage - lives on past the lifetime of the instance.

###### 2. Storage Types
(+) `Block Storage` - volume presented to the `OS` as a collection of blocks, no structure provvided. `Mountable` and `Bootable`. The thing about `Block Storage` is that is has no structure provided, just a collection of uniquely identified blocks, the addressing and structure of data is done by the OS via filesystem.
(+) `File Storage` - Presented as a file share has structure, `mountable` `not bootable`.
(+) `Object Storage` - collection of objects, flat. `Not mountable` and `Not bootable`.

###### 3. Storage Performance
![[Pasted image 20240109125646.png]]

(+) `IO or block size`: the block size specifies the amount of data transferred at once between the volume and the instance attached to it. EBS supports 4 different block sizes: 1KiB, 4KiB, 8KiB, and 32 KiB.
(+) `Input/Output Operation Per Second (IOPS)`: refers to the number of read/wrtie requests a particular storage device can handle concurrently.
(+) `Throughput`: While `IOPS` determine how quickly individual operations occur, throughput describes the total rate at which data moves across the storage interface.
(+) `Latency`: Delay between request and completion (ms)
(+) `Capacity`: Volume of data that can be stored (GB)
