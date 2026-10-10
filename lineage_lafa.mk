#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from lafa device
$(call inherit-product, device/realme/lafa/device.mk)

# HighTouchPollingRate node override, see htpr.mk.
$(call inherit-product, device/realme/lafa/htpr.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_NAME := lineage_lafa
PRODUCT_DEVICE := lafa
PRODUCT_MANUFACTURER := realme
PRODUCT_BRAND := realme
PRODUCT_MODEL := RMX5200

PRODUCT_GMS_CLIENTID_BASE := android-oppo

# Values taken from the running stock ROM (RMX5200_16.0.10.501(CN01)).
PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="qssi-user 16 BP2A.250605.015 1786026378381 release-keys" \
    BuildFingerprint=realme/RMX5200/RE6030L1:16/BP2A.250605.015/B.551d65a-2fef12e-2ff294a:user/release-keys \
    DeviceName=RE6030L1 \
    DeviceProduct=RMX5200 \
    SystemDevice=RE6030L1 \
    SystemName=RMX5200
