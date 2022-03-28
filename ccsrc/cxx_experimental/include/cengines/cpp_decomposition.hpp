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

#ifndef CPP_DECOMPOSER_HPP
#define CPP_DECOMPOSER_HPP

#include <functional>
#include <map>
#include <string>
#include <string_view>
#include <vector>

#include <tweedledum/IR/Circuit.h>

namespace td = tweedledum;

namespace mindquantum::cengines {
//! C++ class to decompose gates with subset of given decomposition rules
class CppDecomposer {
 public:
    using decomp_func_t = std::function<void(td::Circuit&, const td::Instruction&)>;
    using recogn_func_t = std::function<bool(const td::Instruction&)>;

    //! Constructor
    /*!
     * Initialises a CppDecomposer with all the known rules.
     */
    CppDecomposer();

    //! Constructor
    /*!
     * This is intended to be instantiated in Python by users in order to
     * select the decomposition rules, which they want to apply to the
     * cicuit/network
     * \param input_rules List of decomposition rules to apply
     */
    CppDecomposer(std::vector<std::string> input_rules);

    //! Decompose network
    /*!
     * Go through all gates in the network and decompose them if the user
     * specified a rule for them.
     * \param circuit The network to be decomposed according to
     * input_rules
     */
    td::Circuit decompose_circuit(const td::Circuit& circuit);

    //! Register a new gate decomposition
    /*!
     * \param name Name of decomposition
     * \param kind Gate identifier string
     * \param is_recursive Boolean indicating whether the decomposition is recursive
     * \param check Function to check the applicability of the decomposition
     * \param decomp Decomposition function
     */
    static bool register_decomposition(std::string_view name, std::string_view kind, bool is_recursive,
                                       recogn_func_t check, decomp_func_t decomp);

 private:
    // Jump table from gate kind to rules that apply to that gate class
    std::map<std::string, std::vector<std::tuple<std::string, bool, recogn_func_t, decomp_func_t>>, std::less<>>
        rule_table_;

    struct rule_t {
        std::string_view kind;  //!< Gate kind to which this rule applies to
        bool is_recursive;      //!< Whether the rule can be applied recursively or not
        recogn_func_t check;    //!< Gat recognize function
        decomp_func_t decomp;   //!< Gate decomposition function
    };

    //! Dictionary for rules applying to particular gates
    static std::map<std::string, const rule_t, std::less<>> rule_map_;

    struct gen_rule_t {
        bool is_recursive;     //!< Whether the rule can be applied recursively or not
        recogn_func_t check;   //!< Gat recognize function
        decomp_func_t decomp;  //!< Gate decomposition function
    };

    //! Dictionary for rules applying to general gates
    static std::map<std::string, const gen_rule_t, std::less<>> gen_rule_map_;
};
}  // namespace mindquantum::cengines

#endif /* CPP_DECOMPOSER_HPP */
