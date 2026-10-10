#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# AAPT
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := xxxhdpi

# Soong source root pruning
#
# The OPLUS kernel repositories for this tree live at kernel/oneplus/ instead of
# the kernel/platform/kernel-6.12/vendor/oneplus/ path that the kleaf flow
# expects. vendor/lineage/config/common.mk excludes its own kernel tree from
# Soong's Android.bp scan:
#
#     PRODUCT_SOURCE_ROOT_DIRS += -kernel/platform
#
# because the kernel trees' Android.bp files redefine kernel UAPI header modules
# that hardware/qcom-caf/common/Android.bp already provides as stubs. With the
# sources at kernel/oneplus/ that exclusion does not apply, and the build dies in
# soong bootstrap with:
#
#     error: hardware/qcom-caf/common/Android.bp:11:1: module "qti_audio_kernel_uapi" already defined
#            kernel/oneplus/sm8850-modules/qcom/opensource/audio-kernel/Android.bp:37:1 <-- previous definition here
#     (same for qti_display_kernel_headers, qti_ipa_kernel_headers, smmu_proxy_uapi_header)
#
# Excluding the same tree here restores the intended behaviour. If the kernel
# repositories are ever moved back under kernel/platform/, drop this line.
# PRODUCT_SOURCE_ROOT_DIRS += -kernel/oneplus   # OBSOLETE: kernel sources now live under kernel/platform/kernel-6.12/vendor/oneplus/

# Audio
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/audio/audio_module_config_primary.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/audio_module_config_primary.xml \
    $(LOCAL_PATH)/configs/audio/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes.xml \
    $(LOCAL_PATH)/configs/audio/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml

# Boot animation
# Panel AE084 P 3 A0033 is natively 1440x3136 (2K).
TARGET_SCREEN_HEIGHT := 3136
TARGET_SCREEN_WIDTH := 1440

# Display
# The stock vendor image ships five identical display_id_*.xml files (a QTI
# screenBrightnessMap). They are not in the blob lists, so they must be supplied
# here.
#
# The framework only reads the file whose name matches the connected panel's
# uniqueId - display_id_<id>.xml. Those five IDs do NOT include this panel, so
# none of them was ever loaded: the file's screenBrightnessRamp* values silently
# did nothing (`dumpsys display` reported the built-in ramps instead). The real
# ID below was read off the device:
#     dumpsys display | grep -oE 'local:[0-9]+'   ->  local:4630947180293509523
# The five originals are kept so the other panel variants this project supports
# still get a file; all six now carry the same content.
#
# The file also carries a <autoBrightness><luxToBrightnessMapping> because
# config_autoBrightnessLevels stops at 255 lux - past that the curve saturated
# and the screen stopped responding to light. See the note in the XML itself.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/display/displayconfig.xml:$(TARGET_COPY_OUT_VENDOR)/etc/displayconfig/display_id_4630947180293509523.xml \
    $(LOCAL_PATH)/configs/display/displayconfig.xml:$(TARGET_COPY_OUT_VENDOR)/etc/displayconfig/display_id_4630946850534658451.xml \
    $(LOCAL_PATH)/configs/display/displayconfig.xml:$(TARGET_COPY_OUT_VENDOR)/etc/displayconfig/display_id_4630946916234099603.xml \
    $(LOCAL_PATH)/configs/display/displayconfig.xml:$(TARGET_COPY_OUT_VENDOR)/etc/displayconfig/display_id_4630947039571902850.xml \
    $(LOCAL_PATH)/configs/display/displayconfig.xml:$(TARGET_COPY_OUT_VENDOR)/etc/displayconfig/display_id_4630947039571902851.xml \
    $(LOCAL_PATH)/configs/display/displayconfig.xml:$(TARGET_COPY_OUT_VENDOR)/etc/displayconfig/display_id_4630947075271898515.xml

# Keymint
PRODUCT_PACKAGES += \
    android.hardware.security.keymint3-service.strongbox.nxp \
    android.hardware.weaver-service.nxp

