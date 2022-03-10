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

#include "core/circuit_block.hpp"

#include <optional>
#include <type_traits>

#include "ops/gates/measure.hpp"

// =============================================================================

namespace mindquantum {
    bool operator<(qubit_id_t id, const QubitID& qubit) {
        return id < qubit.get();
    }
}  // namespace mindquantum

// =============================================================================

namespace mindquantum {
    CircuitBlock::CircuitBlock() : device_(nullptr) {
    }

    CircuitBlock::CircuitBlock(const CircuitBlock& parent, chained_t)
        : device_(parent.device_)
        , circuit_(tweedledum::shallow_duplicate(parent.circuit_))
        , pq_to_td_(parent.pq_to_td_)
        , qtd_to_pq_(parent.qtd_to_pq_) {
        if (parent.has_mapping()) {
            assert(device_);
            mapping_.emplace(parent.mapping_.value().placement);
        }
    }

    CircuitBlock::CircuitBlock(const CircuitBlock& parent, const std::vector<pq_id_t>& exclude_ids, chained_t)
        : device_(parent.device_) {
        std::vector<qubit_t> old_to_new(parent.circuit_.num_wires(), qubit_t::invalid());

        parent.circuit_.foreach_qubit(
            [this, &exclude_ids, &parent, &old_to_new](const qubit_t& qubit, std::string_view name) {
                for (const auto& exclude: exclude_ids) {
                    assert(parent.has_qubit(exclude));
                    const auto& [exclude_qubit, _] = parent.pq_to_td_.at(exclude);
                    if (exclude_qubit == qubit) {
                        return;
                    }
                }

                const auto pq_id = parent.qtd_to_pq_.find(qubit.uid())->second;
                old_to_new[qubit] = circuit_.create_qubit(name);
                pq_to_td_.emplace(pq_id, std::make_pair(old_to_new[qubit], std::nullopt));

                qtd_to_pq_.emplace(old_to_new[qubit], pq_id);
            });

        parent.circuit_.foreach_cbit([this, &parent](const cbit_t& cbit, std::string_view name) {
            const auto pq_id = parent.ctd_to_pq_.find(cbit.uid())->second;

            // NB: Need to have a qubit registered! Cannot have just a cbit.
            assert(pq_to_td_.count(pq_id) > 0);
            const auto cbit_new = circuit_.create_cbit(name);
            std::get<1>(pq_to_td_.at(pq_id)) = cbit_new;

            ctd_to_pq_.emplace(cbit_new, pq_id);
        });

        if (parent.has_mapping()) {
            using placement_t = std::remove_cvref_t<decltype(std::declval<mapping_t&>().init_placement)>;

            assert(device_);
            placement_t init_placement(device_->num_qubits(), circuit_.num_qubits());

            parent.circuit_.foreach_qubit([&old_to_new, &final_mapping = parent.mapping_.value().placement,
                                           &init_placement](const qubit_t& qubit) {
                if (old_to_new[qubit] == qubit_t::invalid()) {
                    return;
                }
                init_placement.map_v_phy(old_to_new[qubit], final_mapping.v_to_phy(qubit));
            });

            mapping_.emplace(init_placement);
        }
    }
}  // namespace mindquantum

// =============================================================================

namespace mindquantum {
    bool CircuitBlock::has_mapping() const {
        return bool(mapping_);
    }

    bool CircuitBlock::has_qubit(pq_id_t qubit_id) const {
        if (std::size(pq_to_td_) == 0) {
            return false;
        }
#if __cplusplus > 201703L && !(defined CXX20_COMPATIBILITY)
        return pq_to_td_.contains(qubit_id);
#else
        return pq_to_td_.count(qubit_id) > 0;
#endif
    }

    bool CircuitBlock::has_cbit(pq_id_t qubit_id) const {
        if (std::size(pq_to_td_) == 0) {
            return false;
        }

        if (const auto it = pq_to_td_.find(qubit_id); it != end(pq_to_td_)) {
            return bool(std::get<1>(it->second));
        } else {
            return false;
        }
    }

    auto CircuitBlock::pq_ids() const -> std::vector<pq_id_t> {
        std::vector<pq_id_t> ids;
        for (const auto& [pq_id, wires]: pq_to_td_) {
            ids.push_back(pq_id);
        }
        return ids;
    }

