{
  description = "raspberry-pi-nix example";
  nixConfig = {
    extra-substituters = [ "https://raspberry-pi-nix.cachix.org" ];
    extra-trusted-public-keys = [
      "raspberry-pi-nix.cachix.org-1:WmV2rdSangxW0rZjY/tBvBDSaNFQ3DyEQsVw8EvHn9o="
    ];
  };
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    raspberry-pi-nix.url = "github:amorx1/raspberry-pi-nix";
  };

  outputs = { self, nixpkgs, raspberry-pi-nix }:
    let
      inherit (nixpkgs.lib) nixosSystem;
      basic-config = { pkgs, lib, ... }: {
        time.timeZone = "Pacific/Auckland";
        users.users.root.initialPassword = "root";
        users.users.amor = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          packages = with pkgs; [];
        };
        boot.loader.grub.enable = false;
        networking = {
          hostName = "nixos";
          useDHCP = false;
          interfaces = { wlan0.useDHCP = true; };
          wireless.enable = true;
          wireless.networks = {
            "65A" = {
              pskRaw = "945687c72835ba2db670a408f26e598d51712456db1a3a63d198984308ce004b";
            };
          };
        };
        environment.systemPackages = with pkgs; [
          bluez
          bluez-tools
          helix
          zellij
          git
          alacritty
          firefox-wayland
          hyprpaper
          hyprpicker
          libsecret
          neofetch
          waybar
          dunst
          libnotify
          unzip
          rofi-wayland
        ];
        xdg.portal.enable = true;
        xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        programs.hyprland = {
          enable = true;
        };
        programs.hyprland.xwayland = {
          enable = true;
        };
        services.openssh.enable =  true;
        networking.firewall.allowedTCPPorts = [ 22 ];

        services.blueman.enable = true;
        sound.enable = true;
        services.locate = {
          enable = true;
          locate = pkgs.mlocate;
        };
        environment = {
          variables = {
            CONFIG = "/etc/nixos";
          };
        };
        hardware = {
          bluetooth.enable = true;
          raspberry-pi = {
            config = {
              all = {
                base-dt-params = {
                  # enable autoprobing of bluetooth driver
                  # https://github.com/raspberrypi/linux/blob/c8c99191e1419062ac8b668956d19e788865912a/arch/arm/boot/dts/overlays/README#L222-L224
                  krnbt = {
                    enable = true;
                    value = "on";
                  };
                };
              };
            };
          };
        };
      };

    in
    {
      nixosConfigurations = {
        rpi-example = nixosSystem {
          system = "aarch64-linux";
          modules = [ raspberry-pi-nix.nixosModules.raspberry-pi basic-config { raspberry-pi-nix.uboot.enable = false; } ];
        };
      };
    };
}
