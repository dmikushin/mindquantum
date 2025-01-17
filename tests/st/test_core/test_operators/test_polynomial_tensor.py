# -*- coding: utf-8 -*-
#   Copyright (c) 2020 Huawei Technologies Co.,ltd.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   You may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
"""
Test the polynomial_tensor in the ops module.
"""
import numpy as np

from mindquantum.core.operators import PolynomialTensor


def test_polynomial_tensor():
    """
    Description: Test polynomial tensor
    Expectation:
    """
    one_body_term = np.array([[1, 0], [0, 1]])
    two_body_term = np.array([[[[1, 0], [0, 1]], [[1, 0], [0, 1]]], [[[1, 0], [0, 1]], [[1, 0], [0, 1]]]])
    n_body_tensors = {(): 1, (1, 0): one_body_term, (1, 1, 0, 0): two_body_term}
    poly_op = PolynomialTensor(n_body_tensors)

    # test get function
    assert poly_op.constant == 1

    # test set function
    poly_op.constant = 2
    assert poly_op.constant == 2

    # test n_qubits
    assert poly_op.n_qubits == 2

    assert np.allclose(poly_op.one_body_tensor, one_body_term)

    assert np.allclose(poly_op.two_body_tensor, two_body_term)
