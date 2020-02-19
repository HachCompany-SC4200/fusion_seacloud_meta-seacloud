SUMMARY = "Image booting to a console"

LICENSE = "MIT"

PV = "V2.7"

#start of the resulting deployable tarball name
export IMAGE_BASENAME = "console-seacloud-image"
IMAGE_NAME_colibri-vf = "Colibri_VF_LinuxConsoleImage"
# VF is needed in the name, otherwise update.sh script has to be updated
IMAGE_NAME_colibri-vf-1345 = "Colibri_VF_LinuxSeaCloudImage"
IMAGE_NAME = "${MACHINE}_LinuxConsoleImage"


#create the deployment directory-tree
require recipes/images/seacloud-image-fstype.inc

#remove interfering sysv scripts, connman systemd service
do_mkrmscript () {
    echo "for i in ${IMAGE_ROOTFS}/etc/rc0.d ${IMAGE_ROOTFS}/etc/rc1.d ${IMAGE_ROOTFS}/etc/rc2.d ${IMAGE_ROOTFS}/etc/rc3.d ${IMAGE_ROOTFS}/etc/rc4.d ${IMAGE_ROOTFS}/etc/rc5.d ${IMAGE_ROOTFS}/etc/rc6.d ${IMAGE_ROOTFS}/etc/rcS.d ; do" > ${WORKDIR}/rmscript
    echo "    rm -f \$i/*dropbear \$i/*avahi-daemon \$i/*dbus-1 \$i/*lxdm \$i/*ntpd \$i/*syslog \$i/*ofono \$i/*alsa-state \$i/*networking \$i/*udev-late-mount \$i/*sendsigs \$i/*save-rtc.sh \$i/*umountnfs.sh \$i/*portmap \$i/*umountfs \$i/*halt \$i/*rmnologin.sh \$i/*reboot; rm -f \$i/*banner.sh \$i/*sysfs.sh \$i/*checkroot.sh \$i/*alignment.sh \$i/*mountall.sh \$i/*populate-volatile.sh \$i/*devpts.sh \$i/*hostname.sh \$i/*portmap \$i/*mountnfs.sh \$i/*bootmisc.sh" >> ${WORKDIR}/rmscript
    echo "done" >> ${WORKDIR}/rmscript
    chmod +x ${WORKDIR}/rmscript
    readlink -e ${WORKDIR}/rmscript
    cat ${WORKDIR}/rmscript
}
addtask mkrmscript before do_rootfs

IMAGE_LINGUAS = "en-us"
#IMAGE_LINGUAS = "de-de fr-fr en-gb en-us pt-br es-es kn-in ml-in ta-in"
#ROOTFS_POSTPROCESS_COMMAND += 'install_linguas; '

DISTRO_UPDATE_ALTERNATIVES ??= ""
ROOTFS_PKGMANAGE_PKGS ?= '${@base_conditional("ONLINE_PACKAGE_MANAGEMENT", "none", "", "${ROOTFS_PKGMANAGE} ${DISTRO_UPDATE_ALTERNATIVES}", d)}'

CONMANPKGS ?= "connman connman-systemd connman-plugin-loopback connman-plugin-ethernet connman-plugin-wifi connman-client"
CONMANPKGS_libc-uclibc = ""

#don't install some id databases
#BAD_RECOMMENDATIONS_append_colibri-vf += " udev-hwdb cpufrequtils "

IMAGE_INSTALL += " \
    angstrom-packagegroup-boot \
    packagegroup-basic \
    udev-extra-rules \
    ${CONMANPKGS} \
    ${ROOTFS_PKGMANAGE_PKGS} \
    timestamp-service \
    packagegroup-base-extended \
    python-ctypes \
    python-subprocess \
    python-pyudev \
    python-enum34 \
    python-shell \
    python-pyserial \
    python-json \
    python-ipaddress \
    python-multiprocessing \
    python-netifaces \
    boost \
    ofono \
    openvpn \
    wt \
    sudo \
    libavahi-compat-libdnssd \
"

require recipes/images/seacloud-extra.inc

IMAGE_DEV_MANAGER   = "udev"
IMAGE_INIT_MANAGER  = "systemd"
IMAGE_INITSCRIPTS   = " "
IMAGE_LOGIN_MANAGER = "busybox shadow"

# To have the wt static dev package into the SDK
TOOLCHAIN_TARGET_TASK_append = " wt-staticdev uamqp-staticdev"

inherit image extrausers

# Add a user for the system
EXTRA_USERS_PARAMS = "\
	useradd -P 1234 rnd; \
"


