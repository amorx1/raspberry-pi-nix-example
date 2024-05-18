#!/bin/bash

# Build
sudo rm -rf ./result
sudo docker build . -t nixos --no-cache

# Copy
container=$(docker run -d -t nixos)
sudo docker cp $container:/src/result/ .

# Extract
sudo unzstd ./result/sd-image/*.zst
sudo rm -rf ./result/sd-image/*.zst