    auto CircuitBlock::td_ids() const -> std::vector<td_qid_t> {
        std::vector<td_qid_t> ids;
        for (const auto& [td_id, pq_id]: qtd_to_pq_) {
            ids.push_back(td_id);
        }
        return ids;
    }
}  // namespace mindquantum

// =============================================================================

namespace mindquantum {
    bool CircuitBlock::add_qubit(pq_id_t pq_qubit_id) {
        if (has_qubit(pq_qubit_id)) {
            return false;
        }

        if (device_ && circuit_.num_qubits() == device_->num_qubits()) {
            return false;
        } else {
            const auto pq_qubit_str(std::to_string(pq_qubit_id.get()));
            auto td_qubit_id = circuit_.create_qubit("q" + pq_qubit_str);
            pq_to_td_.insert({pq_qubit_id, std::make_tuple(td_qubit_id, std::nullopt)});
            qtd_to_pq_.insert({td_qubit_id, pq_qubit_id});
            return true;
        }
    }
}  // namespace mindquantum

// =============================================================================

namespace mindquantum {
    qubit_id_t CircuitBlock::translate_id(const td_qid_t& ref) const {
        return qubit_id_t(qtd_to_pq_.at(ref));
    }

    qubit_id_t CircuitBlock::translate_id(const td_cid_t& ref) const {
        return qubit_id_t(ctd_to_pq_.at(ref));
    }

    auto CircuitBlock::translate_id_td(const td_qid_t& ref) const -> td_qid_t {
        return td_qid_t(qtd_to_pq_.at(ref));
    }

    auto CircuitBlock::translate_id_td(const td_cid_t& ref) const -> td_cid_t {
        return td_cid_t(ctd_to_pq_.at(ref));
    }

    auto CircuitBlock::translate_id(const pq_id_t& qubit_id) const -> td_qid_t {
        return std::get<0>(pq_to_td_.at(qubit_id));
    }
}  // namespace mindquantum

// =============================================================================
namespace mindquantum {
    auto CircuitBlock::apply_operator(const instruction_t& optor, const qureg_t& control_qubits,
                                      const qureg_t& target_qubits) -> inst_ref_t {
        return circuit_.apply_operator(optor, translate_pq_ids_(control_qubits, target_qubits));
    }

    auto CircuitBlock::apply_measurement(qubit_id_t id) -> inst_ref_t {
        auto& [td_qubit_id, td_cbit_id] = pq_to_td_.at(id);

        if (!td_cbit_id) {
            td_cbit_id = circuit_.create_cbit("c" + std::to_string(id));
            ctd_to_pq_.insert({td_cbit_id.value(), id});
        }

        return circuit_.apply_operator(ops::Measure(), {td_qubit_id}, {td_cbit_id.value()});
    }

}  // namespace mindquantum

// =============================================================================

namespace mindquantum {
    auto CircuitBlock::translate_pq_ids_(const qureg_t& control_qubits, const qureg_t& target_qubits)
        -> std::vector<qubit_t> {
        std::vector<qubit_t> wires;
        wires.reserve(std::size(control_qubits) + std::size(target_qubits));

        for (auto& qubit_id: control_qubits) {
            assert(has_qubit(qubit_id));
            wires.emplace_back(std::get<0>(pq_to_td_.at(qubit_id)));
        }
        for (auto& qubit_id: target_qubits) {
            assert(has_qubit(qubit_id));
            wires.emplace_back(std::get<0>(pq_to_td_.at(qubit_id)));
        }

        return wires;
    }

    void CircuitBlock::update_mappings_(const std::vector<qubit_t>& old_to_new) {
        qtd_to_pq_.clear();

        for (auto& [pq_id, ids]: pq_to_td_) {
            auto& [qubit_id, cbit_id] = ids;
            qubit_id = old_to_new[qubit_id];
            qtd_to_pq_.emplace(qubit_id, pq_id);

            // NB: cbits are never remapped
            assert(!cbit_id || ctd_to_pq_.count(cbit_id.value()) > 0);
        }
    }

}  // namespace mindquantum
