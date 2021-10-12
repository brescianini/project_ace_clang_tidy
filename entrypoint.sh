#!/bin/bash

set -e
env

project_name=$(basename `git rev-parse --show-toplevel`)

# Determine the version of clang-tidy:
if [ "$INPUT_VERSION" == 10 ] ; then
  clang_binary="clang-tidy"
  clang_replacement_binary="clang-apply-replacements"
elif [ "$INPUT_VERSION" == 12 ] ; then
  clang_binary="clang-tidy-12"
  clang_replacement_binary="clang-apply-replacements-12"
else
  echo "Expected version 10 or 12 but got $INPUT_VERSION"
  exit 1
fi

mkdir -p ~/ROS2/"$project_name"_ws/
cd "$GITHUB_WORKSPACE"

# Move all files inside  ~/ROS2/"$project_name"_ws/src
rsync -aq --remove-source-files src ~/ROS2/"$project_name"_ws/

# Determine the version of clang-tidy:
if [ "$INPUT_VERSION" == 10 ] ; then
  clang_binary="clang-tidy"
  clang_replacement_binary="clang-apply-replacements"
  echo "Selected clang tidy v10"
elif [ "$INPUT_VERSION" == 12 ] ; then
  clang_binary="clang-tidy-12"
  echo "Selected clang tidy v12"
  clang_replacement_binary="clang-apply-replacements-12"
else
  echo "$INPUT_VERSION"
  printf "Expected version 10 or 12 but got %s" "$INPUT_VERSION" >&2  # write error message to stderr
  exit 1
fi

# Compile and source workspace packages
cd ~/ROS2/"$project_name"_ws/
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DBUILD_TESTING=OFF


# Read list of ignored directories
ignored_paths=()
while IFS= read -r line; do if [[ ${line::1} != "#" ]] ; then ignored_paths+=("$line"); fi; done < .clang-tidy-ignore
echo "These directories will be ignored:"
for path in "${ignored_paths[@]}"; do echo "$path"; done

all_passed=true

echo "Running script"
cp "$GITHUB_WORKSPACE"/.clang-tidy .
cp "$GITHUB_WORKSPACE"/.clang-tidy-ignore .
mv /run-clang-tidy.py .
time python3 run-clang-tidy.py -p build \
                               -directory src \
                               -ignored-paths "${ignored_paths[@]}" \
                               -clang-tidy-binary "$clang_binary" \
                               -clang-apply-replacements-binary "$clang_replacement_binary"

retval=$?
if [ $retval -ne 0 ]; then
    all_passed=false
fi

if [ "$all_passed" = false ]; then
    echo "Fixes in files required. Exiting"
    exit 1
else
    echo "Clang-tidy did not detect any problem"
    git diff --exit-code
fi