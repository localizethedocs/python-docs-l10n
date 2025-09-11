# Distributed under the OSI-approved BSD 3-Clause License.
# See accompanying file LICENSE-BSD for details.

cmake_minimum_required(VERSION 3.25)
get_filename_component(SCRIPT_NAME "${CMAKE_CURRENT_LIST_FILE}" NAME_WE)
set(CMAKE_MESSAGE_INDENT "[${VERSION}][${LANGUAGE}] ")
set(CMAKE_MESSAGE_INDENT_BACKUP "${CMAKE_MESSAGE_INDENT}")
message(STATUS "-------------------- ${SCRIPT_NAME} --------------------")


set(CMAKE_MODULE_PATH   "${PROJ_CMAKE_MODULES_DIR}")
set(CMAKE_PROGRAM_PATH  "${PROJ_CONDA_DIR}"
                        "${PROJ_CONDA_DIR}/Library")
find_package(Git        MODULE REQUIRED)
find_package(Gettext    MODULE REQUIRED COMPONENTS Msgcat Msgmerge)
find_package(Python     MODULE REQUIRED COMPONENTS Interpreter)
find_package(Sphinx     MODULE REQUIRED COMPONENTS Build)
include(LogUtils)
include(GitUtils)
include(JsonUtils)
include(GettextUtils)


message(STATUS "Determining whether it is required to update .pot files...")
file(READ "${REFERENCES_JSON_PATH}" REFERENCES_JSON_CNT)
get_reference_of_latest_from_repo_and_current_from_json(
    IN_LOCAL_PATH                   "${PROJ_OUT_REPO_DIR}"
    IN_JSON_CNT                     "${REFERENCES_JSON_CNT}"
    IN_VERSION_TYPE                 "${VERSION_TYPE}"
    IN_BRANCH_NAME                  "${BRANCH_NAME}"
    IN_TAG_PATTERN                  "${TAG_PATTERN}"
    IN_TAG_SUFFIX                   "${TAG_SUFFIX}"
    IN_DOT_NOTATION                 ".pot"
    OUT_LATEST_OBJECT               LATEST_POT_OBJECT
    OUT_LATEST_REFERENCE            LATEST_POT_REFERENCE
    OUT_CURRENT_OBJECT              CURRENT_POT_OBJECT
    OUT_CURRENT_REFERENCE           CURRENT_POT_REFERENCE)
if (MODE_OF_UPDATE STREQUAL "COMPARE")
    if (NOT CURRENT_POT_REFERENCE STREQUAL LATEST_POT_REFERENCE)
        set(UPDATE_POT_REQUIRED     ON)
    else()
        set(UPDATE_POT_REQUIRED     OFF)
    endif()
elseif (MODE_OF_UPDATE STREQUAL "ALWAYS")
    set(UPDATE_POT_REQUIRED         ON)
elseif (MODE_OF_UPDATE STREQUAL "NEVER")
    if (NOT CURRENT_POT_REFERENCE)
        set(UPDATE_POT_REQUIRED     ON)
    else()
        set(UPDATE_POT_REQUIRED     OFF)
    endif()
else()
    message(FATAL_ERROR "Invalid MODE_OF_UPDATE value. (${MODE_OF_UPDATE})")
endif()
remove_cmake_message_indent()
message("")
message("LATEST_POT_OBJECT      = ${LATEST_POT_OBJECT}")
message("CURRENT_POT_OBJECT     = ${CURRENT_POT_OBJECT}")
message("LATEST_POT_REFERENCE   = ${LATEST_POT_REFERENCE}")
message("CURRENT_POT_REFERENCE  = ${CURRENT_POT_REFERENCE}")
message("MODE_OF_UPDATE         = ${MODE_OF_UPDATE}")
message("UPDATE_POT_REQUIRED    = ${UPDATE_POT_REQUIRED}")
message("")
restore_cmake_message_indent()


#[================================================================================[
# Required. Otherwise, AttributeError: 'Sphinx' object has no attribute 'add_description_unit'
#
# For version 3.5, to resolve the following error message in pyspecific.py:
#
# ```bash
# Exception occurred:
#
#   File "/project-local-path/out/repo/Doc/tools/extensions/pyspecific.py", line 382, in setup
#     app.add_description_unit('opcode', 'opcode', '%s (opcode)',
#
# AttributeError: 'Sphinx' object has no attribute 'add_description_unit'
# ```
#]================================================================================]


