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
"""Test utils."""

import numpy as np

from mindquantum.utils import f


def test_mod():
    """Test mod"""
    mod_0 = f.mod([[1 + 1j, 0.5 + 0.5j], [0.5 + 1j, 0.5 + 0.5j]])
    mod_1 = f.mod([[1 + 1j, 0.5 + 0.5j], [0.5 + 1j, 0.5 + 0.5j]], axis=1)
    assert round(np.real(mod_1[0, 0]), 5) == round(1.58113883, 5)
    assert round(np.real(mod_0[0, 0]), 5) == round(1.80277564, 5)


def test_normalize():
    """Test normalize"""
    norm = np.real((f.normalize([[1 + 1j, 0.5 + 0.5j], [0.5 + 1j, 0.5 + 0.5j]]))[0, 0])
    assert round(norm, 5) == round(0.5547002, 5)


def test_random_state():
    """Test random state"""
    assert round(np.real(f.random_state((2, 4), seed=55)[0, 0]), 5) == round(0.16926417, 5)
