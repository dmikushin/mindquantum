@echo off

rem Copyright 2021 Huawei Technologies Co., Ltd
rem
rem Licensed under the Apache License, Version 2.0 (the "License");
rem you may not use this file except in compliance with the License.
rem You may obtain a copy of the License at
rem
rem http://www.apache.org/licenses/LICENSE-2.0
rem
rem Unless required by applicable law or agreed to in writing, software
rem distributed under the License is distributed on an "AS IS" BASIS,
rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
rem See the License for the specific language governing permissions and
rem limitations under the License.

setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS

set BASEPATH=%~dp0
set ROOTDIR=%BASEPATH%
set SCRIPTDIR=%BASEPATH%\scripts\build
set PROGRAM=%~nx0

rem ============================================================================
rem Default values

set configure_only=0
set do_clean=0
set do_clean_build_dir=0
set do_clean_cache=0
set do_docs=0
set do_install=0
set prefix=

call %SCRIPTDIR%\default_values.bat

rem ============================================================================

:initial
  set result=false
  if "%1" == "" goto :done_parsing

  if /I "%1" == "/h" set result=true
  if /I "%1" == "/Help" set result=true
  if "%result%" == "true" (
    call :help_message
    goto :EOF
  )

  if /I "%1" == "/n" set result=true
  if "%result%" == "true" (
    set dry_run=1
    shift & goto :initial
  )

  if /I "%1" == "/B" set result=true
  if /I "%1" == "/Build" set result=true
  if "%result%" == "true" (
    set value=%2
    if not defined value goto :arg_build
    if "!value:~0,1!" == "/" (
      :arg_build
      echo %BASENAME%: option requires an argument -- '/B,/Build'
      goto :EOF
    )
    set build_dir=!value!
    shift & shift & goto :initial
  )

  if /I "%1" == "/Clean" (
    set do_clean=1
    shift & goto :initial
  )
  if /I "%1" == "/Clean3rdParty" (
    set do_clean_3rdparty=1
    shift & goto :initial
  )
  if /I "%1" == "/CleanAll" (
    set do_clean_venv=1
    set do_clean_build_dir=1
    shift & goto :initial
  )
  if /I "%1" == "/CleanCache" (
    set do_clean_cache=1
    shift & goto :initial
  )
  if /I "%1" == "/CleanVenv" (
    set do_clean_venv=1
    shift & goto :initial
  )

  if /I "%1" == "/C" set result=true
  if /I "%1" == "/Configure" set result=true
  if "%result%" == "true" (
    set do_configure=1
    shift & goto :initial
  )
  if /I "%1" == "/ConfigureOnly" (
    set configure_only=1
    shift & goto :initial
  )

  if /I "%1" == "/CudaArch" (
    set value=%2
    if not defined value goto :arg_cuda_arch
    if "!value:~0,1!" == "/" (
      :arg_cuda_arch
      echo %BASENAME%: option requires an argument -- '/CudaArch'
      goto :EOF
    )
    call :ToCMakeList value
    set cuda_arch=!value!
    shift & shift & goto :initial
  )

  if /I "%1" == "/Cxx" (
    set enable_cxx=1
    shift & goto :initial
  )

  if /I "%1" == "/Debug" (
    set build_type=Debug
    shift & goto :initial
  )

  if /I "%1" == "/DebugCMake" (
    set cmake_debug_mode=1
    shift & goto :initial
  )

  if /I "%1" == "/Doc" set result=true
  if /I "%1" == "/Docs" set result=true
  if "%result%" == "true" (
    set do_docs=1
    shift & goto :initial
  )

  if /I "%1" == "/Gpu" (
    set enable_gpu=1
    shift & goto :initial
  )

  if /I "%1" == "/Install" (
    set do_install=1
    shift & goto :initial
  )

  if /I "%1" == "/J" set result=true
  if /I "%1" == "/Jobs" set result=true
  if "%result%" == "true" (
    set value=%2
    if not defined value goto :arg_build
    if "!value:~0,1!" == "/" (
      :arg_build
      echo %BASENAME%: option requires an argument -- '/B,/Build'
      goto :EOF
    )
    set n_jobs=!value!
    shift & shift & goto :initial
  )

  if /I "%1" == "/LocalPkgs" (
    set force_local_pkgs=1
    shift & goto :initial
  )

  if /I "%1" == "/Ninja" (
    set ninja=1
    shift & goto :initial
  )

  if /I "%1" == "/Prefix" (
    set value=%2
    if not defined value goto :arg_prefix
    if "!value:~0,1!" == "/" (
      :arg_prefix
      echo %BASENAME%: option requires an argument -- '/Prefix'
      goto :EOF
    )
    set prefix=!value!
    shift & shift & goto :initial
  )

  if /I "%1" == "/Quiet" (
    set cmake_make_silent=1
    shift & goto :initial
  )

  if /I "%1" == "/ShowLibraries" (
    call :print_show_libraries
    goto :EOF
  )

  if /I "%1" == "/Test" (
    set enable_tests=1
    shift & goto :initial
  )

  if /I "%1" == "/UpdateVenv" (
    set do_update_venv=1
    shift & goto :initial
  )

  if /I "%1" == "/Venv" (
    set value=%2
    if not defined value goto :arg_venv
    if "!value:~0,1!" == "/" (
      :arg_venv
      echo %BASENAME%: option requires an argument -- '/Venv'
      goto :EOF
    )
    set python_venv_path=!value!
    shift & shift & goto :initial
  )

  set value=%1
  set with_header=!value:~0,5!
  if /I "!with_header!" == "/with" (
    set library=!value:~5!
    call :LoCase library
    if not defined local_pkgs (
      set local_pkgs=!library!
    ) else (
      set local_pkgs=!local_pkgs!,!library!
    )
    shift & goto :initial
  )

  set unparsed_args=!unparsed_args! %1
  shift & goto :initial

