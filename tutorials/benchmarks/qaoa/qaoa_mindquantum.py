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

"""Benchmark for QAOA with MindQuantum."""

import os
import time

import mindspore.context as context
import mindspore.dataset as ds
import mindspore.nn as nn
import numpy as np
from _parse_args import parser

from mindquantum.core import RX, RZ, UN, Circuit, H, Hamiltonian, QubitOperator, X
from mindquantum.framework import MQAnsatzOnlyLayer
from mindquantum.simulator import Simulator

args = parser.parse_args()
os.environ['OMP_NUM_THREADS'] = str(args.omp_num_threads)

context.set_context(mode=context.PYNATIVE_MODE, device_target="CPU")


def circuit_qaoa(p):
    """Build a QAOA circuit."""
    circ = Circuit()
    circ += UN(H, n)
    for layer in range(p):
        for (u, v) in E:
            circ += X.on(v, u)
            circ += RZ('gamma_{}'.format(layer)).on(v)
            circ += X.on(v, u)
        for v in V:
            circ += RX('beta_{}'.format(layer)).on(v)
    return circ


n = 12
V = range(n)
E = [
    (0, 1),
    (1, 2),
    (2, 3),
    (3, 4),
    (4, 5),
    (5, 0),
    (0, 3),
    (1, 4),
    (2, 6),
    (6, 7),
    (7, 8),
    (3, 8),
    (3, 9),
    (4, 9),
    (0, 10),
    (10, 11),
    (3, 11),
]
p = 4
ITR = 120
LR = 0.1

ham = QubitOperator()
for (v, u) in E:
    ham += QubitOperator('Z{} Z{}'.format(v, u), -1.0)
ham = Hamiltonian(ham)

circ = circuit_qaoa(p)
ansatz_name = circ.params_name
net = MQAnsatzOnlyLayer(Simulator('projectq', circ.n_qubits).get_expectation_with_grad(ham, circ))
train_loader = ds.NumpySlicesDataset(
    {'x': np.array([[0]]).astype(np.float32), 'y': np.array([0]).astype(np.float32)}
).batch(1)

net_opt = nn.Adam(net.trainable_params(), learning_rate=LR)
train_net = nn.TrainOneStepCell(net, net_opt)
t0 = time.time()
for i in range(ITR):
    train_net()
t1 = time.time()
print('Total time for mindquantum :{}'.format(t1 - t0))
