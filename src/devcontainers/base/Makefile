IMAGE_NAME = ghcr.io/nhsdigital/nhs-notify-devcontainer-base
WORKSPACE_FOLDER = ./src

build:
	npm install -g @devcontainers/cli && \
	BUILDKIT_PROGRESS=plain \
	devcontainer build \
	--push false \
	--workspace-folder $(WORKSPACE_FOLDER) \
	--image-name "$(IMAGE_NAME)"
