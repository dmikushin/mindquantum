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

add_library(mindquantum_cxx STATIC)
set_target_properties(mindquantum_cxx PROPERTIES POSITION_INDEPENDENT_CODE TRUE)
target_link_libraries(mindquantum_cxx PUBLIC cxx20_compat mindquantum_setup)

# Minimum required is C++17 but really, some features require C++20 and some workarounds are enabled if only C++17 is
# available but with no guarantees beyond a successful compilation.
target_compile_features(mindquantum_cxx PUBLIC cxx_std_17)

add_subdirectory(include)
add_subdirectory(lib)

add_subdirectory(python)
