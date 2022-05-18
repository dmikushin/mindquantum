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

Param(
    [Alias("B")][ValidateNotNullOrEmpty()][string]$Build,
    [switch]$CCache,
    [switch]$Clean3rdParty,
    [switch]$CleanAll,
    [switch]$CleanBuildDir,
    [switch]$CleanCache,
    [switch]$CleanVenv,
    [ValidateNotNullOrEmpty()][string]$Config,
    [ValidateNotNullOrEmpty()][string]$CudaArch,
    [switch]$Cxx,
    [switch]$Debug,
    [switch]$DebugCMake,
    [switch]$Delocate,
    [Alias("N")][switch]$DryRun,
    [ValidateNotNullOrEmpty()][string]$G,
    [switch]$Gpu,
    [Alias("H")][switch]$Help,
    [Alias("J")][ValidateRange("Positive")][int]$Jobs,
    [switch]$Ninja,
    [switch]$NoBuildIsolation,
    [switch]$NoDelocate,
    [Alias("O")][ValidateNotNullOrEmpty()][string]$Output,
    [ValidateNotNullOrEmpty()][string]$PlatName,
    [switch]$Quiet,
    [switch]$ShowLibraries,
    [switch]$Test,
    [switch]$UpdateVenv,
    [Alias("V")][switch]$Verbose,
    [ValidateNotNullOrEmpty()][string]$Venv
)

$BASEPATH = Split-Path $MyInvocation.MyCommand.Path -Parent
$ROOTDIR = $BASEPATH
$PROGRAM = Split-Path $MyInvocation.MyCommand.Path -Leaf

# ==============================================================================
# Default values

$delocate_wheel = $true
$no_build_isolation = $false
$output_path = "$ROOTDIR\output"
$platform_name = ''

# Override some of the default values
$enable_cxx = $true

. (Join-Path $ROOTDIR 'scripts\build\default_values.ps1')
. (Join-Path $ROOTDIR 'scripts\build\common_functions.ps1')

# ------------------------------------------------------------------------------

function Help-Header {
    Write-Output 'Build binary Python wheel for MindQunantum'
    Write-Output ''
    Write-Output 'This is mainly relevant for developers that want to deploy MindQuantum '
    Write-Output 'on machines other than their own.'
    Write-Output ''
    Write-Output 'This script will create a Python virtualenv in the MindQuantum root'
    Write-Output 'directory and then build a binary Python wheel of MindQuantum.'
}

function Extra-Help {
    Write-Output 'Extra options:'
    Write-Output '  -Delocate            Delocate the binary wheels after build is finished'
    Write-Output '                       (enabled by default; pass -NoDelocate to disable)'
    Write-Output '  -NoIsolation         Pass --no-isolation to python3 -m build'
    Write-Output '  -O,-Output [dir]     Output directory for built wheels'
    Write-Output '  -P,-PlatName [dir]   Platform name to use for wheel delocation'
    Write-Output '                       (only effective if -Delocate is used)'
    Write-Output ''
    Write-Output 'Example calls:'
    Write-Output "$PROGRAM"
    Write-Output "$PROGRAM -Gpu"
    Write-Output "$PROGRAM -Cxx -WithBoost -Without-gmp -Venv D:\venv"
}

# ------------------------------------------------------------------------------

. (Join-Path $ROOTDIR 'scripts\build\parse_common_args.ps1') @args

# ------------------------------------------------------------------------------

if ($Delocate.IsPresent) {
    Set-Value 'delocate_wheel'
}

if ($NoDelocate.IsPresent) {
    Set-Value 'delocate_wheel' $false
}

if ($NoBuildIsolation.IsPresent) {
    Set-Value 'no_build_isolation'
}

if ([bool]$Output) {
    Set-Value 'output_path' "$Output"
}

if ([bool]$PlatName) {
    Set-Value 'platform_name' "$PlatName"
}

