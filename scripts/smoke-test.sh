#!/bin/sh
set -eu

image="${1:-sopel:test}"

docker run --rm --entrypoint /bin/sh "$image" -c 'test "$(id -u)" = 1000 && test "$(id -g)" = 1000'
docker run --rm "$image" --version | grep -q '8.0.4'
docker run --rm --entrypoint /bin/sh "$image" -c 'command -v sopel && command -v sopel-config && command -v sopel-plugins'

name="sopel-smoke-$$"
tmp="$(mktemp -d)"
trap 'docker rm -f "$name" >/dev/null 2>&1 || true; rm -rf "$tmp"' EXIT INT TERM

docker run -d --name "$name" -v "$tmp:/data" "$image" >/dev/null
sleep 2
test "$(docker inspect -f '{{.State.Running}}' "$name")" = true
health="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$name")"
case "$health" in
  unhealthy|starting) : ;;
  *) echo "unexpected health status for unconfigured container: $health" >&2; exit 1 ;;
esac

docker logs "$name" 2>&1 | grep -q 'not configured yet'

echo 'smoke test: PASS'
