IMAGE_NAME = ghcr.io/nhsdigital/nhs-notify-devcontainer-base
WORKSPACE_FOLDER = .

build:
	npm install -g @devcontainers/cli && \
	BUILDKIT_PROGRESS=plain \
	devcontainer build \
	--push false \
	--workspace-folder $(WORKSPACE_FOLDER) \
	--image-name "$(IMAGE_NAME)" \
	--label "devcontainer.metadata=[{\"containerEnv\": { \"NOTIFY_USE_BASE\": \"true\" }}]"

build_no_cache:
	npm install -g @devcontainers/cli && \
	BUILDKIT_PROGRESS=plain \
	devcontainer build \
	--push false \
	--workspace-folder $(WORKSPACE_FOLDER) \
	--image-name "$(IMAGE_NAME)" \
	--no-cache \
	--label "devcontainer.metadata=[{\"containerEnv\": { \"NOTIFY_USE_BASE\": \"true\" }}]"
