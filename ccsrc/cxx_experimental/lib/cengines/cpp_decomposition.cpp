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

#include "cengines/cpp_decomposition.hpp"

#include <iostream>

#include <tweedledum/IR/Circuit.h>
#include <tweedledum/Operators/Standard.h>
#include <tweedledum/Passes/Utility/shallow_duplicate.h>

#include "decompositions.hpp"
#include "ops/gates.hpp"
#include "ops/meta/dagger.hpp"

namespace td = tweedledum;

namespace impl {
auto recognize_all(const td::Instruction& /* inst */) -> bool {
    return true;
}
}  // namespace impl

namespace mindquantum::cengines {
#define RULE(name, gate_class, is_recursive)                                                                           \
    std::make_pair(#name, CppDecomposer::rule_t{gate_class::kind(), is_recursive, &decompositions::recognize_##name,   \
                                                &decompositions::decompose_##name})
#define RULE_ALL(name, gate_class, is_recursive)                                                                       \
    std::make_pair(#name, CppDecomposer::rule_t{gate_class::kind(), is_recursive, impl::recognize_all,                 \
                                                &decompositions::decompose_##name})
#define RULE3_ALL(name, func_name, gate_class, is_recursive)                                                           \
    std::make_pair(#name, CppDecomposer::rule_t{gate_class::kind(), is_recursive, impl::recognize_all,                 \
                                                &decompositions::decompose_##func_name})

std::map<std::string, const CppDecomposer::rule_t, std::less<>> CppDecomposer::rule_map_ = {
    RULE_ALL(cnot2cz, td::Op::X, false),

    RULE3_ALL(cnot2rxx, cnot2rxx_M, td::Op::X, false),
    RULE_ALL(cnot2rxx_M, td::Op::X, false),
    RULE_ALL(cnot2rxx_P, td::Op::X, false),

    RULE_ALL(entangle, ops::Entangle, false),

    RULE_ALL(PhNoCtrl, ops::Ph, false),
    RULE3_ALL(globalphase, PhNoCtrl, ops::Ph, false),

    RULE3_ALL(h2rx, h2rx_M, td::Op::H, false),
    RULE_ALL(h2rx_M, td::Op::H, false),
    RULE_ALL(h2rx_N, td::Op::H, false),

    RULE_ALL(ph2r, ops::Ph, false),

    RULE_ALL(qft2crandhadamard, ops::QFT, false),

    RULE_ALL(r2rzandph, td::Op::P, false),

    RULE_ALL(rx2rz, td::Op::Rx, false),
    RULE_ALL(ry2rz, td::Op::Ry, false),
    RULE3_ALL(rz2rx, rz2rx_P, td::Op::Rz, false),
    RULE_ALL(rz2rx_M, td::Op::Rz, false),
    RULE_ALL(rz2rx_P, td::Op::Rz, false),

    // TODO: Missing SqrtX decomposition

    RULE_ALL(sqrtswap2cnot, ops::SqrtSwap, false),

    RULE_ALL(swap2cnot, td::Op::Swap, false),

    RULE_ALL(toffoli2cnotandtgate, td::Op::X, false),

    RULE_ALL(qubitop2onequbit, ops::QubitOperator, false),

    // NB: recursion taken care of within decomposition function => false
    RULE(time_evolution_commuting, ops::TimeEvolution, false),
    RULE(time_evolution_individual_terms, ops::TimeEvolution, false),
};

#undef RULE
#undef RULE_ALL
#undef RULE3_ALL

#define RULE(name, is_recursive)                                                                                       \
    std::make_pair(#name, CppDecomposer::gen_rule_t{#name, is_recursive, &decompositions::recognize_##name,            \
                                                    &decompositions::decompose_##name})

std::map<std::string, const CppDecomposer::gen_rule_t, std::less<>> CppDecomposer::gen_rule_map_ = {
    // RULE(cnu2toffoliandcu, true)
};
#undef RULE
}  // namespace mindquantum::cengines

mindquantum::cengines::CppDecomposer::CppDecomposer() : CppDecomposer({"qft2crandhadamard"}) {
    // for (const auto& [name, rule]: rule_map_) {
    //      auto [it2, was_inserted] = rule_table_.try_emplace(std::string(rule.kind));
    //      it2->second.push_back(std::make_tuple(name, rule.check, rule.decomp));
    // }
}

mindquantum::cengines::CppDecomposer::CppDecomposer(std::vector<std::string> input_rules) {
    for (auto& rule_str : input_rules) {
        auto it = rule_map_.find(rule_str);
        if (it == rule_map_.end()) {
            std::cerr << "Rule not found: " << rule_str << "\n";
        } else {
            const auto& rule = it->second;
            auto [it2, was_inserted] = rule_table_.try_emplace(std::string(rule.kind));
            it2->second.push_back(std::make_tuple(it->first, rule.is_recursive, rule.check, rule.decomp));
        }
    }
}

td::Circuit mindquantum::cengines::CppDecomposer::decompose_circuit(const td::Circuit& circuit) {
    namespace td = tweedledum;

    auto result = td::shallow_duplicate(circuit);
    circuit.foreach_instruction([&](td::Instruction const& inst) {
        bool is_dagger = false;
        auto kind = inst.kind();
        if (kind == ops::DaggerOperation::kind()) {
            is_dagger = true;
            kind = inst.cast<ops::DaggerOperation>().adjoint().kind();
        }

        if (const auto& it = rule_table_.find(kind); it == rule_table_.end() || std::empty(std::get<1>(*it))) {
            // No rule found -> pass instruction as-is
            result.apply_operator(inst);
        } else {
            const auto& rule_list = std::get<1>(*it);

            // TODO: Need to consider whether we have a dagger gate or not
            if (is_dagger) {
                assert(0 && "Inverse decomposition not yet implemented!");
            } else {
                // Extract all rules that are recognized
                std::vector<std::tuple<std::string, bool, decomp_func_t>> valid_rules;
                for (const auto& [name, is_recursive, check, decomp] : rule_list) {
                    if (check(inst)) {
                        valid_rules.emplace_back(name, is_recursive, decomp);
                    }
                }

                for (const auto& [name, value] : gen_rule_map_) {
                    const auto& [is_recursive, check, decomp] = value;

                    if (check(inst)) {
                        valid_rules.emplace_back(name, is_recursive, decomp);
                    }
                }

                assert(!std::empty(valid_rules));

                // Use the first rule
                const auto& [name, is_recursive, decomp] = valid_rules[0];
                if (!is_recursive) {
                    decomp(result, inst);
                } else {
                    td::Circuit intermediate(td::shallow_duplicate(circuit));
                    decomp(intermediate, inst);

                    const auto temp = decompose_circuit(intermediate);

                    temp.foreach_instruction([&result](const td::Instruction& other) {
                        // This works since result and temp have the same wires IDs...
                        result.apply_operator(other);
                    });
                }
            }
        }
    });
    return result;
}

// ==============================================================================

bool mindquantum::cengines::CppDecomposer::register_decomposition(std::string_view name, std::string_view kind,
                                                                  bool is_recursive, recogn_func_t check,
                                                                  decomp_func_t decomp) {
    return rule_map_
        .insert(std::make_pair(name, CppDecomposer::rule_t{kind, is_recursive, std::move(check), std::move(decomp)}))
        .second;
}
