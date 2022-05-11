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
