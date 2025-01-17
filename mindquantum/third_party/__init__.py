# -*- coding: utf-8 -*-
#   Copyright 2017 The OpenFermion Developers
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
#
"""Third-party modules for MindQuantum."""

# Allow extending this namespace.
from .unitary_cc import (  # noqa: F401
    uccsd_singlet_generator,
    uccsd_singlet_get_packed_amplitudes,
)
