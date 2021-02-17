DESCRIPTION = "Garbage Collector service"
LICENSE = "CLOSED"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += " \
	file://${PN}.sh \
	file://${PN}.service \
	file://${PN}.timer \
"

inherit systemd

do_install () {
	install -d 440 ${D}/bin/
	install -d 440 ${D}${systemd_unitdir}/system/
	install -m 550 ${WORKDIR}/${PN}.sh ${D}/bin/
	install -m 440 ${WORKDIR}/${PN}.service ${D}${systemd_unitdir}/system/
	install -m 440 ${WORKDIR}/${PN}.timer ${D}${systemd_unitdir}/system/
}

FILES_${PN} += "${systemd_unitdir}"
