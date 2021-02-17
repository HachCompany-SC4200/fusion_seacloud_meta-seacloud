DESCRIPTION = "fcc crypto service"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit systemd

RDEPENDS_${PN} = "ecryptfs-utils garbage-collector "

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += " \
	file://fcc-crypto.sh \
	file://ecryptfs-mount.sh \
	file://fcc-crypto.service \
"

do_install () {
	install -d 440 ${D}${sysconfdir}/
	install -d 440 ${D}${systemd_unitdir}/system/
	install -m 550 ${WORKDIR}/fcc-crypto.sh ${D}${sysconfdir}/
	install -m 550 ${WORKDIR}/ecryptfs-mount.sh ${D}${sysconfdir}/
	install -m 440 ${WORKDIR}/fcc-crypto.service ${D}${systemd_unitdir}/system/
}

FILES_${PN} += "{sysconfdir} ${systemd_unitdir}"
