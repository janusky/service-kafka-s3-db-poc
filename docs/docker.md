# docker

Install and Upgrade.

## Instalar docker

```sh
# https://docs.docker.com/install/linux/docker-ce/ubuntu/
sudo apt-get update
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

#sudo usermod -a -G docker $(whoami)
sudo usermod -aG docker $USER

# Install Compose
# https://docs.docker.com/compose/install/
sudo curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Apply executable permissions to the binary
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```

## Upgrade docker-ce

```sh
sudo apt-get autoremove docker-ce

sudo apt-get install docker-ce
```

## Upgrade docker-compose

```sh
# If installed via curl (if exists /usr/bin/docker-compose)
sudo rm /usr/local/bin/docker-compose

VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | jq .name -r)
DESTINATION=/usr/local/bin/docker-compose
sudo curl -L https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-$(uname -s)-$(uname -m) -o $DESTINATION
sudo chmod 755 $DESTINATION
```
