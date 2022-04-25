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

#if MQ_HAS_CONCEPTS
#    include "core/gate_concepts.hpp"
#endif  // MQ_HAS_CONCEPTS
#include <cstddef>
#include <type_traits>
#include <utility>

#include <tweedledum/IR/Operator.h>

namespace mindquantum::traits {
#if MQ_HAS_CONCEPTS
template <typename op_t>
struct gate_traits {
    using non_param_type = op_t;
};

template <concepts::SingleDoubleGate op_t>
struct gate_traits<op_t> {
    using non_param_type = op_t;

    static constexpr auto param(const tweedledum::Operator& op) {
        return op.cast<op_t>().param();
    }
};

template <concepts::MultiDoubleGate op_t>
struct gate_traits<op_t> {
    using non_param_type = op_t;

    static constexpr auto param(const tweedledum::Operator& op) {
        return op.cast<op_t>().params();
    }
};

template <concepts::AngleGate op_t>
struct gate_traits<op_t> {
    using non_param_type = op_t;

    static constexpr auto param(const tweedledum::Operator& op) {
        return op.cast<op_t>().angle();
    }
};

template <concepts::ParametricGate op_t>
struct gate_traits<op_t> {
    using non_param_type = typename op_t::non_param_type;

    static constexpr auto param(const tweedledum::Operator& op) {
        return op.cast<op_t>().params();
    }
};
#else
namespace details {
template <typename op_t, typename = void>
struct has_angle : std::false_type {};

template <typename op_t>
struct has_angle<op_t, std::void_t<decltype(std::declval<op_t>().angle())>> : std::true_type {};

template <typename op_t, typename = void>
struct has_single_param : std::false_type {};

template <typename op_t>
struct has_single_param<op_t, std::void_t<decltype(std::declval<op_t>().param())>> : std::true_type {};

template <typename op_t, typename = void>
struct has_multi_param : std::false_type {};

template <typename op_t>
struct has_multi_param<op_t, std::void_t<decltype(std::declval<op_t>().params())>> : std::true_type {};

template <typename op_t>
struct param_traits {
    static auto apply(const op_t& optor) {
        if constexpr (has_single_param<op_t>::value) {
            return optor.param();
        } else if constexpr (has_multi_param<op_t>::value) {
            return optor.params();
        } else if constexpr (has_angle<op_t>::value) {
            return optor.angle();
        }
    }
};
}  // namespace details

template <typename op_t>
struct gate_traits {
    using non_param_type = op_t;

    static constexpr auto param(const tweedledum::Operator& op) {
        return details::param_traits<op_t>::apply(op.cast<op_t>());
    }
};
#endif  // MQ_HAS_CONCEPTS

}  // namespace mindquantum::traits

#endif /* GATE_TRAITS_HPP */
