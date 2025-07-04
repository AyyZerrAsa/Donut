#
# Copyright (c) 2014-2020, NVIDIA CORPORATION. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.


file(GLOB donut_app_src
    LIST_DIRECTORIES false
    include/donut/app/*.h
    src/app/*.cpp
)

#[[ 26/06/2025 ]]
list(FILTER donut_app_src EXCLUDE REGEX ".*imgui_nvrhi\\.cpp$")
list(FILTER donut_app_src EXCLUDE REGEX ".*imgui_console\\.h$")
list(FILTER donut_app_src EXCLUDE REGEX ".*imgui_console\\.cpp$")
list(FILTER donut_app_src EXCLUDE REGEX ".*UserInterfaceUtils\\.cpp$")
list(FILTER donut_app_src EXCLUDE REGEX ".*imgui_nvrhi\\.h$")
list(FILTER donut_app_src EXCLUDE REGEX ".*imgui_renderer\\.h$")
list(FILTER donut_app_src EXCLUDE REGEX ".*imgui_renderer\\.cpp$")

file(GLOB donut_app_vr_src
    include/donut/app/vr/*.h
    src/app/vr/*.cpp
)

add_library(donut_app STATIC EXCLUDE_FROM_ALL ${donut_app_src})
target_include_directories(donut_app PUBLIC include)

#link streamline since we need to link before d3d11, d3d12, dxgi functions
if(DONUT_WITH_STREAMLINE)
target_sources(donut_app PRIVATE src/app/streamline/StreamlineIntegration.cpp)
target_include_directories(donut_app PRIVATE src/app/streamline/)
target_link_libraries(donut_app streamline)

if(DONUT_WITH_VULKAN)
# Override vulkan dll used by glfw
target_compile_definitions(glfw PRIVATE _GLFW_VULKAN_LIBRARY="sl.interposer.dll")
endif()

# The STREAMLINE_FEATURE_... options come from the Streamline CMakeLists.txt
if (STREAMLINE_FEATURE_DEEPDVC)
    target_compile_definitions(donut_app PRIVATE STREAMLINE_FEATURE_DEEPDVC)
endif()
if (STREAMLINE_FEATURE_DIRECTSR)
    target_compile_definitions(donut_app PRIVATE STREAMLINE_FEATURE_DIRECTSR)
endif()
if(STREAMLINE_FEATURE_DLSS_SR)
    target_compile_definitions(donut_app PRIVATE STREAMLINE_FEATURE_DLSS_SR)
endif()
if (STREAMLINE_FEATURE_DLSS_FG)
    target_compile_definitions(donut_app PRIVATE STREAMLINE_FEATURE_DLSS_FG)
endif()
if (STREAMLINE_FEATURE_DLSS_RR)
    target_compile_definitions(donut_app PRIVATE STREAMLINE_FEATURE_DLSS_RR)
endif()
if(STREAMLINE_FEATURE_IMGUI)
    target_compile_definitions(donut_app PRIVATE STREAMLINE_FEATURE_IMGUI)
endif()
if(STREAMLINE_FEATURE_NIS)
    target_compile_definitions(donut_app PRIVATE STREAMLINE_FEATURE_NIS)
endif()
if(STREAMLINE_FEATURE_NVPERF)
    target_compile_definitions(donut_app PRIVATE STREAMLINE_FEATURE_NVPERF)
endif()
if(STREAMLINE_FEATURE_REFLEX)
    target_compile_definitions(donut_app PRIVATE STREAMLINE_FEATURE_REFLEX)
endif()

endif() #DONUT_WITH_STREAMLINE
#[[ 26/06/2025 ]]
#[[target_link_libraries(donut_app donut_core donut_engine glfw imgui)]]
target_link_libraries(donut_app donut_core donut_engine glfw)

if(DONUT_WITH_DX11)
    target_sources(donut_app PRIVATE src/app/dx11/DeviceManager_DX11.cpp)
    if (NOT NVRHI_BUILD_SHARED)
        target_link_libraries(donut_app nvrhi_d3d11)
    endif()
    target_link_libraries(donut_app d3d11 dxgi dxguid)
endif()

if(DONUT_WITH_DX12)
    target_sources(donut_app PRIVATE src/app/dx12/DeviceManager_DX12.cpp)
    if (NOT NVRHI_BUILD_SHARED)
        target_link_libraries(donut_app nvrhi_d3d12)
    endif()
    target_link_libraries(donut_app d3d12 dxgi dxguid)
endif()

if(DONUT_WITH_VULKAN)
    target_sources(donut_app PRIVATE src/app/vulkan/DeviceManager_VK.cpp)
    if (NOT NVRHI_BUILD_SHARED)
        target_link_libraries(donut_app nvrhi_vk)
    endif()
    target_link_libraries(donut_app Vulkan-Headers)
endif()

if(DONUT_WITH_AFTERMATH)
    target_sources(donut_app PRIVATE src/app/aftermath/AftermathCrashDump.cpp)
endif()

target_compile_definitions(donut_app PUBLIC DONUT_WITH_AFTERMATH=$<BOOL:${DONUT_WITH_AFTERMATH}>)
target_compile_definitions(donut_app PUBLIC DONUT_WITH_STREAMLINE=$<BOOL:${DONUT_WITH_STREAMLINE}>)

if (WIN32)
    target_compile_definitions(donut_app PRIVATE DONUT_FORCE_DISCRETE_GPU=$<BOOL:${DONUT_FORCE_DISCRETE_GPU}>)
endif()

target_link_libraries(donut_app nvrhi) # needs to come after nvrhi_d3d11 etc. for link order

add_dependencies(donut_app donut_shaders)

set_target_properties(donut_app PROPERTIES FOLDER Donut)

if (DONUT_WITH_STATIC_SHADERS)
    target_include_directories(donut_app PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/shaders")
endif()