# LiveDisplay
$(call soong_config_set_bool,OPLUS_LINEAGE_LIVEDISPLAY_HAL,ENABLE_SE,false)

# Overlays
DEVICE_PACKAGE_OVERLAYS += \
    $(LOCAL_PATH)/overlay-lineage

# Device-specific resource overlays.
# FrameworksResEuicc is intentionally absent: lafa has no eSIM/EUICC.
PRODUCT_PACKAGES += \
    OPlusFrameworksResTarget \
    OPlusSettingsProviderResTarget \
    OPlusSettingsResTarget \
    OPlusSystemUIResTarget \
    OPlusWifiResTarget

# VINTF
# The pixelworks Iris7p HALs are lafa-only and have no interface definitions in
# hardware/oplus, so check_vintf needs them declared explicitly.
# NOTE: this must be a source-tree-relative path, not $(LOCAL_PATH)/... - Soong
# consumes DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE on its own and $(LOCAL_PATH)
# is not expanded there, which yields "/vintf/device_framework_matrix.xml" and
#   Module framework_compatibility_matrix.device.xml: Path is outside directory
# Same form as device/oneplus/sm8850-common/common.mk uses for hardware/oplus.
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE += \
    device/realme/lafa/vintf/device_framework_matrix.xml

# PowerShare
PRODUCT_PACKAGES += \
    vendor.lineage.powershare-service.oplus

# Recovery
$(call soong_config_set_bool,recovery,target_recovery_uses_qti_drm,true)

