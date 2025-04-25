#!/usr/bin/env bash
set -e

docker network create exo-net 2>/dev/null || true

for i in 1 2 3; do
  HTTP_PORT=$((52414 + i))     # 52415, 52416, 52417
  GRPC_PORT=$((50050 + i))     # 50051, 50052, 50053
  ALIAS="exo${i}"

  docker run -d \
    --name $ALIAS \
    --network exo-net \
    --network-alias $ALIAS \
    -v ~/.cache/exo:/root/.cache/exo:rw \
    -p ${HTTP_PORT}:52415 \
    exo-debian-jit:latest \
    /opt/exo/bin/exo \
      --disable-tui \
      --node-port ${GRPC_PORT}
done

echo "Launched 2 Exo nodes on exo-net via UDP discovery."