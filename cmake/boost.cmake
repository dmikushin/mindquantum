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

# NB: code in this file assumes Boost >= 1.69

find_package(Boost ${_boost_version} REQUIRED COMPONENTS ${_boost_components})

get_target_property(_headers_path Boost::boost INTERFACE_INCLUDE_DIRECTORIES)
if(NOT _header_path)
  if(TARGET Boost::headers)
    get_target_property(_tmp Boost::headers INTERFACE_INCLUDE_DIRECTORIES)
    set_property(
      TARGET Boost::boost
      APPEND
      PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${_tmp})
  else()
    get_target_property(_tmp Boost::program_options INTERFACE_INCLUDE_DIRECTORIES)
    set_property(
      TARGET Boost::boost
      APPEND
      PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${_tmp})
  endif()
endif()

# ------------------------------------------------------------------------------
# Disable Boost auto-link feature

if(WIN32)
  add_compile_definitions(BOOST_ALL_NO_LIB BOOST_ALL_DYN_LINK)
endif()

# ------------------------------------------------------------------------------
# In some cases where the Boost version is too recent compared to what the CMake version supports, the imported target
# are not properly defined. In this case, try our best to define the target properly and warn the user

if(Boost_FOUND)
  # cmake-lint: disable=C0103

  set(_BOOST_HAS_IMPORTED_TGT TRUE)
  # Starting Boost 1.69, Boost::system not required anymore
  set(Boost_THREAD_DEPENDENCIES chrono date_time atomic)

  foreach(comp ${_Boost_COMPONENTS_SEARCHED})
    if(NOT TARGET Boost::${comp})
      set(_BOOST_HAS_IMPORTED_TGT FALSE)
      define_target(Boost ${comp} "${Boost_INCLUDE_DIR}")
    endif()
  endforeach()

  if(NOT _BOOST_HAS_IMPORTED_TGT)
    message(
      WARNING "Your version of Boost (${Boost_MAJOR_VERSION}.${Boost_MINOR_VERSION}."
              "${Boost_SUBMINOR_VERSION}) is too recent for this version"
              " of CMake."
              "\nThe imported target have been defined manually, but the dependencies "
              " might not be correct. If compilation fails, please try updating your"
              " CMake installation to a newer version (for your information, your "
              "CMake version is ${CMAKE_VERSION}).")
  endif()
endif()

# ==============================================================================
