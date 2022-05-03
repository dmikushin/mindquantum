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

[ "${_sourced_setup_cmake_args}" != "" ] && return || _sourced_setup_cmake_args=.

BASEPATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}" )" &> /dev/null && pwd )

# ------------------------------------------------------------------------------

# NB: to get the default value for the arguments
if [ -z "$_sourced_parse_common_args" ]; then
    die '(internal error): _sourced_parse_common_args variable not defined!'
fi

# ------------------------------------------------------------------------------

# shellcheck source=SCRIPTDIR/default_values.sh
. "$BASEPATH/default_values.sh"

# shellcheck source=SCRIPTDIR/common_functions.sh
. "$BASEPATH/common_functions.sh"

CMAKE_BOOL=(OFF ON)

# ==============================================================================

cmake_args=(-DIN_PLACE_BUILD:BOOL=ON
            -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=ON
            -DCMAKE_BUILD_TYPE:STRING="$build_type"
            -DENABLE_PROJECTQ:BOOL="${CMAKE_BOOL[$enable_projectq]}"
            -DENABLE_QUEST:BOOL="${CMAKE_BOOL[$enable_quest]}"
            -DENABLE_CMAKE_DEBUG:BOOL="${CMAKE_BOOL[$cmake_debug_mode]}"
            -DENABLE_CUDA:BOOL="${CMAKE_BOOL[$enable_gpu]}"
            -DENABLE_CXX_EXPERIMENTAL:BOOL="${CMAKE_BOOL[$enable_cxx]}"
            -DBUILD_TESTING:BOOL="${CMAKE_BOOL[$enable_tests]}"
            -DCLEAN_3RDPARTY_INSTALL_DIR:BOOL="${CMAKE_BOOL[$do_clean_3rdparty]}"
            -DUSE_VERBOSE_MAKEFILE:BOOL="${CMAKE_BOOL[! $cmake_make_silent]}")

if [[ -n "$cmake_generator" ]]; then
    cmake_args+=(-G "${cmake_generator}")
fi

if [ $enable_ccache -eq 1 ]; then
    ccache_exec=
    if command -v ccache > /dev/null 2>&1; then
        ccache_exec=ccache
    elif command -v sccache > /dev/null 2>&1; then
        ccache_exec=sccache
    fi
    if [ -n "$ccache_exec" ]; then
        ccache_exec=$(which "$ccache_exec")
        cmake_args+=(-DCMAKE_C_COMPILER_LAUNCHER="$ccache_exec")
        cmake_args+=(-DCMAKE_CXX_COMPILER_LAUNCHER="$ccache_exec")
    fi
fi

if [[ $enable_gpu -eq 1 && -n "$cuda_arch" ]]; then
    cmake_args+=(-DCMAKE_CUDA_ARCHITECTURES:STRING="$cuda_arch")
fi

local_pkgs_str=$(join_by , "${local_pkgs[@]}")
if [[ $force_local_pkgs -eq 1 ]]; then
    cmake_args+=(-DMQ_FORCE_LOCAL_PKGS=all)
elif [ -n "$local_pkgs_str" ]; then
    cmake_args+=(-DMQ_FORCE_LOCAL_PKGS="$local_pkgs_str")
fi

if [ $n_jobs -ne -1 ]; then
    cmake_args+=(-DJOBS:STRING="$n_jobs")
fi
