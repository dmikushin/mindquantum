//   Copyright 2021 <Huawei Technologies Co., Ltd>
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

#ifndef REGISTER_GATE_TYPE_HPP
#define REGISTER_GATE_TYPE_HPP

#include "ops/parametric/config.hpp"

#if HIQ_USE_CONCEPTS
#    include "core/gate_concepts.hpp"
#endif  // HIQ_USE_CONCEPTS

#include <vector>

#include <tweedledum/IR/Instruction.h>

namespace mindquantum::ops::parametric {
    using operator_t = tweedledum::Operator;

    //! Register a new gate class
    /*!
     * \tparam operator_t Type of the gate to register
     *
     * \note If the gate is neither a parametric gate or a gate with an angle() method, this method is no-op.
     */
    template <typename operator_t>
    void register_gate_type()
#if HIQ_USE_CONCEPTS
        requires((concepts::ParametricGate<operator_t>) || (concepts::AngleGate<operator_t>)
                 || (concepts::SingleDoubleGate<operator_t>) || (concepts::MultiDoubleGate<operator_t>) )
#endif  // HIQ_USE_CONCEPTS
            ;

    //! Get the parameters of an operation
    /*!
     * \param optor A quantum operation
     */
    [[nodiscard]] gate_param_t get_param(const operator_t& optor) noexcept;
}  // namespace mindquantum::ops::parametric

#include "register_gate_type.tpp"

#endif /* REGISTER_GATE_TYPE_HPP */
