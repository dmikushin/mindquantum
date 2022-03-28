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

#ifndef SWAP2CNOT_HPP
#define SWAP2CNOT_HPP

#include <tweedledum/Operators/Standard/Swap.h>
#include <tweedledum/Operators/Standard/X.h>

#include "decompositions.hpp"

namespace mindquantum::decompositions {
namespace td = tweedledum;

void decompose_swap2cnot(circuit_t& result, const instruction_t& inst) {
    assert(inst.kind() == "std.swap");

    auto qubits = inst.qubits();
    decltype(qubits) targets = {inst.target(0), inst.target(1)};
    const auto last = std::size(qubits) - 1;

    // Keep all control qubits and swap the two target qubits
    std::swap(qubits[last - 1], qubits[last]);

    result.apply_operator(td::Op::X(), targets);
    result.apply_operator(td::Op::X(), qubits);
    result.apply_operator(td::Op::X(), targets);
}

}  // namespace mindquantum::decompositions

#endif /* SWAP2CNOT_HPP */
