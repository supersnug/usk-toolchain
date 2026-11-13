FROM ubuntu:jammy-20240808@sha256:075680e983398fda61b1ac59ad733ad81d18df4bc46411666bb8a03fb9ea0195

LABEL org.opencontainers.image.source="https://github.com/supersnug/usk-toolchain" \
      org.opencontainers.image.description="Frozen build tools for the USK 2.80 snapshot"

ENV DEBIAN_FRONTEND=noninteractive

# The base image has no CA bundle. Supply one as a build secret only for
# authenticated HTTPS installation; APT package signatures remain checked.
RUN --mount=type=secret,id=bootstrap_ca,required=true \
    printf '%s\n' \
      'deb [check-valid-until=no] https://snapshot.ubuntu.com/ubuntu/20240904T041204Z jammy main universe' \
      'deb [check-valid-until=no] https://snapshot.ubuntu.com/ubuntu/20240904T041204Z jammy-updates main universe' \
      'deb [check-valid-until=no] https://snapshot.ubuntu.com/ubuntu/20240904T041204Z jammy-security main universe' \
      > /etc/apt/sources.list \
    && apt-get -o Acquire::https::CaInfo=/run/secrets/bootstrap_ca \
      -o APT::Update::Error-Mode=any update \
    && apt-get -o Acquire::https::CaInfo=/run/secrets/bootstrap_ca install -y \
      gcc-arm-none-eabi libnewlib-arm-none-eabi build-essential \
      ca-certificates curl git python3 \
    && rm -rf /var/lib/apt/lists/*

# Match the CMake version listed in the release-time Ubuntu runner manifest.
RUN curl --fail --location --retry 3 \
      https://github.com/Kitware/CMake/releases/download/v3.30.2/cmake-3.30.2-linux-x86_64.tar.gz \
      --output /tmp/cmake.tar.gz \
    && printf '%s  %s\n' \
      cdd7fb352605cee3ae53b0e18b5929b642900e33d6b0173e19f6d4f2067ebf16 \
      /tmp/cmake.tar.gz | sha256sum --check \
    && mkdir -p /opt/cmake \
    && tar -xzf /tmp/cmake.tar.gz -C /opt/cmake --strip-components=1 \
    && rm /tmp/cmake.tar.gz

ENV PATH="/opt/cmake/bin:${PATH}"

RUN cmake --version \
    && arm-none-eabi-gcc --version \
    && gcc --version \
    && python3 --version \
    && make --version \
    && git --version

WORKDIR /workspace
CMD ["bash"]
