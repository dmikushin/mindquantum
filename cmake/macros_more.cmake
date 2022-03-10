# ==============================================================================
#
# Copyright 2020 <Huawei Technologies Co., Ltd>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ==============================================================================

# Add a Python library (overload of the original python_add_library())
#
# python_add_library(<target>)
#
# Override the original python_add_library() to keep track of all python libraries and properly set some target
# properties depending on the current CMake version.
macro(python_add_library target)
  set(_args ${ARGN})
  if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.17)
    # Position 0 is the library type
    list(GET _args 0 _lib_type)
    if(_lib_type STREQUAL "MODULE")
      list(INSERT _args 1 WITH_SOABI)
    endif()
  endif()

  _python_add_library(${target} ${_args})
  append_to_property(_doc_targets GLOBAL ${target})
  append_to_property(_python_targets GLOBAL ${target})

  if(_python_so_extension)
    set_target_properties(${target} PROPERTIES SUFFIX "${_python_so_extension}")
  endif()
endmacro()

# Add a Pybind11 library (overload of the original pybind11_add_module())
#
# python_add_library(<target>)
#
# Override the original python_add_module() to keep track of all python libraries and properly set some target
# properties depending on the current CMake version.
function(pybind11_add_module target)
  _pybind11_add_module(${target} ${ARGN})

  append_to_property(_doc_targets GLOBAL ${target})
  append_to_property(_python_targets GLOBAL ${target})
endfunction()

# ==============================================================================

# Add a Catch2 test executable
function(add_test_executable target)
  cmake_parse_arguments(${target} "" "" "LIBS;DEFINES" ${ARGN})

  add_executable(${target} ${target}.cpp ${${target}_UNPARSED_ARGUMENTS})
  target_include_directories(${target} PRIVATE ${PROJECT_SOURCE_DIR}/tests)
  target_link_libraries(${target} PRIVATE Catch2::Catch2 ${${target}_LIBS})
  catch_discover_tests(${target})
  set_property(
    SOURCE ${target}.cpp
    APPEND_STRING
    PROPERTY COMPILE_DEFINITIONS CATCH_CONFIG_MAIN)

  target_compile_definitions(${target} PRIVATE ${${target}_DEFINES})
endfunction()

# ==============================================================================
