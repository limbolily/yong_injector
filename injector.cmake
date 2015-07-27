macro(_yong_install_cmake_file prj)
  install(FILES ${${prj}_YONG_CONFIG_FILE}
    DESTINATION ${_${prj}_install_cmake_prefix})
endmacro()

macro(_yong_install_library prj lib)
  if (NOT CMAKE_CONFIGURATION_TYPES)
    install(TARGETS ${lib}
      ARCHIVE
      DESTINATION "${_${prj}_install_archive_prefix}"
      LIBRARY
      DESTINATION "${_${prj}_install_library_prefix}"
      RUNTIME
      DESTINATION "${_${prj}_install_runtime_prefix}"
      FRAMEWORK
      DESTINATION "${_${prj}_install_framework_prefix}"
      BUNDLE
      DESTINATION "${_${prj}_install_bundle_prefix}")
  else()
    foreach(conf ${CMAKE_CONFIGURATION_TYPES})
      install(TARGETS ${lib}
        ARCHIVE
        DESTINATION "${_${prj}_install_archive_prefix}"
        CONFIGURATIONS ${conf} OPTIONAL
        LIBRARY
        DESTINATION "${_${prj}_install_library_prefix}"
        CONFIGURATIONS ${conf} OPTIONAL
        RUNTIME
        DESTINATION "${_${prj}_install_runtime_prefix}"
        CONFIGURATIONS ${conf} OPTIONAL
        FRAMEWORK
        DESTINATION "${_${prj}_install_framework_prefix}"
        CONFIGURATIONS ${conf} OPTIONAL
        BUNDLE
        DESTINATION "${_${prj}_install_bundle_prefix}"
        CONFIGURATIONS ${conf} OPTIONAL)
    endforeach()
  endif()
endmacro()

macro(_yong_write_library_config_file prj lib)
  file(APPEND "${${prj}_YONG_CONFIG_FILE}"
    "set(${prj}_${lib}_OUTPUT_NAME \"${${prj}_${lib}_OUTPUT_NAME}\")\n")
  file(APPEND "${${prj}_YONG_CONFIG_FILE}"
    "set(${prj}_${lib}_LIB_TYPE \"${${prj}_${lib}_LIB_TYPE}\")\n")
  file(APPEND "${${prj}_YONG_CONFIG_FILE}"
    "set(${prj}_${lib}_DEPENDENT_PROJECTS \"${${prj}_${lib}_DEPENDENT_PROJECTS}\")\n")
  file(APPEND "${${prj}_YONG_CONFIG_FILE}"
    "set(${prj}_${lib}_DEPENDENT_LOCAL_LIBS \"${${prj}_${lib}_DEPENDENT_LOCAL_LIBS}\")\n")
  foreach(dep_prj ${${prj}_${lib}_DEPENDENT_PROJECTS})
    if (${prj}_${lib}_DEPENDENCE_${dep_prj}_COMMIT_HASHES)
      file(APPEND "${${prj}_YONG_CONFIG_FILE}"
        "set(${prj}_${lib}_DEPENDENCE_${dep_prj}_COMMIT_HASHES \"${${prj}_${lib}_DEPENDENCE_${dep_prj}_COMMIT_HASHES}\")\n")
    endif()
    if (${prj}_${lib}_DEPENDENCE_${dep_prj}_HEADER_ONLY)
      file(APPEND "${${prj}_YONG_CONFIG_FILE}"
        "set(${prj}_${lib}_DEPENDENCE_${dep_prj}_HEADER_ONLY 1)\n")
    endif()
    file(APPEND "${${prj}_YONG_CONFIG_FILE}"
      "set(${prj}_${lib}_DEPENDENCE_${dep_prj}_DEPENDENCE_LIBS \"${${prj}_${lib}_DEPENDENCE_${dep_prj}_DEPENDENCE_LIBS}\")\n")
  endforeach()
endmacro()

