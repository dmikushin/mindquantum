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

set(VER 2.9.1)

if(ENABLE_GITEE)
  set(REQ_URL "https://gitee.com/mirrors/pybind11/repository/archive/v${VER}.tar.gz")
  set(MD5 "47bd7a20616521d9b213677cdec7f684")
else()
  set(REQ_URL "https://github.com/pybind/pybind11/archive/v${VER}.tar.gz")
  set(MD5 "7609dcb4e6e18eee9dc1a5f26572ded1")
endif()

set(CMAKE_OPTION -DPYBIND11_TEST=OFF -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
                 -G${CMAKE_GENERATOR})

if(CMAKE_C_COMPILER)
  list(APPEND CMAKE_OPTION -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER})
endif()

if(WIN32)
  set(TARGET_ALIAS_EXTRA TARGET_ALIAS mindquantum::windows_extra pybind11::windows_extras)
endif()

# cmake-lint: disable=E1122
mindquantum_add_pkg(
  pybind11
  VER ${VER}
  URL ${REQ_URL}
  MD5 ${MD5}
  CMAKE_OPTION ${CMAKE_OPTION}
  TARGET_ALIAS mindquantum::pybind11_headers pybind11::headers
  TARGET_ALIAS mindquantum::pybind11_module pybind11::module
  TARGET_ALIAS mindquantum::pybind11_lto pybind11::lto ${TARGET_ALIAS_EXTRA}) # cmake-lint: disable=E1122
