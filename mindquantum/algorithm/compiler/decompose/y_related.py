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
"""y gate related decompose rule."""

from mindquantum.core import Circuit, gates
from mindquantum.utils.type_value_check import _check_control_num, _check_input_type


def cy_decompose(gate: gates.YGate):
    """
    Decompose cy gate.

    Args:
        gate (YGate): a YGate with one control qubits.

    Returns:
        List[Circuit], all possible decompose solution.

    Examples:
        >>> from mindquantum.algorithm.compiler.decompose import cy_decompose
        >>> from mindquantum.core import Circuit, Y
        >>> cy = Y.on(1, 0)
        >>> origin_circ = Circuit() + cy
        >>> decomposed_circ = cy_decompose(cy)[0]
        >>> origin_circ
        q0: ──●──
              │
        q1: ──Y──
        >>> decomposed_circ
        q0: ────────●───────
                    │
        q1: ──S†────X────S──
    """
    _check_input_type('gate', gates.YGate, gate)
    _check_control_num(gate.ctrl_qubits, 1)
    solutions = []
    c1 = Circuit()
    solutions.append(c1)
    q0 = gate.ctrl_qubits[0]
    q1 = gate.obj_qubits[0]
    c1 += gates.S.on(q1).hermitian()
    c1 += gates.X.on(q1, q0)
    c1 += gates.S.on(q1)
    return solutions


decompose_rules = ['cy_decompose']
__all__ = decompose_rules
