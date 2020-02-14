FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://0001-Customized-version.patch \
	    file://0001-service-Use-PreferredTechnologies-for-service-orderi.patch \
	    file://0001-service-Add-EnableOnlineCheck-config-option.patch \
	    file://0001-service-Fix-loose-mode-routing-not-enabled-with-Enab.patch \
	    file://0001-Add-command-line-option-to-exclude-192.168.X.X-IP-ra.patch \
	    file://0001-Restricted-DHCP-range-skip-192.168.X.X-is-the-defaul.patch \
	    file://0001-Enable-roaming-Telenor.patch \
	    file://0001-Set-DHCP-lease-time-to-2-minutes.patch \
	   "


do_install_append() {
	# install sea cloud configuration file for connman 
	install -d ${D}${sysconfdir}/${BPN}/
}
