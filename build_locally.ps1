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
    [ValidateNotNullOrEmpty()][string]$A,
    [Alias("B")][ValidateNotNullOrEmpty()][string]$Build,
    [switch]$CCache,
    [switch]$Clean,
    [switch]$Clean3rdParty,
    [switch]$CleanAll,
    [switch]$CleanBuildDir,
    [switch]$CleanCache,
    [switch]$CleanVenv,
    [Alias("C")][switch]$Configure,
    [switch]$ConfigureOnly,
    [ValidateNotNullOrEmpty()][string]$CudaArch,
    [switch]$Cxx,
    [switch]$Debug,
    [switch]$DebugCMake,
    [Alias("N")][switch]$DryRun,
    [Alias("Docs")][switch]$Doc,
    [ValidateNotNullOrEmpty()][string]$G,
    [switch]$Gpu,
    [switch]$H,
    [switch]$Help,
    [switch]$Install,
    [Alias("J")][ValidateRange("Positive")][int]$Jobs,
    [switch]$Ninja,
    [ValidateNotNullOrEmpty()][string]$Prefix,
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

$configure_only = 0
$do_clean = 0
$do_clean_build_dir = 0
$do_clean_cache = 0
$do_configure = 0
$do_docs = 0
$do_install = 0
$prefix_dir = ""

. "$ROOTDIR\scripts\build\default_values.ps1"

. "$ROOTDIR\scripts\build\common_functions.ps1"

# ------------------------------------------------------------------------------

function Help-Header {
    Write-Output 'Build MindQunantum locally (in-source build)'
    Write-Output ''
    Write-Output 'This is mainly relevant for developers that do not want to always '
    Write-Output 'have to reinstall the Python package'
    Write-Output ''
    Write-Output 'This script will create a Python virtualenv in the MindQuantum root'
    Write-Output 'directory and then build all the C++ Python modules and place the'
    Write-Output 'generated libraries in their right locations within the MindQuantum'
    Write-Output 'folder hierarchy so Python knows how to find them.'
    Write-Output ''
    Write-Output 'A pth-file will be created in the virtualenv site-packages directory'
    Write-Output 'so that the MindQuantum root folder will be added to the Python PATH'
    Write-Output 'without the need to modify PYTHONPATH.'
}

function Extra-Help {
    Write-Output 'Extra options:'
    Write-Output '  -B,-Build [dir]     Specify build directory'
    Write-Output ("                      Defaults to: {0}" -f $build_dir)
    Write-Output '  -CCache             If ccache or sccache are found within the PATH, use them with CMake'
    Write-Output '  -Clean              Run make clean before building'
    Write-Output '  -CleanAll           Clean everything before building.'
    Write-Output '                      Equivalent to -CleanVenv -CleanBuildDir'
    Write-Output '  -CleanBuildDir      Delete build directory before building'
    Write-Output '  -CleanCache         Re-run CMake with a clean CMake cache'
    Write-Output '  -C,-Configure       Force running the CMake configure step'
    Write-Output '  -ConfigureOnly      Stop after the CMake configure and generation steps (ie. before building MindQuantum)'
    Write-Output '  -Doc, -Docs         Setup the Python virtualenv for building the documentation and ask CMake to build the'
    Write-Output '                      documentation'
    Write-Output '  -Install            Build the ´install´ target'
    Write-Output '  -Prefix             Specify installation prefix'
    Write-Output ''
    Write-Output 'Any options not matching one of the above will be passed on to CMake during the configuration step'
    Write-Output ''
    Write-Output 'Example calls:'
    Write-Output ("{0} -B build" -f $PROGRAM)
    Write-Output ("{0} -B build -Gpu" -f $PROGRAM)
    Write-Output ("{0} -B build -Cxx -WithBoost -Without-Eigen3" -f $PROGRAM)
    Write-Output ("{0} -B build -DCMAKE_CUDA_COMPILER=/opt/cuda/bin/nvcc" -f $PROGRAM)
}

# ------------------------------------------------------------------------------

