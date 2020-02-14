#additional packages to include in our Toradex images

# Copy Licenses to image /usr/share/common-licenses, on vybrid for flash size reasons only the manifest
COPY_LIC_MANIFEST = "1"
#Bug with several MACHINES build, license files for all arch packages stored wrongly
COPY_LIC_DIRS = "0"
COPY_LIC_DIRS_colibri-vf = "0"

#build some ipk which are needed together with CAN, but do not yet install them
DEPENDS += "canutils libsocketcan iproute2"

#the following builds cross gdb and gdbserver
DEPENDS += "gdb-cross-${TARGET_ARCH}"

#create the file /etc/timestamp
IMAGE_PREPROCESS_COMMAND = "rootfs_update_timestamp"

# Removed
#     canutils \
#

IMAGE_INSTALL_append_colibri-vf-1345 = " \
    u-boot-toradex-fsl-fw-utils \
    ptpd \
    iproute2 \
    mtd-utils-ubifs \
    kernel-modules \
    usb-suspend-resume \
"

# Removed
#
#    libusbg \
#    crda \
#    \
#    alsa-utils \
#    alsa-utils-aplay \
#    alsa-utils-amixer \
#    sqlite3 \
#    \
#    joe \
#    minicom \
#    rt-tests \
#    tdx-oak-sensors \
#

IMAGE_INSTALL += " \
    linux-firmware-ralink \
    linux-firmware-rtl8192cu \
    \
    curl \
    nfs-utils-client \
    openssh-scp \
    openssh-sftp \
    \
    bzip2 \
    gdbserver \
    grep \
    ldd \
    lsof \
    mtd-utils \
    dosfstools \
    util-linux-fstrim \
    \
    devmem2 \
    evtest \
    hdparm \
    iperf \
    i2c-tools \
    memtester \
    stress \
    lmbench \
    nbench-byte \
    tinymembench \
    ethtool \
    \
    eject \
    usb-modeswitch \
    usb-modeswitch-data \
    \
"
