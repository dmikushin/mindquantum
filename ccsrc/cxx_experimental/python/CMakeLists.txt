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

# TODO: Create OBJECT libraries to avoid duplicate compilations For that need to get pybind11 dependencies manually...

pybind11_add_module(
  _mindquantum_cxx_core
  MODULE
  ${CMAKE_CURRENT_LIST_DIR}/lib/_mindquantum_cxx_core.cpp
  ${CMAKE_CURRENT_LIST_DIR}/lib/cengines/base.cpp
  ${CMAKE_CURRENT_LIST_DIR}/lib/cengines/engine_list.cpp
  ${CMAKE_CURRENT_LIST_DIR}/lib/cengines/mapping.cpp
  ${CMAKE_CURRENT_LIST_DIR}/lib/cengines/optimisation.cpp
  ${CMAKE_CURRENT_LIST_DIR}/lib/cengines/printer.cpp
  ${CMAKE_CURRENT_LIST_DIR}/lib/cengines/resource_counter.cpp
  ${CMAKE_CURRENT_LIST_DIR}/lib/core/core.cpp
  ${CMAKE_CURRENT_LIST_DIR}/lib/ops/command.cpp)

target_link_libraries(_mindquantum_cxx_core PRIVATE mindquantum_cxx)
target_include_directories(_mindquantum_cxx_core PRIVATE ${CMAKE_CURRENT_LIST_DIR}/include
                                                         ${PROJECT_SOURCE_DIR}/include)
set_output_directory_auto(_mindquantum_cxx_core mindquantum/experimental)

pybind11_add_module(
  _mindquantum_cxx_cengines
  MODULE
  ${CMAKE_CURRENT_LIST_DIR}/lib/cengines/base.cpp
  ${CMAKE_CURRENT_LIST_DIR}/lib/cengines/cengines.cpp
  ${CMAKE_CURRENT_LIST_DIR}/lib/cengines/engine_list.cpp
  ${CMAKE_CURRENT_LIST_DIR}/lib/cengines/mapping.cpp
  ${CMAKE_CURRENT_LIST_DIR}/lib/cengines/optimisation.cpp
  ${CMAKE_CURRENT_LIST_DIR}/lib/cengines/printer.cpp
  ${CMAKE_CURRENT_LIST_DIR}/lib/cengines/resource_counter.cpp
  ${CMAKE_CURRENT_LIST_DIR}/lib/ops/command.cpp)

target_link_libraries(_mindquantum_cxx_cengines PRIVATE mindquantum_cxx)
target_include_directories(_mindquantum_cxx_cengines PRIVATE ${CMAKE_CURRENT_LIST_DIR}/include)
set_output_directory_auto(_mindquantum_cxx_cengines mindquantum/experimental)

pybind11_add_module(_mindquantum_cxx_ops MODULE ${CMAKE_CURRENT_LIST_DIR}/lib/ops/ops.cpp
                    ${CMAKE_CURRENT_LIST_DIR}/lib/ops/command.cpp)

target_link_libraries(_mindquantum_cxx_ops PRIVATE mindquantum_cxx)
target_include_directories(_mindquantum_cxx_ops PRIVATE ${CMAKE_CURRENT_LIST_DIR}/include)
set_output_directory_auto(_mindquantum_cxx_ops mindquantum/experimental)
