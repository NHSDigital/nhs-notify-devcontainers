IMAGE_NAME = ghcr.io/nhsdigital/nhs-notify-devcontainer-loaded
WORKSPACE_FOLDER = .

build:
	npm install -g @devcontainers/cli && \
	BUILDKIT_PROGRESS=plain \
	devcontainer build \
	--push false \
	--workspace-folder $(WORKSPACE_FOLDER) \
	--image-name "$(IMAGE_NAME)" \
	--no-cache \
	--label "devcontainer.metadata=[{\"containerEnv\": { \"CUSTOM_VARIABLE\": \"Testing a variable\" }}]"

