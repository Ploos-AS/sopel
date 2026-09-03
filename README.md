# Sopel container

Production-oriented OCI image for [Sopel](https://sopel.chat/), maintained by Ploos AS.

## Image

```text
ghcr.io/ploos-as/sopel:edge
```

Release tags use semantic container versions such as `0.1.0`.

The image currently pins Sopel `8.0.4`, the latest stable upstream release at the time of packaging.

## Highlights

- Docker and Podman friendly
- `linux/amd64` and `linux/arm64`
- non-root runtime (`1000:1000`)
- persistent `/data` configuration/state directory
- `tini` as PID 1
- first-run configuration workflow
- explicit configuration selection through `SOPEL_CONFIG`
- runtime healthcheck
- Docker Compose example
- Podman Quadlet example
- GHCR publishing with SBOM and provenance

## Quick start

Create persistent storage:

```bash
mkdir -p data
```

Run the interactive Sopel configuration wizard:

```bash
docker run --rm -it \
  -v "$PWD/data:/data" \
  ghcr.io/ploos-as/sopel:edge configure
```

Then start the bot:

```bash
docker run -d \
  --name sopel \
  --restart unless-stopped \
  -v "$PWD/data:/data" \
  ghcr.io/ploos-as/sopel:edge
```

Or use Compose:

```bash
docker compose up -d
```

Sopel normally writes its config to `~/.sopel/default.cfg`; this image instead sets `SOPEL_CONFIG_DIR=/data`, so configuration, the default SQLite database, and related runtime state can be persisted together.

## Configuration

The default configuration is `default.cfg`. Select another config with:

```yaml
environment:
  SOPEL_CONFIG: mybot.cfg
```

The entrypoint also auto-selects the only top-level `*.cfg` in `/data` when exactly one exists.

If no configuration exists, the container stays alive in an unconfigured state and reports unhealthy instead of crash-looping. Run the `configure` command, then restart the service.

Useful commands:

```bash
# Interactive configuration wizard
docker compose run --rm sopel configure

# Shell
docker compose run --rm sopel shell

# Show Sopel version
docker compose run --rm sopel --version

# List plugins
docker compose run --rm sopel sopel-plugins list --config-dir /data
```

## Plugins

Sopel supports built-in plugins, Python package plugins, and additional plugin paths. This image intentionally does not bundle arbitrary third-party plugins. That keeps the base image predictable and reduces supply-chain surface.

For custom deployments, derive a small image and install the required plugin packages at build time. File-based plugins can also be persisted under `/data` and referenced through Sopel's `core.extra` configuration.

## Podman Quadlet

An example is provided at `quadlet/sopel.container`. It stores data at:

```text
%h/.local/share/sopel
```

Install it with:

```bash
mkdir -p ~/.config/containers/systemd ~/.local/share/sopel
cp quadlet/sopel.container ~/.config/containers/systemd/
systemctl --user daemon-reload
systemctl --user enable --now sopel.service
```

## Health

The healthcheck is intentionally strict:

- running Sopel process: healthy
- container waiting for first-run configuration: unhealthy
- configured bot process exited: unhealthy

This prevents an unconfigured but idle container from being mistaken for a working IRC bot.

## Reproducibility

The container pins the upstream Sopel package version (`8.0.4`). Transitive Python dependencies are resolved during image build and are not fully lock-file pinned, so builds are source-version pinned but not byte-for-byte reproducible.

## Upstream

Sopel is an independent upstream project. This container packaging is maintained by Ploos AS and is not an official Sopel project image.

- Upstream project: https://sopel.chat/
- Upstream source: https://github.com/sopel-irc/sopel

## License

Container packaging in this repository is MIT licensed. Sopel itself is distributed under its own upstream license; see `NOTICE`.