macro(_yong_set_library_properties prj lib)
  #Set output name
  set_target_properties(${lib} PROPERTIES OUTPUT_NAME
    ${${prj}_${lib}_OUTPUT_NAME})
  foreach(conf ${CMAKE_CONFIGURATION_TYPES})
    set_target_properties(${lib} PROPERTIES OUTPUT_NAME_${conf}
      ${${prj}_${lib}_OUTPUT_NAME})
  endforeach()

  #Set version and sovertion
  set_target_properties(${lib} PROPERTIES NO_SONAME TRUE)
  set_target_properties(${lib} PROPERTIES VERSION "")
  set_target_properties(${lib} PROPERTIES SOVERSION "")

  #Set POSTFIX
  foreach(conf ${CMAKE_CONFIGURATION_TYPES})
    set_target_properties(${lib} PROPERTIES ${conf}_POSTFIX "")
  endforeach()

  #Set Suffix/Prefix
  if (${${prj}_${lib}_LIB_TYPE} STREQUAL "SHARED")
    set_target_properties(${lib} PROPERTIES SUFFIX
      "${CMAKE_SHARED_LIBRARY_SUFFIX}")
    set_target_properties(${lib} PROPERTIES PREFIX
      "${CMAKE_SHARED_LIBRARY_PREFIX}")
  elseif (${${prj}_${lib}_LIB_TYPE} STREQUAL "STATIC")
    set_target_properties(${lib} PROPERTIES SUFFIX
      "${CMAKE_STATIC_LIBRARY_SUFFIX}")
    set_target_properties(${lib} PROPERTIES PREFIX
      "${CMAKE_STATIC_LIBRARY_PREFIX}")
  elseif (${${prj}_${lib}_LIB_TYPE} STREQUAL "MODULE")
    set_target_properties(${lib} PROPERTIES SUFFIX
      "${CMAKE_MODULE_LIBRARY_SUFFIX}")
    set_target_properties(${lib} PROPERTIES PREFIX
      "${CMAKE_MODULE_LIBRARY_PREFIX}")
  endif()

endmacro()

macro(_yong_resolve_dependence_paths dep_prj dep_lib)
  set(location_dir "bin")
  set(import_dir "lib")
  if (${dep_prj}_${dep_lib}_LIB_TYPE STREQUAL "SHARED")
    set(location_prefix "${CMAKE_SHARED_LIBRARY_PREFIX}")
    set(location_suffix "${CMAKE_SHARED_LIBRARY_SUFFIX}")
    if (WIN32)
      set(location_dir "bin")
      set(import_dir "lib")
    elseif(UNIX)
      set(location_dir "lib")
      set(import_dir "lib")
    endif()
  elseif (${dep_prj}_${dep_lib}_LIB_TYPE STREQUAL "STATIC")
    set(location_prefix "${CMAKE_STATIC_LIBRARY_PREFIX}")
    set(location_suffix "${CMAKE_STATIC_LIBRARY_SUFFIX}")
    if (WIN32)
      set(location_dir "lib")
      set(import_dir "lib")
    elseif(UNIX)
      set(location_dir "lib")
      set(import_dir "lib")
    endif()
  else()
    message(FATAL_ERROR "Unsupported library type.")
  endif()
  set(import_prefix "${CMAKE_IMPORT_LIBRARY_PREFIX}")
  set(import_suffix "${CMAKE_IMPORT_LIBRARY_SUFFIX}")
  set(output_name "${${dep_prj}_${dep_lib}_OUTPUT_NAME}")
  set(location_name ${location_prefix}${output_name}${location_suffix})
  set(import_name ${import_prefix}${output_name}${import_suffix})
  set(target_name "${dep_prj}_${dep_lib}_imp")
  set(full_location_dir "${${dep_prj}_INSTALL_PREFIX}/${location_dir}")
  set(full_import_dir "${${dep_prj}_INSTALL_PREFIX}/${import_dir}")
endmacro()

macro(_yong_add_local_post_copy_command exe local_lib)
  add_custom_command(
    TARGET ${exe}
    POST_BUILD
    COMMAND ${CMAKE_COMMAND}
    -E copy "$<TARGET_FILE:${local_lib}>"
            "$<TARGET_FILE_DIR:${exe}>/")
