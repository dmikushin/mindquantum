cmake_minimum_required(VERSION 3.20 FATAL_ERROR)

project(
  cppsim
  VERSION 1.0.0
  LANGUAGES C CXX)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake/commands)

# Minimum required Python version (used both in this file and in the installed
# CMake configuration)
set(CPPSIM_PYTHON_VERSION_MIN 3.7.0)

option(BUILD_TESTING "Build the test suite?" OFF)

# ==============================================================================

include(GNUInstallDirs)

set(CPPSIM_INSTALL_BINDIR "${CMAKE_INSTALL_BINDIR}")
set(CPPSIM_INSTALL_SBINDIR "${CMAKE_INSTALL_SBINDIR}")
set(CPPSIM_INSTALL_SYSCONFDIR "${CMAKE_INSTALL_SYSCONFDIR}")
set(CPPSIM_INSTALL_INCLUDEDIR "${CMAKE_INSTALL_INCLUDEDIR}/cppsim")
set(CPPSIM_INSTALL_DATADIR "${CMAKE_INSTALL_DATADIR}/cppsim")
set(CPPSIM_INSTALL_LIBDIR "${CMAKE_INSTALL_LIBDIR}/cppsim")
set(CPPSIM_INSTALL_DOCDIR "${CMAKE_INSTALL_DATADIR}/doc/cppsim")
set(CPPSIM_INSTALL_CMAKEDIR "${CPPSIM_INSTALL_DATADIR}/cmake")
set(CPPSIM_INSTALL_3RDPARTYDIR "${CPPSIM_INSTALL_LIBDIR}/third_party")

# ==============================================================================

include(FetchContent)
set(FETCHCONTENT_QUIET OFF)

if(BUILD_TESTING)
  FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG 25cc5777a17820a6339204a3552aa1dd5e428669)
  FetchContent_Declare(
    hipThrust
    GIT_REPOSITORY https://github.com/dmikushin/Thrust.git
    GIT_TAG 9a12c1259805ed0a3a5fe9bdeb098a872deb936b)
  FetchContent_MakeAvailable(hipThrust googletest)

  if(NOT DEFINED Eigen3_DIR)
    FetchContent_Declare(
      Eigen3
      GIT_REPOSITORY https://gitlab.com/libeigen/eigen.git
      GIT_TAG 3147391d946bb4b6c68edd901f2add6ac1f31f8c)
    FetchContent_MakeAvailable(googletest Eigen3)
  else()
    find_package(Eigen3 CONFIG REQUIRED)
  endif()
endif()

# ------------------------------------------------------------------------------
# In the case of digestpp, the repository only consists of a list of
# files/directories that we need both our build process to find as well as
# future users of an installed copy of cppsim.
#
# We therefore provide a target that we use for our current build and also
# install its files into a sub-directory of the installation prefix. We then
# define the digestpp::digestpp target directly within cppsimConfig.cmake

FetchContent_Declare(
  digestpp
  GIT_REPOSITORY https://github.com/kerukuro/digestpp.git
  GIT_TAG 4ec4106677e652a90716ad929d657a622089ef16)
FetchContent_MakeAvailable(digestpp)

add_library(digestpp::digestpp INTERFACE IMPORTED)
target_include_directories(digestpp::digestpp
                           INTERFACE $<BUILD_INTERFACE:${digestpp_SOURCE_DIR}>)

install(
  DIRECTORY ${digestpp_SOURCE_DIR}
  DESTINATION ${CPPSIM_INSTALL_INCLUDEDIR}/third_party
  PATTERN docs EXCLUDE
  PATTERN .git EXCLUDE)

# ------------------------------------------------------------------------------

find_package(res_embed QUIET CONFIG)
if(NOT res_embed_FOUND)
  FetchContent_Declare(
    res_embed
    GIT_REPOSITORY https://github.com/dmikushin/res_embed.git
    GIT_TAG b803e4df20b09bdd65477a9662530a6feeb228e6)
  FetchContent_MakeAvailable(res_embed)
endif()
include(ResEmbed)

# ------------------------------------------------------------------------------

find_package(pybind11 CONFIG QUIET)
if(NOT pybind11_FOUND)
  FetchContent_Declare(
    pybind11
    GIT_REPOSITORY https://github.com/pybind/pybind11.git
    GIT_TAG 68e6fdaa90fc93979e6d5d1e9f788f464593e8f2)
  FetchContent_MakeAvailable(pybind11)
endif()

# ------------------------------------------------------------------------------

find_package(Python ${CPPSIM_PYTHON_VERSION_MIN} COMPONENTS Interpreter
                                                            Development.Embed)

# ------------------------------------------------------------------------------

find_package(OpenMP REQUIRED)

# ==============================================================================

include(CMakePackageConfigHelpers)

set(_namespace cppsim::)

configure_package_config_file(
  ${CMAKE_CURRENT_LIST_DIR}/cmake/cppsimConfig.cmake.in
  ${PROJECT_BINARY_DIR}/cppsimConfig.cmake
  INSTALL_DESTINATION ${CPPSIM_INSTALL_CMAKEDIR})

