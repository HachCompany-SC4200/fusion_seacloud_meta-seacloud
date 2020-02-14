DESCRIPTION = "uAMQP library" 
SECTION = "libs" 
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""
PR = "r0" 

DEPENDS = " openssl util-linux"

SRC_URI = "file://azure-uamqp-c-87c15855ef9b64b20ce3d94a9cd02717ea8c04d6.tar.gz "

S = "${WORKDIR}/azure-uamqp-c-87c15855ef9b64b20ce3d94a9cd02717ea8c04d6/"

inherit autotools cmake pkgconfig pythonnative

EXTRA_OECMAKE = "-Dmemory_trace:BOOL=ON -Duse_condition:STRING=ON -Duse_wsio:BOOL=OFF -Dskip_unittests:BOOL=ON -Duse_openssl:STRING=ON  -DBUILD_TESTING:BOOL=OFF -Duse_schannel:bool=OFF -Duse_wolfssl:bool=OFF -Duse_http:bool=OFF -DCMAKE_BUILD_TYPE:STRING=Debug"

TARGET_CFLAGS += "-fPIC"

#RM_WORK_EXCLUDE += " amqp"

do_install (){
        autotools_do_install
        install ${S}/../build/libuamqp.a ${D}/${libdir}
# The following lines have been added to put the header files in the same folders as FPM did
        mkdir ${D}/${includedir}/azure_uamqp_c
        install ${S}/inc/azure_uamqp_c/* ${D}/${includedir}/azure_uamqp_c
        mv ${D}/${includedir}/azureiot/azure_c_shared_utility ${D}/${includedir}/
        rm -r ${D}/${includedir}/azureiot/
}

FILES_${PN} += "${libdir}/*"
FILES_${PN}-dev += "${includedir}/*"
PACKAGES = "${PN} ${PN}-dev"

