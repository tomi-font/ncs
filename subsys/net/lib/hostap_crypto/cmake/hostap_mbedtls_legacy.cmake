#
# Copyright (c) 2026 Nordic Semiconductor
#
# SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
#
# nrf_security builds (CONFIG_MBEDTLS=n) do not run zephyr/modules/mbedtls/CMakeLists.txt,
# so there is no builtin/mbedtls_iface from the Zephyr Mbed TLS module. Bootstrap the
# same targets and include upstream legacy_support.cmake (DES/DHM for WPS/P2P).
#
# Enterprise uses CONFIG_MBEDTLS=y without CONFIG_TF_PSA_CRYPTO_BUILTIN (nRF Security).
# Zephyr modules/mbedtls creates mbedtls_iface but skips legacy_support.cmake; add
# vendored DES/DHM on a local builtin target (no mbedtls_iface updates).

if(NOT CONFIG_HOSTAP_CRYPTO_ALT_LEGACY_PSA AND NOT CONFIG_HOSTAP_CRYPTO_ALT_PSA)
  return()
endif()

set(MBEDTLS_REMOVED_MODULES_PATH "${ZEPHYR_HOSTAP_MODULE_DIR}/port/mbedtls/removed")

function(hostap_crypto_legacy_builtin)
  if(TARGET builtin)
    return()
  endif()

  add_library(builtin STATIC "")
  target_link_libraries(builtin PRIVATE zephyr_interface)
  add_dependencies(builtin zephyr_generated_headers)

  include(${ZEPHYR_BASE}/modules/mbedtls/legacy_support.cmake)
endfunction()

function(hostap_crypto_enterprise_des_dhm)
  if(TARGET builtin)
    return()
  endif()

  add_library(builtin STATIC "")
  target_link_libraries(builtin PRIVATE zephyr_interface)
  add_dependencies(builtin zephyr_generated_headers)

  target_sources(builtin PRIVATE
    ${MBEDTLS_REMOVED_MODULES_PATH}/des.c
    ${MBEDTLS_REMOVED_MODULES_PATH}/dhm.c
  )
  target_compile_definitions(builtin PRIVATE
    TF_PSA_CRYPTO_CONFIG_CHECK_BYPASS
    MBEDTLS_DES_C
    MBEDTLS_DHM_C
  )
  target_include_directories(builtin PRIVATE ${MBEDTLS_REMOVED_MODULES_PATH})
endfunction()

function(hostap_crypto_enterprise_link)
  get_property(lib GLOBAL PROPERTY HOSTAP_CRYPTO_LIBRARY)

  if(lib AND TARGET builtin)
    target_link_libraries(${lib} PUBLIC builtin)
  endif()
endfunction()

if(NOT CONFIG_MBEDTLS)
  if(NOT TARGET mbedtls_iface)
    # Plain INTERFACE target only; do not use zephyr_interface_library_named()
    # or mbedtls_iface is linked into all of libzephyr (breaks unrelated TUs).
    add_library(mbedtls_iface INTERFACE)

    target_compile_definitions(mbedtls_iface INTERFACE
      TF_PSA_CRYPTO_CONFIG_FILE="${CONFIG_TF_PSA_CRYPTO_CONFIG_FILE}"
      TF_PSA_CRYPTO_USER_CONFIG_FILE="${CONFIG_TF_PSA_CRYPTO_USER_CONFIG_FILE}"
    )

    if(TARGET psa_crypto_config_chosen)
      target_link_libraries(mbedtls_iface INTERFACE psa_crypto_config_chosen)
    endif()

    if(CONFIG_MBEDTLS_DECLARE_PRIVATE_IDENTIFIERS)
      target_include_directories(mbedtls_iface INTERFACE
        ${CONFIG_TF_PSA_CRYPTO_MODULE_DIR}/legacy_sub/include
      )
    endif()
  endif()

  hostap_crypto_legacy_builtin()
elseif(NOT CONFIG_TF_PSA_CRYPTO_BUILTIN)
  cmake_language(DEFER CALL hostap_crypto_enterprise_des_dhm)
  cmake_language(DEFER CALL hostap_crypto_enterprise_link)
endif()
