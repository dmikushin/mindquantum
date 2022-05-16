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

BASEPATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}" )" &> /dev/null && pwd )

[ "${_sourced_common_functions}" != "" ] && return || _sourced_common_functions=.

# ==============================================================================

# shellcheck source=SCRIPTDIR/default_values.sh
. "$BASEPATH/default_values.sh"

# ==============================================================================

function debug_print() {
    if [ ${verbose:-0} -eq 1 ]; then
        echo "DEBUG $*"
    fi
}

function print_warning() {
    echo '**********' >&2
    echo "WARN $*" >&2
    echo '**********' >&2
}

# ------------------------------------------------------------------------------

function die() {
    # complain to STDERR and exit with error
    echo "$*" >&2; exit 2;
}

function no_arg() {
    if [ -n "$OPTARG" ]; then
        die "No arg allowed for --$OPT option";
    fi
}

function needs_arg() {
    if [ -z "$OPTARG" ]; then
        die "No arg for --$OPT option"
    fi
}

# ==============================================================================

call_cmd() {
   if [ $dry_run -ne 1 ]; then
       "$@"
       return $?
   else
       echo "$@"
       return 0
   fi
 }

# ------------------------------------------------------------------------------

call_cmake() {
    if [ $dry_run -ne 1 ]; then
        echo "**********"
        echo "Calling CMake with: cmake " "$@"
        echo "**********"
    fi
    call_cmd "$CMAKE" "$@"
    return $?
}

# ==============================================================================

function join_by {
    local d=${1-} f=${2-}
    if shift 2; then
        printf %s "$f" "${@/#/$d}"
    fi
}

# ==============================================================================

function version_less_equal() {
    local a_major a_minor b_major b_minor
    a_major=$(echo "$1" | cut -d. -f1)
    a_minor=$(echo "$1" | cut -d. -f2)
    b_major=$(echo "$2" | cut -d. -f1)
    b_minor=$(echo "$2" | cut -d. -f2)

    if [ "$a_major" -le "$b_major" ]; then
        if [ "$a_minor" -le "$b_minor" ]; then
            return 0
        fi
    fi
    return 1
}

# ==============================================================================
