cmake_minimum_required(VERSION 3.20 FATAL_ERROR)

project(cppsim)

list(PREPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake/Modules)
list(PREPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake/commands)

option(BUILD_TESTING "Build the test suite?" OFF)

include(FetchContent)
set(FETCHCONTENT_QUIET OFF)

if(BUILD_TESTING)
  FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG        25cc5777a17820a6339204a3552aa1dd5e428669
  )
  FetchContent_Declare(
    hipThrust
    GIT_REPOSITORY https://github.com/dmikushin/Thrust.git
    GIT_TAG        9a12c1259805ed0a3a5fe9bdeb098a872deb936b
  )
  FetchContent_MakeAvailable(hipThrust googletest)

  if(NOT DEFINED Eigen3_DIR)
    FetchContent_Declare(
      Eigen3
      GIT_REPOSITORY https://gitlab.com/libeigen/eigen.git
      GIT_TAG        3147391d946bb4b6c68edd901f2add6ac1f31f8c
    )
    FetchContent_MakeAvailable(googletest Eigen3)
  else()
    find_package(Eigen3 CONFIG REQUIRED)
  endif()
endif()

if(NOT DEFINED digestpp_DIR)
  message(STATUS "Checking out ")
  FetchContent_Declare(
    digestpp
    GIT_REPOSITORY https://github.com/kerukuro/digestpp.git
    GIT_TAG        4ec4106677e652a90716ad929d657a622089ef16
  )
  FetchContent_MakeAvailable(digestpp)
  add_library(digestpp::digestpp INTERFACE IMPORTED)
  target_include_directories(digestpp::digestpp INTERFACE ${digestpp_SOURCE_DIR})
else()
  find_package(digestpp CONFIG REQUIRED)
endif()

if(NOT DEFINED res_embed_CMAKE_DIR)
  FetchContent_Declare(
    res_embed
    GIT_REPOSITORY https://github.com/dmikushin/res_embed.git
    GIT_TAG        26a18b27794c1fcf698e603beb8b122218dae490
  )
  FetchContent_MakeAvailable(res_embed)
  include(ResEmbed)
else()
  include(${res_embed_CMAKE_DIR}/ResEmbed.cmake)
endif()

if(NOT pybind11_DIR)
  FetchContent_Declare(
    pybind11
    GIT_REPOSITORY https://github.com/pybind/pybind11.git
    GIT_TAG        68e6fdaa90fc93979e6d5d1e9f788f464593e8f2
  )
  FetchContent_MakeAvailable(pybind11)
else()
  find_package(pybind11 REQUIRED)
endif()

find_package(Python 3.7.0 COMPONENTS Interpreter Development.Embed)

find_package(OpenMP REQUIRED)

# ==============================================================================

add_library(kernelgen STATIC "src/kernelgen.cpp" "src/compiler.cpp" "src/tempfile.cpp")
set_target_properties(kernelgen PROPERTIES CXX_STANDARD 17 CXX_EXTENSIONS OFF)
set_property(TARGET kernelgen PROPERTY POSITION_INDEPENDENT_CODE ON)
target_include_directories(kernelgen PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
res_embed(TARGET kernelgen NAME "nointrin" PATH "${CMAKE_CURRENT_SOURCE_DIR}/include/nointrin/kernelgen.py" KEYWORD)
target_link_libraries(kernelgen PUBLIC digestpp::digestpp pybind11::pybind11 Python::Python OpenMP::OpenMP_CXX ${CMAKE_DL_LIBS})

pybind11_add_module(${PROJECT_NAME} SHARED "src/_${PROJECT_NAME}.cpp")
target_link_libraries(${PROJECT_NAME} PRIVATE kernelgen)

macro(kernelgen)
	set(oneValueArgs NQUBITS VARIANT TARGET)
	cmake_parse_arguments(KERNELGEN "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

	set(NQUBITS ${KERNELGEN_NQUBITS})
	set(VARIANT ${KERNELGEN_VARIANT})
	set(KERNELGEN "${CMAKE_CURRENT_SOURCE_DIR}/include/${VARIANT}/kernelgen.py")
	set(KERNEL_PATH "${CMAKE_CURRENT_BINARY_DIR}/generated/${VARIANT}/kernel${NQUBITS}.hpp")

	# Call generator.
	add_custom_command(
		OUTPUT ${KERNEL_PATH}
		COMMAND ${Python_EXECUTABLE} ${KERNELGEN} ${NQUBITS} ${KERNEL_PATH} --combinations=True
		COMMENT "Generating kernel for ${NQUBITS} qubits"
		DEPENDS ${KERNELGEN})
	set_source_files_properties("${KERNEL_PATH}" PROPERTIES GENERATED TRUE)

	# Append the generated file to the target sources.
	target_sources(${KERNELGEN_TARGET} PRIVATE ${KERNEL_PATH})
	target_include_directories(${KERNELGEN_TARGET} PRIVATE ${CMAKE_CURRENT_BINARY_DIR})
endmacro()

if(BUILD_TESTING)
  add_executable(test_nointrin "src/test/test_nointrin.cpp")
  set_target_properties(test_nointrin PROPERTIES CXX_STANDARD 17 CXX_EXTENSIONS OFF)
  target_include_directories(test_nointrin PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
  target_include_directories(test_nointrin PRIVATE Eigen3::Eigen)
  target_link_libraries(test_nointrin PRIVATE gtest kernelgen)
  kernelgen(TARGET test_nointrin NQUBITS 1 VARIANT nointrin)
  kernelgen(TARGET test_nointrin NQUBITS 2 VARIANT nointrin)
  kernelgen(TARGET test_nointrin NQUBITS 3 VARIANT nointrin)
  kernelgen(TARGET test_nointrin NQUBITS 4 VARIANT nointrin)
  kernelgen(TARGET test_nointrin NQUBITS 5 VARIANT nointrin)

  add_executable(test_popcount "src/test/test_popcount.cpp")
  set_target_properties(test_popcount PROPERTIES CXX_STANDARD 17 CXX_EXTENSIONS OFF)
  target_include_directories(test_popcount PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
  target_link_libraries(test_popcount PRIVATE Eigen3::Eigen gtest)

  add_executable(test_combinations "src/test/test_combinations.cpp")
  set_target_properties(test_combinations PROPERTIES CXX_STANDARD 17 CXX_EXTENSIONS OFF)
  target_include_directories(test_combinations PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
  target_link_libraries(test_combinations PRIVATE gtest Eigen3::Eigen OpenMP::OpenMP_CXX)

  add_executable(benchmark "src/benchmark/benchmark.cpp")
  target_link_libraries(benchmark PRIVATE gtest kernelgen)   
endif()

