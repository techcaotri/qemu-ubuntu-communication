# Working environment for QEMU VMs with shared virtual bridge interface `virbr0` and `ivshmem` Shared Memory

## Preparation steps:
+ Clone the image `ubuntu-24-04-base.qcow2` to `ubuntu-24-04-base_2.qcow2`
+ Username and password for all the VMs is `user/user`

## Running steps:
1. Run the first VM 
   1. Execute: `ubuntu-24-04-base.sh`
   2. Run `remote-viewer.sh` script to start the remote display session or connect to the running VM via `ssh`
2. Run the second VM 
   1. Execute: `ubuntu-24-04-base_2.sh`
   2. Run `remote-viewer_2.sh` script to start the remote display session or connect to the running VM via `ssh`
3. Switch to the first VM to build and run the [`ivshmem-sample`](https://github.com/techcaotri/ivshmem-sample)
   1. Build from source: `~/Dev/ivshmem-sample/build.sh`
   2. Run the sample: `remote-viewer_2.sh`
   3. The output running `ivshmem-sample` on the first VM should look like:
   ```
    user@user-Standard-PC-Q35-ICH9-2009:~/Dev/ivshmem-sample$ ./run.sh 
    sudo ./build/ivshmem_read_write
    [sudo] password for user: 
    Checkpoint: mmap successful
    Case 2: Written to shmem - 'Other VM says Hello!'; run this program again on another VM
   ```
4. Switch to the second VM to build and run the [`ivshmem-sample`](https://github.com/techcaotri/ivshmem-sample)
   1. Build from source: `~/Dev/ivshmem-sample/build.sh`
   2. Run the sample: `remote-viewer_2.sh`
   3. The output running `ivshmem-sample` on the first VM should look like:
   ```
    user@user-Standard-PC-Q35-ICH9-2009:~/Dev/ivshmem-sample$ ./run.sh 
    sudo ./build/ivshmem_read_write
    [sudo] password for user: 
    Checkpoint: mmap successful
    Case 1: Read from shmem - 'Other VM says Hello!'
   ```

## Note: You might need to setup `virbr0` bridge and corresponding permissions to run the VMs