endmacro()

macro(_yong_add_post_copy_command prj exe dep_prj dep_lib)
  _yong_resolve_dependence_paths(${dep_prj} ${dep_lib})
  if (NOT CMAKE_CONFIGURATION_TYPES)
    add_custom_command(
      TARGET ${exe}
      POST_BUILD
      COMMAND ${CMAKE_COMMAND}
      -E copy "${full_location_dir}/${location_name}"
              "$<TARGET_FILE_DIR:${exe}>/")
  else()
    add_custom_command(
      TARGET ${exe}
      POST_BUILD
      COMMAND ${CMAKE_COMMAND}
      -E copy "${full_location_dir}/$<CONFIG>/${location_name}"
              "$<TARGET_FILE_DIR:${exe}>/")
  endif()
endmacro()

macro(_yong_target_add_dependence prj target dep_prj dep_lib)
  _yong_resolve_dependence_paths(${dep_prj} ${dep_lib})
  if (NOT ${dep_prj}_${dep_lib}_ADDED)
    add_library(${target_name}
      ${${dep_prj}_${dep_lib}_LIB_TYPE} IMPORTED)
    set_target_properties(${target_name} PROPERTIES IMPORTED_LOCATION
      "${full_location_dir}/${location_name}")
    set_target_properties(${target_name} PROPERTIES IMPORTED_IMPLIB
      "${full_import_dir}/${import_name}")
    foreach (conf ${CMAKE_CONFIGURATION_TYPES})
      string(TOUPPER "${conf}" uconf)
      set_target_properties(${target_name}
        PROPERTIES IMPORTED_LOCATION_${uconf}
        "${full_location_dir}/${conf}/${location_name}")
      set_target_properties(${target_name}
        PROPERTIES IMPORTED_IMPLIB_${uconf}
        "${full_import_dir}/${conf}/${import_name}")
    endforeach()
    set(${dep_prj}_${dep_lib}_ADDED 1)
  endif()
  target_link_libraries(${target} ${target_name})
  add_dependencies(${target} ${target_name})
endmacro()

macro(_yong_append_uniquely list_var element)
  list(FIND ${list_var} ${element} output_index)
  if (output_index EQUAL -1)
    list(APPEND ${list_var} ${element})
  endif()
endmacro()

macro(_yong_recursive_fill_dependence_list prj target dep_prj dep_lib)
  set(${dep_prj}_CMAKE_CONFIG_FILE
    "${${dep_prj}_INSTALL_PREFIX}/cmake/${dep_prj}_yong_config.cmake")
  include("${${dep_prj}_CMAKE_CONFIG_FILE}")
  foreach(recursive_dep_prj ${${dep_prj}_${dep_lib}_DEPENDENT_PROJECTS})
    foreach(recursive_dep_lib
      ${${dep_prj}_${dep_lib}_DEPENDENCE_${recursive_dep_prj}_DEPENDENCE_LIBS})
    _yong_recursive_fill_dependence_list(
       ${prj} ${target} ${recursive_dep_prj} ${recursive_dep_lib})
    endforeach()
  endforeach()
  _yong_append_uniquely(${prj}_${target}_RECURSIVE_DEPENDENT_PROJECTS
                        ${dep_prj})
  _yong_append_uniquely(
    ${prj}_${target}_DEPENDENCE_${dep_prj}_RECURSIVE_DEPENDENCE_LIBS
    ${dep_lib})
endmacro()

