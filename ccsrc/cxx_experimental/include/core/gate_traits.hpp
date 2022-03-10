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

#ifndef GATE_TRAITS_HPP
#define GATE_TRAITS_HPP

#if HIQ_USE_CONCEPTS
#    include "core/gate_concepts.hpp"
#endif  // HIQ_USE_CONCEPTS
#include <cstddef>
#include <type_traits>
#include <utility>

#include <tweedledum/IR/Operator.h>

namespace mindquantum::traits {
#if HIQ_USE_CONCEPTS
    template <typename operator_t>
    struct gate_traits {
        using non_param_type = operator_t;
    };

    template <concepts::SingleDoubleGate operator_t>
    struct gate_traits<operator_t> {
        using non_param_type = operator_t;

        static constexpr auto param(const tweedledum::Operator& op) {
            return op.cast<operator_t>().param();
        }
    };

    template <concepts::MultiDoubleGate operator_t>
    struct gate_traits<operator_t> {
        using non_param_type = operator_t;

        static constexpr auto param(const tweedledum::Operator& op) {
            return op.cast<operator_t>().params();
        }
    };

    template <concepts::AngleGate operator_t>
    struct gate_traits<operator_t> {
        using non_param_type = operator_t;

        static constexpr auto param(const tweedledum::Operator& op) {
            return op.cast<operator_t>().angle();
        }
    };

    template <concepts::ParametricGate operator_t>
    struct gate_traits<operator_t> {
        using non_param_type = typename operator_t::non_param_type;

        static constexpr auto param(const tweedledum::Operator& op) {
            return op.cast<operator_t>().params();
        }
    };
#else
    namespace details {
        template <typename operator_t, typename = void>
        struct has_angle : std::false_type {};

        template <typename operator_t>
        struct has_angle<operator_t, std::void_t<decltype(std::declval<operator_t>().angle())>> : std::true_type {};

        template <typename operator_t, typename = void>
        struct has_single_param : std::false_type {};

        template <typename operator_t>
        struct has_single_param<operator_t, std::void_t<decltype(std::declval<operator_t>().param())>>
            : std::true_type {};

        template <typename operator_t, typename = void>
        struct has_multi_param : std::false_type {};

        template <typename operator_t>
        struct has_multi_param<operator_t, std::void_t<decltype(std::declval<operator_t>().params())>>
            : std::true_type {};

        template <typename operator_t>
        struct param_traits {
            static auto apply(const operator_t& optor) {
                if constexpr (has_single_param<operator_t>::value) {
                    return optor.param();
                } else if constexpr (has_multi_param<operator_t>::value) {
                    return optor.params();
                } else if constexpr (has_angle<operator_t>::value) {
                    return optor.angle();
                }
            }
        };
    }  // namespace details

    template <typename operator_t>
    struct gate_traits {
        using non_param_type = operator_t;

        static constexpr auto param(const tweedledum::Operator& op) {
            return details::param_traits<operator_t>::apply(op.cast<operator_t>());
        }
    };
#endif  // HIQ_USE_CONCEPTS

}  // namespace mindquantum::traits

#endif /* GATE_TRAITS_HPP */
