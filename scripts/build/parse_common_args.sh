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

[ "${_sourced_parse_common_args}" != "" ] && return || _sourced_parse_common_args=.

BASEPATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ROOTDIR=$(realpath "$BASEPATH/../..")
PROGRAM=$(basename "$0")

# ==============================================================================

# shellcheck source=SCRIPTDIR/default_values.sh
. "$BASEPATH/default_values.sh"

# shellcheck source=SCRIPTDIR/common_functions.sh
. "$BASEPATH/common_functions.sh"

# ==============================================================================

print_show_libraries() {
    echo 'Known third-party libraries:'
    for lib in $third_party_libraries; do
        echo " - $lib"
    done
}

parse_with_libraries() {
    if ! echo "$third_party_libraries" | tr ' ' '\n' | grep -F -x -q "$1" ; then
        print_show_libraries
        echo ''
        die "Unknown library for --with-$1 or --without-$1"
    fi

    if [ "$1" == "projectq" ]; then
        enable_projectq=$2
    elif [ "$1" == "quest" ]; then
        enable_quest=$2
    elif [ "$2" -eq 1 ]; then
        local_pkgs+=("$1")
    else
        for index in "${!local_pkgs[@]}" ; do [[ ${local_pkgs[$index]} == "$1" ]] && unset -v 'local_pkgs[$index]' ; done
        local_pkgs=("${local_pkgs[@]}")
    fi
}

# ------------------------------------------------------------------------------

help_message() {
    help_header

    echo -e '\nUsage:'
    echo "  $PROGRAM [options] [-- cmake_options]"
    echo -e '\nOptions:'
    echo '  -h,--help            Show this help message and exit'
    echo '  -n                   Dry run; only print commands but do not execute them'
    echo ''
    echo '  --ccache             If ccache or sccache are found within the PATH, use them with CMake'
    echo '  --clean-3rdparty     Clean 3rd party installation directory'
    echo '  --clean-venv         Delete Python virtualenv before building'
    echo '  --cxx                (experimental) Enable MindQuantum C++ support'
    echo '  --debug              Build in debug mode'
    echo '  --debug-cmake        Enable debugging mode for CMake configuration step'
    echo '  --gpu                Enable GPU support'
    echo '  -j,--jobs [N]        Number of parallel jobs for building'
    echo "                       Defaults to: $n_jobs_default"
    echo '  --local-pkgs         Compile third-party dependencies locally'
    echo '  --ninja              Build using Ninja instead of make'
    echo '  --quiet              Disable verbose build rules'
    echo '  --show-libraries     Show all known third-party libraries'
    echo '  --test               Build C++ tests and install dependencies for Python testing as well'
    echo '  -v, --verbose        Enable verbose output from the Bash scripts'
    echo '  --venv=[dir]         Path to Python virtual environment'
    echo "                       Defaults to: $python_venv_path"
    echo '  --with-<library>     Build the third-party <library> from source'
    echo '                       (ignored if --local-pkgs is passed, except for projectq and quest)'
    echo '  --without-<library>  Do not build the third-party library from source'
    echo '                       (ignored if --local-pkgs is passed, except for projectq and quest)'
    echo ''
    echo 'CUDA related options:'
    echo '  --cuda-arch=[arch]   Comma-separated list of architectures to generate device code for.'
    echo '                       Only useful if --gpu is passed. See CMAKE_CUDA_ARCHITECTURES for more information.'
    echo ''
    echo 'Python related options:'
    echo '  --update-venv        Update the python virtual environment'
    echo ''

    if command -v extra_help >/dev/null 2>&1; then
        extra_help
    fi
}

# ==============================================================================

has_extra_args=0
getopts_args='hcnvj:-:'

if [ -n "$getopts_args_extra" ]; then
    has_extra_args=1
    getopts_args="${getopts_args_extra}${getopts_args}"

    if ! command -v parse_extra_args >/dev/null 2>&1; then
        die "Must provide a function named 'parse_extra_args' since 'getopts_args_extra' is defined."
    fi
fi

while getopts "${getopts_args}" OPT; do
    # shellcheck disable=SC2214,SC2295
    if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
        OPT="${OPTARG%%=*}"       # extract long option name
        OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
        OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
    fi

    if [[ $OPT =~ with-([a-zA-Z0-9_]+) ]]; then
        OPT=with
        enable_lib=1
        library=${BASH_REMATCH[1]}
    elif [[ $OPT =~ without-([a-zA-Z0-9_]+) ]]; then
        OPT=with
        enable_lib=0
        library=${BASH_REMATCH[1]}
    fi

    case "$OPT" in
        h | help )       no_arg;
                         help_message >&2
                         exit 1 ;;
        ccache )         no_arg;
                         enable_ccache=1
                         ;;
        clean-3rdparty ) no_arg;
                         do_clean_3rdparty=1
                         ;;
        clean-venv )     no_arg;
                         do_clean_venv=1
                         ;;
        cuda-arch )      needs_arg;
                         cuda_arch=$(echo "$OPTARG" | tr ',' ';')
                         ;;
        cxx )            no_arg;
                         enable_cxx=1
                         ;;
        debug )          no_arg;
                         build_type='Debug'
                         ;;
        debug-cmake )    no_arg;
                         cmake_debug_mode=1
                         ;;
        gpu )            no_arg;
                         enable_gpu=1
                         ;;
        j | jobs )       needs_arg;
                         n_jobs="$OPTARG"
                         ;;
        local-pkgs )     no_arg;
                         force_local_pkgs=1
                         ;;
        n )              no_arg;
                         dry_run=1
                         ;;
        ninja )          no_arg;
                         cmake_generator='Ninja'
                         ;;
        quiet )          no_arg;
                         cmake_make_silent=1
                         ;;
        show-libraries ) no_arg;
                         print_show_libraries
                         exit 1
                         ;;
        test )           no_arg;
                         enable_tests=1
                         ;;
        update-venv )    no_arg;
                         do_update_venv=1
                         ;;
        v | verbose )    no_arg;
                         verbose=1
                         ;;
        venv )           needs_arg;
                         python_venv_path="$OPTARG"
                         ;;
        with )           no_arg;
                         parse_with_libraries "$library" $enable_lib
                         ;;
        \? )             # bad short option (error reported via getopts)
                         exit 2
                         ;;
         * )             success=0
                         if [ $has_extra_args -eq 1 ]; then
                             parse_extra_args "$OPT"
                             success="$?"
                         fi
                         if [ $success -ne 0 ]; then
                             die "Illegal option: $OPT or --$OPT"
                         fi
                         ;;
   esac
done
shift $((OPTIND-1)) # remove parsed options and args from $@ list

# ==============================================================================

if [[ $n_jobs -eq -1 && ! $cmake_generator == "Ninja"  ]]; then
    n_jobs=$n_jobs_default
fi

# ==============================================================================
