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

if ($_sourced_default_values -eq $null) { $_sourced_default_values=1 } else { return }

$BASEPATH = Split-Path $MyInvocation.MyCommand.Path -Parent

# ==============================================================================
# Default values for input arguments

if( $build_type -eq $null) { $build_type = 'Release' }
if( $cmake_debug_mode -eq $null) { $cmake_debug_mode = $false }
if( $cmake_generator -eq $null) { $cmake_generator='' }
if( $cmake_make_silent -eq $null) { $cmake_make_silent = $false }
if( $cuda_arch -eq $null) { $cuda_arch='' }
if( $do_clean_3rdparty -eq $null) { $do_clean_3rdparty = $false }
if ($do_clean_build_dir -eq $null) { $do_clean_build_dir = $false }
if ($do_clean_cache -eq $null) { $do_clean_cache = $false }
if( $do_clean_venv -eq $null) { $do_clean_venv = $false }
if( $do_update_venv -eq $null) { $do_update_venv = $false }
if ($do_verbose -eq $null) { $do_verbose = $false }
if( $dry_run -eq $null) { $dry_run = $false }
if( $enable_ccache -eq $null) { $enable_ccache = $false }
if( $enable_cxx -eq $null) { $enable_cxx = $false }
if( $enable_gpu -eq $null) { $enable_gpu = $false }
if( $enable_projectq -eq $null) { $enable_projectq = $true }
if( $enable_tests -eq $null) { $enable_tests = $false }
if( $force_local_pkgs -eq $null) { $force_local_pkgs = $false }
if( $local_pkgs -eq $null) { $local_pkgs = @() }
if ($n_jobs -eq $null) { $n_jobs = -1 }

$IsLinuxEnv = [bool](Get-Variable -Name "IsLinux" -ErrorAction Ignore)
$IsMacOSEnv = [bool](Get-Variable -Name "IsMacOS" -ErrorAction Ignore)
$IsWinEnv = !$IsLinuxEnv -and !$IsMacOSEnv

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

# ------------------------------------------------------------------------------

if ($n_jobs_default -eq $null) {
    $n_jobs_default = 8
    if(Test-CommandExists nproc) {
        $n_jobs_default = nproc
    }
    elseif (Test-CommandExists sysctl) {
        $n_jobs_default = Invoke-Expression -Command "sysctl -n hw.logicalcpu"
    }
    elseif ($IsWinEnv -eq 1) {
        if (Test-CommandExists Get-CimInstance) {
            $n_jobs_default = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
        }
        elseif (Test-CommandExists wmic) {
            $tmp = (wmic cpu get NumberOfLogicalProcessors /value) -Join ' '
            if ($tmp -match "\s*[a-zA-Z]+=([0-9]+)") {
                $n_jobs_default = $Matches[1]
            }
        }
    }
}

# ==============================================================================

$source_dir = Resolve-Path "$BASEPATH\..\.."
$build_dir = "$source_dir\build"
$python_venv_path="$source_dir\venv"

$third_party_libraries = ((Get-ChildItem -Path "$source_dir\third_party" -Directory -Exclude cmake).Name).ForEach("ToLower")

# ==============================================================================
# Other helper variables

if ($cmake_from_venv -eq $null) { $cmake_from_venv = $false }
