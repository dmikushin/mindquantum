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
"""Benchmakr for gradient calculation of mindquantum."""

import os
import time

import mindspore.context as context
import numpy as np
import tqdm
from _parse_args import parser

from mindquantum.core import XX, ZZ, Circuit, H, Hamiltonian, QubitOperator, X
from mindquantum.simulator import Simulator

args = parser.parse_args()
os.environ['OMP_NUM_THREADS'] = str(args.omp_num_threads)
context.set_context(mode=context.PYNATIVE_MODE, device_target="CPU")


class CircuitLayerBuilder:
    """CircuitLayerBuilder class."""

    def __init__(self, data_qubits, readout):
        """Initialize a CircuitLayerBuilder object."""
        self.data_qubits = data_qubits
        self.readout = readout

    def add_layer(self, circuit, gate, prefix):
        """Add a layer to this instance."""
        for i, qubit in enumerate(self.data_qubits):
            symbol = prefix + '-' + str(i)
            circuit.append(gate({symbol: np.pi / 2}).on([qubit, self.readout]))


def convert_to_circuit(image, data_qubits=None):
    """
    Convert an image to a circuit.

    Returns:
        Circuit
    """
    values = np.ndarray.flatten(image)
    if data_qubits is None:
        data_qubits = range(len(values))

    c = Circuit()
    for i, value in enumerate(values[: len(data_qubits)]):
        if value:
            c += X.on(data_qubits[i])
    return c


def create_quantum_model(n_qubits):
    """
    Create QNN.

    Returns:
        tuple
    """
    data_qubits = range(1, n_qubits)
    readout = 0
    c = Circuit()

    c = c + X.on(readout) + H.on(readout)
    builder = CircuitLayerBuilder(data_qubits=data_qubits, readout=readout)
    builder.add_layer(c, XX, 'xx1')
    builder.add_layer(c, ZZ, 'zz1')
    c += H.on(readout)
    return c, Hamiltonian(QubitOperator('Z{}'.format(readout)))


n_qubits = 17
data = np.load('./mnist_resize.npz')
x_train_bin, y_train_nocon, x_test_bin, y_test_nocon = data['arr_0'], data['arr_1'], data['arr_2'], data['arr_3']
x_train_circ = [convert_to_circuit(x, range(1, n_qubits)) for x in x_train_bin]

ansatz, ham = create_quantum_model(n_qubits)
model_params_names = ansatz.params_name
ops = Simulator('projectq', ansatz.n_qubits).get_expectation_with_grad(
    ham, ansatz, parallel_worker=args.parallel_worker
)

t0 = time.time()
eval_time = []
for x in tqdm.tqdm(x_train_circ[: args.num_sampling]):
    eval_time.append(time.time())
    ops(np.random.normal(size=32))
    eval_time[-1] = time.time() - eval_time[-1]
eval_time = np.sort(eval_time[1:])
t1 = time.time()
print("Eval grad mean time:{}".format(eval_time[1:-1].mean()))
print("Total time:{}".format(t1 - t0))
