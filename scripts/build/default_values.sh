#!/bin/bash
# Copyright 2022 Huawei Technologies Co., Ltd
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

[ "${_sourced_default_values}" != "" ] && return || _sourced_default_values=.

# ==============================================================================
# Default values for input arguments

: "${build_type=Release}"
: "${cmake_debug_mode=0}"
: "${cmake_generator=}"
: "${cmake_make_silent=0}"
: "${cuda_arch=}"
: "${do_clean_3rdparty=0}"
: "${do_clean_build_dir=0}"
: "${do_clean_cache=0}"
: "${do_clean_venv=0}"
: "${do_update_venv=0}"
: "${dry_run=0}"
: "${enable_ccache=0}"
: "${enable_cxx=0}"
: "${enable_gpu=0}"
: "${enable_projectq=1}"
: "${enable_tests=0}"
: "${force_local_pkgs=0}"
[[ -z ${local_pkgs@a} ]] && local_pkgs=()
: "${n_jobs=-1}"
: "${verbose=0}"

if [ -z "$n_jobs_default" ]; then
    if command -v nproc >/dev/null 2>&1; then
        n_jobs_default=$(nproc)
    elif command -v sysctl >/dev/null 2>&1; then
        n_jobs_default=$(sysctl -n hw.logicalcpu)
    else
        n_jobs_default=8
    fi
fi

# ==============================================================================

: "${source_dir=$(realpath "$ROOTDIR")}"
: "${build_dir="$source_dir/build"}"
: "${python_venv_path="$source_dir/venv"}"

: "${third_party_libraries=$(cd "$source_dir/third_party" \
                                && find . -maxdepth 1 -type d ! -path . | grep -vE '(cmake|CMakeLists.txt)' \
                                    | sed 's|./||')}"

# ==============================================================================
# Other helper variables

: "${cmake_from_venv=0}"
