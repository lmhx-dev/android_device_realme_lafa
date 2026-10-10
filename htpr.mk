#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# HighTouchPollingRate node override for lafa (RMX5200 / RE6030L1).
#
# Lives in its own file, inherited from lineage_lafa.mk beside device.mk, with a
# name that sorts AFTER "device.mk". Both details matter: soong_config_set is a
# plain assignment and SOONG_CONFIG_* is not in _product_var_list, so
# inherit-product does not tag it and whoever assigns last wins. _import-node()
# (build/make/core/node_fns.mk) parses a file before anything it inherits, so
# device.mk can never beat sm8850-common's HTPR_ENABLE_NODE=REPORT_RATE_NODE
# (common.mk:514). Siblings are parsed in sorted order, so "htpr.mk" >
# "device.mk" puts us last.
#
# REPORT_RATE_NODE (182) does not exist on lafa - isTouchNodeSupport(0, 182)
# returns -1, (0, 26) returns 1. The panel listens to GAME_SWITCH_ENABLE_NODE
# (26). The value is a hex report-rate slot, not Hz: lafa's BOE panel has
# extreme_game_report_rate = 360, so "c" applies -> mode 1 = 360Hz (measured
# 2.729 ms/frame with getevent). "10" is accepted but a no-op (182Hz); "set N"
# only means the mode number parsed.
$(call soong_config_set,OPLUS_LINEAGE_TOUCH_HAL,HTPR_ENABLE_NODE,GAME_SWITCH_ENABLE_NODE)
$(call soong_config_set,OPLUS_LINEAGE_TOUCH_HAL,HTPR_ENABLE_VALUE,c)