write_basic_package_version_file(${PROJECT_BINARY_DIR}/cppsimConfigVersion.cmake
                                 COMPATIBILITY SameMajorVersion)

install(FILES ${PROJECT_BINARY_DIR}/cppsimConfig.cmake
              ${PROJECT_BINARY_DIR}/cppsimConfigVersion.cmake
        DESTINATION ${CPPSIM_INSTALL_CMAKEDIR})

install(DIRECTORY ${PROJECT_SOURCE_DIR}/cmake/commands
        DESTINATION ${CPPSIM_INSTALL_CMAKEDIR})

file(GLOB _headers ${CMAKE_CURRENT_LIST_DIR}/include/*.h
     ${CMAKE_CURRENT_LIST_DIR}/include/*.hpp LIST_DIRECTORIES FALSE)
install(FILES ${_headers} DESTINATION ${CPPSIM_INSTALL_INCLUDEDIR})
install(
  DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/include/cpu
            ${CMAKE_CURRENT_LIST_DIR}/include/gpu
            ${CMAKE_CURRENT_LIST_DIR}/include/intrin
            ${CMAKE_CURRENT_LIST_DIR}/include/nointrin
  DESTINATION ${CPPSIM_INSTALL_INCLUDEDIR})

# ==============================================================================

add_library(kernelgen STATIC "src/kernelgen.cpp" "src/compiler.cpp"
                             "src/tempfile.cpp")
set_target_properties(kernelgen PROPERTIES CXX_STANDARD 17 CXX_EXTENSIONS OFF)
set_property(TARGET kernelgen PROPERTY POSITION_INDEPENDENT_CODE ON)
target_include_directories(
  kernelgen PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
                   $<INSTALL_INTERFACE:${CPPSIM_INSTALL_INCLUDEDIR}>)
res_embed(
  TARGET
  kernelgen
  NAME
  "nointrin"
  PATH
  "${CMAKE_CURRENT_SOURCE_DIR}/include/nointrin/kernelgen.py"
  KEYWORD)

target_link_libraries(
  kernelgen PUBLIC digestpp::digestpp pybind11::pybind11 Python::Python
                   OpenMP::OpenMP_CXX ${CMAKE_DL_LIBS})

pybind11_add_module(${PROJECT_NAME} SHARED "src/_${PROJECT_NAME}.cpp")
target_link_libraries(${PROJECT_NAME} PRIVATE kernelgen)

# ==============================================================================

install(
  TARGETS kernelgen kernelgen_nointrin
  EXPORT cppsimTargets
  PRIVATE_HEADER DESTINATION ${CPPSIM_INSTALL_INCLUDEDIR}
  PUBLIC_HEADER DESTINATION ${CPPSIM_INSTALL_INCLUDEDIR}
  ARCHIVE DESTINATION ${CPPSIM_INSTALL_LIBDIR}
  LIBRARY DESTINATION ${CPPSIM_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CPPSIM_INSTALL_BINDIR})

install(
  EXPORT cppsimTargets
  NAMESPACE ${_namespace}
  DESTINATION ${CPPSIM_INSTALL_CMAKEDIR})

# ==============================================================================

if(BUILD_TESTING)
  include(kernelgen)

  add_executable(test_nointrin "src/test/test_nointrin.cpp")
  set_target_properties(test_nointrin PROPERTIES CXX_STANDARD 17 CXX_EXTENSIONS
                                                                 OFF)
  target_include_directories(test_nointrin
                             PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
  target_include_directories(test_nointrin PRIVATE Eigen3::Eigen)
  target_link_libraries(test_nointrin PRIVATE gtest kernelgen)
  kernelgen(TARGET test_nointrin NQUBITS 1 VARIANT nointrin)
  kernelgen(TARGET test_nointrin NQUBITS 2 VARIANT nointrin)
  kernelgen(TARGET test_nointrin NQUBITS 3 VARIANT nointrin)
  kernelgen(TARGET test_nointrin NQUBITS 4 VARIANT nointrin)
  kernelgen(TARGET test_nointrin NQUBITS 5 VARIANT nointrin)

  add_executable(test_popcount "src/test/test_popcount.cpp")
  set_target_properties(test_popcount PROPERTIES CXX_STANDARD 17 CXX_EXTENSIONS
                                                                 OFF)
  target_include_directories(test_popcount
                             PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
  target_link_libraries(test_popcount PRIVATE Eigen3::Eigen gtest)

  add_executable(test_combinations "src/test/test_combinations.cpp")
  set_target_properties(test_combinations PROPERTIES CXX_STANDARD 17
                                                     CXX_EXTENSIONS OFF)
  target_include_directories(test_combinations
                             PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
  target_link_libraries(test_combinations PRIVATE gtest Eigen3::Eigen
                                                  OpenMP::OpenMP_CXX)

  add_executable(benchmark "src/benchmark/benchmark.cpp")
  target_link_libraries(benchmark PRIVATE gtest kernelgen)
endif()
