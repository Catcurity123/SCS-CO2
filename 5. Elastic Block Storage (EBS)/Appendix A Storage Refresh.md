#### A. Storage refresher
###### 1. Storage Categories
(+) `Direct (local) attached Storage` - Storage on the EC2 Host, it is fast but if the disk, or hardware fails, the disk is lost and if the EC2 instance moves to a different host, the disk is lost. As this storage option is directly attached to the EC2 instance.
(+) `Network Attached Storage` - Volumes delivered over the network (EBS), which is highly resilient and is separated from the EC2 instance (but in the same AZ).
(+) `Ephemeral Storage` - Temporary storage
(+) `Persistent Storage` - Permanently storage - lives on past the lifetime of the instance.

###### 2. Storage Types
(+) `Block Storage` - volume presented to the `OS` as a collection of blocks, no structure provided. `Mountable` and `Bootable`. These blocks are stored without any hierarchical structure or metadata about the file they belong to. The operating system (OS) or a specialized application manages these blocks, piecing them together to form files


(+) `File Storage` - Presented as a file share has structure, `mountable` `not bootable`. This methods organizes data in a hierarchical manner that is familiar to any computer user: files in folders, inside other folders. This structure includes metadata at the file level, such as the file name, creation date, and permission.
==> File server, file system with folder structure, that we can browse to it, locating the file and use it. 


(+) `Object Storage` - collection of objects, flat. `Not mountable` and `Not bootable`. Each object consists of the data itself, a flexible amount of metadata, and a globally unique identifier. Unlike the rigid hierarchy of file storage, object storage has a flat address space. This means objects are not organized in folders but are retrieved using their unique ID.

##### 2.1 Mountable? Bootable? What is it?
(+) The difference between these type of storage is their tiers and their use cases:

###### For Block Storage
**1. How it's Bootable (The Pre-Boot Stage)**
When you press the power button, your computer's firmware (BIOS/UEFI) wakes up. The firmware is very primitive; it doesn't have drivers for networking, sound, or complex devices. Its primary job is to initialize the hardware and find a bootloader to start the Operating System.

- **Low-Level Access:** Block storage presents itself to the firmware as a raw, simple device—a sequential series of data blocks. It speaks the most basic language of storage that the firmware can understand.
- **The Boot Process:** The firmware is programmed to scan these raw block devices (your SSD, HDD). It looks at a specific, standardized location—the Master Boot Record (MBR) or the EFI System Partition (ESP). It finds the bootloader code in that location and executes it. This bootloader then takes over and loads the rest of the Operating System (which is also stored on the same block device).

Because block storage is exposed at this fundamental, low level, the primitive firmware can access it directly to "bootstrap" the entire system.

**2. How it's Muntable (The Post-Boot Stage)**
Once the Operating System (like Windows or Linux) is running, it's far more sophisticated than the firmware.

- **OS Control:** The OS loads its own drivers to communicate with the block device. It can see the device as a volume (e.g., `/dev/sdb1` in Linux or `Disk 1` in Windows).
- **Applying a File System:** The `mount` command tells the OS: "Take this block volume, use the NTFS (or ext4, etc.) file system driver to interpret the data on it, and make it accessible at this location (e.g., the `D:` drive or the `/data` directory)."

So, block storage can be **booted** because the firmware can see it, and it can be **mounted** because the fully-loaded OS can see it.

###### For File Storage
**1. Why it's NOT Bootable (The Pre-Boot Stage)**
File storage (like a Network Attached Storage, or NAS) does not present raw blocks to a computer. It presents a fully formed file system over a network connection.

- **High-Level Abstraction:** It communicates using network protocols like SMB (for Windows) or NFS (for Linux). It doesn't say "here are blocks 1 through 1 million"; it says "here is a folder named 'Documents' containing a file named 'report.docx'."
- **The Firmware Barrier:** Your computer's firmware **does not have a network card driver, a TCP/IP stack, or an SMB/NFS client.** It's too basic. It cannot connect to a network, log in to a share, and navigate a folder structure to find the bootloader. The very protocols that make file storage easy for an OS to use make it invisible and inaccessible to the firmware.

Because the firmware can't see or speak the language of file storage, it's impossible to boot from it directly.

**2. Why it IS Mountable (The Post-Boot Stage)**
This picture changes completely once the Operating System is running.

- **OS Has the Tools:** Your running OS has a full networking stack and the client software needed to speak SMB or NFS.
- **The Mount Process:** The `mount` command now tells the OS: "Connect to the server at this IP address (`192.168.1.10`), log in with these credentials, access the share named `//NAS/Public`, and make its contents appear in the `/mnt/nas` directory."

The OS handles all the complex network communication and presents the remote folder structure as if it were a local part of the computer's file system. This happens long after the system has booted using a local block device.

###### Object Storage
**1. Why Object Storage is NOT Bootable**
This is for the same fundamental reason that file storage isn't bootable, but even more so.

- **Access Method is an API:** Object storage isn't accessed like a disk or a network share. It's accessed like a web service, using programmatic commands over the internet via an **HTTP RESTful API**. Common commands are `GET` (to retrieve an object), `PUT` (to upload an object), and `DELETE`.
- **The Firmware Can't Make API Calls:** Your computer's basic firmware (BIOS/UEFI) is extremely primitive. It has no concept of TCP/IP, DNS, or HTTP. It cannot form an HTTP `GET` request, send it to a web endpoint, and process the response to find a bootloader. It's designed to scan for simple, low-level block devices, and an object store is completely invisible to it.

**2. Why Object Storage is NOT Mountable (Natively)**
While block storage is a blank canvas and file storage is a structured filing cabinet, object storage is like a massive valet parking service or a coat check.

- **Flat Namespace (No Folders):** Object storage has a **flat data structure**. All objects live in a single, massive pool called a "bucket." There is no inherent hierarchy of folders or directories. You don't find an object by navigating a path like `C:\Users\Photos\cat.jpg`. Instead, you give the valet your unique ticket ID (`cat.jpg`), and they retrieve your object from the vast parking lot (the bucket). This flat model is fundamentally incompatible with the hierarchical directory tree that operating systems are built on.
- **High Latency and Different Operations:** A traditional mounted file system expects to be able to perform operations like modifying a tiny piece of a file in the middle (a random write) very quickly. Object storage is not designed for this. **Objects are immutable**, meaning to change even one byte of a 10 GB object, you must upload a completely new 10 GB version of that object. This would be catastrophically slow and inefficient for normal applications that expect a mounted drive.
- **It's a Database, Not a File System:** It's more accurate to think of object storage as a simple key-value database. The "key" is the object's unique ID, and the "value" is the data itself plus its metadata. An OS doesn't know how to "mount" a database as a drive.

###### 3. Storage Performance
![[Pasted image 20240109125646.png]]

(+) `IO or block size`: the block size specifies the amount of data transferred at once between the volume and the instance attached to it. EBS supports 4 different block sizes: 1KiB, 4KiB, 8KiB, and 32 KiB.
(+) `Input/Output Operation Per Second (IOPS)`: refers to the number of read/wrtie requests a particular storage device can handle concurrently.
(+) `Throughput`: While `IOPS` determine how quickly individual operations occur, throughput describes the total rate at which data moves across the storage interface.
(+) `Latency`: Delay between request and completion (ms)
(+) `Capacity`: Volume of data that can be stored (GB)
