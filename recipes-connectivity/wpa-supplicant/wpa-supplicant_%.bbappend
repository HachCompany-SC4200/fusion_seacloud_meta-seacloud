FILESEXTRAPATHS_prepend := "${THISDIR}/wpa-supplicant:"

SRC_URI_append = "\
	file://defconfig \
	"
