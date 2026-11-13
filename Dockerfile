# PicoShare on Railway — thin wrapper around the pinned upstream image.
#
# Upstream: mtlynch/picoshare v1.5.4 (AGPL-3.0), https://github.com/mtlynch/picoshare
#
# Why this wrapper exists (and why it is so small):
# - The stock image already does the right things: it listens on $PORT
#   (read straight from the environment by cmd/picoshare/main.go, default
#   4001), stores everything — files included — in a single SQLite database
#   at the -db path, and its entrypoint creates the DB directory on boot.
# - The stock image runs as root (alpine, no USER directive), which is what
#   Railway's root-owned persistent volumes need; USER root is stated
#   explicitly so a future upstream USER change cannot break volume writes.
# - PS_BEHIND_PROXY=true makes PicoShare trust X-Forwarded-* headers from
#   Railway's edge, so HTTPS upgrades and client-IP logging behave behind
#   the proxy instead of redirect-looping or logging the proxy IP.
# - PS_SHARED_SECRET is the admin passphrase and is REQUIRED at boot (the
#   binary log.Fatals without it). It is set as a service variable with a
#   generated default (see template-vars.json), never baked into the image.
# - Litestream replication is deliberately OFF: LITESTREAM_BUCKET is unset,
#   so the entrypoint runs PicoShare directly and the SQLite file on the
#   Railway volume is the single source of truth.
# - No Docker HEALTHCHECK: the alpine image ships no curl/wget; Railway's
#   external healthcheckPath (see railway.json) probes the app instead.

# PicoShare v1.5.4 — pinned by manifest-list digest (digest-only FROM: Railpack
# 0.43.0 fails to detect a Dockerfile whose FROM carries both a tag and a digest).
FROM mtlynch/picoshare@sha256:053fee7cbdc64894e924733d5405158a9baadbecd231bfe97ae69d16fd2c2639

LABEL org.opencontainers.image.source="https://github.com/INAPP-Mobile/picoshare"

# Run as root: Railway mounts persistent volumes root-owned.
USER root

# Trust Railway's reverse proxy (X-Forwarded-Proto / X-Forwarded-For).
ENV PS_BEHIND_PROXY=true

# The upstream image's own ENTRYPOINT (/app/docker-entrypoint) and CMD
# ("-db", "/data/store.db") are inherited unchanged: the SQLite database —
# which holds the files themselves — lives on the mounted volume at /data.
EXPOSE 4001
