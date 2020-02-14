DESCRIPTION = "Telit Ofono library customization"
SECTION = "libs"
LICENSE = "CLOSED"
# LIC_FILES_CHKSUM = ""

PR = "hach"
PV = "1.23+git${SRCPV}"

require ofono.inc

DEPENDS += "python python-pygobject python-dbus"

#!!!!! This version has to be updated if a new commit on fusion_seacloud_ofono.git is done !!!!!
BRANCH = "github_publication_SC4200"
SRCREV="c1c884027fe9ed5625408280153582c80edbc211"

SRC_URI = "\
    git://github.com/HachCompany-SC4200/fusion_seacloud_ofono.git;branch=${BRANCH} \
    file://ofono-git-version.patch \
	file://ofono.service \
	file://ofono.sh \
	file://test-python2.tar.bz2 \
"

S = "${WORKDIR}/git/"

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
