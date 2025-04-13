#!/bin/bash
#
# SPDX-FileCopyrightText: 2016 The CyanogenMod Project
# SPDX-FileCopyrightText: 2017-2024 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=common
VENDOR=xiaomi/miuicamera

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
            CLEAN_VENDOR=false
            ;;
        -k | --kang )
            KANG="--kang"
            ;;
        -s | --section )
            SECTION="${2}"; shift
            CLEAN_VENDOR=false
            ;;
        * )
            SRC="${1}"
            ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
        system/lib64/libcamera_mianode_jni.xiaomi.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --add-needed "libgui_shim_miuicamera.so" "${2}"
            ;;
        system/lib64/libcamera_algoup_jni.xiaomi.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --add-needed "libgui_shim_miuicamera.so" "${2}"
            sed -i "s/\x08\xad\x40\xf9/\x08\xa9\x40\xf9/" "${2}"
            ;;
        system/lib64/libdoc_photo.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF_0_17_2}" --set-soname libdoc_photo.so "${2}"
            ;;
        system/lib64/libdoc_photo_c++_shared.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF_0_17_2}" --set-soname libdoc_photo_c++_shared.so "${2}"
            ;;
        system/lib64/libgallery_arcsoft_dualcam_refocus.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF_0_17_2}" --set-soname libgallery_arcsoft_dualcam_refocus.so "${2}"
            ;;
        system/lib64/libgallery_arcsoft_portrait_lighting.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF_0_17_2}" --set-soname libgallery_arcsoft_portrait_lighting.so "${2}"
            ;;
        system/lib64/libgallery_arcsoft_portrait_lighting_c.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF_0_17_2}" --set-soname libgallery_arcsoft_portrait_lighting_c.so "${2}"
            ;;
        system/lib64/libgallery_mpbase.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF_0_17_2}" --set-soname libgallery_mpbase.so "${2}"
            ;;
        system/priv-app/MiuiCamera/MiuiCamera.apk)
            [ "$2" = "" ] && return 0
            split --bytes=49M -d "$2" "$2".part
            ;;
        *)
            return 1
            ;;
    esac

    return 0
}

function blob_fixup_dry() {
    blob_fixup "$1" ""
}

if [ -z "$SRC" ]; then
    echo "Path to system dump not specified! Specify one with --path"
    exit 1
fi

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh"
