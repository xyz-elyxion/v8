FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    --no-install-recommends \
    -o Acquire::Retries=5 \
    git \
    python3 \
    python3-pip \
    build-essential \
    ninja-build \
    clang \
    lld \
    pkg-config \
    ca-certificates \
    curl \
    wget \
    xz-utils \
    file \
    unzip \
    && rm -rf /var/lib/apt/lists/*


# Install Google's depot_tools
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git /depot_tools

ENV PATH="/depot_tools:$PATH"


# Initialize depot_tools
RUN gclient --version
RUN update_depot_tools


# Source directory
WORKDIR /src


# Download V8 source
RUN fetch --nohooks v8


WORKDIR /src/v8


# Download dependencies
RUN gclient sync --no-history


# Create build directory
RUN mkdir -p out.gn/x64.release


# Configure V8
RUN printf "is_component_build = true\nv8_monolithic = false\nv8_use_external_startup_data = false\nis_debug = false\nsymbol_level = 0\n" > out.gn/x64.release/args.gn


# Generate build files
RUN gn gen out.gn/x64.release


# Compile V8
RUN ninja -C out.gn/x64.release


# Create output folders
RUN mkdir -p /output/include
RUN mkdir -p /output/lib


# Copy headers
RUN cp -r include/* /output/include/


# Copy libraries
RUN cp out.gn/x64.release/*.so /output/lib/ || true
RUN cp out.gn/x64.release/*.a /output/lib/ || true


# Copy d8 shell
RUN cp out.gn/x64.release/d8 /output/ || true


WORKDIR /output


CMD ["bash"]