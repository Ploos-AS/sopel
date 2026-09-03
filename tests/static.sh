#!/bin/sh
set -eu

required='Dockerfile README.md LICENSE NOTICE VERSION compose.yaml quadlet/sopel.container rootfs/usr/local/bin/entrypoint rootfs/usr/local/bin/healthcheck scripts/smoke-test.sh'
for f in $required; do
  test -s "$f"
done

grep -q 'USER 1000:1000' Dockerfile
grep -q 'VOLUME \["/data"\]' Dockerfile
grep -q 'SOPEL_VERSION=8.0.4' Dockerfile
grep -q 'linux/amd64,linux/arm64' .github/workflows/container.yml
sh -n rootfs/usr/local/bin/entrypoint
sh -n rootfs/usr/local/bin/healthcheck
sh -n scripts/smoke-test.sh

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  docker compose config >/dev/null
fi

echo 'static validation: PASS'
