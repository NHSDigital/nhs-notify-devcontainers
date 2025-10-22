FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04
LABEL org.opencontainers.image.source=https://github.com/NHSDigital/nhs-notify-devcontainers/tree/main/src/devcontainers/base
LABEL org.opencontainers.image.url=https://github.com/NHSDigital/nhs-notify-devcontainers/blob/main/src/devcontainers/base/README.md
LABEL org.opencontainers.image.description="Base Dev Container for NHS Digital Notify development environments"
LABEL org.opencontainers.image.vendor="NHS England"
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="NHS Digital Notify Base Dev Container"
LABEL org.opencontainers.image.description="Base Dev Container for NHS Digital Notify development environments"


COPY scripts /usr/local/share/nhsnotify-base

WORKDIR /usr/local/share/nhsnotify-base
RUN ./install.sh