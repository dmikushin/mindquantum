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

"""Decompose rule for gate."""

from . import (
    h_related,
    rx_related,
    ry_related,
    rz_related,
    s_related,
    swap_related,
    t_related,
    x_related,
    xx_related,
    y_related,
    yy_related,
    z_related,
    zz_related,
)
from .h_related import ch_decompose  # noqa: F401
from .ry_related import cry_decompose  # noqa: F401
from .rz_related import crz_decompose  # noqa: F401
from .s_related import cs_decompose  # noqa: F401
from .swap_related import cswap_decompose, swap_decompose  # noqa: F401
from .t_related import ct_decompose  # noqa: F401
from .x_related import ccx_decompose  # noqa: F401
from .xx_related import cxx_decompose, xx_decompose  # noqa: F401
from .y_related import cy_decompose  # noqa: F401
from .yy_related import cyy_decompose, yy_decompose  # noqa: F401
from .z_related import cz_decompose  # noqa: F401
from .zz_related import zz_decompose  # noqa: F401

__all__ = []
__all__.extend(x_related.__all__)
__all__.extend(xx_related.__all__)
__all__.extend(yy_related.__all__)
__all__.extend(y_related.__all__)
__all__.extend(h_related.__all__)
__all__.extend(z_related.__all__)
__all__.extend(ry_related.__all__)
__all__.extend(rz_related.__all__)
__all__.extend(rx_related.__all__)
__all__.extend(swap_related.__all__)
__all__.extend(zz_related.__all__)
__all__.extend(s_related.__all__)
__all__.extend(t_related.__all__)
__all__.sort()
