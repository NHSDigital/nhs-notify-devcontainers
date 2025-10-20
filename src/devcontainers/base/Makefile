build:
	npm install && \
	export PATH="./node_modules/.bin:$$PATH" && \
	BUILDKIT_PROGRESS=plain \
	devcontainer build \
	--workspace-folder ./src \
	--image-name "ghcr.io/nhsdigital/nhs-notify-devcontainer-base:latest"
