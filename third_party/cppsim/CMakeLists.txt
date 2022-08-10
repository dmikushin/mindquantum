cmake_minimum_required(VERSION 3.12 FATAL_ERROR)

project(_cppsim)

add_subdirectory(ThirdParty/googletest EXCLUDE_FROM_ALL)

add_subdirectory(ThirdParty/res_embed EXCLUDE_FROM_ALL)

add_subdirectory(ThirdParty/pybind11 EXCLUDE_FROM_ALL)

find_package(Python3 COMPONENTS Interpreter)

include(ResEmbed)

pybind11_add_module(${PROJECT_NAME} SHARED "src/${PROJECT_NAME}.cpp")
target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
res_embed(TARGET ${PROJECT_NAME} NAME "nointrin" PATH "${CMAKE_CURRENT_SOURCE_DIR}/include/nointrin/kernelgen.py" KEYWORD)

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
		COMMAND ${Python3_EXECUTABLE} ${KERNELGEN} ${NQUBITS} ${KERNEL_PATH}
		COMMENT "Generating kernel for ${NQUBITS} qubits"
		DEPENDS ${KERNELGEN})
	set_source_files_properties("${KERNEL_PATH}" PROPERTIES GENERATED TRUE)

	# Append the generated file to the target sources.
	target_sources(${KERNELGEN_TARGET} PRIVATE ${KERNEL_PATH})
	target_include_directories(${KERNELGEN_TARGET} PRIVATE ${CMAKE_CURRENT_BINARY_DIR})
endmacro()

add_executable(test_nointrin "src/test/test_nointrin.cpp")
set_target_properties(test_nointrin PROPERTIES CXX_STANDARD 17 CXX_EXTENSIONS OFF)
target_include_directories(test_nointrin PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
target_link_libraries(test_nointrin PRIVATE gtest)
kernelgen(TARGET test_nointrin NQUBITS 1 VARIANT nointrin)
kernelgen(TARGET test_nointrin NQUBITS 2 VARIANT nointrin)
kernelgen(TARGET test_nointrin NQUBITS 3 VARIANT nointrin)
kernelgen(TARGET test_nointrin NQUBITS 4 VARIANT nointrin)
kernelgen(TARGET test_nointrin NQUBITS 5 VARIANT nointrin)

