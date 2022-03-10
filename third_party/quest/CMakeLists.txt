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

if(NOT DEFINED CMAKE_CUDA_ARCHITECTURES)
  set(CMAKE_CUDA_ARCHITECTURES 60;70)
endif()

FetchContent_Declare(quest URL "https://gitee.com/donghufeng/QuEST/repository/archive/v3.2.1.tar.gz")
if(NOT quest_POPULATED)
  FetchContent_Populate(quest)
endif()

# ------------------------------------------------------------------------------
# Patch the source code

file(GLOB _patch_files "${CMAKE_CURRENT_LIST_DIR}/patch/*.patch*")
list(SORT _patch_files CASE INSENSITIVE)
apply_patches("${quest_SOURCE_DIR}" ${_patch_files})

# ==============================================================================

# Add QuEST as a sub-directory (NB: only used to create a new scope for temporary variables)
function(add_quest_subdirectory)
  set(GPUACCELERATED ${ENABLE_CUDA})
  set(TESTING OFF)
  set(GPU_COMPUTE_CAPABILITY ${CMAKE_CUDA_ARCHITECTURES})
  add_subdirectory("${quest_SOURCE_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/quest" EXCLUDE_FROM_ALL)
endfunction()

add_quest_subdirectory()
set_output_directory_auto(QuEST mindquantum)

# ==============================================================================

add_library(mq_quest INTERFACE)
target_sources(mq_quest INTERFACE quest.h quest_utils.h)

target_include_directories(mq_quest INTERFACE ${CMAKE_CURRENT_LIST_DIR})
target_link_libraries(mq_quest INTERFACE QuEST)
