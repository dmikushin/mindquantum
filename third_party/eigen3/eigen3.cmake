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

if(MSVC)
  set(VER 3.4.0)
  set(MD5 "4c527a9171d71a72a9d4186e65bea559")
else()
  set(VER 3.3.9)
  set(MD5 "609286804b0f79be622ccf7f9ff2b660")
endif()
set(REQ_URL "https://gitlab.com/libeigen/eigen/-/archive/${VER}/eigen-${VER}.tar.gz")

mindquantum_add_pkg(
  Eigen3
  VER ${VER}
  URL ${REQ_URL}
  MD5 ${MD5}
  CMAKE_OPTION -DBUILD_TESTING=OFF
  TARGET_ALIAS mindspore::eigen Eigen3::Eigen)
