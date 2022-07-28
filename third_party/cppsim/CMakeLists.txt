cmake_minimum_required(VERSION 3.12 FATAL_ERROR)

project(ProjectQGen)

find_package(Python3 COMPONENTS Interpreter)

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
target_include_directories(test_nointrin PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
kernelgen(TARGET test_nointrin NQUBITS 1 VARIANT nointrin)
kernelgen(TARGET test_nointrin NQUBITS 2 VARIANT nointrin)
kernelgen(TARGET test_nointrin NQUBITS 3 VARIANT nointrin)
kernelgen(TARGET test_nointrin NQUBITS 4 VARIANT nointrin)
kernelgen(TARGET test_nointrin NQUBITS 5 VARIANT nointrin)