# ==============================================================================
# Locate python or python3

. (Join-Path $ROOTDIR 'scripts\build\locate_python3.ps1')

# ==============================================================================

$ErrorActionPreference = 'Stop'

cd "$ROOTDIR"

# ------------------------------------------------------------------------------

# NB: `created_venv` variable can be used to detect if a virtualenv was created or not
. (Join-Path $ROOTDIR 'scripts\build\python_virtualenv_activate.ps1')

# ------------------------------------------------------------------------------
# Update Python virtualenv (if requested/necessary)

. (Join-Path $ROOTDIR 'scripts\build\python_virtualenv_update.ps1')

# ------------------------------------------------------------------------------
# Setup arguments for build

$build_args = @()

$cmake_option_names = @{
    cmake_debug_mode = 'ENABLE_CMAKE_DEBUG'
    enable_cxx = 'ENABLE_CXX_EXPERIMENTAL'
    enable_gpu = 'ENABLE_CUDA'
    enable_projectq = 'ENABLE_PROJECTQ'
    enable_tests = 'BUILD_TESTING'
    do_clean_3rdparty = 'CLEAN_3RDPARTY_INSTALL_DIR'
}

foreach ($el in $cmake_option_names.GetEnumerator()) {
    $value = Invoke-Expression -Command ("`${0}" -f $el.Name)

    if ($value) {
        $build_args += '--set', "$($el.Value)"
    }
    else {
        $build_args += '--unset', "$($el.Value)"
    }
}

if ($cmake_make_silent) {
    $build_args += '--unset', 'USE_VERBOSE_MAKEFILE'
}
else {
    $build_args += '--set', 'USE_VERBOSE_MAKEFILE'
}

if ([bool]$cmake_generator) {
    $build_args += '-G', "$cmake_generator"
}

if ($n_jobs -ne -1) {
    $build_args += 'build', "--parallel=$n_jobs"
}

if ($build_type -eq 'Debug') {
    $build_args += 'build', "--debug"
}

if ($has_build_dir) {
    $build_args += 'build_ext', '--build-dir', "$build_dir"
}

# --------------------------------------

if ($enable_ccache)  {
    Write-Error -Category NotImplemented -Message "-Ccache is unsupported (thus ignored) with $PROGRAM!"
}

if ($enable_gpu -And [bool]$cuda_arch) {
    Write-Error -Category NotImplemented -Message "-CudaArch is unsupported (thus ignored) with $PROGRAM!"
}

Write-Debug 'Will be passing these arguments to setup.py:'
Write-Debug "    $build_args"

# Convert the CMake arguments for passing them using -C to python3 -m build
$fixed_args = @()
foreach($arg in $build_args) {
    $fixed_args += "-C--global-option=$arg"
}

$build_args = @('-w')
if ($no_build_isolation) {
    $build_args += "--no-isolation"
}

# ------------------------------------------------------------------------------
# Build the wheels

if ($has_build_dir) {
    if ($do_clean_build_dir) {
        Write-Output "Deleting build folder: $build_dir"
        Call-Cmd Remove-Item -Force -Recurse "$build_dir" -ErrorAction SilentlyContinue
    }
    elseif ($do_clean_cache) {
        Write-Output "Removing CMake cache at: $build_dir/CMakeCache.txt"
        Call-Cmd Remove-Item -Force "$build_dir/CMakeCache.txt" -ErrorAction SilentlyContinue
        Write-Output "Removing CMake files at: $build_dir/CMakeFiles"
        Call-Cmd Remove-Item -Force -Recurse "$build_dir/CMakeFiles" -ErrorAction SilentlyContinue
    }
}

if ($delocate_wheel) {
    $Env:MQ_DELOCATE_WHEEL = 1

    if ([bool]$platform_name) {
        $Env:MQ_DELOCATE_WHEEL_PLAT = "$platform_name"
    }
}
else {
    $Env:MQ_DELOCATE_WHEEL = 0
}

