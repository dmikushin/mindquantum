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

#ifndef CORE_CXX20_COMPATIBILITY_HPP
#define CORE_CXX20_COMPATIBILITY_HPP

#include <type_traits>
#ifdef __has_include
#    if __has_include(<version>)
#        include <version>
#    endif
#endif

#if MQ_HAS_CONCEPTS
#    include <concepts>
#endif

namespace std {
#if MQ_HAS_CONCEPTS && !MQ_HAS_CONCEPT_LIBRARY && !(defined(_MSC_VER) && __cpp_lib_concepts == 201907L)
// clang-format off
template <class T>
concept integral = std::is_integral_v<T>;
template <class T>
concept signed_integral = std::integral<T> && std::is_signed_v<T>;

template <class T>
concept unsigned_integral = std::integral<T> && !std::signed_integral<T>;
template <class T>
concept floating_point = std::is_floating_point_v<T>;

template <class Derived, class Base>
concept derived_from = std::is_base_of_v<Base, Derived> && std::is_convertible_v<const volatile Derived*,
                                                                                 const volatile Base*>;

template <class T>
concept destructible = std::is_nothrow_destructible_v<T>;

template <class T, class... Args>
concept constructible_from = std::destructible<T>&& std::is_constructible_v<T, Args...>;

template <class T>
concept default_initializable = std::constructible_from<T>&& requires {
    T{};
}
&&requires {
    ::new (static_cast<void*>(nullptr)) T;
};

template <class From, class To>
concept convertible_to = std::is_convertible_v<From, To>&& requires(std::add_rvalue_reference_t<From> (&f)()) {
    static_cast<To>(f());
};

template <class T>
concept move_constructible = std::constructible_from<T, T>&& std::convertible_to<T, T>;

template <class T>
concept copy_constructible = std::move_constructible<T>&& std::constructible_from<T, T&>&& std::convertible_to<T&, T>&&
    std::constructible_from<T, const T&>&& std::convertible_to<const T&, T>&& std::constructible_from<T, const T>&&
        std::convertible_to<const T, T>;

// template < class T, class U >
// concept common_reference_with =
//      std::same_as<std::common_reference_t<T, U>, std::common_reference_t<U, T>>
//      && std::convertible_to<T, std::common_reference_t<T, U>>
//      && std::convertible_to<U, std::common_reference_t<T, U>>;

// template< class T >
// concept swappable = requires(T& a, T& b) { ranges::swap(a, b); };

// template< class T, class U >
// concept swappable_with =
//      std::common_reference_with<T, U>
//      && requires(T&& t, U&& u) {
//      ranges::swap(std::forward<T>(t), std::forward<T>(t));
//      ranges::swap(std::forward<U>(u), std::forward<U>(u));
//      ranges::swap(std::forward<T>(t), std::forward<U>(u));
//      ranges::swap(std::forward<U>(u), std::forward<T>(t));
// };

// template< class LHS, class RHS >
// concept assignable_from =
//      std::is_lvalue_reference_v<LHS>
//      && std::common_reference_with<const std::remove_reference_t<LHS>&,
//                                    const std::remove_reference_t<RHS>&>
//      && requires(LHS lhs, RHS&& rhs) { { lhs = std::forward<RHS>(rhs) } -> std::same_as<LHS>; };

// template < class T >
// concept movable =
//      std::is_object_v<T>
//      && std::move_constructible<T>
//      && std::assignable_from<T&, T>
//      && std::swappable<T>;

// template <class T>
// concept copyable = std::copy_constructible<T>
//      && std::movable<T>
//      && std::assignable_from<T&, T&>
//      && std::assignable_from<T&, const T&>
//      && std::assignable_from<T&, const T>;
// clang-format on
#endif  // MQ_HAS_CONCEPTS && !MQ_HAS_CONCEPT_LIBRARY

#if !MQ_HAS_REMOVE_CVREF_T
template <class T>
struct remove_cvref {
    using type = std::remove_cv_t<std::remove_reference_t<T>>;
};

template <class T>
using remove_cvref_t = typename remove_cvref<T>::type;
#endif  // !MQ_HAS_REMOVE_CVREF_T

#if !MQ_HAS_STD_LAUNDER
template <typename T>
constexpr T* launder(T* t) noexcept {
    return t;
}
#endif  // !MQ_HAS_STD_LAUNDER

}  // namespace std

#endif /* CORE_CXX20_COMPATIBILITY_HPP */
