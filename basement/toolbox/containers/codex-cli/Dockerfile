# syntax=docker/dockerfile:1
# Codex CLI container scaffold using official OpenAI binary.
# Do not promote to production before security review.

FROM debian:bookworm-slim

ARG TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive \
    CODEX_VERSION=rust-v0.42.0

# Base packages for CLI usage and utilities (curl/tar for fetching Codex release).
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        jq \
        python3 \
        python3-pip \
        python3-venv \
        tar \
    && rm -rf /var/lib/apt/lists/*

# Download architecture-specific Codex binary from the official GitHub release.
RUN set -eux; \
    case "${TARGETARCH}" in \
      "arm64") COD_ARCH="aarch64-unknown-linux-musl" ;; \
      "amd64") COD_ARCH="x86_64-unknown-linux-musl" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL -o /tmp/codex.tar.gz "https://github.com/openai/codex/releases/download/${CODEX_VERSION}/codex-${COD_ARCH}.tar.gz"; \
    tar -xzf /tmp/codex.tar.gz -C /tmp; \
    install -m 0755 "/tmp/codex-${COD_ARCH}" /usr/local/bin/codex; \
    rm -rf /tmp/codex.tar.gz "/tmp/codex-${COD_ARCH}"

# Create non-root user for interactive sessions.
RUN useradd -ms /bin/bash coder

# Ship GARVIS default Codex configuration pointing at the internal Ollama service.
COPY config/config.toml /tmp/config.toml
RUN mkdir -p /home/coder/.codex \
    && cp /tmp/config.toml /home/coder/.codex/config.toml \
    && chown -R coder:coder /home/coder/.codex \
    && rm /tmp/config.toml

USER coder

# Ensure predictable PATH that exposes Codex binary and common tools.
ENV PATH="/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin"

# Shared workspace volume for host/project exchange.
WORKDIR /workspace
VOLUME ["/workspace"]

# Environment for CLI to locate the Ollama service inside the compose stack.
ENV OLLAMA_HOST=http://host.docker.internal:11434

# Default entrypoint: interactive shell. Wrapper script may override with `codex`.
CMD ["/bin/bash"]
