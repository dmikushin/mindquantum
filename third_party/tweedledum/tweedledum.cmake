# ==============================================================================
#
# Copyright 2022 <Huawei Technologies Co., Ltd>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License.  You may obtain a copy of
# the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.
#
# ==============================================================================

set(TWEEDLEDUM_PYBINDS OFF)
set(TWEEDLEDUM_USE_EXTERNAL_FMT OFF)

if(TWEEDLEDUM_DIR)
  message(STATUS "Using Tweedledum from external directory: ${TWEEDLEDUM_DIR}")
  list(APPEND CMAKE_MODULE_PATH ${TWEEDLEDUM_DIR}/cmake)
  add_subdirectory(${TWEEDLEDUM_DIR} ${CMAKE_CURRENT_BINARY_DIR}/tweedledum EXCLUDE_FROM_ALL)
elseif(EXISTS ${CMAKE_CURRENT_LIST_DIR}/../tweedledum/cmake)
  list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/../tweedledum/cmake)
  add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/../tweedledum EXCLUDE_FROM_ALL)
else()
  find_package(tweedledum REQUIRED)
endif()

if(TARGET tweedledum)
  get_target_property(_lib_type tweedledum TYPE)
  if(_lib_type STREQUAL "OBJECT_LIBRARY")
    add_library(tweedledum_lib STATIC $<TARGET_OBJECTS:tweedledum>)

    get_target_property(_link_libs tweedledum INTERFACE_LINK_LIBRARIES)
    target_link_libraries(tweedledum_lib PUBLIC ${_link_libs})
    get_target_property(_inc_dirs tweedledum INTERFACE_INCLUDE_DIRECTORIES)
    target_include_directories(tweedledum_lib PUBLIC ${_inc_dirs})
    target_link_libraries(tweedledum_lib INTERFACE ${_zlib_tgt})
  else()
    target_link_libraries(tweedledum INTERFACE ${_zlib_tgt})
    add_library(tweedledum_lib ALIAS tweedledum)
  endif()
else()
  target_link_libraries(tweedledum::tweedledum INTERFACE ${_zlib_tgt})
  add_library(tweedledum_lib ALIAS tweedledum::tweedledum)
endif()
