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

if ($_sourced_parse_common_args -eq $null) { $_sourced_parse_common_args=1 } else { return }

$BASEPATH = Split-Path $MyInvocation.MyCommand.Path -Parent

# ------------------------------------------------------------------------------

$has_build_dir = $false

. "$BASEPATH\default_values.ps1"

. "$BASEPATH\common_functions.ps1"

# ==============================================================================

function Print-Show-Libraries {
    Write-Output 'Known third-party libraries:'
    foreach($lib in $third_party_libraries) {
        Write-Output (" - {0}" -f $lib)
    }
}

# ------------------------------------------------------------------------------

function Help-Message() {
    Help-Header

    Write-Output 'Usage:'
    Write-Output ('  {0} [options]' -f $BASENAME)
    Write-Output ''
    Write-Output 'Options:'
    Write-Output '  -H,-Help            Show this help message and exit'
    Write-Output '  -N,$DryRun          Dry run; only print commands but do not execute them'
    Write-Output ''
    Write-Output '  -B,-Build [dir]     Specify build directory'
    Write-Output ("                      Defaults to: {0}" -f $build_dir)
    Write-Output '  -CCache             If ccache or sccache are found within the PATH, use them with CMake'
    Write-Output '  -Clean3rdParty      Clean 3rd party installation directory'
    Write-Output '  -CleanAll           Clean everything before building.'
    Write-Output '                      Equivalent to -CleanVenv -CleanBuildDir'
    Write-Output '  -CleanBuildDir      Delete build directory before building'
    Write-Output '  -CleanCache         Re-run CMake with a clean CMake cache'
    Write-Output '  -CleanVenv          Delete Python virtualenv before building'
    Write-Output '  -Cxx                (experimental) Enable MindQuantum C++ support'
    Write-Output '  -Debug              Build in debug mode'
    Write-Output '  -DebugCMake         Enable debugging mode for CMake configuration step'
    Write-Output '  -Gpu                Enable GPU support'
    Write-Output '  -J,-Jobs [N]        Number of parallel jobs for building'
    Write-Output ("                      Defaults to: {0}" -f $n_jobs_default)
    Write-Output '  -LocalPkgs          Compile third-party dependencies locally'
    Write-Output '  -Ninja              Build using Ninja instead of make'
    Write-Output '  -Quiet              Disable verbose build rules'
    Write-Output '  -ShowLibraries      Show all known third-party libraries'
    Write-Output '  -Test               Build C++ tests and install dependencies for Python testing as well'
    Write-Output '  -V,-Verbose         Enable verbose output from the Bash scripts'
    Write-Output '  -Venv <path>        Path to Python virtual environment'
    Write-Output ("                      Defaults to: {0}" -f $python_venv_path)
    Write-Output '  -With<library>      Build the third-party <library> from source (<library> is case-insensitive)'
    Write-Output '                      (ignored if --local-pkgs is passed, except for projectq)'
    Write-Output '  -Without<library>   Do not build the third-party library from source (<library> is case-insensitive)'
    Write-Output '                      (ignored if --local-pkgs is passed, except for projectq)'
    Write-Output ''
    Write-Output 'CUDA related options:'
    Write-Output '  -CudaArch <arch>    Comma-separated list of architectures to generate device code for.'
    Write-Output '                      Only useful if -Gpu is passed. See CMAKE_CUDA_ARCHITECTURES for more information.'
    Write-Output ''
    Write-Output 'Python related options:'
    Write-Output '  -UpdateVenv         Update the python virtual environment'
    Write-Output ''

    if (Test-CommandExists Extra-Help) {
        Extra-Help
    }
}

# ==============================================================================

if ($DryRun.IsPresent) {
    $dry_run = $true
}

if ($CCache.IsPresent) {
    $enable_ccache = $true
}

if ($Clean3rdParty.IsPresent) {
    $do_clean_3rdparty = $true
}
if ($CleanAll.IsPresent) {
    $do_clean_venv = $true
    $do_clean_build_dir = $true
}
if ($CleanBuildDir.IsPresent) {
    $do_clean_build_dir = $true
}
if ($CleanCache.IsPresent) {
    $do_clean_cache = $true
}
if ($CleanVenv.IsPresent) {
    $do_clean_venv = $true
}

if ($Cxx.IsPresent) {
    $enable_cxx = $true
}

if ($Debug.IsPresent) {
    $build_type = 'Debug'
}

if ($DebugCMake.IsPresent) {
    $cmake_debug_mode = $true
}

if ($Gpu.IsPresent) {
    $enable_gpu = $true
}

if ($LocalPkgs.IsPresent) {
    $force_local_pkgs = $true
}

if ($Quiet.IsPresent) {
    $cmake_make_silent = $true
}

if ($Test.IsPresent) {
    $enable_tests = $true
}

if ($UpdateVenv.IsPresent) {
    $do_update_venv = $true
}

if ($Verbose.IsPresent -Or $Debug.IsPresent) {
    $DebugPreference = 'Continue'
}

if ([bool]$Build) {
    $has_build_dir = $true
    $build_dir = "$Build"
}

if ([bool]$CudaArch) {
    $cuda_arch = $CudaArch.Replace(' ', ';').Replace(',', ';')
}

if ($Jobs -ne 0) {
    $n_jobs = $Jobs
}

if ([bool]$Venv) {
    $python_venv_path = "$Venv"
}

$unparsed_args = @()

foreach($arg in $args) {
    if ("$arg" -match "[Ww]ith[Oo]ut-?([a-zA-Z0-9_]+)") {
        $enable_lib = $false
        $library = ($Matches[1]).Tolower()
    }
    elseif("$arg" -match "[Ww]ith-?([a-zA-Z0-9_]+)") {
        $enable_lib = $true
        $library = ($Matches[1]).Tolower()
    }
    else {
        $unparsed_args += $arg
    }

    if (-Not [bool](($third_party_libraries -eq $library) -join " ")) {
        Write-Output ('Unkown library for {0}' -f $arg)
        exit 1
    }

    if ($library -eq "projectq") {
        $enable_projectq = $enable_lib
    }
    elseif ($enable_lib) {
        $local_pkgs += $library
    }
    else {
        $local_pkgs = $local_pkgs -ne $library
    }
}

$local_pkgs = ($local_pkgs -join ',')

# ==============================================================================

if ($H.IsPresent -or $Help.IsPresent) {
    Help-Message
    exit 1
}

if($ShowLibraries.IsPresent) {
    Print-Show-Libraries
    exit 0
}

# ==============================================================================

if ($Ninja.IsPresent) {
    $cmake_generator = 'Ninja'
}
elseif ($n_jobs -eq -1){
    $n_jobs = $n_jobs_default
}

# ==============================================================================
