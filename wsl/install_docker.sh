#!/usr/bin/env bash

# docker
if [ ! -f "/usr/bin/docker" ]; then
	curl -fsSL https://get.docker.com -o get-docker.sh
	sudo sh get-docker.sh
	sudo usermod -aG docker $USER
	docker buildx install
fi

# docker-compose
if [ ! -f "/usr/local/bin/docker-compose" ]; then
LATEST_VERSION_LINK=$(curl --silent "https://api.github.com/repos/docker/compose/releases/latest" | grep -E "\"browser_download_url.+linux-x86_64\"" | cut -d '"' -f4)
sudo curl -L "$LATEST_VERSION_LINK" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
fi

# reload docker group
newgrp docker
