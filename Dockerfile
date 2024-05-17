FROM nixos/nix
USER root

RUN mkdir src
COPY . ./src/

WORKDIR ./src
RUN rm -rf ./result
RUN nix build '.#nixosConfigurations.rpi-example.config.system.build.sdImage' --extra-experimental-features nix-command --extra-experimental-features flakes --accept-flake-config
