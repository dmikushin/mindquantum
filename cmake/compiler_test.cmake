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

include(CheckCXXSourceCompiles)

check_cxx_source_compiles(
  "#include <concepts>
#include <type_traits>
template <class T>
concept integral = std::is_integral_v<T>;

template <integral T> auto foo(T t) { return t + t; }
int main() { return foo(42); }
"
  compiler_has_concepts)

if(NOT compiler_has_concepts)
  message(WARNING "C++ compiler does not support C++20 concepts (language support, not STL implementation)")
endif()
