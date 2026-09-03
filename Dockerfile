# syntax=docker/dockerfile:1.7

ARG PYTHON_VERSION=3.12
ARG SOPEL_VERSION=8.0.4

FROM python:${PYTHON_VERSION}-slim-bookworm AS builder
ARG SOPEL_VERSION

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    VIRTUAL_ENV=/opt/sopel/venv

RUN python -m venv "$VIRTUAL_ENV" \
    && "$VIRTUAL_ENV/bin/python" -m pip install --upgrade pip wheel \
    && "$VIRTUAL_ENV/bin/python" -m pip install "sopel==${SOPEL_VERSION}" \
    && "$VIRTUAL_ENV/bin/sopel" --version

FROM python:${PYTHON_VERSION}-slim-bookworm

ARG VERSION=0.1.0
ARG SOPEL_VERSION=8.0.4

LABEL org.opencontainers.image.title="Sopel" \
      org.opencontainers.image.description="Production-oriented OCI image for the Sopel IRC bot" \
      org.opencontainers.image.url="https://github.com/Ploos-AS/sopel" \
      org.opencontainers.image.source="https://github.com/Ploos-AS/sopel" \
      org.opencontainers.image.documentation="https://github.com/Ploos-AS/sopel#readme" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.licenses="MIT AND EFL-2.0" \
      io.ploos.sopel.upstream.version="${SOPEL_VERSION}" \
      io.ploos.sopel.upstream.commit="78e4a32bd63a2f220cdae3ac069584507e8ae9a1"

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates tini \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 1000 sopel \
    && useradd --uid 1000 --gid 1000 --home-dir /data --no-create-home --shell /usr/sbin/nologin sopel \
    && mkdir -p /data \
    && chown 1000:1000 /data

COPY --from=builder /opt/sopel/venv /opt/sopel/venv
COPY rootfs/usr/local/bin/entrypoint /usr/local/bin/entrypoint
COPY rootfs/usr/local/bin/healthcheck /usr/local/bin/healthcheck

RUN chmod 0755 /usr/local/bin/entrypoint /usr/local/bin/healthcheck

ENV PATH="/opt/sopel/venv/bin:${PATH}" \
    HOME=/data \
    SOPEL_CONFIG_DIR=/data \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /data
VOLUME ["/data"]
USER 1000:1000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 CMD ["/usr/local/bin/healthcheck"]

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint"]
CMD ["run"]
