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

#ifndef PARAMETRIC_SUBSTITUTIONS_HPP
#define PARAMETRIC_SUBSTITUTIONS_HPP

#include "ops/parametric/config.hpp"

#include "ops/parametric/traits.hpp"

namespace mindquantum::ops::parametric {

    //! Generate a substitution dictionary from a single double
    /*!
     * \pre \c sizeof(args_t) == operator_t::num_params()
     */
    template <typename operator_t, typename... args_t>
    HIQ_NODISCARD static auto generate_subs(args_t&&... args);

    //! Generate a substitution dictionary from an array of double
    /*!
     * \sa generate_subs_(const std::vector<T>& param) const;
     */
    template <typename operator_t>
    HIQ_NODISCARD static auto generate_subs(const double_list_t& params);

    //! Generate a substitution dictionary from an array of expressions
    /*!
     * \sa generate_subs_(const std::vector<T>& param) const;
     */
    template <typename operator_t>
    HIQ_NODISCARD static auto generate_subs(const param_list_t& params);

    namespace details {
        //! Generate a substitution dictionary from an array of elements
        /*!
         * \pre \c size(param) == operator_t::num_params()
         */
        template <typename operator_t, typename T>
        HIQ_NODISCARD static auto generate_subs(const std::vector<T>& params);

#if HIQ_USE_CONCEPTS
        template <typename operator_t, std::size_t... indices, concepts::expr_or_number... expr_t>
        HIQ_NODISCARD static auto create_subs_from_params(std::index_sequence<indices...> /*unused*/,
                                                          expr_t&&... exprs);
#else
        template <typename operator_t, std::size_t... indices, typename... args_t>
        HIQ_NODISCARD static auto create_subs_from_params(std::index_sequence<indices...> /*unused*/, args_t&&... args);
#endif  // HIQ_USE_CONCEPTS
    }   // namespace details
}  // namespace mindquantum::ops::parametric

#include "ops/parametric/substitutions.tpp"

#endif /* PARAMETRIC_SUBSTITUTIONS_HPP */