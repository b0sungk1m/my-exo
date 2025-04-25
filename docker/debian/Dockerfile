# Run this Docker file from exo root directory with:
# docker build . -f ./docker/debian/Dockerfile -t exo-debian:latest --no-cache --progress=plain

# --------------------------
# Step 1 : Build sources
# --------------------------

    FROM debian:bookworm-20250224-slim AS builder

    # Install build tools + dependencies for llvmlite and MLX engine
    RUN apt-get update \
        && apt-get install -y --no-install-recommends \
            python-is-python3 python3-pip python3-venv python3-dev git build-essential cmake ninja-build \
            libdrm-dev llvm-dev libffi-dev clang binutils \
        && rm -rf /var/lib/apt/lists/*
    
    WORKDIR /app
    
    # Create and activate virtualenv
    RUN python3 -m venv /opt/exo
    ENV PATH="/opt/exo/bin:$PATH"
    
    # Copy source code
    COPY . .
    
    # Upgrade pip tools and install llvmlite for LLVM JIT
    RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
        && pip install --no-cache-dir llvmlite
    
    # Install exo and build MLX extension via pip
    RUN pip install --no-cache-dir .
    
    # Patch tinygrad clang ops for optimal CPU flags
    RUN find /opt/exo/lib -type f -name ops_clang.py -exec sed -i \
          -e 's/\["-march=native"\]/["-mcpu=native"]/g' \
          -e 's/-march=native/-mcpu=native/g' \
          -e 's/--target=\([a-z0-9_-]*\)-none-unknown-elf/--target=\1-linux-gnu/g' \
          {} +
    
    # --------------------------
    # Step 2 : Build final image
    # --------------------------
    
    FROM debian:bookworm-20250224-slim AS target
    
    # Install runtime deps, clang, and tools for MLX backend
    RUN apt-get update \
        && apt-get install -y --no-install-recommends \
            python-is-python3 libgl1 libglib2.0-dev uuid-runtime ca-certificates \
            clang binutils gcc libc6-dev linux-libc-dev libffi8 llvm libstdc++6 \
            cmake ninja-build \
        && rm -rf /var/lib/apt/lists/*
    
    # Copy the built exo virtualenv
    COPY --from=builder /opt/exo /opt/exo
    ENV PATH="/opt/exo/bin:$PATH"
    
    # Default to the MLX high-performance CPU engine
    ENV EXO_INFERENCE_ENGINE=mlx
    
    # Run inference server explicitly with run subcommand and model
    CMD ["sh", "-c", "/opt/exo/bin/exo run llama-3.2-1b --disable-tui --node-port ${NODE_PORT:-50051}"]
    