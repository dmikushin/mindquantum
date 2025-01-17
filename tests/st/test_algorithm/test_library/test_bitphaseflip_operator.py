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
"""Bitphaseflip operator."""

import numpy as np

from mindquantum import UN, H
from mindquantum.algorithm.library import bitphaseflip_operator
from mindquantum.core.circuit import Circuit


def test_bitphaseflip_operator():
    """
    Description: Test bitphaseflip_operator
    Expectation:
    """
    circuit = Circuit()
    circuit += UN(H, 3)
    circuit += bitphaseflip_operator([2], 3)
    circuit = circuit.get_qs()
    qs_exp = 1 / np.sqrt(8) * np.array([1, 1, -1, 1, 1, 1, 1, 1])
    assert np.allclose(circuit, qs_exp)
