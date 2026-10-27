FROM debian:13.7-slim

LABEL org.opencontainers.image.source="https://github.com/x-hermes-agent/hermes-sandbox" \
      org.opencontainers.image.description="Isolated SSH terminal sandbox for Hermes Agent" \
      org.opencontainers.image.licenses="MIT"

# UID/GID of the user Hermes runs as (10000 in the official hermes-agent image).
ARG HERMES_UID=10000
ARG HERMES_GID=10000
ARG NIX_VERSION=2.28.5

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      bash ca-certificates curl file fd-find git jq less nano nodejs npm openssh-server procps \
      python3 python3-pip python3-venv ripgrep rsync sudo tmux tree unzip wget xz-utils zip && \
    ln -s /usr/bin/fdfind /usr/local/bin/fd && \
    rm -rf /var/lib/apt/lists/* && \
    useradd -m -u 1000 -s /bin/bash agent && \
    echo "agent ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/agent && \
    chmod 440 /etc/sudoers.d/agent && \
    install -d -m 755 -o agent -g agent /nix && \
    install -d -m 755 -o "$HERMES_UID" -g "$HERMES_GID" /home/agent/hermes-to-sandbox && \
    mkdir -p /etc/nix && \
    printf 'experimental-features = nix-command flakes\n' > /etc/nix/nix.conf

# Single-user Nix for the agent; the store lives on its own volume so installs survive rebuilds.
USER agent
RUN curl -fsSL "https://releases.nixos.org/nix/nix-${NIX_VERSION}/install" | \
      USER=agent sh -s -- --no-daemon --no-channel-add --no-modify-profile && \
    /home/agent/.nix-profile/bin/nix-env -p /nix/var/nix/profiles/default --set "$(readlink -f /home/agent/.nix-profile)"
USER root

COPY nix.sh /etc/profile.d/nix.sh
COPY sshd_config /etc/ssh/sshd_config.d/sandbox.conf
COPY --chmod=755 entrypoint.sh /usr/local/bin/sandbox-entrypoint

ENTRYPOINT ["/usr/local/bin/sandbox-entrypoint"]
