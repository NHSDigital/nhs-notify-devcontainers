FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04
LABEL org.opencontainers.image.source=https://github.com/NHSDigital/nhs-notify-devcontainers/src/base/src
LABEL org.opencontainers.image.description="Base Dev Container for NHS Digital Notify development environments"
LABEL org.opencontainers.image.licenses=MIT
WORKDIR /setup
COPY scripts ./scripts
WORKDIR /setup/scripts
RUN . ./configure-apt.sh