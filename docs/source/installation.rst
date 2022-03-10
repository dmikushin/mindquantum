.. Copyright 2022 <Huawei Technologies Co., Ltd>

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

.. _installation:

Requirements
============

.. toctree::
   :maxdepth: 2

In order to get started with MindQuantum, you will need to have a C++ compiler installed on your system as well as a few libraries and programs:

    - CMake >= 3.18

Below you will find detailed installation instructions for various operating systems. If you have the dependencies already installed, you can directly skip to :ref:`mindquantum_installation`.

Pre-requisite installation
==========================

Here you will find detailed installation instructions for various operating systems.

Linux
-----

Ubuntu/Debian
+++++++++++++

After having installed the build tools (for g++):

.. code-block:: bash

   sudo apt-get install build-essential

You only need to install Python (and the package manager). For version 3, run

.. code-block:: bash

   sudo apt-get install python3-dev python3-pip


Then install the rest of the required libraries using the following command:

.. code-block:: bash

   sudo apt-get install cmake

ArchLinux/Manjaro
+++++++++++++++++

Make sure that you have a C/C++ compiler installed:

.. code-block:: bash

   sudo pacman -Syu gcc

You only need to install Python (and the package manager). For version 3, run

.. code-block:: bash

   sudo pacman -Syu python python-pip

Then install the rest of the required libraries using the following command:

.. code-block:: bash

   sudo pacman -Syu cmake


CentOS 7
++++++++

Run the following commands:

.. code-block:: bash

   sudo yum install -y epel-release
   sudo yum install -y centos-release-scl
   sudo yum install -y devtoolset-8
   sudo yum check-update -y

   scl enable devtoolset-8 bash
   sudo yum install -y gcc-c++ make git cmake3
   sudo yum install -y python3 python3-devel python3-pip

   sudo alternatives --install /usr/local/bin/cmake cmake /usr/bin/cmake3 20 \
    --slave /usr/local/bin/ctest ctest /usr/bin/ctest3 \
    --slave /usr/local/bin/cpack cpack /usr/bin/cpack3 \
    --slave /usr/local/bin/ccmake ccmake /usr/bin/ccmake3 \
    --family cmake

CentOS 8
++++++++

Run the following commands:

.. code-block:: bash

   sudo dnf config-manager --set-enabled PowerTools
   sudo yum install -y epel-release
   sudo yum check-update -y

   sudo yum install -y gcc-c++ make git
   sudo yum install -y python3 python3-devel python3-pip

   pversion=3.17.3
   package=cmake
   wget https://github.com/Kitware/CMake/releases/download/v${pversion}/${package}-${pversion}-Linux-x86_64.tar.gz
   gunzip -c ${package}-${pversion}-Linux-x86_64.tar.gz | tar -xf -
   /bin/rm ${package}-${pversion}-Linux-x86_64.tar.gz
   /bin/mv -vrf ${package}-${pversion}-Linux-x86_64/bin/* /usr/local/bin
   /bin/mv -vrf ${package}-${pversion}-Linux-x86_64/share/* /usr/local/share
   /bin/mv -vrf ${package}-${pversion}-Linux-x86_64/doc/* /usr/local/doc
   /bin/mv -vrf ${package}-${pversion}-Linux-x86_64/man/* /usr/local/man
   /bin/rm -r ${package}-${pversion}-Linux-x86_64


Mac OS
------

We require that a C++ compiler is installed on your system. There are two options you can choose from:

   1. Using Homebrew
   2. Using MacPorts


Before moving on, install the XCode command line tools by opening a terminal window and running the following command:

.. code-block:: bash

   xcode-select --install

Homebrew
++++++++

Install Homebrew with the following command:

.. code-block:: bash

   /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

Then proceed to install Python as well as a C++ compiler (note: gcc installed via Homebrew may lead to some issues therefore we choose clang):

.. code-block:: bash

   brew install python llvm

Then install the rest of the required libraries/programs using the following command:

.. code-block:: bash

   sudo port install cmake


MacPorts
++++++++

Visit `macports.org <https://www.macports.org/install.php>`_ and install the latest version that corresponds to your operating system's version. Afterwards, open a new terminal window.

Then, use macports to install Python 3.8 with pip by entering the following command

.. code-block:: bash

   sudo port install python38 py38-pip

A warning might show up about using Python from the terminal.In this case, you should also install

.. code-block:: bash

   sudo port install py38-gnureadline

Then install the rest of the required libraries/programs and a C++ compiler using the following command:

.. code-block:: bash

   sudo port install cmake clang-9.0


Windows
-------

On Windows, we only support installing the some of the dependencies using the `Chocolatey package manager <https://chocolatey.org/>`_. Unfortunately, not all the required libraries can be installed using Chocolatey at the time of this writing. However, we provide some pre-compiled binaries at https://github.com/Huawei-HiQ/windows-binaries/releases/

In the following, all the commands are to be run from within a PowerShell window. In some cases, you might need to run PowerShell as administrator.

Chocolatey
++++++++++

First install Chocolatey using the installer following the instructions on their `website <https://chocolatey.org/docs/installation>`_. Once that is done, you can start by installing some of the required packages. Reboot as needed during the process.

.. code-block:: powershell

   choco install -y visualstudio2019-workload-vctools --includeOptional
   choco install -y windows-sdk-10-version-2004-all
   choco install -y cmake git

Python
++++++

Installing Python is as simply as running the following commands:

.. code-block:: powershell

   choco install -y python3 --version 3.8.3
   cmd /c mklink "C:\Python38\python3.exe" "C:\Python38\python.exe"

.. _mindquantum_installation:

Installation of MindQuantum
============================

The latest version of MindQuantum can be found on Pypi:
https://pypi.org/project/mindquantum/. In order to start using MindQuantum,
simply run the following command

.. code-block:: bash

    python -m pip install --user mindquantum

or, alternatively, `clone/download <https://github.com/Huawei-HiQ/HiQSimulator>`_ this repo (e.g., to your /home directory) and run

.. code-block:: bash

    cd /home/mindquantum
    python -m pip install --user .

.. note::

   Make sure you also clone the repository's **submodules**

   .. code-block:: bash

      git clone --recurse-submodules -j4 "URL to repository" mindquantum


Mac OS
------

On Mac OS, you might want to specify the compiler explicitely so that you benefit from all the functionalities.

Homebrew
++++++++

Run the following command:

.. code-block::

   env CC=/usr/local/opt/llvm/bin/clang \
   CXX=/usr/local/opt/llvm/bin/clang++ \
   python3 -m pip install --user mindquantum

MacPorts
++++++++

Run the following command:

.. code-block::

   env CC=clang-mp-9.0 CXX=clang++-mp-9.0 \
   python3 -m pip install --user mindquantum
