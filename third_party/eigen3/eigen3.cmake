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

set(VER 3.4.0)
set(MD5 "4c527a9171d71a72a9d4186e65bea559")
set(REQ_URL "https://gitlab.com/libeigen/eigen/-/archive/${VER}/eigen-${VER}.tar.gz")

set(CMAKE_OPTION -DBUILD_TESTING=OFF -DEIGEN_BUILD_DOC=OFF -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
                 -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -G${CMAKE_GENERATOR})

if(CMAKE_C_COMPILER)
  list(APPEND CMAKE_OPTION -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER})
endif()

if(DISABLE_FORTRAN_COMPILER)
  list(APPEND CMAKE_OPTION -DCMAKE_Fortran_COMPILER=NOTFOUND)
endif()

if(MSVC)
  list(APPEND CMAKE_OPTION -DCMAKE_CXX_STANDARD=11 -DEIGEN_COMPILER_SUPPORT_CPP11=ON)
endif()

mindquantum_add_pkg(
  Eigen3
  VER ${VER}
  URL ${REQ_URL}
  MD5 ${MD5}
  CMAKE_OPTION ${CMAKE_OPTION}
  TARGET_ALIAS mindquantum::eigen Eigen3::Eigen)
