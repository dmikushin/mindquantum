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

#ifndef PROJECTQ_SIMULATOR_HPP
#define PROJECTQ_SIMULATOR_HPP

#include <algorithm>

#include "simulator/config.hpp"

#include "core/types.hpp"
#include "simulator/simulator.hpp"
#include "simulator/simulator_base.hpp"

namespace mindquantum::simulation::projectq {
class Simulator : public BaseSimulator<Simulator> {
 public:
    //! Simple constructor
    /*!
     * \param seed Seed for random generator.
     */
    Simulator(uint32_t seed = 0);

    //! Check whether a qubit is already allocated by the simulator
    /*!
     * \param qubit A qubit ID
     * \return True if the qubit is allocated, false otherwise
     */
    MQ_NODISCARD bool has_qubit(const qubit_t& qubit) const;
    //! Check whether a qubit is already allocated by the simulator
    /*!
     * \param qubit qubits A list of qubits to allocate
     * \return True if the allocation was successful, false otherwise
     */
    MQ_NODISCARD bool allocate_qubits(const qubits_t& qubits);
    //! Check whether a qubit is already allocated by the simulator
    /*!
     * \param inst A quantum instruction
     * \return True if running the instruction was successful, false otherwise
     */
    MQ_NODISCARD bool run_instruction(const instruction_t& inst);

    MQ_NODISCARD auto is_classical(const qubit_t& qubit, double tol = 1.e-12) {
        return sim_.is_classical(qubit_id_t{qubit}, tol);
    }

    MQ_NODISCARD auto get_classical_value(const qubit_t& qubit, double tol = 1.e-12) {
        return sim_.get_classical_value(qubit_id_t{qubit}, tol);
    }

    MQ_NODISCARD auto measure_qubits_return(const qubits_t& qubits) {
        std::vector<qubit_id_t> targets;
        std::for_each(begin(qubits), end(qubits),
                      [&targets](const auto& qubit) { targets.emplace_back(qubit_id_t{qubit}); });
    }

    MQ_NODISCARD auto cheat() {
        return sim_.cheat();
    }

    MQ_NODISCARD auto run() {
        return sim_.run();
    }

 private:
    ::projectq::Simulator sim_;
};
}  // namespace mindquantum::simulation::projectq

#endif /* PROJECTQ_SIMULATOR_HPP */