macro(yong_project prj language)
  set(YONG_PROJECT_NAME ${prj})
  set(YONG_${prj}_LANGUAGE ${language})

  set(_${prj}_install_include_prefix
    "${CMAKE_INSTALL_PREFIX}/${prj}/include")
  set(_${prj}_install_archive_prefix
    "${CMAKE_INSTALL_PREFIX}/${prj}/lib")
  set(_${prj}_install_library_prefix
    "${CMAKE_INSTALL_PREFIX}/${prj}/lib")
  set(_${prj}_install_runtime_prefix
    "${CMAKE_INSTALL_PREFIX}/${prj}/bin")
  set(_${prj}_install_framework_prefix
    "${CMAKE_INSTALL_PREFIX}/${prj}/framework")
  set(_${prj}_install_bundle_prefix
    "${CMAKE_INSTALL_PREFIX}/${prj}/bundle")
  set(_${prj}_install_cmake_prefix
    "${CMAKE_INSTALL_PREFIX}/${prj}/cmake")

  execute_process(
    COMMAND git log -1 --format=%H
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    OUTPUT_VARIABLE ${YONG_PROJECT_NAME}_GIT_COMMIT_HASH
    OUTPUT_STRIP_TRAILING_WHITESPACE)

  project(${prj} ${YONG_${prj}_LANGUAGE})
  set(${prj}_YONG_CONFIG_FILE
    "${CMAKE_CURRENT_BINARY_DIR}/${prj}_yong_config.cmake")
  file(WRITE "${${prj}_YONG_CONFIG_FILE}"
    "set(${prj}_GIT_COMMIT_HASH \"${${prj}_GIT_COMMIT_HASH}\")\n")
endmacro()

macro(yong_option var_name option_text)
  set(prj ${YONG_PROJECT_NAME})
  if (ARGN STREQUAL "")
    set(initial_var OFF)
  else()
    set(initial_var ${ARGN})
  endif()

  option(${prj}_${var_name} "${option_text}" ${initial_var})
  set(${var_name} ${${prj}_${var_name}} CACHE INTERNAL "${option_text}")
endmacro()

macro(yong_set_cache var_name value cache type text)
  set(prj ${YONG_PROJECT_NAME})
  set(${prj}_${var_name} ${value} CACHE ${type} "${text}")
  set(${var_name} ${value} CACHE INTERNAL "${text}")
endmacro()

macro(yong_add_library lib)
  set(prj ${YONG_PROJECT_NAME})
  foreach(arg ${ARGN})
    if (arg STREQUAL "SOURCES")
      set(listvar ${prj}_${lib}_SOURCES)
    elseif (arg STREQUAL "LIB_TYPE")
      set(listvar ${prj}_${lib}_LIB_TYPES)
    elseif (arg STREQUAL "OUTPUT_NAME")
      set(listvar ${prj}_${lib}_OUTPUT_NAMES)
    else()
      list(APPEND ${listvar} "${arg}")
    endif()
  endforeach()
  unset(listvar)

  if (BUILD_SHARED_LIBS)
    set(${prj}_${lib}_LIB_TYPE SHARED)
  else()
    set(${prj}_${lib}_LIB_TYPE STATIC)
  endif()

  if (${prj}_${lib}_LIB_TYPES)
    list(GET ${prj}_${lib}_LIB_TYPES 0 ${prj}_${lib}_LIB_TYPE)
  endif()

  if (${prj}_${lib}_OUTPUT_NAMES)
    list(GET ${prj}_${lib}_OUTPUT_NAMES 0 ${prj}_${lib}_OUTPUT_NAME)
  else()
    set(${prj}_${lib}_OUTPUT_NAME ${lib})
  endif()

  list(APPEND ${prj}_LIBRARIES ${lib})

  add_library(${lib} ${${prj}_${lib}_LIB_TYPE} ${${prj}_${lib}_SOURCES})

endmacro()

macro(yong_add_library_end lib)
  set(prj ${YONG_PROJECT_NAME})
  _yong_set_library_properties(${prj} ${lib})
  _yong_write_library_config_file(${prj} ${lib})
  _yong_install_library(${prj} ${lib})
endmacro()

