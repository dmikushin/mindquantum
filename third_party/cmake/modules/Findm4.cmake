# ==============================================================================
#
# Copyright 2022 <Huawei Technologies Co., Ltd>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ==============================================================================

find_program(M4_EXEC m4 PATHS /usr/local/bin /usr/bin /bin /sbin)

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(m4 REQUIRED_VARS M4_EXEC)

mark_as_advanced(M4_EXEC)
