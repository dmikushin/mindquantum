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
    # Flags
    [switch]$Clean,
    [switch]$CleanAll,
    [switch]$CleanBuildDir,
    [switch]$CleanCache,
    [switch]$CleanVenv,
    [switch]$Configure,
    [switch]$ConfigureOnly,
    [switch]$Cxx,
    [switch]$Debug,
    [switch]$DryRun,
    [switch]$Gpu,
    [switch]$Help,
    [switch]$Ninja,
    [switch]$ShowLibraries,
    [switch]$c,
    [switch]$h,
    [switch]$n,

    # Option with values
    [string]$B,
    [string]$Build,
    [string]$J,
    [string]$Jobs
)

$BASENAME = Split-Path $MyInvocation.MyCommand.Path -Leaf
$BASEPATH = Split-Path $MyInvocation.MyCommand.Path -Parent
$CMAKE_BOOL = @('OFF', 'ON')

$IsLinuxEnv = (Get-Variable -Name "IsLinux" -ErrorAction Ignore)
$IsMacOSEnv = (Get-Variable -Name "IsMacOS" -ErrorAction Ignore)
$IsWinEnv = !$IsLinuxEnv -and !$IsMacOSEnv

# ==============================================================================
# Default values

$build_type = "Release"
$configure_only = 0
$do_clean = 0
$do_clean_build_dir = 0
$do_clean_cache = 0
$do_clean_venv = 0
$do_configure = 0
$dry_run = 0
$enable_cxx = 0
$enable_gpu = 0
$enable_projectq = 1
$enable_quest = 0
$force_local_pkgs = 0
$local_pkgs = @()
$n_jobs = 8

$source_dir = Resolve-Path $BASEPATH
$build_dir = "$BASEPATH\build"

$third_party_libraries = ((Get-ChildItem -Path $BASEPATH\third_party -Directory -Exclude cmake).Name).ForEach("ToLower")

# ==============================================================================

function Call-Cmd {
    if ($dry_run -ne 1) {
        Invoke-Expression -Command "$args"
    }
    else {
        echo "$args"
    }
}

function Call-CMake {
    if ($dry_run -ne 1) {
        echo "**********"
        echo "Calling CMake with: cmake $args"
        echo "**********"
    }
    Call-Cmd cmake @args
}

