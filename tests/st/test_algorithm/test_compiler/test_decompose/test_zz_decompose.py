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
'''test decompose rule'''
import numpy as np

from mindquantum.algorithm.compiler.decompose import zz_decompose
from mindquantum.core import ZZ, Circuit


def circuit_equal_test(gate, decompose_circ):
    """
    require two circuits are equal.
    """
    orig_circ = Circuit() + gate
    assert np.allclose(orig_circ.matrix(), decompose_circ.matrix())


def test_zz():
    """
    Description: Test zz decompose
    Expectation: success
    """
    zz = ZZ(1).on([1, 0])
    for solution in zz_decompose(zz):
        circuit_equal_test(zz, solution)
