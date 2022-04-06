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

set(MQ_BASE_HEADERS
    gate/basic_gate.h
    gate/gates.h
    hamiltonian/hamiltonian.h
    matrix/two_dim_matrix.h
    core/popcnt.h
    pr/parameter_resolver.h
    projector/projector.h
    sparse/algo.h
    sparse/csrhdmatrix.h
    sparse/paulimat.h
    sparse/sparse_utils.h
    core/type.h
    core/utils.h)
set(MQ_BASE_SOURCES utils.cc)

if(ENABLE_CUDA)
  add_library(mq_base STATIC ${MQ_BASE_SOURCES} ${MQ_BASE_HEADERS})

  target_compile_definitions(mq_base PUBLIC GPUACCELERATED)
  target_link_libraries(mq_base PUBLIC $<IF:$<BOOL:${CUDA_STATIC}>,CUDA::cudart_static,CUDA::cudart>)
else()
  add_library(mq_base STATIC ${MQ_BASE_SOURCES} ${MQ_BASE_HEADERS})
endif()
target_include_directories(mq_base PUBLIC ${CMAKE_CURRENT_LIST_DIR})
target_link_libraries(mq_base PUBLIC mindquantum_setup)