#Usage:
#   yong_add_executable(<exe>
#                       [EXCLUDE_FROM_ALL]
#                       [WIN32]
#                       [MACOSX_BUNDLE]
#                       SOURCES source1 source2 ...)
macro(yong_add_executable exe)
  set(prj ${YONG_PROJECT_NAME})
  set(${prj}_${exe}_EXCLUDE_FROM_ALL "")
  set(${prj}_${exe}_WIN32 "")
  set(${prj}_${exe}_MACOSX_BUNDLE "")
  foreach(arg ${ARGN})
    if (arg STREQUAL "EXCLUDE_FROM_ALL")
      set(${prj}_${exe}_EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
    elseif (arg STREQUAL "WIN32")
      set(${prj}_${exe}_WIN32 WIN32)
    elseif (arg STREQUAL "MACOSX_BUNDLE")
      set(${prj}_${exe}_MACOSX_BUNDLE MACOSX_BUNDLE)
    elseif (arg STREQUAL "SOURCES")
      set(listvar ${prj}_${exe}_SOURCES)
    else()
      list(APPEND ${listvar} "${arg}")
    endif()
  endforeach()
  unset(listvar)

  list(APPEND ${prj}_EXECUTABLES ${exe})

  add_executable(${exe}
    ${${prj}_${exe}_EXCLUDE_FROM_ALL}
    ${${prj}_${exe}_WIN32}
    ${${prj}_${exe}_MACOSX_BUNDLE}
    ${${prj}_${exe}_SOURCES})

endmacro()

macro(yong_add_executable_end exe)
  set(prj ${YONG_PROJECT_NAME})
  foreach (dep_prj ${${prj}_${exe}_DEPENDENT_PROJECTS})
    if (NOT ${prj}_${exe}_DEPENDENCE_${dep_prj}_HEADER_ONLY)
      foreach(dep_lib
        ${${prj}_${exe}_DEPENDENCE_${dep_prj}_DEPENDENCE_LIBS})
        _yong_recursive_fill_dependence_list(
          ${prj} ${exe} ${dep_prj} ${dep_lib})
      endforeach()
    endif()
  endforeach()

  foreach(local_lib ${${prj}_${exe}_DEPENDENT_LOCAL_LIBS})
    _yong_add_local_post_copy_command(${exe} ${local_lib})
  endforeach()

  foreach (dep_prj ${${prj}_${exe}_RECURSIVE_DEPENDENT_PROJECTS})
    if (NOT ${prj}_${exe}_DEPENDENCE_${dep_prj}_HEADER_ONLY)
      foreach(dep_lib
          ${${prj}_${exe}_DEPENDENCE_${dep_prj}_RECURSIVE_DEPENDENCE_LIBS})
        _yong_add_post_copy_command(${prj} ${exe} ${dep_prj} ${dep_lib})
      endforeach()
    endif()
  endforeach()

endmacro()

macro(yong_install_header_files prj dir)
  install(FILES ${ARGN}
    DESTINATION "${_${prj}_install_include_prefix}/${dir}")
endmacro()

macro(yong_install_header_directories prj)
  unset(listvar)
  unset(dirs)
  unset(destination)
  unset(files_matching)

  foreach(arg ${ARGN})
    if (arg STREQUAL "DIRECTORIES")
      set(listvar dirs)
    elseif (arg STREQUAL DESTINATION)
      set(listvar destination)
    elseif (arg STREQUAL "FILES_MATCHING")
      set(listvar files_matching)
    else()
      list(APPEND ${listvar} "${arg}")
    endif()
  endforeach()
  unset(listvar)

  if (files_matching)
    install(DIRECTORY ${dirs}
      DESTINATION "${_${prj}_install_include_prefix}/${destination}"
      FILES_MATCHING ${files_matching})
    unset(files_matching_str)
  else()
    install(DIRECTORY ${dirs}
      DESTINATION "${_${prj}_install_include_prefix}")
  endif()

  unset(dirs)
  unset(files_matching)
endmacro()

#Usage:
#   yong_add_dependence(<prj> <target>
#                       [DEPENDENT_LOCAL_LIBS <local_lib1> [local_lib2]...]
#                       [DEPENDENT_PROJECT <dep_prj1>
#                        [COMMIT_HASH <commit_hash1>]
#                        [HEADER_ONLY |
#                        [DEPENDENT_LIBS dep_lib_1 [dep_lib2] ...]] ]
#                       [DEPENDENT_PROJECT <dep_prj2>
#                        [COMMIT_HASH <commit_hash2>]
#                        [HEADER_ONLY |
#                        [DEPENDENT_LIBS dep_lib_1 [dep_lib2] ...]] ] ...)
macro(yong_add_dependence prj target)
  unset(listvar)
  foreach(arg ${ARGN})
    if (arg STREQUAL "DEPENDENT_LOCAL_LIBS")
      set(listvar ${prj}_${target}_DEPENDENT_LOCAL_LIBS)
    elseif (arg STREQUAL "DEPENDENT_PROJECT")
      set(listvar ${prj}_${target}_DEPENDENT_PROJECTS)
    elseif (arg STREQUAL "COMMIT_HASH")
      list(GET ${prj}_${target}_DEPENDENT_PROJECTS -1 dep_prj)
      set(listvar ${prj}_${target}_DEPENDENCE_${dep_prj}_COMMIT_HASHES)
    elseif (arg STREQUAL "HEADER_ONLY")
      list(GET ${prj}_${target}_DEPENDENT_PROJECTS -1 dep_prj)
      set(${prj}_${target}_DEPENDENCE_${dep_prj}_HEADER_ONLY 1)
    elseif (arg STREQUAL "DEPENDENT_LIBS")
      list(GET ${prj}_${target}_DEPENDENT_PROJECTS -1 dep_prj)
      set(listvar ${prj}_${target}_DEPENDENCE_${dep_prj}_DEPENDENCE_LIBS)
    else ()
      list(APPEND ${listvar} "${arg}")
    endif()
  endforeach()
  unset(listvar)

  foreach (local_lib ${${prj}_${target}_DEPENDENT_LOCAL_LIBS})
    target_link_libraries(${target} ${local_lib})
    add_dependencies(${target} ${local_lib})
  endforeach()

  #foreach (dep_prj ${${prj}_${target}_DEPENDENT_PROJECTS})
  #  if (NOT ${prj}_${target}_DEPENDENCE_${dep_prj}_HEADER_ONLY)
  #    foreach(dep_lib
  #      ${${prj}_${target}_DEPENDENCE_${dep_prj}_DEPENDENCE_LIBS})
  #      _yong_recursive_fill_dependence_list(
  #        ${prj} ${target} ${dep_prj} ${dep_lib})
  #    endforeach()
  #  endif()
  #endforeach()

  foreach (dep_prj ${${prj}_${target}_DEPENDENT_PROJECTS})
    if (NOT ${dep_prj}_INSTALL_PREFIX)
      message(FATAL_ERROR "Variable ${dep_prj}_INSTALL_PREFIX Not Set!")
    endif()
    set(${dep_prj}_CMAKE_CONFIG_FILE
      "${${dep_prj}_INSTALL_PREFIX}/cmake/${dep_prj}_yong_config.cmake")
    include("${${dep_prj}_CMAKE_CONFIG_FILE}")
    if (${prj}_${target}_DEPENDENCE_${dep_prj}_COMMIT_HASHES)
      list(GET ${prj}_${target}_DEPENDENCE_${dep_prj}_COMMIT_HASHES
           -1 commit_hash)
      if (NOT commit_hash STREQUAL ${${dep_prj}_GIT_COMMIT_HASH})
        message(STATUS
          "Request ${prj} hash: ${commit_hash}")
        message(STATUS
          "Installed ${prj} hash: ${${dep_prj}_GIT_COMMIT_HASH}")
        message(FATAL_ERROR "Commit hash not match!")
      endif()
    endif()

    include_directories("${${dep_prj}_INSTALL_PREFIX}/include")
    if (NOT ${prj}_${target}_DEPENDENCE_${dep_prj}_HEADER_ONLY)
      foreach(dep_lib
        ${${prj}_${target}_DEPENDENCE_${dep_prj}_DEPENDENCE_LIBS})
        _yong_target_add_dependence(${prj} ${target} ${dep_prj} ${dep_lib})
      endforeach()
    endif()
  endforeach()

endmacro()

macro(yong_project_end)
  set(prj ${YONG_PROJECT_NAME})
  _yong_install_cmake_file(${prj})
endmacro()
