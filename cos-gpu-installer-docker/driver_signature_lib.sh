#!/bin/bash
#
# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


GPU_DRIVER_SIGNATURE="gpu-driver-signature.tar.gz"
GPU_PRECOMPILED_DRIVER_SIGNATURE="gpu-precompiled-driver-signature.tar.gz"
GPU_DRIVER_PUBLIC_KEY_PEM="gpu-driver-cert.pem"
GPU_DRIVER_PUBLIC_KEY_DER="gpu-driver-cert.der"
GPU_DRIVER_PRIVATE_KEY="dummy-key"
GPU_DRIVER_SIGNING_DIR="/build/sign-gpu-driver"

download_helper() {
  local -r gcs_bucket="$1"
  local -r build_id="$2"
  local -r filename="$3"
  local -r download_url="${gcs_bucket}/${build_id}/${filename}"
  local -r output_path="${GPU_DRIVER_SIGNING_DIR}/${filename}"

  download_content_from_url "${download_url}" "${output_path}" "${filename}"
}

download_driver_signature() {
  local -r gcs_bucket="$1"
  local -r build_id="$2"
  if [[ ! -d "${GPU_DRIVER_SIGNING_DIR}" ]]; then
    mkdir -p "${GPU_DRIVER_SIGNING_DIR}"
  fi

  # Try to Download GPU driver signature. If fail then return immediately to
  # reduce latency because in such case precompiled GPU driver signature must
  # not exist.
  download_helper "${gcs_bucket}" "${build_id}" "${GPU_DRIVER_SIGNATURE}" || return 0
  # Try to download precompiled GPU driver signature
  download_helper "${gcs_bucket}" "${build_id}" "${GPU_PRECOMPILED_DRIVER_SIGNATURE}" || true
}

has_driver_signature() {
  [[ -f "${GPU_DRIVER_SIGNING_DIR}/${GPU_DRIVER_SIGNATURE}" ]] || return $?
}

has_precompiled_driver_signature() {
  [[ -f "${GPU_DRIVER_SIGNING_DIR}/${GPU_PRECOMPILED_DRIVER_SIGNATURE}" ]] || return $?
}

decompress_driver_signature() {
  if ! has_driver_signature && ! has_precompiled_driver_signature; then
    return 1
  fi

  pushd "${GPU_DRIVER_SIGNING_DIR}" || return 1
  if has_precompiled_driver_signature; then
    tar xzf "${GPU_PRECOMPILED_DRIVER_SIGNATURE}"
  elif has_driver_signature; then
    tar xzf "${GPU_DRIVER_SIGNATURE}"
  fi
  popd || return 1

  # Create a dummy private key. We don't need private key to sign the driver
  # because we already have the signature.
  touch "${GPU_DRIVER_SIGNING_DIR}/${GPU_DRIVER_PRIVATE_KEY}"
}

get_private_key() {
  echo "${GPU_DRIVER_SIGNING_DIR}/${GPU_DRIVER_PRIVATE_KEY}"
}

get_public_key_pem() {
  echo "${GPU_DRIVER_SIGNING_DIR}/${GPU_DRIVER_PUBLIC_KEY_PEM}"
}

load_public_key() {
  info "Loading GPU driver public key to system keyring."
  /bin/keyctl padd asymmetric "gpu_key" \
    %keyring:.secondary_trusted_keys < \
    "${GPU_DRIVER_SIGNING_DIR}/${GPU_DRIVER_PUBLIC_KEY_DER}"
}
