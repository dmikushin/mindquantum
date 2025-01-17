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
"""Test uccsd."""
import warnings

import numpy as np

from mindquantum.algorithm.nisq.chem import generate_uccsd
from mindquantum.core import gates as G


def test_generate_uccsd():
    """
    Description: Test generate_uccsd
    Expectation:
    """

    with warnings.catch_warnings():
        warnings.simplefilter('ignore', category=DeprecationWarning)
        circ, init_amp, params_name, ham, n_q, n_e = generate_uccsd('./tests/st/LiH.hdf5')
    circ = circ.remove_barrier()
    assert len(circ) == 4416
    assert circ[2000] == G.X.on(9, 8)
    assert np.allclose(init_amp[-5], 0.001687182323430231)
    assert len(params_name) == 20
    assert len(ham.terms) == 631
    assert n_q == 12
    assert n_e == 4
