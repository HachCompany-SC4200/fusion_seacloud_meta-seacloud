DESCRIPTION = "Seacloud application" 
SECTION = "apps" 
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

SRC_URI = "git://git@stash.hach.ewqg.com:7999/fcfw/fusion_fw_common.git;protocol=ssh;branch=master \
	   file://YOCTO.patch"
SRCREV = "00020497a90cef0b406edaab51c7d81fcf1933f3"

S = "${WORKDIR}/git"

DEPENDS = "uamqp curl"

# FCC doesn't support parallel build
PARALLEL_MAKE = ""

do_compile() {
	cd fusion_fw
	make ARCH=YOCTO ROOTFSTOP=${STAGING_DIR_HOST} TARGET=SEACLOUD VERBOSE=Y all
}

prefix="/usr/local"
exec_prefix="/usr/local"

do_install() {
	install -d ${D}/usr/local/bin
	install -d ${D}/usr/local/lib
	install -m 0755 fusion_fw/bin/* ${D}/usr/local/bin/
	install -m 0755 fusion_fw/lib/* ${D}/usr/local/lib/
}

FILES_${PN} += "/usr/local/lib/* \
                /usr/local/bin/* "

FILES_${PN}-dbg += "/usr/local/bin/.debug/* \
                    /usr/local/lib/.debug/* "