:done_parsing

rem ============================================================================
rem Locate python or python3

call %SCRIPTDIR%\locate_python3.bat
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%

rem ============================================================================

cd %ROOTDIR%

rem ----------------------------------------------------------------------------

if !do_clean_build_dir! == 1 (
  echo Deleting build folder: !build_dir!
  if exist !build_dir! call :call_cmd rd /Q /S !build_dir!
)

rem NB: `created_venv` variable can be used to detect if a virtualenv was created or not
call %SCRIPTDIR%\python_virtualenv_activate.bat
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%

if NOT !dry_run! == 1 (
   rem Make sure the root directory is in the virtualenv PATH
   for /F %%i in ('!PYTHON! -c "import site; print(site.getsitepackages()[0])"') do set site_pkg_dir=%%i
   set pth_file=!site_pkg_dir!\mindquantum_local.pth

   if NOT exist !pth_file! (
      echo Creating pth-file in !pth_file!
      echo %BASEPATH% > !pth_file!
   )
)

rem ------------------------------------------------------------------------------
rem Locate cmake or cmake3

call %SCRIPTDIR%\locate_cmake.bat
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%

rem ------------------------------------------------------------------------------

call %SCRIPTDIR%\python_virtualenv_update.bat
if %ERRORLEVEL% NEQ 0 exit /B %ERRORLEVEL%

rem ----------------------------------------------------------------------------
rem Setup arguments for build

set cmake_args="-DIN_PLACE_BUILD:BOOL=ON -DIS_PYTHON_BUILD:BOOL=OFF -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=ON"

set cmake_args=!cmake_args! -DENABLE_BUILD_TYPE:STRING=!build_type!

if !cmake_debug_mode! == 1 set cmake_args=!cmake_args! -DENABLE_CMAKE_DEBUG:BOOL=ON

if !cmake_make_silent! == 1 set cmake_args=!cmake_args! -DUSE_VERBOSE_MAKEFILE:BOOL=OFF

if !do_clean_3rdparty! == 1 set cmake_args=!cmake_args! -DCLEAN_3RDPARTY_INSTALL_DIR:BOOL=ON

