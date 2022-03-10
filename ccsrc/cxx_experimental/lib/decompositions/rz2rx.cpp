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

#include <tweedledum/Operators/Standard/Rx.h>
#include <tweedledum/Operators/Standard/Ry.h>
#include <tweedledum/Operators/Standard/Rz.h>

#include "decompositions.hpp"

namespace mindquantum::decompositions {
    namespace td = tweedledum;

    //! Decompose (controlled) z-rotation gate using y-rotation and x-rotation
    void decompose_rz2rx_P(circuit_t& result, const instruction_t& inst) {
        assert(inst.kind() == "std.rz");

        const auto& qubits = inst.qubits();

        result.apply_operator(td::Op::Ry(-0.5), qubits);
        // NB: * 2 factor compared to ProjectQ because of Tweedledum gate definition
        result.apply_operator(td::Op::Rx(-inst.cast<td::Op::Rz>().angle() * 2), qubits);
        result.apply_operator(td::Op::Ry(0.5), qubits);
    }

    //! Decompose (controlled) z-rotation gate using y-rotation and x-rotation
    void decompose_rz2rx_M(circuit_t& result, const instruction_t& inst) {
        assert(inst.kind() == "std.rz");

        const auto& qubits = inst.qubits();

        result.apply_operator(td::Op::Ry(0.5), qubits);
        // NB: * 2 factor compared to ProjectQ because of Tweedledum gate definition
        result.apply_operator(td::Op::Rx(inst.cast<td::Op::Rz>().angle() * 2), qubits);
        result.apply_operator(td::Op::Ry(-0.5), qubits);
    }
}  // namespace mindquantum::decompositions
