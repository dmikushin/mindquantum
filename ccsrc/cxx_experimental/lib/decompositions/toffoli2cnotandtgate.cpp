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

#include <tweedledum/Operators/Standard/H.h>
#include <tweedledum/Operators/Standard/T.h>
#include <tweedledum/Operators/Standard/X.h>

#include "decompositions.hpp"

namespace mindquantum::decompositions {
    namespace td = tweedledum;

    void decompose_toffoli2cnotandtgate(circuit_t& result, const instruction_t& inst) {
        assert(inst.kind() == "std.x");

        if (const auto& qubits = inst.qubits(); std::size(qubits) == 3) {
            const auto &c1 = qubits[0], c2 = qubits[1];
            const auto& target = qubits[2];

            result.apply_operator(td::Op::H(), {target});
            result.apply_operator(td::Op::X(), {c1, target});
            result.apply_operator(td::Op::T(), {c1});
            result.apply_operator(td::Op::Tdg(), {target});
            result.apply_operator(td::Op::X(), {c2, target});
            result.apply_operator(td::Op::X(), {c2, c1});
            result.apply_operator(td::Op::Tdg(), {c1});
            result.apply_operator(td::Op::T(), {target});
            result.apply_operator(td::Op::X(), {c2, c1});
            result.apply_operator(td::Op::X(), {c1, target});
            result.apply_operator(td::Op::Tdg(), {target});
            result.apply_operator(td::Op::X(), {c2, target});
            result.apply_operator(td::Op::T(), {target});
            result.apply_operator(td::Op::T(), {c2});
            result.apply_operator(td::Op::H(), {target});
        } else {
            result.apply_operator(inst);
        }
    }
}  // namespace mindquantum::decompositions
