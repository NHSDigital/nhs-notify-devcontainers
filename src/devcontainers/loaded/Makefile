IMAGE_NAME = ghcr.io/nhsdigital/nhs-notify-devcontainer-loaded
VERSION = latest
WORKSPACE_FOLDER = ./src

build:
	npm install -g @devcontainers/cli && \
	BUILDKIT_PROGRESS=plain \
	devcontainer build \
	--workspace-folder $(WORKSPACE_FOLDER) \
	--image-name "$(IMAGE_NAME):$(VERSION)"
