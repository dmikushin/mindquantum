//   Copyright 2020 <Huawei Technologies Co., Ltd>
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.

#ifndef CORE_CONFIG_HPP
#define CORE_CONFIG_HPP

#include <vector>

#include "core/details/clang_version.hpp"

#ifdef CXX20_COMPATIBILITY
#    include "core/details/cxx20_compatibility.hpp"
#endif  // CXX20_COMPATIBILITY

#ifdef __has_cpp_attribute
#    if __has_cpp_attribute(nodiscard)
#        define HIQ_NODISCARD [[nodiscard]]
#    endif  // __has_cpp_attribute(nodiscard)
#endif      // __has_cpp_attribute

#ifndef HIQ_NODISCARD
#    define HIQ_NODISCARD
#endif  // HIQ_NODISCARD

#ifndef HIQ_IS_CLANG_VERSION_LESS
#    define HIQ_IS_CLANG_VERSION_LESS(major, minor)                                                                    \
        (defined __clang__) && (HIQ_CLANG_MAJOR < major) && (HIQ_CLANG_MINOR < minor)
#    define HIQ_IS_CLANG_VERSION_LESS_EQUAL(major, minor)                                                              \
        (defined __clang__) && (HIQ_CLANG_MAJOR <= major) && (HIQ_CLANG_MINOR <= minor)
#endif  // HIQ_IS_CLANG_VERSION_LESS

// NB: Clang <= 13.0 for some reason has some troubles with some of the concepts codes
#if __cpp_concepts && !((defined __clang__) && (HIQ_CLANG_MAJOR <= 13))
#    define HIQ_USE_CONCEPTS 1
#else
#    define HIQ_USE_CONCEPTS 0
#endif  // __cpp_concepts

#if !defined(HIQ_CONFIG_NO_COUNTER) && !defined(HIQ_CONFIG_COUNTER)
#    define HIQ_CONFIG_COUNTER
#endif  // !HIQ_CONFIG_NO_COUNTER && !HIQ_CONFIG_COUNTER

#define HIQ_UNIQUE_NAME_LINE2(name, line) name##line
#define HIQ_UNIQUE_NAME_LINE(name, line)  HIQ_UNIQUE_NAME_LINE2(name, line)
#ifdef HIQ_CONFIG_COUNTER
#    define HIQ_UNIQUE_NAME(name) HIQ_UNIQUE_NAME_LINE(name, __COUNTER__)
#else
#    define HIQ_UNIQUE_NAME(name) HIQ_UNIQUE_NAME_LINE(name, __LINE__)
#endif

namespace mindquantum {
    using qubit_id_t = unsigned int;
    using qureg_t = std::vector<qubit_id_t>;
}  // namespace mindquantum

#endif /* CORE_CONFIG_HPP */
