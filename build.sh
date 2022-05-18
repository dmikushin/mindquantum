#!/bin/bash
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

# shellcheck disable=SC2154

BASEPATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}" )" &> /dev/null && pwd )
ROOTDIR="$BASEPATH"
PROGRAM=$(basename "${BASH_SOURCE[0]:-$0}")

# ==============================================================================
# Default values for this particular script

delocate_wheel=1
no_build_isolation=0
output_path="${BASEPATH}/output"
platform_name=''

# Override some of the default values
# shellcheck disable=SC2034
enable_cxx=1

. "$ROOTDIR/scripts/build/default_values.sh"

# Load common bash helper functions
. "$ROOTDIR/scripts/build/common_functions.sh"

# ==============================================================================

function help_header() {
    echo 'Build binary Python wheel for MindQunantum'
    echo ''
    echo 'This is mainly relevant for developers that want to deploy MindQuantum '
    echo 'on machines other than their own.'
    echo ''
    echo 'This script will create a Python virtualenv in the MindQuantum root'
    echo 'directory and then build a binary Python wheel of MindQuantum.'
}

function extra_help() {
    echo 'Extra options:'
    echo '  --delocate           Delocate the binary wheels after build is finished'
    echo '                       (enabled by default; pass --no-delocate to disable)'
    echo '  --no-delocate        Disable delocating the binary wheels after build is finished'
    echo '  --no-isolation       Pass --no-isolation to python3 -m build'
    echo '  -o,--output=[dir]    Output directory for built wheels'
    echo '  -p,--plat-name=[dir] Platform name to use for wheel delocation'
    echo '                       (only effective if --delocate is used)'
    echo -e '\nExample calls:'
    echo "$PROGRAM"
    echo "$PROGRAM --gpu"
    echo "$PROGRAM --cxx --with-boost --without-gmp --venv=/tmp/venv"
}

# ==============================================================================

getopts_args_extra='o:p:'

function parse_extra_args() {
    case "$1" in
        delocate )       no_arg;
                         set_var delocate_wheel
                         ;;
        no-delocate )    no_arg;
                         set_var delocate_wheel 0
                         ;;
        no-isolation )   no_arg;
                         set_var no_build_isolation
                         ;;
        o | output )     needs_arg;
                         set_var output_path "$2"
                         ;;
        p | plat-name )  needs_arg;
                         set_var platform_name "$2"
                         ;;
        ??* )            die "Illegal option --OPT: $1"
                         ;;
    esac
}


# NB: using the default values from parse_common_args.sh
. "$ROOTDIR/scripts/build/parse_common_args.sh"

# ------------------------------------------------------------------------------

# Locate python or python3
. "$ROOTDIR/scripts/build/locate_python3.sh"

# ==============================================================================

set -e

cd "${ROOTDIR}"

# ------------------------------------------------------------------------------

# NB: `created_venv` variable can be used to detect if a virtualenv was created or not
. "$ROOTDIR/scripts/build/python_virtualenv_activate.sh"

# ------------------------------------------------------------------------------
# Update Python virtualenv (if requested/necessary)

. "$ROOTDIR/scripts/build/python_virtualenv_update.sh"

# ------------------------------------------------------------------------------
# Setup arguments for build

args=()

declare -A cmake_option_names
cmake_option_names[cmake_debug_mode]=ENABLE_CMAKE_DEBUG
cmake_option_names[enable_cxx]=ENABLE_CXX_EXPERIMENTAL
cmake_option_names[enable_gpu]=ENABLE_CUDA
cmake_option_names[enable_projectq]=ENABLE_PROJECTQ
cmake_option_names[enable_tests]=BUILD_TESTING
cmake_option_names[do_clean_3rdparty]=CLEAN_3RDPARTY_INSTALL_DIR

for var in "${!cmake_option_names[@]}"; do
    if [ "${!var}" -eq 1 ]; then
        args+=(--set "${cmake_option_names[$var]}")
    else
        args+=(--unset "${cmake_option_names[$var]}")
    fi
done

if [ "$cmake_make_silent" -eq 0 ]; then
    args+=(--set USE_VERBOSE_MAKEFILE)
else
    args+=(--unset USE_VERBOSE_MAKEFILE)
fi

if [ -n "$cmake_generator" ]; then
    args+=(-G "${cmake_generator}")
fi

if [ "$n_jobs" -ne -1 ]; then
    args+=(build --parallel="$n_jobs")
fi

if [[ "$build_type" == 'Debug' ]]; then
    args+=(build --debug)
fi

if [ "$has_build_dir" -eq 1 ]; then
    args+=(build_ext --build-dir "$build_dir")
fi

# --------------------------------------

if [ "$enable_ccache" -eq 1 ]; then
    print_warning "--ccache is unsupported (thus ignored) with $PROGRAM!"
fi

if [[ "$enable_gpu" -eq 1 && -n "$cuda_arch" ]]; then
    print_warning "--cuda-arch is unsupported (thus ignored) with $PROGRAM!"
fi

debug_print "Will be passing these arguments to setup.py:"
debug_print "    ${args[*]}"

# Convert the CMake arguments for passing them using -C to python3 -m build
fixed_args=()
for arg in "${args[@]}"; do
    fixed_args+=("-C--global-option=$arg")
done

args=("-w")
if [ $no_build_isolation -eq 1 ]; then
    args+=("--no-isolation")
fi

# ------------------------------------------------------------------------------
# Build the wheels

if [ "$has_build_dir" -eq 1 ]; then
    if [ "$do_clean_build_dir" -eq 1 ]; then
        echo "Deleting build folder: $build_dir"
        call_cmd rm -rf "$build_dir"
    elif [ "$do_clean_cache" -eq 1 ]; then
        echo "Removing CMake cache at: $build_dir/CMakeCache.txt"
        call_cmd rm -f "$build_dir/CMakeCache.txt"
        echo "Removing CMake files at: $build_dir/CMakeFiles"
        call_cmd  rm -rf "$build_dir/CMakeFiles"
    fi
fi

if [ "$delocate_wheel" -eq 1 ]; then
    env_vars=(MQ_DELOCATE_WHEEL=1)

    if [ -n "$platform_name" ]; then
        env_vars+=(MQ_DELOCATE_WHEEL_PLAT="$platform_name")
    fi
    call_cmd env "${env_vars[@]}" "${PYTHON}" -m build "${args[@]}" "${fixed_args[@]}" "$@"
else
    call_cmd "${PYTHON}" -m build "${args[@]}" "${fixed_args[@]}" "$@"
fi

# ------------------------------------------------------------------------------
# Move the wheels to the output directory

if [[ -d "${output_path}" ]];then
    call_cmd rm -rf "${output_path}"
fi

call_cmd mkdir -pv "${output_path}"

call_cmd mv -v "$ROOTDIR/dist/"* "${output_path}"

echo "------Successfully created mindquantum package------"