if (VERSION MATCHES "^(2.6|3.0|3.1|3.2|3.5)$")
    message(STATUS "Copying '3.6/pyspecific.py' file to the sphinx extensions directory...")
    configure_file(
        "${PROJ_CMAKE_CUSTOM_DIR}/3.6/pyspecific.py"
        "${PROJ_OUT_REPO_DOCS_EXTNS_DIR}/pyspecific.py")
    remove_cmake_message_indent()
    message("")
    message("From:  ${PROJ_CMAKE_CUSTOM_DIR}/3.6/pyspecific.py")
    message("To:    ${PROJ_OUT_REPO_DOCS_EXTNS_DIR}/pyspecific.py")
    message("")
    restore_cmake_message_indent()
    message(STATUS "Copying '3.6/suspicious.py' file to the sphinx extensions directory...")
    configure_file(
        "${PROJ_CMAKE_CUSTOM_DIR}/3.6/suspicious.py"
        "${PROJ_OUT_REPO_DOCS_EXTNS_DIR}/suspicious.py")
    remove_cmake_message_indent()
    message("")
    message("From:  ${PROJ_CMAKE_CUSTOM_DIR}/3.6/suspicious.py")
    message("To:    ${PROJ_OUT_REPO_DOCS_EXTNS_DIR}/suspicious.py")
    message("")
    restore_cmake_message_indent()
endif()


#[================================================================================[
# Python Docs ~v3.3.2 requires the 'sphinx.ext.refcounting' extension. However,
# the 'sphinx.ext.refcounting' extension was removed in Sphinx 1.2. Thus, it is
# recommended to install Sphinx versions earlier than 1.2. (required: sphinx<1.2)
# See: https://www.sphinx-doc.org/en/master/changes/1.2.html#release-1-2-released-dec-10-2013
#
# However, the '--version' option for the sphinx-build command was not introduced
# until Sphinx 1.2.3. Without this option, the find_package(Sphinx) command will
# fail. Thus, Sphinx 1.2.3 or later is required. (required: sphinx>=1.2.3)
# See: https://www.sphinx-doc.org/en/master/changes/1.2.html#release-1-2-3-released-sep-1-2014
#
# This creates a version conflict. Therefore, just remove it.
#
# See:
# - https://github.com/python/cpython/blob/v2.6.9/Doc/conf.py#L16
# - https://github.com/python/cpython/blob/v3.0.1/Doc/conf.py#L16
# - https://github.com/python/cpython/blob/v3.1.5/Doc/conf.py#L16
# - https://github.com/python/cpython/blob/v3.2.6/Doc/conf.py#L15
#]================================================================================]


if (VERSION MATCHES "^(2.6|3.0|3.1|3.2)$")
    message(STATUS "Removing 'sphinx.ext.refcounting' from 'extensions' list in 'conf.py' file...")
    set(DOCS_CONF_PY_FILE "${PROJ_OUT_REPO_DOCS_CONFIG_DIR}/conf.py")
    file(READ "${DOCS_CONF_PY_FILE}" DOCS_CONF_PY_CNT)
    set(EXTENSIONS_LIST_REGEX "extensions[ ]*=[ ]*[\[][^\]]*[\]]")
    string(REGEX MATCH "${EXTENSIONS_LIST_REGEX}" OLD_EXTENSIONS_LIST "${DOCS_CONF_PY_CNT}")
    if (OLD_EXTENSIONS_LIST)
        string(REGEX REPLACE "'sphinx.ext.refcounting'[ ]*,[ ]*" "" NEW_EXTENSIONS_LIST "${OLD_EXTENSIONS_LIST}")
        string(REGEX REPLACE "${EXTENSIONS_LIST_REGEX}" "${NEW_EXTENSIONS_LIST}" DOCS_CONF_PY_CNT "${DOCS_CONF_PY_CNT}")
        file(WRITE "${DOCS_CONF_PY_FILE}" "${DOCS_CONF_PY_CNT}")
        remove_cmake_message_indent()
        message("")
        message("${DOCS_CONF_PY_FILE}")
        message("[OLD_EXTENSIONS_LIST_BEGIN]")
        message("${OLD_EXTENSIONS_LIST}")
        message("[OLD_EXTENSIONS_LIST_END]")
        message("[NEW_EXTENSIONS_LIST_BEGIN]")
        message("${NEW_EXTENSIONS_LIST}")
        message("[NEW_EXTENSIONS_LIST_END]")
        message("")
        restore_cmake_message_indent()
    endif()
