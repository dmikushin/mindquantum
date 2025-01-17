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

"""SWAP gate related decompose rule."""

from mindquantum.core import Circuit, gates
from mindquantum.utils.type_value_check import _check_control_num, _check_input_type


def swap_decompose(gate: gates.SWAPGate):
    """
    Decompose swap gate.

    Args:
        gate (SWAPGate): a SWAP gate.

    Returns:
        List[Circuit], all possible decompose solution.

    Examples:
        >>> from mindquantum.algorithm.compiler.decompose import swap_decompose
        >>> from mindquantum.core import Circuit, SWAP
        >>> swap = SWAP.on([1, 0])
        >>> origin_circ = Circuit() + swap
        >>> decomposed_circ = swap_decompose(swap)[0]
        >>> origin_circ
        q0: ──@──
              │
        q1: ──@──
        >>> decomposed_circ
        q0: ──X────●────X──
              │    │    │
        q1: ──●────X────●──
    """
    _check_input_type('gate', gates.SWAPGate, gate)
    _check_control_num(gate.obj_qubits, 2)
    solutions = []
    c1 = Circuit()
    solutions.append(c1)
    q0 = gate.obj_qubits[0]
    q1 = gate.obj_qubits[1]
    c1 += gates.X.on(q1, q0)
    c1 += gates.X.on(q0, q1)
    c1 += gates.X.on(q1, q0)
    return solutions


def cswap_decompose(gate: gates.SWAPGate):
    """
    Decompose cswap gate.

    Args:
        gate (SWAPGate): a SWAPGate with one control qubit.

    Returns:
        List[Circuit], all possible decompose solution.

    Examples:
        >>> from mindquantum.algorithm.compiler.decompose import cswap_decompose
        >>> from mindquantum.core import Circuit, SWAP
        >>> swap = SWAP.on([1, 2], 0)
        >>> origin_circ = Circuit() + cswap
        >>> decomposed_circ = cswap_decompose(swap)[0]
        >>> origin_circ
        q0: ──●──
              │
        q1: ──@──
              │
        q2: ──@──
        >>> decomposed_circ
        q0: ───────●───────
                   │
        q1: ──X────●────X──
              │    │    │
        q2: ──●────X────●──
    """
    _check_input_type('gate', gates.SWAPGate, gate)
    _check_control_num(gate.ctrl_qubits, 1)
    solutions = []
    c1 = Circuit()
    solutions.append(c1)
    q0 = gate.ctrl_qubits[0]
    q1 = gate.obj_qubits[0]
    q2 = gate.obj_qubits[1]
    c1 += gates.X.on(q1, q2)
    c1 += gates.X.on(q2, [q0, q1])
    c1 += gates.X.on(q1, q2)
    return solutions


decompose_rules = ['swap_decompose', 'cswap_decompose']
__all__ = decompose_rules
