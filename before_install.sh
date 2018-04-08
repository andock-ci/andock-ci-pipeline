#!/usr/bin/env bash
set -e
ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in id_rsa.enc -out ~/.ssh/id_rsa -d
chmod 600 ~/.ssh/id_rsa
eval `ssh-agent -s`
ssh-add ~/.ssh/id_rsa
mv -fv ssh-config ~/.ssh/config

git config --global user.email "christian.wiedemann@key-tec.de"
git config --global user.name "KEY-TEC (via TravisCI)"

curl -sL https://github.com/digitalocean/doctl/releases/download/v1.7.2/doctl-1.7.2-linux-amd64.tar.gz | tar -xzv
sudo mv doctl /usr/local/bin
doctl auth init -t $do_token

doctl compute droplet-action restore 88798812 --image-id=33288941 --wait
