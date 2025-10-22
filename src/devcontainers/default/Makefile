IMAGE_NAME = ghcr.io/nhsdigital/nhs-notify-devcontainer-default
WORKSPACE_FOLDER = .

build:
	npm install -g @devcontainers/cli && \
	BUILDKIT_PROGRESS=plain \
	devcontainer build \
	--push false \
	--workspace-folder $(WORKSPACE_FOLDER) \
	--image-name "$(IMAGE_NAME)" \
	--label "devcontainer.metadata=[{\"containerEnv\": { \"CUSTOM_VARIABLE\": \"Testing a variable\" }}]"