if !enable_cxx! == 1 set cmake_args=!cmake_args! -DENABLE_CXX_EXPERIMENTAL:BOOL=ON

if !enable_gpu! == 1 (
  set cmake_args=!cmake_args! -DENABLE_CUDA:BOOL=ON
  if NOT "!cuda_arch!" == "" set cmake_args=!cmake_args! -DCMAKE_CUDA_ARCHITECTURES:STRING=!cuda_arch!
)

if !enable_projectq! == 1 (
  set cmake_args=!cmake_args! -DENABLE_PROJECTQ:BOOL=ON
) else (
  set cmake_args=!cmake_args! -DENABLE_PROJECTQ:BOOL=OFF
)

if !enable_tests! == 1 set cmake_args=!cmake_args! -DBUILD_TESTING:BOOL=ON

if !force_local_pkgs! == 1 (
  set cmake_args=!cmake_args! -DMQ_FORCE_LOCAL_PKGS=all
) else (
  if NOT "!local_pkgs!" == "" set cmake_args=!cmake_args! -DMQ_FORCE_LOCAL_PKGS=!local_pkgs!
)

if NOT "!prefix!" == "" set cmake_args=!cmake_args! -DCMAKE_INSTALL_PREFIX:FILEPATH=!prefix!

if !ninja! == 1 (
  set cmake_args=!cmake_args! -GNinja
) else (
  if !n_jobs! == -1 set n_jobs=!n_jobs_default!
)

set make_args=
if NOT !n_jobs! == -1 (
  set cmake_args=!cmake_args! -DJOBS:STRING=!n_jobs!
  set make_args=!make_args! -j !n_jobs!
)

set target_args=
if !do_install! == 1 set target_args=!target_args! --target install

if !cmake_make_silent! == 0 set make_args=!make_args! -v

rem ----------------------------------------------------------------------------
rem Build

if NOT exist !build_dir! goto :do_configure
if !do_clean_build_dir! == 1 goto :do_configure

if !do_clean_cache! == 1 (
    echo Removing CMake cache at: !build_dir!\CMakeCache.txt
    if exist !build_dir!\CMakeCache.txt call :call_cmd del /Q "!build_dir!\CMakeCache.txt"
    echo Removing CMake files at: !build_dir!/CMakeFiles
    if exist !build_dir!/CMakeFiles call :call_cmd rd /Q /S "!build_dir!\CMakeFiles"
    goto :do_configure
)

if !do_configure! == 1 goto :do_configure

goto :done_configure

:do_configure
call :call_cmake -S !source_dir! -B !build_dir! !cmake_args! !unparsed_args!

:done_configure

if !configure_only! == 1 goto :EOF

if !do_clean! == 1 call :call_cmake --build "!build_dir!" --target clean

if !do_docs! == 1 call :call_cmake --build "!build_dir!" --config !build_type! --target docs !make_args!

call :call_cmake --build "!build_dir!" --config !build_type! !target_args! !make_args!

goto :EOF

rem ============================================================================

:LoCase
:: Subroutine to convert a variable VALUE to all lower case.
:: The argument for this subroutine is the variable NAME.
set %~1=!%~1:A=a!
set %~1=!%~1:B=b!
set %~1=!%~1:C=c!
set %~1=!%~1:D=d!
set %~1=!%~1:E=e!
set %~1=!%~1:F=f!
set %~1=!%~1:G=g!
set %~1=!%~1:H=h!
set %~1=!%~1:I=i!
set %~1=!%~1:J=j!
set %~1=!%~1:K=k!
set %~1=!%~1:L=l!
set %~1=!%~1:M=m!
set %~1=!%~1:N=n!
set %~1=!%~1:O=o!
set %~1=!%~1:P=p!
set %~1=!%~1:Q=q!
set %~1=!%~1:R=r!
set %~1=!%~1:S=s!
set %~1=!%~1:T=t!
set %~1=!%~1:U=u!
set %~1=!%~1:V=v!
set %~1=!%~1:W=w!
set %~1=!%~1:X=x!
set %~1=!%~1:Y=y!
set %~1=!%~1:Z=z!
exit /B 0

