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

if ($_sourced_common_functions -eq $null) { $_sourced_common_functions=1 } else { return }

$BASEPATH = Split-Path $MyInvocation.MyCommand.Path -Parent

# ==============================================================================

. "$BASEPATH\default_values.ps1"

# ==============================================================================

function Assign-Value([switch]$Script, [switch]$OnlyOutput) {
    $name = $args[0]
    $value = $args[1]

    if ($Script) {
        $eval_str = "`$script:$name = "
    }
    else {
        $eval_str = "`$$name = "
    }

    if ($value -is [string]) {
        $eval_str += "`"$value`""
    }
    elseif ($value -is [array]) {
        $eval_str += "@({0})" -f (($value | ForEach-Object {"`"$_`""}) -Join ",")
    }
    elseif ($value -is [bool]) {
        if ($value) {
            $eval_str += "`$true"
        }
        else {
            $eval_str += "`$false"
        }
    }
    else {
        $eval_str += "$value"
    }

    if ($OnlyOutput) {
        return $eval_str
    }
    else {
        Write-Debug "$eval_str"
        Invoke-Expression -Command "$eval_str"
    }
}

function Set-Value {
    $name = $args[0]
    if ($args.Length -gt 1) {
        $value = $args[1]
    }
    else {
        $value = $true
    }
    Assign-Value -Script $name $value
    Assign-Value -Script "_${name}_was_set" $true
}

# ------------------------------------------------------------------------------

function die {
    Write-Error "$args"
    exit 2
}

# ------------------------------------------------------------------------------

function Call-Cmd {
    if ($dry_run -ne 1) {
        Invoke-Expression -Command "$args"
    }
    else {
        Write-Output "$args"
    }
}

# ------------------------------------------------------------------------------

function Call-CMake {
    if ($dry_run -ne 1) {
        Write-Output "**********"
        Write-Output "Calling CMake with: cmake $args"
        Write-Output "**********"
    }
    Call-Cmd $CMAKE @args
}

# ==============================================================================

function Test-CommandExists{
    Param ($command)

    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'

    try {
        if(Get-Command $command) {
            return $TRUE
        }
        else {
            return $FALSE
        }
    }
    Catch {
        return $FALSE
    }
    Finally {
        $ErrorActionPreference=$oldPreference
    }
}

# ==============================================================================
