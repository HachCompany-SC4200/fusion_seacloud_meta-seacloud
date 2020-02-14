DESCRIPTION = "Telit Ofono library customization" 
SECTION = "libs" 
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""
PR = "r0" 

require ofono.inc

DEPENDS += "python python-pygobject python-dbus"

SRC_URI = " file://ofono.service \
            file://ofono.sh \
	        file://ofono-1.18_R5.00.02.B3.tar.gz \
	        file://test-python2.tar.bz2 \
            file://0001-Put-struct-definitions-before-using-them.patch \
            file://0002-fix-for-USB-descriptors.patch \
            file://0003-Change-Ofono-version-to-include-fix-USB-descriptor.patch \
           "

S = "${WORKDIR}/ofono-5584e21/"

CFLAGS_append_libc-uclibc = " -D_GNU_SOURCE"

do_install_append() {
   	# Replace the file ofono.service which has been automatically generated by our custom ofono.service
   	cp ${WORKDIR}/ofono.service ${D}${systemd_unitdir}/system/
	# Add ofono.sh
   	cp ${WORKDIR}/ofono.sh ${D}${systemd_unitdir}/system/
	# Add ofono test using python 2.7 because python3 is not fully available for our architecture
	install -d ${D}${libdir}/${BPN}/test 
	cp ${WORKDIR}/test-python2/* ${D}${libdir}/${BPN}/test
}

FILES_${PN} += "${libdir}/*"

# duplicated form ofono.inc. Remove it when python3 will be available and ofono test files will be included by ofono.inc
RDEPENDS_${PN} += "python python-pygobject python-dbus"