endif()


#[================================================================================[
# Patch for Python 2 print statement in 'patchlevel.py' to ensure compatibility with Python 3.
#
# In Python 2, 'print' is a statement, while in Python 3, it is a function.
# This patch updates the print statement in 'patchlevel.py' to use Python 3 syntax.
#
# Officially, Python 2.6, 3.0, and 3.1 should be built using Python 2.
# However, since we are building with Python 3, a patch is required to fix
# Python 2 print statements in 'patchlevel.py' for compatibility with Python 3.
#
# See:
# - https://github.com/python/cpython/blob/v2.6.9/Doc/tools/sphinxext/patchlevel.py#L71
# - https://github.com/python/cpython/blob/v3.0.1/Doc/tools/sphinxext/patchlevel.py#L71
# - https://github.com/python/cpython/blob/v3.1.5/Doc/tools/sphinxext/patchlevel.py#L71
#]================================================================================]


if (VERSION MATCHES "^(2.6|3.0|3.1)$")
    message(STATUS "Patching 'patchlevel.py' to use Python 3 print function syntax...")
    set(PATCHLEVEL_PY_FILE "${PROJ_OUT_REPO_DOCS_EXTNS_DIR}/patchlevel.py")
    file(READ "${PATCHLEVEL_PY_FILE}" PATCHLEVEL_PY_CNT)
    set(PRINT_STATEMENT_REGEX "print get_header_version_info\\('\\.'\\)\\[1\\]")
    string(REGEX MATCH "${PRINT_STATEMENT_REGEX}" OLD_PRINT_STATEMENT "${PATCHLEVEL_PY_CNT}")
    if (OLD_PRINT_STATEMENT)
        set(NEW_PRINT_STATEMENT "print(get_header_version_info('.')[1])")
        string(REPLACE "${OLD_PRINT_STATEMENT}" "${NEW_PRINT_STATEMENT}" PATCHLEVEL_PY_CNT "${PATCHLEVEL_PY_CNT}")
        file(WRITE "${PATCHLEVEL_PY_FILE}" "${PATCHLEVEL_PY_CNT}")
        remove_cmake_message_indent()
        message("")
        message("${PATCHLEVEL_PY_FILE}")
        message("[OLD_PRINT_STATEMENT_BEGIN]")
        message("${OLD_PRINT_STATEMENT}")
        message("[OLD_PRINT_STATEMENT_END]")
        message("[NEW_PRINT_STATEMENT_BEGIN]")
        message("${NEW_PRINT_STATEMENT}")
        message("[NEW_PRINT_STATEMENT_END]")
        message("")
        restore_cmake_message_indent()
    endif()
endif()


