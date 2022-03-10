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

#ifndef GATE_CONCEPTS_HPP
#define GATE_CONCEPTS_HPP

#include <functional>
#include <string_view>
#include <tuple>
#include <type_traits>
#include <vector>

#include <symengine/dict.h>

#include "tweedledum/IR/Operator.h"

#include "ops/parametric/config.hpp"

#if HIQ_USE_CONCEPTS
#    include "core/concepts.hpp"
#endif  // HIQ_USE_CONCEPTS
#include "core/operator_traits.hpp"

namespace mindquantum::concepts {
#if HIQ_USE_CONCEPTS
    template <typename operator_t>
    concept Gate = requires(operator_t optor) {
        // clang-format off
        { operator_t::kind() } -> std::same_as<std::string_view>;
        // clang-format on
    };

    template <typename operator_t>
    concept FixedNumTargetGate = requires(operator_t optor) {
        requires Gate<operator_t>;
        requires std::default_initializable<operator_t>;
        // clang-format off
        requires std::greater<>{}(traits::num_targets<operator_t>, 0);
        // clang-format on
    };

    template <typename operator_t>
    concept VariableNumTargetGate = requires(operator_t optor) {
        requires Gate<operator_t>;
        requires std::constructible_from<operator_t, uint32_t>;
    };

    template <typename operator_t>
    concept SingleDoubleGate = requires(operator_t optor) {
        requires Gate<operator_t>;
        // clang-format off
        { optor.param() } -> same_decay_as<double>;
        // clang-format on
    };

    template <typename operator_t>
    concept MultiDoubleGate = requires(operator_t optor) {
        requires Gate<operator_t>;
        // clang-format off
        // TODO(damien): Perhaps store the number of parameters as a static constexpr class variable?
        { optor.params() } -> same_decay_as<std::vector<double>>;
        // clang-format on
    };

    template <typename operator_t>
    concept AngleGate = requires(operator_t optor) {
        requires Gate<operator_t>;
        requires std::constructible_from<operator_t, double>;
        // clang-format off
        { optor.angle() } -> same_decay_as<double>;
        // clang-format on
    };

    template <typename operator_t>
    concept ParametricGate = requires(operator_t optor, SymEngine::map_basic_basic subs) {
        requires Gate<operator_t>;
        requires std::same_as<typename operator_t::is_parametric, void>;
        requires Gate<typename operator_t::non_param_type>;
        requires std::integral<decltype(operator_t::num_params)>;
        requires std::greater<> {
        }
        (operator_t::num_params, 0);

        // clang-format off
        { optor.param(0UL) } -> same_decay_as<ops::parametric::basic_t>;
        { optor.params() } -> same_decay_as<ops::parametric::param_list_t>;
        { optor.eval(subs)} -> same_decay_as<operator_t>;
        { optor.eval_full(subs) } -> same_decay_as<typename operator_t::non_param_type>;
        { optor.eval_smart(subs) } -> same_decay_as<tweedledum::Operator>;
        // clang-format on
    };

    template <typename operator_t>
    concept NonParametricGate = requires(operator_t optor) {
        requires Gate<operator_t>;
        requires !ParametricGate<operator_t>;
    };

    //! Helper typedef
    template <std::size_t idx, typename param_t>
    using param_eval_t = typename std::tuple_element_t<0, param_t>::param_type::type;

    template <typename operator_t /*, typename evaluated_t */>
    concept SingleParameterGate = requires(operator_t optor) {
        requires ParametricGate<operator_t>;
        // clang-format off
        requires std::equal_to<>{}(operator_t::num_params, 1);
        // clang-format on
        // // Make sure that the parameter evaluates to what we expect
        // requires std::same_as<param_eval_t<0, typename operator_t::params_type>, evaluated_t>;
    };

#else
#endif  // HIQ_USE_CONCEPTS
}  // namespace mindquantum::concepts

#endif /* GATE_CONCEPTS_HPP */
