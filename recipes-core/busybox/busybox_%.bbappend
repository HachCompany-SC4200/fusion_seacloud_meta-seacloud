FILESEXTRAPATHS_prepend := "${THISDIR}/busybox:"

SRC_URI_append = "\
	file://timeout.cfg \
	"
