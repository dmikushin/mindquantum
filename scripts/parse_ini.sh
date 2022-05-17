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

[ "${_sourced_parse_ini}" != "" ] && return || _sourced_parse_ini=.


if [ -z "$AWK" ]; then
    if command -v gawk >/dev/null 2>&1; then
        AWK='gawk'
    elif command -v awk >/dev/null 2>&1; then
        AWK='awk'
    else
        echo 'ERROR: Unable to locate gawk or awk!' 1>&2
    fi
fi

# ==============================================================================

function read_ini_sections() {
    if [ -z "$AWK" ]; then
        return
    fi
    local filename="$1"
    # shellcheck disable=SC2016
    $AWK '{
         if ($1 ~ /^\[/) {
           section=tolower(gensub(/\[(.+)\]/,"\\1",1,$1));
           configuration[section]=1
         }
       }
       END {
         for (key in configuration) {
           gsub( "\\.", "_", key)
           print key
         }
       }' "${filename}"
}

# ------------------------------------------------------------------------------

function parse_ini_file() {
    if [ -z "$AWK" ]; then
        return
    fi

    local filename sections

    filename="$1"
    sections="$(read_ini_sections "$filename")"
    for section in $sections; do
        array_name="configuration_${section}"
        declare -g -A "${array_name}"
    done

    # shellcheck disable=SC2016
    $AWK -F= '{
              section="main"
              if ($1 ~ /^\[/)
                section=tolower(gensub(/\[(.+)\]/,"\\1",1,$1))
              else if ($1 !~ /^$/ && $1 !~ /^;|#/) {
                gsub(/^[ \t]+|[ \t]+$/, "", $1);
                if ($1 ~ /[.*\[\]]/) {
                    is_array_val=1
                }
                else {
                    is_array_val=0
                }
                gsub(/[\[\]]/, "", $1);
                gsub(/^[ \t]+|[ \t]+$/, "", $2);

                is_array[section][$1]=is_array_val;

                if (section == "") {
                  section="main"
                }
                if (tolower($2) ~ /^yes|true$/) {
                   value=1;
                }
                else if (tolower($2) ~ /^no|false$/) {
                   value=0;
                }
                else if ($2 !~ /^[0-9]+$/) {
                   value="\""$2"\"";
                }
                else {
                   value=$2;
                }
                if (configuration[section][$1] == "")
                  configuration[section][$1]=value
                else
                  configuration[section][$1]=configuration[section][$1]" "value
              }
            }
            END {
              for (section in configuration)
                for (key in configuration[section]) {
                  section_name = section
                  gsub( "-", "_", section_name)
                  gsub( "\\.", "_", section_name)
                  if (configuration[section][key] ~ /.*" ".*/ || is_array[section][key]) {
                    print "[[ ${_"key"_was_set:-0} -eq 0 ]] && declare -a "key"=( "configuration[section][key]" )"
                  }
                  else if (configuration[section][key] ~ /^"/) {
                    print "[[ ${_"key"_was_set:-0} -eq 0 ]] && "key"=\""configuration[section][key]"\""
                  }
                  else {
                    print "[[ ${_"key"_was_set:-0} -eq 0 ]] && declare -i "key"="configuration[section][key]
                  }
                  # print "configuration_" section_name "[\""key"\"]="configuration[section][key]";"
            }
         }' "${filename}"
}