. "$ROOTDIR\scripts\build\parse_common_args.ps1" @args

# ------------------------------------------------------------------------------

if ($Clean.IsPresent) {
    $do_clean = $true
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

if ($C.IsPresent -or $Configure.IsPresent) {
    $do_configure = $true
}
if ($ConfigureOnly.IsPresent) {
    $configure_only = $true
}

if ($Doc.IsPresent) {
    $do_docs = $true
}

if ($Install.IsPresent) {
    $do_install = $true
}

if ([bool]$Build) {
    $build_dir = "$Build"
}

if ([bool]$Prefix) {
    $prefix_dir = "$Prefix"
}

# ==============================================================================
# Locate python or python3

. "$ROOTDIR\scripts\build\locate_python3.ps1"

# ==============================================================================

# Parse -With<library> and -Without<library>
$cmake_extra_args = @()

if([bool]$G) {
    $cmake_extra_args += "-G `"$G`""
}
if([bool]$A) {
    $cmake_extra_args += "-A `"$A`""
}

# ==============================================================================

$ErrorActionPreference = 'Stop'

cd "$ROOTDIR"

# ------------------------------------------------------------------------------
# Create a virtual environment for building the wheel

if ($do_clean_build_dir) {
    Write-Output "Deleting build folder: $build_dir"
    Call-Cmd Remove-Item -Force -Recurse "$build_dir" -ErrorAction SilentlyContinue
}

# NB: `created_venv` variable can be used to detect if a virtualenv was created or not
. "$ROOTDIR\scripts\build\python_virtualenv_activate.ps1"

if ($dry_run -ne 1) {
    # Make sure the root directory is in the virtualenv PATH
    $site_pkg_dir = Invoke-Expression -Command "$PYTHON -c 'import site; print(site.getsitepackages()[0])'"
    $pth_file = "$site_pkg_dir\mindquantum_local.pth"

    if (-Not (Test-Path -Path "$pth_file" -PathType leaf)) {
        Write-Output "Creating pth-file in $pth_file"
        Write-Output "$ROOTDIR" > "$pth_file"
    }
}

# ------------------------------------------------------------------------------
# Locate cmake or cmake3

# NB: `cmake_from_venv` variable is set by this script (and is used by python_virtualenv_update.sh)
. "$ROOTDIR\scripts\build\locate_cmake.ps1"

# ------------------------------------------------------------------------------
# Update Python virtualenv (if requested/necessary)

. "$ROOTDIR\scripts\build\python_virtualenv_update.ps1"

# ------------------------------------------------------------------------------
# Setup arguments for build

$CMAKE_BOOL = @('OFF', 'ON')

$cmake_args = @('-DIN_PLACE_BUILD:BOOL=ON'
                '-DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=ON'
                "-DCMAKE_BUILD_TYPE:STRING={0}" -f $build_type
                "-DENABLE_PROJECTQ:BOOL={0}" -f $CMAKE_BOOL[$enable_projectq]
                "-DENABLE_CMAKE_DEBUG:BOOL={0}" -f $CMAKE_BOOL[$cmake_debug_mode]
                "-DENABLE_CUDA:BOOL={0}" -f $CMAKE_BOOL[$enable_gpu]
                "-DENABLE_CXX_EXPERIMENTAL:BOOL={0}" -f $CMAKE_BOOL[$enable_cxx]
                "-DBUILD_TESTING:BOOL={0}" -f $CMAKE_BOOL[$enable_tests]
                "-DCLEAN_3RDPARTY_INSTALL_DIR:BOOL={0}" -f $CMAKE_BOOL[$do_clean_3rdparty]
                "-DUSE_VERBOSE_MAKEFILE:BOOL={0}" -f $CMAKE_BOOL[-not $cmake_make_silent]
               )
$make_args = @()

if ([bool]$cmake_generator) {
    $cmake_args += "-G", "$cmake_generator"
}

if([bool]$prefix_dir) {
    $cmake_args += "-DCMAKE_INSTALL_PREFIX:FILEPATH=`"${prefix_dir}`""
}

if ($enable_ccache) {
    $ccache_exec=''
    if(Test-CommandExists ccache) {
        $ccache_exec = 'ccache'
    }
    elseif(Test-CommandExists sccache) {
        $ccache_exec = 'sccache'
    }

    if ([bool]$ccache_exec) {
        $ccache_exec = (Get-Command "$ccache_exec").Source
        $cmake_args += "-DCMAKE_C_COMPILER_LAUNCHER=`"$ccache_exec`""
        $cmake_args += "-DCMAKE_CXX_COMPILER_LAUNCHER=`"$ccache_exec`""
    }
}

if ($enable_gpu -and [bool]$cuda_arch) {
    $cmake_args += "-DCMAKE_CUDA_ARCHITECTURES:STRING=`"$cuda_arch`""
}

if ($force_local_pkgs) {
    $cmake_args += "-DMQ_FORCE_LOCAL_PKGS=all"
}
elseif ([bool]"$local_pkgs") {
    $cmake_args += "-DMQ_FORCE_LOCAL_PKGS=`"$local_pkgs`""
}

if($n_jobs -ne -1) {
    $cmake_args += "-DJOBS:STRING={0}" -f $n_jobs
    $make_args += "-j `"$n_jobs`""
}

if(-Not $cmake_make_silent) {
    $make_args += "-v"
}

$target_args = @()
if($do_install) {
    $target_args += '--target', 'install'
}

# ------------------------------------------------------------------------------
# Build

if (-Not (Test-Path -Path "$build_dir" -PathType Container) -or $do_clean_build_dir) {
    $do_configure = $true
}
elseif ($do_clean_cache) {
    $do_configure = $true
    Write-Output "Removing CMake cache at: $build_dir/CMakeCache.txt"
    Call-Cmd Remove-Item -Force "$build_dir/CMakeCache.txt" -ErrorAction SilentlyContinue
    Write-Output "Removing CMake files at: $build_dir/CMakeFiles"
    Call-Cmd Remove-Item -Force -Recurse "$build_dir/CMakeFiles" -ErrorAction SilentlyContinue
}

if ($do_configure) {
    Call-CMake -S "$source_dir" -B "$build_dir" @cmake_args @unparsed_args
}

if ($configure_only) {
    exit 0
}

if ($do_clean) {
    Call-CMake --build "$build_dir" --target clean
}

if($do_docs) {
    Call-CMake --build "$build_dir" --config "$build_type" --target docs @make_args
}

Call-CMake --build "$build_dir" --config "$build_type" @target_args @make_args

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

.PARAMETER Clean
Run make clean before building

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

.PARAMETER Configure
Force running the CMake configure step

.PARAMETER ConfigureOnly
Stop after the CMake configure and generation steps (ie. before building MindQuantum)

.PARAMETER Cxx
(experimental) Enable MindQuantum C++ support

.PARAMETER Debug
Build in debug mode

.PARAMETER DebugCMake
Enable debugging mode for CMake configuration step

.PARAMETER DryRun
Dry run; only print commands but do not execute them

.PARAMETER Doc
Setup the Python virtualenv for building the documentation and ask CMake to build the documentation

.PARAMETER Gpu
Enable GPU support

.PARAMETER Help
Show help message.

.PARAMETER Install
Build the `install` target

.PARAMETER Jobs
Number of parallel jobs for building

.PARAMETER LocalPkgs
Compile third-party dependencies locally

.PARAMETER Prefix
Specify installation prefix

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

.PARAMETER A
CMake argument: Specify platform name if supported by generator.

.PARAMETER D
CMake argument: Create or update a cmake cache entry.

.INPUTS

None.

.OUTPUTS

None.

.EXAMPLE

PS> .\build_locally.ps1

.EXAMPLE

PS> .\build_locally.ps1 -gpu

.EXAMPLE

PS> .\build_locally.ps1 -Cxx -WithBoost -WithoutEigen3

.EXAMPLE

PS> .\build_locally.ps1 -Gpu -DCMAKE_CUDA_COMPILER=D:\cuda\bin\nvcc
#>
