# Based on SkyrimNet_SexLab's overlay triplet, but with a static CRT so vcpkg deps match the plugin's /MT
# (SexLab's copy uses dynamic CRT linkage, which fails to link against /MT with LNK2038).
set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE static)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_BUILD_TYPE release)
