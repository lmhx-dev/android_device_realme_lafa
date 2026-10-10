#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Partitions
# Physical super partition size, read via `blockdev --getsize64 /dev/block/by-name/super`
# and cross-checked with `fastboot getvar partition-size:super` (0x467000000).
# NOTE: ro.oplus.storage.super_size (12782178304) is NOT this value - it is only the
# sum of the logical partition sizes on the stock ROM.
BOARD_SUPER_PARTITION_SIZE := 18907922432

# Include the common OEM chipset BoardConfig.
include device/oneplus/sm8850-common/BoardConfigCommon.mk

DEVICE_PATH := device/realme/lafa

# Assert
TARGET_OTA_ASSERT_DEVICE := RMX5200,RE6030L1,lafa

# Display
# Panel AE084 P 3 A0033 (BOE) is natively 1440x3136 (2K); stock runs the 1080x2352
# (1.5K) mode by default. Density matches what stock ships as the override.
TARGET_SCREEN_DENSITY := 480

# Properties
TARGET_ODM_PROP += $(DEVICE_PATH)/properties/odm.prop
TARGET_SYSTEM_EXT_PROP += $(DEVICE_PATH)/properties/system_ext.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/properties/vendor.prop

# Recovery
TARGET_RECOVERY_DENSITY := xxhdpi
TARGET_RECOVERY_UI_MARGIN_HEIGHT := 103

# Include the proprietary files BoardConfig.
include vendor/realme/lafa/BoardConfigVendor.mk
