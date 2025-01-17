# -*- coding: utf-8 -*-
# Copyright 2021 Huawei Technologies Co., Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ============================================================================
"""
Gate.

Gate provides different quantum gate.
"""

from .basic import (  # noqa: F401
    HERMITIAN_PROPERTIES,
    BasicGate,
    NoiseGate,
    NoneParameterGate,
    ParameterGate,
)
from .basicgate import (
    BARRIER,
    CNOT,
    ISWAP,
    RX,
    RY,
    RZ,
    SWAP,
    XX,
    YY,
    ZZ,
    BarrierGate,
    CNOTGate,
    GlobalPhase,
    H,
    HGate,
    I,
    IGate,
    ISWAPGate,
    PhaseShift,
    Power,
    S,
    SGate,
    SWAPGate,
    T,
    TGate,
    UnivMathGate,
    X,
    XGate,
    Y,
    YGate,
    Z,
    ZGate,
    gene_univ_parameterized_gate,
)
from .channel import (
    AmplitudeDampingChannel,
    BitFlipChannel,
    BitPhaseFlipChannel,
    DepolarizingChannel,
    PauliChannel,
    PhaseDampingChannel,
    PhaseFlipChannel,
)
from .measurement import Measure, MeasureResult

__all__ = [
    "BasicGate",
    "NoneParameterGate",
    "ParameterGate",
    "HERMITIAN_PROPERTIES",
    "BarrierGate",
    "CNOTGate",
    "HGate",
    "IGate",
    "XGate",
    "YGate",
    "ZGate",
    "gene_univ_parameterized_gate",
    "UnivMathGate",
    "SWAPGate",
    "ISWAPGate",
    "RX",
    "RY",
    "RZ",
    "PhaseShift",
    "SGate",
    "TGate",
    "XX",
    "YY",
    "ZZ",
    "Power",
    "I",
    "X",
    "Y",
    "Z",
    "H",
    "S",
    "T",
    "SWAP",
    "ISWAP",
    "CNOT",
    "BARRIER",
    "Measure",
    "MeasureResult",
    "PauliChannel",
    "BitFlipChannel",
    "PhaseFlipChannel",
    "BitPhaseFlipChannel",
    "DepolarizingChannel",
    "GlobalPhase",
    "AmplitudeDampingChannel",
    "PhaseDampingChannel",
]

__all__.sort()
