# ==============================================================================
#
# Copyright 2020 <Huawei Technologies Co., Ltd>
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

find_package(Catch2 CONFIG REQUIRED)
list(APPEND CMAKE_MODULE_PATH ${Catch2_DIR})

include(CTest)
include(Catch)
# include(ParseAndAddCatchTests)

# ==============================================================================

add_subdirectory(core)
add_subdirectory(decompositions)
add_subdirectory(mapping)
add_subdirectory(ops)
add_subdirectory(optimisation)

# ==============================================================================

# add_test(NAME pytest COMMAND ${Python_EXECUTABLE} -m pytest -p no:warnings -v ${CMAKE_CURRENT_LIST_DIR})

# ==============================================================================

install(FILES ${CMAKE_CURRENT_LIST_DIR}/utils.hpp DESTINATION ${MQ_INSTALL_INCLUDEDIR}/tests)
install(
  DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/core ${CMAKE_CURRENT_LIST_DIR}/ops
  DESTINATION ${MQ_INSTALL_INCLUDEDIR}/tests
  FILES_MATCHING
  PATTERN "*.hpp")

# ==============================================================================