# Regional properties
REGIONAL_PROP_FILES := $(wildcard $(LOCAL_PATH)/properties/*/*.prop)

PRODUCT_COPY_FILES += $(foreach f,$(REGIONAL_PROP_FILES), \
    $(f):$(TARGET_COPY_OUT_ODM)/etc/$(patsubst $(LOCAL_PATH)/properties/%,%,$(f)) \
    $(f):$(TARGET_COPY_OUT_RECOVERY)/root/vendor/odm/etc/$(patsubst $(LOCAL_PATH)/properties/%,%,$(f)))

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

# Telephony
# NOTE: lafa has no eSIM/EUICC. `pm list features` on the stock ROM shows no
# android.hardware.telephony.euicc, so OplusEuicc / OplusEsimSwitcher and the
# euicc permission XMLs are deliberately not included here (infiniti has them).

# Touch features
# Glove mode is supported: the stock tp firmware ships GloveDetect.tflite and
# sys_edge_touch_config.xml under odm/firmware/tp/24624/, which is now extracted
# into vendor/realme/lafa (see the Touch entry in proprietary-files.txt).
$(call soong_config_set_bool,OPLUS_LINEAGE_TOUCH_HAL,ENABLE_GM,true)
#
# Double-tap to wake: the touchscreen reports gestures as KEY_F4 (see the
# generic gesture branch in syna_tcm2.c), and a key only wakes the screen when
# InputReader finds WAKE on its mapping. Generic.kl ships a bare "key 62 F4" -
# the stock ROM gets away with that because OPPO's framework special-cases
# KEY_F4, LineageOS does not, so the event arrives and is then ignored without
# logging anything. Fully explained in configs/keylayout/touchpanel.kl.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/keylayout/touchpanel.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/touchpanel.kl

# Vibrator
# lafa uses the stock OPPO vibrator HAL, NOT LineageOS' richtap one. The richtap
# HAL implements only the AAC backend and fails in aac_vibra_init() because lafa
# has no /odm/etc/aac_richtap.config - the stock ROM never ships one either, since
# lafa's actuator is driven through the Si livetap backend. Verified on the device
# with the stock binary: it loads the 816 effect set, reports
# "Vibrator driver loaded success" and registers the AIDL instance.
#
# Both HALs declare the same VINTF instance
# (android.hardware.vibrator IVibrator/default), so exactly one may be built.
# Shipping both makes checkvintf fail the whole build with
#   HAL "android.hardware.vibrator" has a conflict:
#   Conflicting FqInstance: IVibrator/default (@2)
# The stock one wins, so nothing is added to PRODUCT_PACKAGES here - it comes in
# as a blob from vendor/realme/lafa (see the Vibrator entry in proprietary-files.txt).

# NFC
# Two separate problems lived here; both are covered below.
#
# 1. The vendor extension library.
#    AOSP ships it at hardware/nxp/nfc/vendor_extns/libnfc_vendor_extn as
#    libnfc_vendor_extn_sys (stem libnfc_vendor_extn) and libnfc_vendor_extn_vnd,
#    both disabled: the vendor is expected to supply the .so. The stock lafa blob
#    is written against OPPO's own NFC HAL and does not work with the HAL
#    LineageOS builds - OPPO's copy wants the NXP config content out of
#    INxpNfc.getVendorParam, while AOSP's HAL answers that call with a system
#    property value, so it logs "No content from getVendorParam!" and
#    HalOpenInternal fails. LineageOS's own _sys variant is written against that
#    HAL, and its stem already installs as /system/lib64/libnfc_vendor_extn.so -
#    the only path NfcVendorExtn::findLibPath() searches.
PRODUCT_PACKAGES += \
    libnfc_vendor_extn_sys

# 2. /vendor/etc/libnfc-nxp.conf.
#    That path is hardcoded in the HAL as default_nxp_config_path
#    (hardware/nxp/nfc/snxxx/halimpl_v2/hal/phNxpNciHal_IoctlOperations.cc), and
#    phNxpNciHal_getNxpConfigIf() reads it to answer the extn lib's
#    getVendorParam("libnfc-nxp.conf"). Nothing ships it - the stock ROM uses
#    OPPO's HAL, which reads libnfc-mtp-SN220.conf_<prjname> instead - so the HAL
#    came up with an empty config and NFC stayed off forever.
#
#    Content matters as much as the file: feeding the stock
#    libnfc-mtp-SN220.conf_24624 verbatim makes phNxpNciHal_MinOpen() fail, while
#    LineageOS' own SN220 sample works (verified on device - MinOpen(): exit with
#    "read successful status = 0x0"). Hence the in-tree copy at
#    configs/nfc/libnfc-nxp.conf, taken from
#    hardware/nxp/nfc/snxxx/halimpl_v2/conf/SN220/gen-config-files/
#    libnfc-nxp-SN220U_example.conf with NXP_NFC_DEV_NODE pointed at /dev/nq-nci
#    (the node lafa's kernel actually creates; the sample defaults to
#    /dev/nxp-nci).
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/nfc/libnfc-nxp.conf:$(TARGET_COPY_OUT_VENDOR)/etc/libnfc-nxp.conf

# Kernel page size
# lafa's kernel runs 4 KiB pages: the built kernel config has
# CONFIG_ARM64_4K_PAGES=y / CONFIG_PAGE_SHIFT=12, and `getconf PAGESIZE` on the
# device reports 4096. On such a kernel a 4 KiB-aligned .so loads fine, so
# check_elf_file's 16 KiB requirement is a false positive for blobs taken from
# the stock ROM.
#
# This fired once, on system/lib64/libnfc_vendor_extn.so - the only /system blob
# this device tree has taken from stock so far; it has since been replaced by
# LineageOS' own libnfc_vendor_extn_sys (see the NFC section above), so nothing
# in the tree currently needs this. It is kept as a guard: plenty of the stock
# .so files are still only 4 KiB-aligned (156 of 574 under proprietary/, e.g.
# vendor/lib64/rfs/dsp/* and odm/lib/rfsa/adsp/*), and the check has only ever
# been observed to fire on the /system side. If the kernel is ever moved to
# 16 KiB pages this has to be revisited - those blobs would then genuinely fail
# to load.
PRODUCT_CHECK_PREBUILT_MAX_PAGE_SIZE := false

# Inherit from the common OEM chipset makefile.
$(call inherit-product, device/oneplus/sm8850-common/common.mk)

# Inherit from the proprietary files makefile.
$(call inherit-product, vendor/realme/lafa/lafa-vendor.mk)

# The HighTouchPollingRate override is deliberately not here: it has to be
# parsed after this file's whole subtree. See htpr.mk, inherited from
# lineage_lafa.mk.