:ToCMakeList
set %~1=!%~1: =;!
set %~1=!%~1:,=;!
exit /B 0

:call_cmake
  if NOT !dry_run! == 1 (
    echo **********
    echo Calling CMake with: cmake  %*
    echo **********
    cmake %*
  ) else (
    echo cmake %*
  )
  EXIT /B 0

:print_show_libraries
  echo Known third-party libraries:
  for %%a in (%third_party_libraries%) do (
      echo - %%a
  )
  EXIT /B 0

:help_message
  echo Build MindQunantum locally (in-source build)
  echo:
  echo This is mainly relevant for developers that do not want to always
  echo have to reinstall the Python package
  echo:
  echo This script will create a Python virtualenv in the MindQuantum root
  echo directory and then build all the C++ Python modules and place the
  echo generated libraries in their right locations within the MindQuantum
  echo folder hierarchy so Python knows how to find them.
  echo:
  echo A pth-file will be created in the virtualenv site-packages directory
  echo so that the MindQuantum root folder will be added to the Python PATH
  echo without the need to modify PYTHONPATH.
  echo:
  echo Usage:
  echo   %BASENAME% [options]
  echo:
  echo Options:
  echo   /H,/Help            Show this help message and exit
  echo   /N                  Dry run; only print commands but do not execute them
  echo   /B,/Build [dir]     Specify build directory
  echo                       Defaults to: %build_dir%
  echo   /C,/Clean           Run make clean before building
  echo   /Clean3rdParty      Clean 3rd party installation directory
  echo   /CleanAll           Clean everything before building.
  echo                       Equivalent to /CleanVenv /CleanBuilddir
  echo   /CleanBuildDir      Delete build directory before building
  echo   /CleanCache         Re-run CMake with a clean CMake cache
  echo   /CleanVenv          Delete Python virtualenv before building
  echo   /ConfigureOnly      Stop after the CMake configure and generation steps (ie. before building MindQuantum)
  echo   /Cxx                (experimental) Enable MindQuantum C++ support
  echo   /Debug              Build in debug mode
  echo   /DebugCMake         Enable debugging mode for CMake configuration step
  echo   /Doc, /Docs         Setup the Python virtualenv for building the documentation and ask CMake to build the
  echo                       documentation
  echo   /Gpu                Enable GPU support
  echo   /Install            Build the 'install' target
  echo   /J,/Jobs [N]        Number of parallel jobs for building
  echo                       Defaults to: !n_jobs_default!
  echo   /LocalPkgs          Compile third-party dependencies locally
  echo   /Ninja              Use the Ninja CMake generator
  echo   /Prefix             Specify installation prefix
  echo   /Quiet              Disable verbose build rules
  echo   /ShowLibraries      Show all known third-party libraries
  echo   /Test               Build C++ tests and install dependencies for Python testing as well
  echo   /Venv *path*        Path to Python virtual environment
  echo                       Defaults to: %python_venv_path%
  echo   /With*library*      Build the third-party *library* from source (*library* is case-insensitive)
  echo                       (ignored if /LocalPkgs is passed, except for projectq)
  rem echo   /Without*library*   Do not build the third-party library from source (*library* is case-insensitive)
  rem echo                       (ignored if /LocalPkgs is passed, except for projectq)
  echo:
  echo CUDA related options:
  echo   /CudaArch *arch*    Comma-separated list of architectures to generate device code for.
  echo                       Only useful if /Gpu is passed. See CMAKE_CUDA_ARCHITECTURES for more information.
  echo:
  echo NB: any unknown arguments will be passed onto the CMake during the configuration step.
  echo:
  echo Example calls:
  echo %BASENAME% /B build
  echo %BASENAME% /B build /gpu
  echo %BASENAME% /B build /cxx /WithBoost
  echo %BASENAME% /B build "-DCMAKE_CUDA_COMPILER^=/opt/cuda/bin/nvcc"
  EXIT /B 0

rem ============================================================================
