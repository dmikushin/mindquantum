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

include(${CMAKE_CURRENT_LIST_DIR}/cmake/utils.cmake)

# ==============================================================================

if(ENABLE_PROJECTQ)
  add_subdirectory(projectq)
endif()

if(ENABLE_QUEST)
  add_subdirectory(quest)
endif()

# =============================================================================

include(${CMAKE_CURRENT_LIST_DIR}/pybind11/pybind11.cmake)

if(ENABLE_CXX_EXPERIMENTAL)
  set(_include_boost FALSE)

  if(NOT MQ_HAS_STD_FILESYSTEM)
    set(_include_boost TRUE)
  endif()

  if(NOT MSVC AND NOT "${OS_NAME}" STREQUAL "MinGW")
    include(${CMAKE_CURRENT_LIST_DIR}/gmp/gmp.cmake)
  else()
    set(_include_boost TRUE)
  endif()

  if(_include_boost)
    include(${CMAKE_CURRENT_LIST_DIR}/boost/boost.cmake)
  endif()
  include(${CMAKE_CURRENT_LIST_DIR}/nlohmann_json/nlohmann_json.cmake)
  include(${CMAKE_CURRENT_LIST_DIR}/fmt/fmt.cmake)
  include(${CMAKE_CURRENT_LIST_DIR}/eigen3/eigen3.cmake)
  include(${CMAKE_CURRENT_LIST_DIR}/symengine/symengine.cmake)
  include(${CMAKE_CURRENT_LIST_DIR}/tweedledum/tweedledum.cmake)

  if(BUILD_TESTING)
    include(${CMAKE_CURRENT_LIST_DIR}/catch2/catch2.cmake)
  endif()
endif()
