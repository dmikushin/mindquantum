# -*- coding: utf-8 -*-
#   Copyright 2022 <Huawei Technologies Co., Ltd>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

"""Experimental C++ backend for MindQuantum."""

import sys

from ._mindquantum_cxx import (  # noqa: F401
    circuit,
    ops,
    optimizer,
    simulator,
    symengine,
)

# isort: split

from . import _symengine_utilities

# NB: These below will allow `from mindquantum.experimental.XXX import YYY` but not
#     `from minquantum.experimental.XXX.YYY import ZZZ` for example
sys.modules[f'{__name__}.circuit'] = circuit
sys.modules[f'{__name__}.ops'] = ops
sys.modules[f'{__name__}.optimizer'] = optimizer
sys.modules[f'{__name__}.simulator'] = simulator
sys.modules[f'{__name__}.simulator.projectq'] = simulator.projectq
sys.modules[f'{__name__}.symengine'] = symengine

symengine.symbols = _symengine_utilities.symbols
