//   Copyright 2022 <Huawei Technologies Co., Ltd>
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

#ifndef GATE_DECOMPOSITION_RULE_HPP
#define GATE_DECOMPOSITION_RULE_HPP

#include "decompositions/decomposition_rule.hpp"

#if __cplusplus > 201703L
#    include "decompositions/details/gate_decomposition_rule_cxx20.hpp"
#else
#    include "decompositions/details/gate_decomposition_rule_cxx17.hpp"
#endif  // __cplusplus > 201703L

#endif /* GATE_DECOMPOSITION_RULE_HPP */
