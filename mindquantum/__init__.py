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
""".. MindQuantum package."""

import os
from . import circuit
from . import engine
from . import gate
from . import nn
from . import parameterresolver
from . import utils
from .circuit import *
from .gate import *
from .parameterresolver import *
from .version import __version__

__version_info__ = tuple(__version__.split('.'))

__all__ = ['__version__', '__version_info__']
__all__.extend(circuit.__all__)
__all__.extend(gate.__all__)
__all__.extend(parameterresolver.__all__)
__all__.sort()

total_num_core = os.cpu_count()
omp_num_threads = os.environ.get('OMP_NUM_THREADS')
if omp_num_threads is None:
    omp_num_threads = total_num_core
print('[NOTE] Current simulator thread is {}. If your simulation is slow, \
set OMP_NUM_THREADS to a appropriate number accroding to your model.'.format(
    omp_num_threads))