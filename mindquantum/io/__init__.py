# -*- coding: utf-8 -*-
#   Copyright 2021 <Huawei Technologies Co., Ltd>
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
"""Input/Output module for MindQuantum."""

from . import display, qasm
from .beauty_print import bprint
from .display import *  # noqa: F401,F403
from .qasm import *  # noqa: F401,F403

__all__ = ['bprint']
__all__.extend(display.__all__)
__all__.extend(qasm.__all__)
__all__.sort()