message(STATUS "Adding 'custom' into 'extensions' list in 'conf.py' file...")
set(SPHINX_CONF_PY_FILE "${PROJ_OUT_REPO_DOCS_CONFIG_DIR}/conf.py")
file(READ "${SPHINX_CONF_PY_FILE}" SPHINX_CONF_PY_CNT)
set(EXTENSIONS_LIST_REGEX "([^a-zA-Z_]|^)(extensions[ ]*=[ ]*[\[])([^\]]*[\]])")
string(REGEX MATCH "${EXTENSIONS_LIST_REGEX}" OLD_EXTENSIONS_LIST "${SPHINX_CONF_PY_CNT}")
if (OLD_EXTENSIONS_LIST)
    if (NOT OLD_EXTENSIONS_LIST MATCHES "\"custom\"")
        string(REGEX REPLACE "${EXTENSIONS_LIST_REGEX}" "\\1\\2\"custom\", \\3" NEW_EXTENSIONS_LIST "${OLD_EXTENSIONS_LIST}")
        string(REGEX REPLACE "${EXTENSIONS_LIST_REGEX}" "${NEW_EXTENSIONS_LIST}" SPHINX_CONF_PY_CNT "${SPHINX_CONF_PY_CNT}")
        file(WRITE "${SPHINX_CONF_PY_FILE}" "${SPHINX_CONF_PY_CNT}")
        remove_cmake_message_indent()
        message("")
        message("Added 'custom' into 'extensions' list in 'conf.py' file.")
        message("File: ${SPHINX_CONF_PY_FILE}")
        message("")
        message("[OLD_EXTENSIONS_LIST_BEGIN]")
        message("${OLD_EXTENSIONS_LIST}")
        message("[OLD_EXTENSIONS_LIST_END]")
        message("[NEW_EXTENSIONS_LIST_BEGIN]")
        message("${NEW_EXTENSIONS_LIST}")
        message("[NEW_EXTENSIONS_LIST_END]")
        message("")
        restore_cmake_message_indent()
    else()
        remove_cmake_message_indent()
        message("")
        message("No need to add 'custom' into 'extensions' list in 'conf.py' file.")
        message("File: ${SPHINX_CONF_PY_FILE}")
        message("")
        message("[OLD_EXTENSIONS_LIST_BEGIN]")
        message("${OLD_EXTENSIONS_LIST}")
        message("[OLD_EXTENSIONS_LIST_END]")
        message("")
        restore_cmake_message_indent()
    endif()
else()
    set(EXTENSIONS_LIST "extensions = [\"custom\"]")
    file(APPEND "${SPHINX_CONF_PY_FILE}" "\n${EXTENSIONS_LIST}\n")
    remove_cmake_message_indent()
    message("")
    message("'extensions' list not found. Appending '${EXTENSIONS_LIST}' to 'conf.py' file.")
    message("File: ${SPHINX_CONF_PY_FILE}")
    message("")
    message("[NEWLY_ADDED_CONTENT_BEGIN]")
    message("${EXTENSIONS_LIST}")
    message("[NEWLY_ADDED_CONTENT_END]")
    message("")
    restore_cmake_message_indent()
endif()


message(STATUS "Copying 'custom.py' file to the sphinx extensions directory...")
file(MAKE_DIRECTORY "${PROJ_OUT_REPO_DOCS_EXTNS_DIR}")
file(COPY_FILE
    "${PROJ_CMAKE_CUSTOM_DIR}/custom.py"
    "${PROJ_OUT_REPO_DOCS_EXTNS_DIR}/custom.py")
remove_cmake_message_indent()
message("")
message("From:  ${PROJ_CMAKE_CUSTOM_DIR}/custom.py")
message("To:    ${PROJ_OUT_REPO_DOCS_EXTNS_DIR}/custom.py")
message("")
restore_cmake_message_indent()


message(STATUS "Copying 'layout.html' file to the sphinx templates directory...")
file(MAKE_DIRECTORY "${PROJ_OUT_REPO_DOCS_TMPLS_DIR}")
file(COPY_FILE
    "${PROJ_CMAKE_CUSTOM_DIR}/layout.html"
    "${PROJ_OUT_REPO_DOCS_TMPLS_DIR}/layout.html")
remove_cmake_message_indent()
message("")
message("From: ${PROJ_CMAKE_CUSTOM_DIR}/layout.html")
message("To:   ${PROJ_OUT_REPO_DOCS_TMPLS_DIR}/layout.html")
message("")
restore_cmake_message_indent()


message(STATUS "Copying 'indexsidebar.html' file to the sphinx templates directory...")
file(MAKE_DIRECTORY "${PROJ_OUT_REPO_DOCS_TMPLS_DIR}")
file(COPY_FILE
    "${PROJ_CMAKE_CUSTOM_DIR}/indexsidebar.html"
    "${PROJ_OUT_REPO_DOCS_TMPLS_DIR}/indexsidebar.html")
remove_cmake_message_indent()
message("")
message("From: ${PROJ_CMAKE_CUSTOM_DIR}/indexsidebar.html")
message("To:   ${PROJ_OUT_REPO_DOCS_TMPLS_DIR}/indexsidebar.html")
message("")
restore_cmake_message_indent()


message(STATUS "Copying 'versions.json' file to the sphinx config directory...")
file(MAKE_DIRECTORY "${PROJ_OUT_REPO_DOCS_CONFIG_DIR}")
file(COPY_FILE
    "${PROJ_CMAKE_CUSTOM_DIR}/versions.json"
    "${PROJ_OUT_REPO_DOCS_CONFIG_DIR}/versions.json")
