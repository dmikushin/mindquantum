# ==============================================================================
#
# Copyright 2021 <Huawei Technologies Co., Ltd>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ==============================================================================
# Fetch the source code

FetchContent_Declare(projectq URL "https://gitee.com/mirrors/ProjectQ/repository/archive/v0.5.1.tar.gz")
if(NOT projectq_POPULATED)
  FetchContent_Populate(projectq)
endif()

# ------------------------------------------------------------------------------
# Patch the source code

file(GLOB _patch_files "${CMAKE_CURRENT_LIST_DIR}/patch/*.patch*")
list(SORT _patch_files CASE INSENSITIVE)
apply_patches("${projectq_SOURCE_DIR}" ${_patch_files})

# ==============================================================================

add_library(projectq INTERFACE)
target_compile_features(projectq INTERFACE cxx_std_14)
target_include_directories(projectq INTERFACE ${projectq_SOURCE_DIR})

# ==============================================================================

add_library(mq_projectq INTERFACE)
target_sources(mq_projectq INTERFACE projectq.h projectq_utils.h)

target_compile_definitions(mq_projectq INTERFACE INTRIN)
target_include_directories(mq_projectq INTERFACE ${CMAKE_CURRENT_LIST_DIR})
target_link_libraries(mq_projectq INTERFACE projectq intrin_flag_CXX)
