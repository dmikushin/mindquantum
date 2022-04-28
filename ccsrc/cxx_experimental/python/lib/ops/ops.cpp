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

#include <pybind11/operators.h>
#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include <tweedledum/IR/Circuit.h>
#include <tweedledum/IR/Qubit.h>

#include "ops/gates.hpp"
#include "ops/parametric/angle_gates.hpp"
#include "python/bindings.hpp"
#include "python/ops/gate_adapter.hpp"

namespace ops = mindquantum::ops;
namespace py = pybind11;

void init_tweedledum_ops(pybind11::module& module) {
    py::class_<ops::Barrier>(module, "Barrier").def(py::init<>());
    py::class_<ops::H>(module, "H").def(py::init<>());
    py::class_<ops::Measure>(module, "Measure").def(py::init<>());
    py::class_<ops::S>(module, "S").def(py::init<>());
    py::class_<ops::Sdg>(module, "Sdg").def(py::init<>());
    py::class_<ops::Swap>(module, "Swap").def(py::init<>());
    py::class_<ops::Sx>(module, "Sx").def(py::init<>());
    py::class_<ops::Sxdg>(module, "Sxdg").def(py::init<>());
    py::class_<ops::T>(module, "T").def(py::init<>());
    py::class_<ops::Tdg>(module, "Tdg").def(py::init<>());
    py::class_<ops::X>(module, "X").def(py::init<>());
    py::class_<ops::Y>(module, "Y").def(py::init<>());
    py::class_<ops::Z>(module, "Z").def(py::init<>());

    py::class_<ops::P>(module, "P").def(py::init<const double>());
    py::class_<ops::Rx>(module, "Rx").def(py::init<const double>());
    py::class_<ops::Rxx>(module, "Rxx").def(py::init<const double>());
    py::class_<ops::Ry>(module, "Ry").def(py::init<const double>());
    py::class_<ops::Ryy>(module, "Ryy").def(py::init<const double>());
    py::class_<ops::Rz>(module, "Rz").def(py::init<const double>());
    py::class_<ops::Rzz>(module, "Rzz").def(py::init<const double>());
}

void init_mindquantum_ops(pybind11::module& module) {
    py::class_<ops::SqrtSwap>(module, "SqrtSwap").def(py::init<>());

    py::class_<ops::Entangle>(module, "Entangle").def(py::init<const uint32_t>());
    py::class_<ops::Ph>(module, "Ph").def(py::init<const double>());
    py::class_<ops::QFT>(module, "QFT").def(py::init<const uint32_t>());
    py::class_<ops::QubitOperator>(module, "QubitOperator")
        .def(py::init<const uint32_t, const ops::QubitOperator::ComplexTermsDict&>());

    // py::class_<ops::parametric::P>(module, "P").def(py::init<const double>());
    // py::class_<ops::parametric::Ph>(module, "Ph").def(py::init<SymEngine::number>());
    // py::class_<ops::parametric::Rx>(module, "Rx").def(py::init<const double>());
    // py::class_<ops::parametric::Rxx>(module, "Rxx").def(py::init<const double>());
    // py::class_<ops::parametric::Ry>(module, "Ry").def(py::init<const double>());
    // py::class_<ops::parametric::Ryy>(module, "Ryy").def(py::init<const double>());
    // py::class_<ops::parametric::Rz>(module, "Rz").def(py::init<const double>());
    // py::class_<ops::parametric::Rzz>(module, "Rzz").def(py::init<const double>());
}

void mindquantum::python::init_ops(pybind11::module& module) {
    init_tweedledum_ops(module);
    init_mindquantum_ops(module);
}
