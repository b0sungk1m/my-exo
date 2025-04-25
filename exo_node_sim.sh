#!/usr/bin/env bash
set -euo pipefail

# Usage message
usage() {
  cat <<EOF >&2
Usage: $0 <docker_image> <num_nodes>

  <docker_image>  : The exo Docker image (e.g. exo-debian-jit:latest)
  <num_nodes>     : Number of Exo nodes to spawn (positive integer)

Example:
  $0 exo-debian-jit:latest 3
EOF
  exit 1
}

# Validate args
if [ $# -ne 2 ]; then
  usage
fi

IMAGE="$1"
NUM_NODES="$2"

if ! [[ "$NUM_NODES" =~ ^[0-9]+$ && "$NUM_NODES" -ge 1 ]]; then
  echo "Error: <num_nodes> must be a positive integer." >&2
  usage
fi

# Create network if needed
docker network create exo-net >/dev/null 2>&1 || true

# Launch the nodes
for (( i=1; i<=NUM_NODES; i++ )); do
  HTTP_PORT=$((52414 + i))   # maps container’s 52415 → host 52414+i
  GRPC_PORT=$((50050 + i))   # node-port inside container

  ALIAS="exo${i}"

  echo "Launching node $i → alias=$ALIAS, HTTP=${HTTP_PORT}, GRPC=${GRPC_PORT}"
  docker run -d \
    --name "${ALIAS}" \
    --network exo-net \
    --network-alias "${ALIAS}" \
    -v "${HOME}/.cache/exo:/root/.cache/exo:rw" \
    -p "${HTTP_PORT}:52415" \
    "${IMAGE}" \
      /opt/exo/bin/exo \
        --disable-tui \
        --node-port "${GRPC_PORT}"
done

echo "Launched ${NUM_NODES} Exo node(s) on network 'exo-net'."