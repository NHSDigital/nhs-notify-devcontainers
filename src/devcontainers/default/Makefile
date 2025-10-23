CONTAINER_PREFIX=ghcr.io/nhsdigital/nhs-notify-devcontainer-
CONTAINER_NAME=default
BASE_CONTAINER_PREFIX=$(CONTAINER_PREFIX)
BASE_CONTAINER_NAME=base
BASE_IMAGE_TAG=1.0.5
IMAGE_NAME=${CONTAINER_PREFIX}$(CONTAINER_NAME)
WORKSPACE_FOLDER=.

build:
	npm install -g @devcontainers/cli && \
	BUILDKIT_PROGRESS=plain \
	BASE_CONTAINER_NAME=$(BASE_CONTAINER_NAME) \
	CONTAINER_NAME=$(CONTAINER_NAME) \
	BASE_IMAGE_TAG=$(BASE_IMAGE_TAG) \
	BASE_CONTAINER_PREFIX=$(BASE_CONTAINER_PREFIX) \
	devcontainer build \
	--push false \
	--workspace-folder $(WORKSPACE_FOLDER) \
	--image-name "$(IMAGE_NAME)" \
	--label "devcontainer.metadata=[{\"containerEnv\": { \"NOTIFY_USE_$(CONTAINER_NAME)\": \"true\" }}]"

build_no_cache:
	npm install -g @devcontainers/cli && \
	BUILDKIT_PROGRESS=plain \
	BASE_CONTAINER_NAME=$(BASE_CONTAINER_NAME) \
	CONTAINER_NAME=$(CONTAINER_NAME) \
	BASE_IMAGE_TAG=$(BASE_IMAGE_TAG) \
	BASE_CONTAINER_PREFIX=$(BASE_CONTAINER_PREFIX) \
	devcontainer build \
	--push false \
	--workspace-folder $(WORKSPACE_FOLDER) \
	--image-name "$(IMAGE_NAME)" \
	--no-cache \
	--label "devcontainer.metadata=[{\"containerEnv\": { \"NOTIFY_USE_$(CONTAINER_NAME)\": \"true\" }}]"
