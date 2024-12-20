#!/bin/bash
# ----------------------------------
# Colors
# ----------------------------------
NOCOLOR='\033[0m'
LIGHTBLUE='\033[1;34m'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

BOOT_BIN=/usr/bin/qemu-system-x86_64
NETNAME=ubuntu
HOSTNAME=${NETNAME}
MEM=8G
DP=gtk,gl=on,grab-on-hover=on
MTYPE=q35,usb=off,dump-guest-core=off,pflash0=libvirt-pflash0-format,pflash1=libvirt-pflash1-format,mem-merge=on,smm=on,vmport=off,nvdimm=off,hmat=on,memory-backend=mem1
ACCEL=accel=kvm,kvm-shadow-mem=256000000,kernel_irqchip=on
UUID="$(uuidgen)"
CPU=4,sockets=4,cores=1,threads=1

args=(
	-uuid ${UUID}
	-name ${NETNAME},process=${NETNAME}
	-no-user-config
	-cpu host,vmx=on,hypervisor=on,hv-time=on,hv-relaxed=on,hv-vapic=on,hv-spinlocks=0x1fff,hv-vendor-id=1234567890,kvm=on
	-smp ${CPU}
	-m ${MEM}
	-blockdev '{"driver":"file","filename":"'$SCRIPT_DIR'/OVMF_CODE_4M.fd","node-name":"libvirt-pflash0-storage","auto-read-only":true,"discard":"unmap"}'
	-blockdev '{"node-name":"libvirt-pflash0-format","read-only":true,"driver":"raw","file":"libvirt-pflash0-storage"}'
	-blockdev '{"driver":"file","filename":"'$SCRIPT_DIR'/ubuntu-24-04-base_VARS.fd","node-name":"libvirt-pflash1-storage","auto-read-only":true,"discard":"unmap"}'
	-blockdev '{"node-name":"libvirt-pflash1-format","read-only":false,"driver":"raw","file":"libvirt-pflash1-storage"}'
	-machine ${MTYPE},${ACCEL}
	-mem-prealloc
	-rtc base=localtime
	-drive file=ubuntu-24-04-base.qcow2,if=virtio,format=qcow2,cache=writeback
	-enable-kvm
	-object memory-backend-memfd,id=mem1,share=on,size=${MEM}
	-overcommit mem-lock=off
	-object rng-random,id=objrng0,filename=/dev/urandom
	-device virtio-rng-pci,rng=objrng0,id=rng0
	-device virtio-serial-pci

  -device qxl-vga
  -global qxl-vga.ram_size=4194304 -global qxl-vga.vram_size=4194304 -global qxl-vga.vgamem_mb=4096
  -spice agent-mouse=off,addr=/tmp/${NETNAME}/spice.sock,unix=on,disable-ticketing=on,rendernode=${NV_RENDER}

	-usb
	-device usb-tablet
	-monitor stdio
	-k de
	-global ICH9-LPC.disable_s3=1
	-global ICH9-LPC.disable_s4=1
	-device ide-cd,bus=ide.0,id=sata0-0-0
	-device virtio-serial-pci

  -device virtio-serial
	-chardev socket,path=/tmp/qga.sock,server=on,wait=off,id=qga0
	-device virtserialport,chardev=qga0,name=org.qemu.guest_agent.0
	-chardev spicevmc,id=ch1,name=vdagent,clipboard=on
	-device virtserialport,chardev=ch1,id=ch1,name=com.redhat.spice.0

  # add ivshmem for shared memory
	-device ivshmem-plain,memdev=ivshmem
	-object memory-backend-file,id=ivshmem,share=on,mem-path=/dev/shm/ivshmem,id=ivshmem,size=64M

	-device ich9-intel-hda,id=sound0,bus=pcie.0,addr=0x1b
	-device hda-duplex,id=sound0-codec0,bus=sound0.0,cad=0
	-global ICH9-LPC.disable_s3=1 -global ICH9-LPC.disable_s4=1
  -netdev bridge,id=hn0,br=virbr0
	-device virtio-net-pci,netdev=hn0,id=nic1,mac=e6:c8:ff:09:76:9b
  
	-chardev pty,id=charserial0
	-device isa-serial,chardev=charserial0,id=serial0
	-chardev null,id=chrtpm
	-chardev socket,id=char0,path=/tmp/vhostqemu_ubuntu_24_04_base
	-device vhost-user-fs-pci,queue-size=1024,chardev=char0,tag=host_downloads
	-msg timestamp=on
)

# check if the bridge is up, if not, dont let us pass here
# if [[ $(ip -br l | awk '$1 !~ "lo|vir|wl" { print $1 }') != *tap0-${NETNAME}* ]]; then
#     echo "bridge is not running, please start bridge interface"
#     exit 1
# fi

#create tmp dir if not exists
if [ ! -d "/tmp/${NETNAME}" ]; then
	mkdir /tmp/${NETNAME}
fi

echo -e "${LIGHTBLUE}Start VirtioFS Daemon virtiofsd for sharing Downloads directory ...${NOCOLOR}"
sudo rm /tmp/vhostqemu_ubuntu_24_04_base
sudo /usr/lib/qemu/virtiofsd --socket-path=/tmp/vhostqemu_ubuntu_24_04_base --socket-group=${USER} -o source=${HOME}/Downloads/ -o allow_direct_io -o cache=always &

# Kill all sockets
rm -rf "${NETNAME}-agent.sock"

echo -e "${LIGHTBLUE}Start the VM using QEMU ...${NOCOLOR}"
echo ${BOOT_BIN} "${args[@]}"
GDK_SCALE=1 GTK_BACKEND=x11 GDK_BACKEND=x11 QT_BACKEND=x11 VDPAU_DRIVER="nvidia" ${BOOT_BIN} "${args[@]}"

exit 0
