FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://main.conf.reference \
	    file://0001-Customized-version.patch \
	    file://0001-service-Use-PreferredTechnologies-for-service-orderi.patch \
	    file://0001-service-Add-EnableOnlineCheck-config-option.patch \
	    file://0001-service-Fix-loose-mode-routing-not-enabled-with-Enab.patch \
	   "


do_install_append() {
	# install sea cloud configuration file for connman 
	install -d ${D}${sysconfdir}/${BPN}/
	install -m 0644 ${WORKDIR}/main.conf.reference ${D}${sysconfdir}/${BPN}/main.conf
}
