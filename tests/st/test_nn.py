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
"""Test nn."""

import numpy as np
import mindspore as ms
from projectq.ops import QubitOperator
import mindquantum.gate as G
import mindquantum as mq
from mindquantum import Hamiltonian
from mindquantum.nn.mindquantumlayer import MindQuantumLayer
from mindquantum.circuit import Circuit
from mindquantum.engine import circuit_generator
from mindquantum.nn import generate_evolution_operator


def test_mindquantumlayer():
    """Test mindquantumlayer forward and backward."""
    encoder = Circuit()
    ansatz = Circuit()
    encoder += G.RX('e1').on(0)
    encoder += G.RY('e2').on(1)
    ansatz += G.X.on(1, 0)
    ansatz += G.RY('p1').on(0)
    ham = Hamiltonian(QubitOperator('Z0'))
    ms.set_seed(55)
    ms.context.set_context(mode=ms.context.GRAPH_MODE, device_target="CPU")
    net = MindQuantumLayer(['e1', 'e2'], ['p1'], encoder + ansatz, ham)
    encoder_data = ms.Tensor(np.array([[0.1, 0.2]]).astype(np.float32))
    res = net(encoder_data)
    assert round(float(res.asnumpy()[0, 0]), 6) == round(float(0.9949919), 6)
    state = net.final_state(encoder_data[0])
    assert np.allclose(state[0], 9.9375761e-01 + 1.2387493e-05j)


def test_generate_pqc_operator():
    """Test generate pqc operator"""
    @circuit_generator(2)
    def encoder(qubits):
        G.RY('a').__or__((qubits[0],))
        G.RY('b').__or__((qubits[1],))

    @circuit_generator(2)
    def ansatz(qubits):
        G.X.__or__((qubits[0], qubits[1]))
        G.RX('p1').__or__((qubits[0],))
        G.RX('p2').__or__((qubits[1],))

    ham = mq.Hamiltonian(QubitOperator('Z1'))
    encoder_names = ['a', 'b']
    ansatz_names = ['p1', 'p2']

    ms.context.set_context(mode=ms.context.GRAPH_MODE, device_target="CPU")

    pqc = mq.nn.generate_pqc_operator(encoder_names, ansatz_names,
                                      encoder + ansatz, ham)
    encoder_data = ms.Tensor(np.array([[0.1, 0.2]]).astype(np.float32))
    ansatz_data = ms.Tensor(np.array([0.3, 0.4]).astype(np.float32))
    measure_result, encoder_grad, ansatz_grad = pqc(encoder_data, ansatz_data)
    assert round(float(measure_result.asnumpy()[0, 0]),
                 6) == round(float(0.89819133), 6)
    assert round(float(encoder_grad.asnumpy()[0, 0, 0]),
                 6) == round(float(-0.09011973), 6)
    assert round(float(ansatz_grad.asnumpy()[0, 0, 1]),
                 6) == round(float(-3.7974921e-01), 6)


def test_generate_evolution_operator():
    circ = Circuit(G.RX('a').on(0))
    evol = generate_evolution_operator(['a'], circ)
    state = evol(ms.Tensor(np.array([0.5]).astype(np.float32)))
    state = state.asnumpy()
    state = state[:, 0] + 1j * state[:, 1]
    assert np.allclose(state, G.RX(0.5).matrix()[:, 0])