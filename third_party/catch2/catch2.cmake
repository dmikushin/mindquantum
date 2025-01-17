# ==============================================================================
#
# Copyright 2022 <Huawei Technologies Co., Ltd>
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

# cmake-lint: disable=C0103

set(REQ_URL "https://github.com/catchorg/Catch2/archive/refs/tags/v2.13.9.tar.gz")
set(MD5 "feda9b6fd01621d404537d38df56ff83")

set(CMAKE_OPTION
    -DCATCH_BUILD_TESTING=OFF
    -DCATCH_INSTALL_DOCS=OFF
    -DCATCH_INSTALL_HELPERS=ON
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -G${CMAKE_GENERATOR})

if(CMAKE_C_COMPILER)
  list(APPEND CMAKE_OPTION -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER})
endif()

mindquantum_add_pkg(
  Catch2
  VER 2.13.0
  URL ${REQ_URL}
  MD5 ${MD5}
  CMAKE_PKG_NO_COMPONENTS
  CMAKE_OPTION ${CMAKE_OPTION}
  TARGET_ALIAS mindquantum::catch2 Catch2::Catch2
  SKIP_IN_INSTALL_CONFIG)