Call-Cmd "$PYTHON" -m build @build_args @fixed_args @unparsed_args
if ($LastExitCode -ne 0) {
    exit 1
}

# ------------------------------------------------------------------------------

if (Test-Path -Path "$output_path") {
    Call-Cmd Remove-Item -Force -Recurse "$output_path" -ErrorAction SilentlyContinue
}

Call-Cmd New-Item -Path "$output_path" -ItemType "directory"

Call-Cmd Move-Item -Path "$ROOTDIR\*" -Destination "$output_path"

Call-Cmd Write-Output "------Successfully created mindquantum package------"

# ==============================================================================

<#
.SYNOPSIS

Performs monthly data updates.

.DESCRIPTION

Build MindQunantum locally (in-source build)

This is mainly relevant for developers that do not want to always have to reinstall the Python package

This script will create a Python virtualenv in the MindQuantum root directory and then build all the C++ Python
modules and place the generated libraries in their right locations within the MindQuantum folder hierarchy so Python
knows how to find them.

A pth-file will be created in the virtualenv site-packages directory so that the MindQuantum root folder will be added
to the Python PATH without the need to modify PYTHONPATH.

.PARAMETER Build
Specify build directory. Defaults to: Path\To\Script\build

.PARAMETER CCache
If ccache or sccache are found within the PATH, use them with CMake

.PARAMETER Clean3rdParty
Clean 3rd party installation directory

.PARAMETER CleanAll
Clean everything before building.
Equivalent to -CleanVenv -CleanBuildDir

.PARAMETER CleanBuildDir
Delete build directory before building

.PARAMETER CleanCache
Re-run CMake with a clean CMake cache

.PARAMETER CleanVenv
Delete Python virtualenv before building

.PARAMTER Config
Path to INI configuration file with default values for the parameters

.PARAMETER Cxx
(experimental) Enable MindQuantum C++ support

.PARAMETER Debug
Build in debug mode

.PARAMETER DebugCMake
Enable debugging mode for CMake configuration step

.PARAMETER DryRun
Dry run; only print commands but do not execute them

.PARAMETER Delocate
Delocate the binary wheels after build is finished (enabled by default; pass -NoDelocate to disable)

.PARAMETER Gpu
Enable GPU support

.PARAMETER Help
Show help message.

.PARAMETER Jobs
Number of parallel jobs for building

.PARAMETER LocalPkgs
Compile third-party dependencies locally

.PARAMETER NoDelocate
Do not delocate the binary wheels after build is finished (pass -Delocate to enable)

.PARAMETER NoBuildIsolation
Pass --no-isolation to python3 -m build

.PARAMETER Output
Output directory for built wheels

.PARAMETER PlatName
Platform name to use for wheel delocation (only effective if -Delocate is used)

.PARAMETER Quiet
Disable verbose build rules

.PARAMETER ShowLibraries
Show all known third-party libraries.

.PARAMETER Test
Build C++ tests and install dependencies for Python testing as well

.PARAMETER Verbose
Enable verbose output from the Bash scripts

.PARAMETER Venv
Path to Python virtual environment. Defaults to: Path\To\Script\venv

.PARAMETER UpdateVenv
Update the python virtual environment

.PARAMETER CudaArch
Comma-separated list of architectures to generate device code for.
Only useful if -Gpu is passed. See CMAKE_CUDA_ARCHITECTURES for more information.

.PARAMETER G
CMake argument: Specify a build system generator.

.INPUTS

None.

.OUTPUTS

None.

.EXAMPLE

PS> .\build.ps1

.EXAMPLE

PS> .\build.ps1 -gpu

.EXAMPLE

PS> .\build.ps1 -Cxx -WithBoost -WithoutEigen3

.EXAMPLE

PS> .\build.ps1 -Gpu -DCMAKE_CUDA_COMPILER=D:\cuda\bin\nvcc
#>
