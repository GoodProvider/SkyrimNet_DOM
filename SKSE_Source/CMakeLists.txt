cmake_minimum_required(VERSION 3.21)

project(SkyrimNet_DOM VERSION 0.2.0 LANGUAGES CXX RC)

set(MOD_FOLDER_NAME "SkyrimNet_DOM")

if(DEFINED ENV{SKYRIM_FOLDER} AND IS_DIRECTORY "$ENV{SKYRIM_FOLDER}/Data")
    set(OUTPUT_FOLDER "$ENV{SKYRIM_FOLDER}/Data")
endif()

if(DEFINED ENV{SKYRIM_MODS_FOLDER} AND IS_DIRECTORY "$ENV{SKYRIM_MODS_FOLDER}")
    set(OUTPUT_FOLDER "$ENV{SKYRIM_MODS_FOLDER}/${MOD_FOLDER_NAME}")
endif()

# Vendored MIT MinLL/CommonLibVR (see lib/CommonLibSSE-NG/VENDORED.md), same tree as SkyrimNet_SexLab.
set(CommonLibPath "lib/CommonLibSSE-NG")
set(CommonLibName "CommonLibSSE")

set(BUILD_TESTS       OFF CACHE BOOL "" FORCE)
set(SKSE_SUPPORT_XBYAK OFF CACHE BOOL "" FORCE)

# Static CRT, matching SkyrimNet_SexLab
set(VCPKG_TARGET_TRIPLET "x64-windows-static" CACHE STRING "")
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>" CACHE STRING "" FORCE)

add_subdirectory(${CommonLibPath} ${CommonLibName} EXCLUDE_FROM_ALL)
include("${CommonLibPath}/cmake/CommonLibSSE.cmake")

file(GLOB_RECURSE SOURCE_FILES
    CONFIGURE_DEPENDS
    "src/*.h"
    "src/*.cpp"
)

configure_file("src/Version.rc.in" "${CMAKE_CURRENT_BINARY_DIR}/Version.rc" @ONLY)

add_commonlibsse_plugin(${PROJECT_NAME} SOURCES ${SOURCE_FILES} "${CMAKE_CURRENT_BINARY_DIR}/Version.rc")

target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_23)
target_precompile_headers(${PROJECT_NAME} PRIVATE src/PCH.h)
target_include_directories(${PROJECT_NAME} PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
)

if(MSVC)
    # Workaround for MSBuild 17.14 bug: props file overrides ATL_KeyFile
    set(PROPS_FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.props")
    file(WRITE "${PROPS_FILE}" "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n")
    file(APPEND "${PROPS_FILE}" "<Project xmlns=\"http://schemas.microsoft.com/developer/msbuild/2003\">\n")
    file(APPEND "${PROPS_FILE}" "  <PropertyGroup>\n")
    file(APPEND "${PROPS_FILE}" "    <ATL_KeyFile></ATL_KeyFile>\n")
    file(APPEND "${PROPS_FILE}" "  </PropertyGroup>\n")
    file(APPEND "${PROPS_FILE}" "</Project>\n")
    set_target_properties(${PROJECT_NAME} PROPERTIES VS_USER_PROPS "${PROJECT_NAME}.props")

    set_property(TARGET ${PROJECT_NAME} PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    if(TARGET ${CommonLibName})
        set_property(TARGET ${CommonLibName} PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    endif()

    target_compile_options(${PROJECT_NAME} PRIVATE "/Zi")
    target_link_options(${PROJECT_NAME} PRIVATE "/DEBUG" "/INCREMENTAL:NO" "/OPT:REF" "/OPT:ICF")
endif()

# Debug builds are never deployed (SkyrimNet_SexLab KNOWLEDGEBASE "Debug SKSE DLL"):
# Debug only echoes; Release/RelWithDebInfo copy into SKSE/Plugins.
set(DEPLOY_OP "$<IF:$<CONFIG:Debug>,echo,copy_if_different>")

set(REPO_DLL_FOLDER "${CMAKE_CURRENT_SOURCE_DIR}/../SKSE/Plugins")
set(POST_BUILD_COPY
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${REPO_DLL_FOLDER}"
    COMMAND "${CMAKE_COMMAND}" -E ${DEPLOY_OP} "$<TARGET_FILE:${PROJECT_NAME}>" "${REPO_DLL_FOLDER}/$<TARGET_FILE_NAME:${PROJECT_NAME}>"
)

if(DEFINED OUTPUT_FOLDER)
    set(DLL_FOLDER "${OUTPUT_FOLDER}/SKSE/Plugins")
    message(STATUS "SKSE plugin output folder: ${DLL_FOLDER}")
    list(APPEND POST_BUILD_COPY
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${DLL_FOLDER}"
        COMMAND "${CMAKE_COMMAND}" -E ${DEPLOY_OP} "$<TARGET_FILE:${PROJECT_NAME}>" "${DLL_FOLDER}/$<TARGET_FILE_NAME:${PROJECT_NAME}>"
        COMMAND "${CMAKE_COMMAND}" -E ${DEPLOY_OP} "$<TARGET_PDB_FILE:${PROJECT_NAME}>" "${DLL_FOLDER}/$<TARGET_PDB_FILE_NAME:${PROJECT_NAME}>"
    )
endif()

add_custom_command(
    TARGET "${PROJECT_NAME}"
    POST_BUILD
    ${POST_BUILD_COPY}
    VERBATIM
)
