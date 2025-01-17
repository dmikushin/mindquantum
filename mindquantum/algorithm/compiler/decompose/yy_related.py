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

"""YY gate related decompose rule."""

import numpy as np

from mindquantum.core import Circuit, gates
from mindquantum.core.gates.basicgate import YY
from mindquantum.utils.type_value_check import _check_input_type  # , _check_control_num


def _check_control_num(ctrl_qubits, require_n):
    if len(ctrl_qubits) != require_n:
        raise RuntimeError(f"requires {(require_n,'control qubit')}, but get {len(ctrl_qubits)}")


def yy_decompose(gate: gates.YY):
    """
    Decompose YY gate.

    Args:
        gate (YY): a YY gate.

    Returns:
        List[Circuit], all possible decompose solution.

    Examples:
        >>> from mindquantum.algorithm.compiler.decompose import yy_decompose
        >>> from mindquantum.core import Circuit, YY
        >>> yy = YY(1).on([0, 1])
        >>> origin_circ = Circuit() + yy
        >>> decomposed_circ = yy_decompose(yy)[0]
        >>> origin_circ
        q0: ──YY(1)──
                │
        q1: ──YY(1)──
        >>> decomposed_circ
        q0: ──RX(π/2)────●─────────────●────RX(-π/2)──
                         │             │
        q1: ──RX(π/2)────X────RZ(2)────X────RX(-π/2)──
    """
    _check_input_type('gate', YY, gate)
    _check_control_num(gate.ctrl_qubits, 0)
    return cyy_decompose(gate)


def cyy_decompose(gate: gates.YY):
    """
    Decompose yy gate with control qubits.

    Args:
        gate (YY): a YY gate.

    Returns:
        List[Circuit], all possible decompose solution.

    Examples:
        >>> from mindquantum.algorithm.compiler.decompose import cyy_decompose
        >>> from mindquantum.core import Circuit, YY
        >>> cyy = YY(2).on([0, 1], [2, 3])
        >>> origin_circ = Circuit() + cyy
        >>> decomposed_circ = cyy_decompose(cyy)[0]
        >>> origin_circ
        q0: ──YY(2)──
                │
        q1: ──YY(2)──
                │
        q2: ────●────
                │
        q3: ────●────
        >>> decomposed_circ
        q0: ──RX(π/2)───────────────●─────────────●────────────────RX(-π/2)──
                 │                  │             │                   │
        q1: ─────┼───────RX(π/2)────X────RZ(4)────X────RX(-π/2)───────┼──────
                 │          │       │      │      │       │           │
        q2: ─────●──────────●───────●──────●──────●───────●───────────●──────
                 │          │       │      │      │       │           │
        q3: ─────●──────────●───────●──────●──────●───────●───────────●──────
    """
    _check_input_type('gate', YY, gate)
    solutions = []
    q0 = gate.obj_qubits[0]
    q1 = gate.obj_qubits[1]
    cq = gate.ctrl_qubits

    c1 = Circuit()
    solutions.append(c1)
    c1 += gates.RX(np.pi / 2).on(q0, cq)
    c1 += gates.RX(np.pi / 2).on(q1, cq)
    c1 += gates.X.on(q1, [q0] + cq)
    c1 += gates.RZ(2 * gate.coeff).on(q1, cq)
    c1 += c1[-2]
    c1 += gates.RX(-np.pi / 2).on(q1, cq)
    c1 += gates.RX(-np.pi / 2).on(q0, cq)

    c2 = Circuit()
    solutions.append(c2)
    c2 += gates.RX(np.pi / 2).on(q0, cq)
    c2 += gates.RX(np.pi / 2).on(q1, cq)
    c2 += gates.X.on(q0, [q1] + cq)
    c2 += gates.RZ(2 * gate.coeff).on(q0, cq)
    c2 += c2[-2]
    c2 += gates.RX(-np.pi / 2).on(q1, cq)
    c2 += gates.RX(-np.pi / 2).on(q0, cq)

    return solutions


decompose_rules = ['yy_decompose', 'cyy_decompose']
__all__ = decompose_rules
