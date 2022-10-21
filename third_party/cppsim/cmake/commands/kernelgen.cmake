# ~~~
# Generate some kernel functions
#
# kernelgen([NQUBITS <n_qubits>]
#           [VARIANT <intrin>|<nointrin>]
#           [TARGET <target-name>]
# )
# ~~~
macro(kernelgen)
  set(oneValueArgs NQUBITS VARIANT TARGET)
  cmake_parse_arguments(KERNELGEN "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  set(NQUBITS ${KERNELGEN_NQUBITS})
  set(VARIANT ${KERNELGEN_VARIANT})
  if(NOT DEFINED CPPSIM_INCLUDE_DIR)
    set(CPPSIM_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/include)
  endif()
  set(KERNELGEN "${CPPSIM_INCLUDE_DIR}/${VARIANT}/kernelgen.py")
  set(KERNEL_PATH
      "${CMAKE_CURRENT_BINARY_DIR}/generated/${VARIANT}/kernel${NQUBITS}.hpp")

  # Call generator.
  add_custom_command(
    OUTPUT ${KERNEL_PATH}
    COMMAND ${Python_EXECUTABLE} ${KERNELGEN} ${NQUBITS} ${KERNEL_PATH}
            --combinations=True
    COMMENT "Generating kernel for ${NQUBITS} qubits"
    DEPENDS ${KERNELGEN})
  set_source_files_properties("${KERNEL_PATH}" PROPERTIES GENERATED TRUE)

  # Append the generated file to the target sources.
  target_sources(${KERNELGEN_TARGET} PRIVATE ${KERNEL_PATH})
  target_include_directories(${KERNELGEN_TARGET}
                             PRIVATE ${CMAKE_CURRENT_BINARY_DIR})
endmacro()