remove_cmake_message_indent()
message("")
message("From:  ${PROJ_CMAKE_CUSTOM_DIR}/versions.json")
message("To:    ${PROJ_OUT_REPO_DOCS_CONFIG_DIR}/versions.json")
message("")
restore_cmake_message_indent()


if (NOT UPDATE_POT_REQUIRED)
    message(STATUS "No need to update .pot files.")
    return()
else()
    message(STATUS "Prepare to update .pot files.")
endif()


message(STATUS "Removing directory '${PROJ_OUT_REPO_DOCS_LOCALE_DIR}/'...")
if (EXISTS "${PROJ_OUT_REPO_DOCS_LOCALE_DIR}")
    file(REMOVE_RECURSE "${PROJ_OUT_REPO_DOCS_LOCALE_DIR}")
    remove_cmake_message_indent()
    message("")
    message("Directory '${PROJ_OUT_REPO_DOCS_LOCALE_DIR}/' exists.")
    message("Removed '${PROJ_OUT_REPO_DOCS_LOCALE_DIR}/'.")
    message("")
    restore_cmake_message_indent()
else()
    remove_cmake_message_indent()
    message("")
    message("Directory '${PROJ_OUT_REPO_DOCS_LOCALE_DIR}/' does NOT exist.")
    message("No need to remove '${PROJ_OUT_REPO_DOCS_LOCALE_DIR}/'.")
    message("")
    restore_cmake_message_indent()
endif()


message(STATUS "Running 'sphinx-build' command with 'gettext' builder to generate .pot files...")
if (CMAKE_HOST_LINUX)
    set(ENV_PATH                "${PROJ_CONDA_DIR}/bin:$ENV{PATH}")
    set(ENV_LD_LIBRARY_PATH     "${PROJ_CONDA_DIR}/lib:$ENV{ENV_LD_LIBRARY_PATH}")
    set(ENV_PYTHONPATH          "${PROJ_OUT_REPO_DOCS_EXTNS_DIR}")
    set(ENV_VARS_OF_SYSTEM      PATH=${ENV_PATH}
                                LD_LIBRARY_PATH=${ENV_LD_LIBRARY_PATH}
                                PYTHONPATH=${ENV_PYTHONPATH})
elseif (CMAKE_HOST_WIN32)
    set(ENV_PATH                "${PROJ_CONDA_DIR}/bin"
                                "${PROJ_CONDA_DIR}/Scripts"
                                "${PROJ_CONDA_DIR}/Library/bin"
                                "${PROJ_CONDA_DIR}"
                                "$ENV{PATH}")
    set(ENV_PYTHONPATH          "${PROJ_OUT_REPO_DOCS_EXTNS_DIR}")
    string(REPLACE ";" "\\\\;" ENV_PATH "${ENV_PATH}")
    string(REPLACE ";" "\\\\;" ENV_PYTHONPATH "${ENV_PYTHONPATH}")
    set(ENV_VARS_OF_SYSTEM      PATH=${ENV_PATH}
                                PYTHONPATH=${ENV_PYTHONPATH})
else()
    message(FATAL_ERROR "Invalid OS platform. (${CMAKE_HOST_SYSTEM_NAME})")
endif()
set(WARNING_FILE_PATH           "${PROJ_BINARY_DIR}/log-gettext-${VERSION}.txt")
remove_cmake_message_indent()
message("")
execute_process(
    COMMAND ${CMAKE_COMMAND} -E env
            ${ENV_VARS_OF_SYSTEM}
            ${Sphinx_BUILD_EXECUTABLE}
            -b gettext
            -D templates_path=${TMPLS_TO_SOURCE_DIR}            # Relative to <sourcedir>.
            -D gettext_compact=${SPHINX_GETTEXT_COMPACT}
            -D gettext_additional_targets=${SPHINX_GETTEXT_TARGETS}
            -w ${WARNING_FILE_PATH}
            -j ${SPHINX_JOB_NUMBER}
            ${SPHINX_VERBOSE_ARGS}
            -c ${PROJ_OUT_REPO_DOCS_CONFIG_DIR}                 # <configdir>, where conf.py locates.
            ${PROJ_OUT_REPO_DOCS_SOURCE_DIR}                    # <sourcedir>, where index.rst locates.
            ${PROJ_OUT_REPO_DOCS_LOCALE_DIR}/pot/LC_MESSAGES    # <outputdir>, where .pot generates.
    WORKING_DIRECTORY ${PROJ_OUT_REPO_DOCS_DIR}
    ECHO_OUTPUT_VARIABLE
    ECHO_ERROR_VARIABLE
    RESULT_VARIABLE RES_VAR
    OUTPUT_VARIABLE OUT_VAR OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_VARIABLE  ERR_VAR ERROR_STRIP_TRAILING_WHITESPACE)
