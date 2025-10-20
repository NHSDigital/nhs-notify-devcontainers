FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04
LABEL org.opencontainers.image.source=https://github.com/NHSDigital/nhs-notify-devcontainers/src/base/src
WORKDIR /setup
COPY scripts ./scripts
WORKDIR /setup/scripts
RUN . ./configure-apt.sh