#!/bin/bash
# Copyright (c) 2023-2024, NVIDIA CORPORATION

set -euo pipefail

source rapids-configure-sccache

rapids-logger "Install CUDA Toolkit"
source "$(dirname "$0")/install_latest_cuda_toolkit.sh"

RAPIDS_PY_CUDA_SUFFIX="$(rapids-wheel-ctk-name-gen ${RAPIDS_CUDA_VERSION})"

sccache --zero-stats

rapids-logger "Build wheel"
mkdir -p ./dist
python -m pip wheel . --wheel-dir=./dist -v --disable-pip-version-check --no-deps

sccache --show-adv-stats

# Exclude libcuda.so.1 because we only install a driver stub
python -m auditwheel repair --exclude libcuda.so.1 -w ./final_dist ./dist/*

./ci/validate_wheel.sh final_dist

rapids-logger "Upload Wheel"
RAPIDS_PY_WHEEL_NAME="pynvjitlink_${RAPIDS_PY_CUDA_SUFFIX}" rapids-upload-wheels-to-s3 python ./final_dist
