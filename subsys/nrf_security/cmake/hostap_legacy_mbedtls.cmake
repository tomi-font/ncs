#
# Copyright (c) 2026 Nordic Semiconductor
#
# SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
#
# HostAP mbedtls alt still uses DES/DHM removed from TF-PSA-Crypto. Mirror
# zephyr/modules/mbedtls/legacy_support.cmake (builtin target) on mbedcrypto
# for CONFIG_WIFI_NM_WPA_SUPPLICANT_CRYPTO_EXT / Nordic hostap_crypto.
#
# Per-file COMPILE_DEFINITIONS are not applied through nrf_security's Zephyr
# compile integration; build des.c/dhm.c in a dedicated OBJECT library.

if(NOT CONFIG_MBEDTLS_PSA_CRYPTO_SPM)
  if(CONFIG_WIFI_NM_WPA_SUPPLICANT AND (CONFIG_HOSTAP_CRYPTO_ALT_LEGACY_PSA OR
      CONFIG_HOSTAP_CRYPTO_ALT_PSA))
    if(DEFINED ZEPHYR_HOSTAP_MODULE_DIR)
      set(HOSTAP_MBEDTLS_REMOVED "${ZEPHYR_HOSTAP_MODULE_DIR}/port/mbedtls/removed")

      add_library(hostap_legacy_mbedtls OBJECT
        ${HOSTAP_MBEDTLS_REMOVED}/des.c
        ${HOSTAP_MBEDTLS_REMOVED}/dhm.c
      )

      target_compile_definitions(hostap_legacy_mbedtls PRIVATE
        TF_PSA_CRYPTO_CONFIG_CHECK_BYPASS
        MBEDTLS_DES_C
        MBEDTLS_DHM_C
      )

      target_include_directories(hostap_legacy_mbedtls PRIVATE
        ${HOSTAP_MBEDTLS_REMOVED}
      )

      target_sources(${mbedcrypto_target} PRIVATE
        $<TARGET_OBJECTS:hostap_legacy_mbedtls>
      )

      target_include_directories(${mbedcrypto_target}
        PUBLIC
          ${HOSTAP_MBEDTLS_REMOVED}
      )
    endif()
  endif()
endif()
