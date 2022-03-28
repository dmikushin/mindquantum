# ==============================================================================
#
# Copyright 2022 <Huawei Technologies Co., Ltd>
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

# for pybind
pybind11_add_module(mqbackend ${CMAKE_CURRENT_SOURCE_DIR}/binding.cc)
target_compile_definitions(mqbackend PUBLIC $<$<BOOL:${ENABLE_PROJECTQ}>:ENABLE_PROJECTQ>
                                            $<$<BOOL:${ENABLE_QUEST}>:ENABLE_QUEST>)
target_include_directories(mqbackend PUBLIC ${CMAKE_CURRENT_LIST_DIR})

target_link_libraries(mqbackend PUBLIC ${PARALLEL_LIBS} "$<$<BOOL:${ENABLE_PROJECTQ}>:mq_projectq>"
                                       "$<$<BOOL:${ENABLE_QUEST}>:QuEST;mq_quest>" mq_base)

set_output_directory_auto(mqbackend mindquantum)
python_install_set_rpath(mqbackend "")

if(WIN32)
  get_filename_component(CXX_DIR ${CMAKE_CXX_COMPILER} PATH)
  file(
    GLOB
    LIB_LIST
    ${CXX_DIR}/libstdc++-6.dll
    ${CXX_DIR}/libwinpthread-1.dll
    ${CXX_DIR}/libssp-0.dll
    ${CXX_DIR}/libgcc_s_*-1.dll
    ${CXX_DIR}/libgomp-1.dll)
  # install(FILES ${LIB_LIST} DESTINATION ${CMAKE_BINARY_DIR})
  foreach(win_dep_lib ${LIB_LIST})
    message("COPYING ${WIN_DEP_LIB}")
    file(COPY ${win_dep_lib} DESTINATION ${MQBACKEND_OUTPUT_DIR} FOLLOW_SYMLINK_CHAIN)
  endforeach()
endif()