if (RES_VAR EQUAL 0)
    if (ERR_VAR)
        string(APPEND WARNING_REASON
        "The command succeeded with warnings.\n\n"
        "    result:\n\n${RES_VAR}\n\n"
        "    stderr:\n\n${ERR_VAR}")
        message("${WARNING_REASON}")
    endif()
else()
    string(APPEND FAILURE_REASON
    "The command failed with fatal errors.\n"
    "    result:\n${RES_VAR}\n"
    "    stderr:\n${ERR_VAR}")
    message(FATAL_ERROR "${FAILURE_REASON}")
endif()
message("")
restore_cmake_message_indent()


message(STATUS "Running 'msgcat' command to update 'sphinx.pot' file...")
execute_process(
    COMMAND ${Python_EXECUTABLE} -c "import sphinx; print(sphinx.__file__);"
    RESULT_VARIABLE RES_VAR
    OUTPUT_VARIABLE OUT_VAR OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_VARIABLE  ERR_VAR ERROR_STRIP_TRAILING_WHITESPACE)
if (RES_VAR EQUAL 0)
    get_filename_component(SPHINX_LIB_DIR "${OUT_VAR}" DIRECTORY)
else()
    string(APPEND FAILURE_REASON
    "The command failed with fatal errors.\n"
    "    result:\n${RES_VAR}\n"
    "    stdout:\n${OUT_VAR}\n"
    "    stderr:\n${ERR_VAR}")
    message(FATAL_ERROR "${FAILURE_REASON}")
endif()
set(DEFAULT_SPHINX_POT_FILE "${SPHINX_LIB_DIR}/locale/sphinx.pot")
set(PACKAGE_SPHINX_POT_FILE "${PROJ_OUT_REPO_DOCS_LOCALE_DIR}/pot/LC_MESSAGES/sphinx.pot")
remove_cmake_message_indent()
message("")
message("From: ${DEFAULT_SPHINX_POT_FILE}")
message("To:   ${PACKAGE_SPHINX_POT_FILE}")
message("")
update_sphinx_pot_from_def_to_pkg(
    IN_DEF_FILE     "${DEFAULT_SPHINX_POT_FILE}"
    IN_PKG_FILE     "${PACKAGE_SPHINX_POT_FILE}"
    IN_WRAP_WIDTH   "${GETTEXT_WRAP_WIDTH}")
message("")
restore_cmake_message_indent()


message(STATUS "Running 'msgmerge/msgcat' command to update .pot files...")
set(SRC_POT_DIR "${PROJ_OUT_REPO_DOCS_LOCALE_DIR}/pot")
set(DST_POT_DIR "${PROJ_L10N_VERSION_LOCALE_DIR}/pot")
remove_cmake_message_indent()
message("")
message("From: ${SRC_POT_DIR}/")
message("To:   ${DST_POT_DIR}/")
message("")
update_pot_from_src_to_dst(
    IN_SRC_DIR      "${SRC_POT_DIR}"
    IN_DST_DIR      "${DST_POT_DIR}"
    IN_WRAP_WIDTH   "${GETTEXT_WRAP_WIDTH}")
message("")
restore_cmake_message_indent()


set_json_value_by_dot_notation(
    IN_JSON_OBJECT      "${REFERENCES_JSON_CNT}"
    IN_DOT_NOTATION     ".pot"
    IN_JSON_VALUE       "${LATEST_POT_OBJECT}"
    OUT_JSON_OBJECT     REFERENCES_JSON_CNT)


file(WRITE "${REFERENCES_JSON_PATH}" "${REFERENCES_JSON_CNT}")
