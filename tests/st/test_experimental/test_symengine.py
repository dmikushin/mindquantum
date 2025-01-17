# -*- coding: utf-8 -*-
#   Copyright 2022 <Huawei Technologies Co., Ltd>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

"""Tests for mindquantum.experimental.symengine"""

import pytest

from mindquantum.experimental import symengine


@pytest.mark.symengine
def test_symbols_function_simple():
    """Simple tests for symbols()"""
    # pylint: disable=invalid-name

    x, y, z = symengine.symbols('x,y,z')
    assert isinstance(x, symengine.Symbol)
    assert isinstance(y, symengine.Symbol)
    assert isinstance(z, symengine.Symbol)

    a, b, c = symengine.symbols('a b c')
    assert isinstance(a, symengine.Symbol)
    assert isinstance(b, symengine.Symbol)
    assert isinstance(c, symengine.Symbol)


@pytest.mark.symengine
@pytest.mark.parametrize(
    'symbol_str, kwargs, symbols_type, length',
    [
        ('x, ', {}, tuple, 1),
        ('x, y', {}, tuple, 2),
        ('x', {'seq': True}, tuple, 1),
        (('a', 'b', 'c'), {}, tuple, 3),
        (['a', 'b', 'c'], {}, list, 3),
        ({'a', 'b', 'c'}, {}, set, 3),
        ('x:10', {}, tuple, 10),
        ('x:z', {}, tuple, 3),
        ('x((a:b))', {}, tuple, 2),
    ],
    ids=lambda x: x if isinstance(x, type) else (f'"{x}"' if isinstance(x, str) else str(x)),
)
def test_symbols_function(symbol_str, kwargs, symbols_type, length):
    """Test symbols() generating iterables."""
    symbols = symengine.symbols(symbol_str, **kwargs)
    assert isinstance(symbols, symbols_type)

    assert len(symbols) == length
    for symbol in symbols:
        assert isinstance(symbol, symengine.Symbol)


# ==============================================================================