function Test-CommandExists{
    Param ($command)

    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = ‘stop’

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

function print_show_libraries {
    echo 'Known third-party libraries:'
    foreach($lib in $third_party_libraries) {
        echo (" - {0}" -f $lib)
    }
}

# ------------------------------------------------------------------------------

function help_message() {
    echo 'Build MindQunantum locally (in-source build)'
    echo ''
    echo 'This is mainly relevant for developers that do not want to always '
    echo 'have to reinstall the Python package'
    echo ''
    echo 'This script will create a Python virtualenv in the MindQuantum root'
    echo 'directory and then build all the C++ Python modules and place the'
    echo 'generated libraries in their right locations within the MindQuantum'
    echo 'folder hierarchy so Python knows how to find them.'
    echo ''
    echo 'A pth-file will be created in the virtualenv site-packages directory'
    echo 'so that the MindQuantum root folder will be added to the Python PATH'
    echo 'without the need to modify PYTHONPATH.'
    echo ''
    echo 'Usage:'
    echo ('  {0} [options]' -f $BASENAME)
    echo ''
    echo 'Options:'
    echo '  -h,--help           Show this help message and exit'
    echo '  -n                  Dry run; only print commands but do not execute them'
    echo ''
    echo '  -B,-Build [dir]     Specify build directory'
    echo ("                      Defaults to: {0}" -f $build_dir)
    echo '  -Clean              Run make clean before building'
    echo '  -CleanAll           Clean everything before building.'
    echo '                      Equivalent to --clean-venv --clean-builddir'
    echo '  -CleanBuildDir      Delete build directory before building'
    echo '  -CleanCache         Re-run CMake with a clean CMake cache'
    echo '  -CleanVenv          Delete Python virtualenv before building'
    echo '  -c,-Configure       Force running the CMake configure step'
    echo '  -ConfigureOnly      Stop after the CMake configure and generation steps (ie. before building MindQuantum)'
    echo '  -Cxx                (experimental) Enable MindQuantum C++ support'
    echo '  -Debug              Build in debug mode'
    echo '  -Gpu                Enable GPU support'
    echo '  -J,-Jobs [N]        Number of parallel jobs for building'
    echo ("                      Defaults to: {0}" -f $n_jobs)
    echo '  -LocalPkgs          Compile third-party dependencies locally'
    echo '  -ShowLibraries      Show all known third-party libraries'
    echo '  -With<library>      Build the third-party <library> from source (<library> is case-insensitive)'
    echo '                      (ignored if --local-pkgs is passed, except for projectq and quest)'
    echo '  -Without<library>   Do not build the third-party library from source (<library> is case-insensitive)'
    echo '                      (ignored if --local-pkgs is passed, except for projectq and quest)'
    echo ''
    echo 'Any options not matching one of the above will be passed on to CMake during the configuration step'
    echo ''
    echo 'Example calls:'
    echo ("{0} -B build" -f $BASENAME)
    echo ("{0} -B build -gpu" -f $BASENAME)
    echo ("{0} -B build -cxx -WithBoost -Without-Quest" -f $BASENAME)
    echo ("{0} -B build -DCMAKE_CUDA_COMPILER=/opt/cuda/bin/nvcc" -f $BASENAME)
}

# ==============================================================================

if ($n.IsPresent -Or $DryRun.IsPresent) {
    $dry_run = 1
}

if ($Clean.IsPresent) {
    $do_clean=1
}
if ($CleanAll.IsPresent) {
    $do_clean_venv = 1
    $do_clean_build_dir = 1
}
if ($CleanBuildDir.IsPresent) {
    $do_clean_build_dir = 1
}
if ($CleanCache.IsPresent) {
    $do_clean_cache = 1
}
if ($CleanVenv.IsPresent) {
    $do_clean_venv = 1
}

if ($C.IsPresent -Or $Configure.IsPresent) {
    $do_configure = 1
}
if ($ConfigureOnly.IsPresent) {
    $configure_only = 1
}

if ($Cxx.IsPresent) {
    $enable_cxx = 1
}

if ($Debug.IsPresent) {
    $build_type = "Debug"
}

if ($Gpu.IsPresent) {
    $enable_gpu = 1
}

if ($LocalPkgs.IsPresent) {
    $force_local_pkgs = 1
}

if ($B -ne "" -Or $Build -ne "") {
    $build_dir = "$B" + "$Build"
}

if ($J -ne "" -Or $Jobs -ne "") {
    $n_jobs = "$J" + "$Jobs"
}

# Parse -With<library> and -Without<library>
$cmake_extra_args = @()
foreach($arg in $args) {
    if ("$arg" -match "[Ww]ith[Oo]ut-?([a-zA-Z0-9_]+)") {
        $enable_lib = 0
        $library = ($Matches.1).Tolower()
    }
    elseif("$arg" -match "[Ww]ith-?([a-zA-Z0-9_]+)") {
        $enable_lib = 1
        $library = ($Matches.1).Tolower()
    }
    else {
        $cmake_extra_args += $arg
    }

    if ((($third_party_libraries -eq $library) -join " ") -eq "") {
        echo ('Unkown library for {0}' -f $arg)
        exit 1
    }

    if ($library -eq "projectq") {
        $enable_projectq = $enable_lib
    }
    elseif ($library -eq "quest") {
        $enable_quest = $enable_lib
    }
    elseif ($enable_lib -eq 1) {
        $local_pkgs += $library
    }
    else {
        $local_pkgs = $local_pkgs -ne $library
    }
}

$local_pkgs = ($local_pkgs -join ',')


if ($H.IsPresent -Or $Help.IsPresent) {
    help_message
    exit 1
}

if($ShowLibraries.IsPresent) {
    print_show_libraries
    exit 1
}

# ==============================================================================
# Locate python or python3

if(Test-CommandExists python3) {
    $PYTHON = "python3"
}
elseif (Test-CommandExists python) {
    $PYTHON = "python"
}
else {
    echo 'Unable to locate python or python3!'
    exit 1
}

# ==============================================================================

$ErrorActionPreference="stop"

cd $BASEPATH

# ------------------------------------------------------------------------------

if ($do_clean_venv -eq 1) {
    echo "Deleting virtualenv folder: $BASEPATH\venv"
    Call-Cmd Remove-Item -Force -Recurse "$BASEPATH\venv" -ErrorAction SilentlyContinue
}

if ($do_clean_build_dir -eq 1) {
    echo "Deleting build folder: $build_dir"
    Call-Cmd Remove-Item -Force -Recurse "$build_dir" -ErrorAction SilentlyContinue
}

$created_venv = 0
if (-Not (Test-Path -Path "$BASEPATH/venv" -PathType Container)) {
    $created_venv = 1
    echo "Creating Python virtualenv: $PYTHON -m venv venv"
    Call-Cmd $PYTHON -m venv venv
}

if($IsWinEnv) {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
}

if (Test-Path -Path $BASEPATH/venv/Scripts/activate.ps1) {
    ./venv/Scripts/Activate.ps1
}
else {
    ./venv/bin/Activate.ps1
}

if ($created_venv -eq 1) {
    $pkgs = @("pip", "setuptools", "wheel", "build", "pybind11")

    if($IsLinuxEnv) {
        $pkgs += "auditwheel"
    }
    elseif($IsMacOSEnv) {
        $pkgs += "delocate"
    }

    # TODO(dnguyen): add wheel delocation package for Windows once we figure this out


    echo ("Updating Python packages: $PYTHON -m pip install -U "  + ($pkgs -Join ' '))
    Call-Cmd $PYTHON -m pip install -U @pkgs
}

# Make sure the root directory is in the virtualenv PATH
$site_pkg_dir = Invoke-Expression -Command "$PYTHON -c 'import site; print(site.getsitepackages()[0])'"
$pth_file = "$site_pkg_dir\mindquantum_local.pth"

if (-Not (Test-Path -Path "$pth_file" -PathType leaf)) {
    echo "Creating pth-file in $pth_file"
    echo "$BASEPATH" > "$pth_file"
}

# ------------------------------------------------------------------------------
# Setup arguments for build

$cmake_args = @('-DIN_PLACE_BUILD:BOOL=ON')

$cmake_args += "-DENABLE_PROJECTQ:BOOL={0}" -f $CMAKE_BOOL[$enable_projectq]
$cmake_args += "-DENABLE_QUEST:BOOL={0}" -f $CMAKE_BOOL[$enable_quest]

if ($enable_gpu -eq 1) {
    $cmake_args += "-DENABLE_CUDA:BOOL=ON"
}

if ($enable_cxx -eq 1) {
    $cmake_args += "-DENABLE_CXX_EXPERIMENTAL:BOOL=ON"
}

if ($force_local_pkgs -eq 1) {
    $cmake_args += "-DMQ_FORCE_LOCAL_PKGS=all"
}
elseif ("$local_pkgs" -ne "") {
    $cmake_args += "-DMQ_FORCE_LOCAL_PKGS=`"$local_pkgs`""
}

if ($Ninja.IsPresent) {
    $cmake_args += "-GNinja"
}

$cmake_args += "-DJOBS:STRING={0}" -f $n_jobs

# ------------------------------------------------------------------------------
# Build

if ($do_configure -eq 0) {
    if (-Not (Test-Path -Path "$build_dir" -PathType Container) -Or $do_clean_build_dir -eq 1) {
        $do_configure=1
    }
    elseif ($do_clean_cache -eq 1) {
        $do_configure=1
        echo "Removing CMake cache at: $build_dir/CMakeCache.txt"
        Call-Cmd Remove-Item -Force "$build_dir/CMakeCache.txt" -ErrorAction SilentlyContinue
        echo "Removing CMake files at: $build_dir/CMakeFiles"
        Call-Cmd Remove-Item -Force -Recurse "$build_dir/CMakeFiles" -ErrorAction SilentlyContinue
    }
}

if ($do_configure -eq 1) {
    Call-CMake -S "$source_dir" -B "$build_dir" @cmake_args @cmake_extra_args
}

if ($configure_only -eq 1) {
    exit 0
}

if ($do_clean -eq 1) {
    Call-CMake --build "$build_dir" --target clean
}

Call-CMake --build "$build_dir" -j "$n_jobs" --config "$build_type"

# ==============================================================================
