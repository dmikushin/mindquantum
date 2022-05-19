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

# shellcheck source=SCRIPTDIR/../parse_ini.sh
. "$BASEPATH/../parse_ini.sh"

# ==============================================================================

function debug_print() {
    if [ "${verbose:-0}" -eq 1 ]; then
        echo "DEBUG $*" >&2
    fi
}

function print_warning() {
    echo '**********' >&2
    echo "WARN $*" >&2
    echo '**********' >&2
}

# ------------------------------------------------------------------------------

function assign_value() {
    name=$1
    shift
    value=$1
    shift
    output_only=${1:-0}

    eval_str="$name"

    if [[ ${value,,} =~ ^(yes|true)$ ]]; then
        eval_str="$eval_str=1"
    elif [[ ${value,,} =~ ^(no|false)$ ]]; then
        eval_str="$eval_str=0"
    elif [[ ${value,,} =~ ^[0-9]+$ ]]; then
        eval_str="$eval_str=$value"
    elif [[ ${value,,} =~ \"\ \" ]]; then
        eval_str="$eval_str=( $value )"
    else
        eval_str="$eval_str=\"$value\""
    fi

    if [ "$output_only " -eq 1 ]; then
        echo "$eval_str"
    else
        debug_print "$eval_str"
        eval "$eval_str"
    fi
}

function set_var() {
    local name value

    name=$1
    shift
    value=${1:-1}

    assign_value "$name" "$value"
    assign_value "_${name}_was_set" 1
}

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

# ------------------------------------------------------------------------------

function is_abspath {
    case "x$1" in
    (x*/..|x*/../*|x../*|x*/.|x*/./*|x./*)
        rc=1
        ;;
    (x/*)
        rc=0
        ;;
    (*)
        rc=1
        ;;
    esac
    return $rc
}

# __set_variable_from_ini <section> <check_set> <check_null> <dry_run>
function __set_variable_from_ini {
    local section check_set check_null do_dry_run var value eval_str null_test
    section=$1 && shift
    check_set=$1 && shift
    check_null=$1 && shift
    do_dry_run=$1 && shift

    for var in $(eval "echo \${!configuration_${section/./_}[*]}"); do
        value=$(eval "echo \${configuration_${section/./_}[$var]}")
        eval_str=''
        null_test='%s'
        if [[ $section =~ ^.*(path|paths)$ ]]; then
            if [ -n "$value" ]; then
                if ! is_abspath "$value"; then
                    value="\"$ROOTDIR/$value\""
                fi
            fi
            eval_str="declare -g $var=$value"
        elif [[ ${value,,} =~ ^(true|yes)$ ]]; then
            eval_str="declare -gi $var=1"
        elif [[ ${value,,} =~ ^(false|no)$ ]]; then
            eval_str="declare -gi $var=0"
        elif [[ ${value} =~ ^.*\|.*$ ]]; then
            null_test='%s@a'
            eval_str="declare -ga $var && mapfile -t $var <<< \"$(echo -e "${value/|/\\n}")\""
        elif [[ $value =~ ^-?[0-9]+$ ]]; then
            eval_str="declare -gi $var=$value"
        else
            eval_str="declare -g $var='$value'"
        fi

        debug_print "$(printf "%-50s  # [%s]" "$eval_str" "$section")"

        if [ "$check_set" -eq 1 ]; then
            eval_str=$(printf "[[ \"\${_%s_was_set:-0}\" -eq 0 ]] && %s" "$var" "$eval_str")
        elif [ "$check_null" -eq 1 ]; then
            eval_str=$(printf "[[ -z \"\${${null_test}}\" ]] && %s" "$var" "$eval_str")
        fi

        if [ "$do_dry_run" -eq 0 ]; then
            # debug_print "  invoked expression: $eval_str"
            eval "$eval_str"
        fi
    done
}

# --------------------------------------

# set_variable_from_ini <filename> [-s <section>] [-c] [-C] [-n]
# -c: check_set
# -C: check_null
# -n: dry_run
function set_variable_from_ini {
    local target_section do_dry_run check_set check_null OPT OPTARG OPTIND

    declare -i do_dry_run=0
    declare -i check_set=0
    declare -i check_null=0
    target_section=''
    while getopts "s:cCn" OPT; do
        case "$OPT" in
            s)  target_section="$OPTARG"
                ;;
            c)  check_set=1
                ;;
            C)  check_null=1
                ;;
            n)  do_dry_run=1
                ;;
            /?) exit 2
                ;;
        esac
    done
    shift $((OPTIND-1)) # remove parsed options and args from $@ list

    parse_ini_file "$1"

    if [ -n "$target_section" ]; then
        __set_variable_from_ini "$target_section" $check_set $check_null $do_dry_run
    else
        # shellcheck disable=SC2154
        for section in "${configuration_sections[@]}"; do
            __set_variable_from_ini "$section" $check_set $check_null $do_dry_run
        done
    fi
}

# ==============================================================================

call_cmd() {
   if [ "${dry_run:-0}" -ne 1 ]; then
       "$@"
       return $?
   else
       echo "$@"
       return 0
   fi
 }

# ------------------------------------------------------------------------------

call_cmake() {
    if [ "${dry_run:-0}" -ne 1 ]; then
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
