#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

from extract_utils.fixups_blob import (
    blob_fixup,
    blob_fixups_user_type,
)
from extract_utils.fixups_lib import (
    lib_fixups,
    lib_fixups_user_type,
)
from extract_utils.main import (
    ExtractUtils,
    ExtractUtilsModule,
)

namespace_imports = [
    'hardware/oplus',
    'hardware/qcom-caf/sm8850',
    'vendor/oneplus/sm8850-common',
    'vendor/qcom/opensource/commonsys-intf/display',
]

lib_fixups: lib_fixups_user_type = {
    **lib_fixups,
}

# lafa and OnePlus 15 are the same OPPO SM8850 platform and share the whole
# vendor/odm HAL set, so this list is ported from
# device/oneplus/infiniti/extract-files.py. Every entry was re-verified against
# lafa's own blobs rather than copied blind - see the per-entry notes.
blob_fixups: blob_fixups_user_type = {
    'odm/etc/camera/CameraHWConfiguration.config': blob_fixup()
        # Disable face detection AE behaviour
        .regex_replace(r'(enableSWfdForThirdCamUnit += )TRUE', r'\1FALSE')
        .regex_replace(r'(fdSupport += )TRUE;', r'\1FALSE;'),
    'odm/etc/init/init.camera_process.rc': blob_fixup()
        # AOSP init has no delete_recursion keyword; host_init_verifier rejects
        # the script outright ("Invalid keyword 'delete_recursion'").
        .regex_replace('    delete_recursion', '    #delete_recursion'),
    (
        'odm/etc/libnfc-mtp-SN220.conf_24831',
        'odm/etc/libnfc-mtp-SN220.conf_24863',
        # lafa's own project ids - see the NFC note in proprietary-files.txt
        'odm/etc/libnfc-mtp-SN220.conf_24624',
        'odm/etc/libnfc-mtp-SN220.conf_24776',
    ): blob_fixup()
        .regex_replace('(NXPLOG_.*_LOGLEVEL)=0x03', '\\1=0x02')
        .regex_replace('NFC_DEBUG_ENABLED=1', 'NFC_DEBUG_ENABLED=0'),
    'vendor/etc/libnfc-nci.conf': blob_fixup()
        .regex_replace('NFC_DEBUG_ENABLED=1', 'NFC_DEBUG_ENABLED=0'),
    # These reference android.hardware.graphics.common-V5-ndk, while
    # android.hardware.graphics.composer3-V3-ndk (built by the platform)
    # re-exports V7. Soong refuses a module whose dependency graph reaches two
    # versions of the same aidl_interface.
    (
        'odm/lib64/libAlgoProcess.so',
        'odm/lib64/libpwirishalwrapper.so',
    ): blob_fixup()
        .replace_needed('android.hardware.graphics.common-V5-ndk.so', 'android.hardware.graphics.common-V7-ndk.so'),
    # Same class of problem for the graphics allocator: these two reference
    # allocator-V1 while libgralloccore/libgrallocutils pull in allocator-V2.
    (
        'vendor/lib64/camera/components/com.qti.node.dewarp.so',
        'vendor/lib64/vendor.qti.hardware.camera.offlinecamera-service-impl.so',
    ): blob_fixup()
        .replace_needed('android.hardware.graphics.allocator-V1-ndk.so', 'android.hardware.graphics.allocator-V2-ndk.so'),
    # LineageOS ships the VNDK v36 compat prebuilt as libtinyxml2-v36
    # (hardware/lineage/compat/Android.bp); the plain libtinyxml2 has a newer
    # ABI. Verified with readelf that these three really need it.
    (
        'vendor/lib64/camera/components/com.qti.node.fd.so',
        'vendor/lib64/hw/camera.qcom.core.so',
        'vendor/lib64/libcamxdumpinforecorder.so',
    ): blob_fixup()
        .replace_needed('libtinyxml2.so', 'libtinyxml2-v36.so'),
    # These carry versioned AHardwareBuffer_* references against the platform
    # libandroid, which a vendor module cannot link against. Dropping the version
    # suffix lets them bind to the NDK export instead.
    # List verified against lafa's own blobs with
    #   readelf --dyn-syms -W | grep 'AHardwareBuffer_.*@'
    # - it is NOT the same set as OnePlus 15's: lafa's libAlgoProcess and
    # libaiboost_te carry no versioned AHardwareBuffer symbols, and lafa's
    # liboprec_audrec does not need the libstdc++ -> libstdc++_vendor rename.
    (
        'odm/lib64/libEIS.so',
        'odm/lib64/libEISLive.so',
        'odm/lib64/libFaceBeautyJni.so',
        'odm/lib64/libFaceDistortionCorrection.so',
        'odm/lib64/libOPAlgoCamAiBeautyFaceRetouchCn.so',
        'odm/lib64/libOPAlgoCamAiUnifySkin.so',
        'odm/lib64/libOPAlgoCamFaceBeautyCap.so',
    ): blob_fixup()
        .clear_symbol_version('AHardwareBuffer_acquire')
        .clear_symbol_version('AHardwareBuffer_allocate')
        .clear_symbol_version('AHardwareBuffer_describe')
        .clear_symbol_version('AHardwareBuffer_lock')
        .clear_symbol_version('AHardwareBuffer_lockPlanes')
        .clear_symbol_version('AHardwareBuffer_release')
        .clear_symbol_version('AHardwareBuffer_unlock'),
}  # fmt: skip

module = ExtractUtilsModule(
    'lafa',
    'realme',
    blob_fixups=blob_fixups,
    lib_fixups=lib_fixups,
    namespace_imports=namespace_imports,
    add_firmware_proprietary_file=True,
)

if __name__ == '__main__':
    # NOTE: the second argument is the *common* device and the third is its
    # vendor namespace. lafa lives under device/realme but its common tree is
    # device/oneplus/sm8850-common, so 'oneplus' must be passed explicitly -
    # defaulting to module.vendor would resolve to the wrong path.
    utils = ExtractUtils.device_with_common(
        module, 'sm8850-common', 'oneplus'
    )
    utils.run()
