#create the deployment directory-tree

BURNFLASH := "${THISDIR}/files/${MACHINE}"
IMAGE_DIR = "${IMAGE_NAME}_${PV}"
IMAGE_ROOTFS = "${WORKDIR}/${IMAGE_DIR}/rootfs"

SEACLOUD_APPFS_FOLDER = "appfs"

U_BOOT_EXT = "bin"
U_BOOT_EXT_vf = "imx"
U_BOOT_SYMLINK = "u-boot-${MACHINE}.${U_BOOT_EXT}"
U_BOOT_BINARY = "u-boot.${U_BOOT_EXT}"

#we need some native tools for deployment
DEPENDS_append_vf = " mtd-utils-native imx-loader-native"
#we need mkimage to produce the U-Boot scripts even if not building a uImage kernel
DEPENDS_append = " virtual/bootloader u-boot-mkimage-native"

imagedeploytools() {
    # default to nothing to deploy
    :
}

imagedeploytools_append_vf() {
    IMAGE_ROOT="${IMAGE_ROOTFS}/../vf_flash/"
    rm -f ${IMAGE_ROOT}/mkfs.ubifs  ${IMAGE_ROOT}/imx_uart
    mkdir -p ${IMAGE_ROOT}

    # add the mkfs.ubifs binary
    cp ${STAGING_DIR_NATIVE}/usr/sbin/mkfs.ubifs ${IMAGE_ROOT}/
    ${BUILD_STRIP} ${IMAGE_ROOT}/mkfs.ubifs

    # add imx-loader and its configuration files
    cp ${STAGING_BINDIR_NATIVE}/imx_uart ${IMAGE_ROOT}/
    ${BUILD_STRIP} ${IMAGE_ROOT}/imx_uart*
    cp ${STAGING_ETCDIR_NATIVE}/imx-loader.d/vybrid_usb_work.conf ${IMAGE_ROOT}/
}

imagedeploy_kernel() {
    # put kernel, device-tree into the bin directories, remove the kernel/dtb from the rootfs/boot
    rm -f ${IMAGE_ROOTFS}/boot/${KERNEL_IMAGETYPE}* ${IMAGE_ROOTFS}/boot/*.dtb
    cp -pP ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}* ${IMAGE_ROOTFS}/../${MACHINE}_bin/
    ls ${DEPLOY_DIR_IMAGE}/*.dtb 2> /dev/null && cp -pP ${DEPLOY_DIR_IMAGE}/*.dtb ${IMAGE_ROOTFS}/../${MACHINE}_bin/
    mv ${IMAGE_ROOTFS}/../${MACHINE}_bin/${KERNEL_IMAGETYPE}-${MACHINE}.bin ${IMAGE_ROOTFS}/../${MACHINE}_bin/${KERNEL_IMAGETYPE}
}

imagedeploy_kernel_vf() {
    # put kernel, device-tree into the bin directories
    cp -pP ${DEPLOY_DIR_IMAGE}/zImage* ${IMAGE_ROOTFS}/../${MACHINE}_bin/
    ls ${DEPLOY_DIR_IMAGE}/*.dtb 2> /dev/null && cp -pP ${DEPLOY_DIR_IMAGE}/*.dtb ${IMAGE_ROOTFS}/../${MACHINE}_bin/
    mv ${IMAGE_ROOTFS}/../${MACHINE}_bin/zImage-${MACHINE}.bin ${IMAGE_ROOTFS}/../${MACHINE}_bin/zImage   
}

imagedeploy_appfs() {
   # create a appfs folder
   mkdir -p ${IMAGE_DIR}/${SEACLOUD_APPFS_FOLDER}
}

fakeroot do_imagedeploy() {
    cd ${WORKDIR}
    cp -Lr ${BURNFLASH}/* ${IMAGE_DIR}/

    cd ${IMAGE_DIR}/${MACHINE}_bin
    ./mk-u-boot-scripts.sh
    cd ${WORKDIR}

    # deploy the appfs folder
    imagedeploy_appfs

    imagedeploy_kernel

    cp -pP ${DEPLOY_DIR_IMAGE}/u-boot* ${IMAGE_ROOTFS}/../${MACHINE}_bin/
    rm -f ${IMAGE_ROOTFS}/../${MACHINE}_bin/u-boot-hsmmc-${MACHINE}.${U_BOOT_EXT}
    mv ${IMAGE_ROOTFS}/../${MACHINE}_bin/${U_BOOT_SYMLINK} ${IMAGE_ROOTFS}/../${MACHINE}_bin/${U_BOOT_BINARY}

    # add the rootfs version to the welcome banner
    echo "${IMAGE_DIR}_${DATE}" >> ${IMAGE_ROOTFS}/etc/issue
    echo "" >> ${IMAGE_ROOTFS}/etc/issue

    # add additional tools if required
    imagedeploytools    

    # remove intermediate file rootfs.lock
    rm -f ${IMAGE_DIR}/rootfs.lock

    #create tarball
    DATE=`date +%Y%m%d`

    set +e
    echo "List processes"
    ps aux
    echo "Openned files before"
    lsof | grep ${IMAGE_DIR}
    echo "List files access, change, modified time before"
    find ${IMAGE_DIR} -exec stat -c %x,%z,%y,%n {} \;

    echo "Generate archive"
    tar -cjvf ${DEPLOY_DIR_IMAGE}/${IMAGE_DIR}_${DATE}.tar.bz2 ${IMAGE_DIR}
    result=$?

    echo "Openned files after"
    lsof | grep ${IMAGE_DIR}
    echo "List processes after"
    ps aux
    echo "List files access, change, modified time after"
    find ${IMAGE_DIR} -exec stat -c %x,%z,%y,%n {} \;

    [ "$result" -ne "0" ] && exit 1
    set -e

    ln -fs ${IMAGE_DIR}_${DATE}.tar.bz2 ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}
}

addtask imagedeploy after do_rootfs before do_build
