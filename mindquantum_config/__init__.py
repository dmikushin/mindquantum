# -*- coding: utf-8 -*-
#   Copyright 2022 <Huawei Technologies Co., Ltd>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

import argparse
import sys
from pathlib import Path

# ==============================================================================


def get_cmake_dir(as_string=True):
    """
    Return the path to the MindQuantum CMake module directory.

    Args:
        as_string (bool): (optional) If true, returned value is a string, else a pathlib.Path object.
    """
    cmake_installed_path = Path(Path(__file__).parent.parent.resolve(), 'mindquantum', 'share', 'mindquantum', 'cmake')
    if cmake_installed_path.exists():
        if as_string:
            return str(cmake_installed_path)
        return cmake_installed_path

    raise ImportError('MindQuantum not installed, installation required to access the CMake files')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--cmakedir",
        action="store_true",
        help="Print the CMake module directory, ideal for setting -Dmindquantum_ROOT in CMake.",
    )
    args = parser.parse_args()
    if not sys.argv[1:]:
        parser.print_help()
    if args.cmakedir:
        print(get_cmake_dir())


if __name__ == "__main__":
    main()
