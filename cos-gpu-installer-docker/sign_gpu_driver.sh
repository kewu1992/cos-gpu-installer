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

check_file_exist() {
  if [[ ! -f ${1} ]]; then
    exit 1
  fi
}

sign_gpu_driver() {
  local -r hash_algo="$1"
  # private key is a dummy key.
  #local -r priv_key="$2"
  local -r pub_key="$3"
  local -r module="$4"
  local -r sign_file="$(dirname "${pub_key}")"/sign-file
  local -r signature="$(dirname "${pub_key}")/$(basename "${module}")".sig

  check_file_exist "${pub_key}"
  check_file_exist "${module}"
  check_file_exist "${sign_file}"
  check_file_exist "${signature}"

  chmod +x "${sign_file}"

  "${sign_file}" -s "${signature}" "${hash_algo}" "${pub_key}" "${module}"
}

sign_gpu_driver "$@"
