# Copyright 2017 Google LLC
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
#
# Dockerfile for the COS Module Builder container.

# Build openssl_tpm2_engine
FROM ubuntu:18.04
RUN apt-get update -qq && \
    apt-get install -y wget autoconf automake libtool libssl-dev pkg-config \
      tss2 libtss0 libtss-dev help2man
RUN wget https://git.kernel.org/pub/scm/linux/kernel/git/jejb/openssl_tpm2_engine.git/snapshot/openssl_tpm2_engine-1.2.0.tar.gz
RUN tar -xzf openssl_tpm2_engine-1.2.0.tar.gz
WORKDIR openssl_tpm2_engine-1.2.0
RUN chmod +x bootstrap.sh
RUN ./bootstrap.sh
RUN ./configure LIBS=-l:libtss.so.0
RUN make
RUN make install


FROM ubuntu:18.04
LABEL maintainer="cos-containers@google.com"

# Install minimal tools needed to build and sign kernel modules.
RUN apt-get update -qq && \
    apt-get install -y xz-utils python2.7-minimal kmod git make bc curl ccache \
      libc6-dev pciutils gcc libelf-dev libssl-dev tss2 && \
    rm -rf /var/lib/apt/lists/*

# Download & install prebuild COS toolchain package, and prepare the environment for cross-compiling.
RUN cd /usr/bin && ln -s python2.7 python && ln -s python2.7 python2

COPY --from=0 /usr/local/bin/create_tpm2_key /usr/local/bin/create_tpm2_key
COPY --from=0 /usr/lib/x86_64-linux-gnu/engines-1.1/libtpm2.so /usr/lib/x86_64-linux-gnu/engines-1.1/libtpm2.so
COPY --from=0 /usr/lib/x86_64-linux-gnu/engines-1.1/libtpm2.la /usr/lib/x86_64-linux-gnu/engines-1.1/libtpm2.la
COPY README.container /README
COPY x509.genkey /x509.genkey
COPY openssl.cnf /openssl.cnf
COPY entrypoint.sh /entrypoint.sh
CMD /entrypoint.sh
