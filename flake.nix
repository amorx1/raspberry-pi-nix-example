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
    home-manager.url = "github:nix-community/home-manager/ab5542e9dbd13d0100f8baae2bc2d68af901f4b4";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, raspberry-pi-nix, home-manager }:
    let
      inherit (nixpkgs.lib) nixosSystem;
      basic-config = { pkgs, lib, ... }: {
        # Bootloader
        boot.loader.grub.enable = false;

        # TimeZone
        time.timeZone = "Pacific/Auckland";

        # Users
        users.users.root.initialPassword = "root";
        users.users.amor = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          packages = with pkgs; [];
        };

        # Network
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

        # System Packages
        environment.systemPackages = with pkgs; [
          helix
        ];

        # SSH
        services.openssh.enable =  true;
        networking.firewall.allowedTCPPorts = [ 22 ];

        # Bluetooth
        services.blueman.enable = true;

        # Sound
        sound.enable = true;

        # Environment Variables
        environment = {
          variables = {
            CONFIG = "/etc/nixos";
          };
        };

        # Hardware
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
          modules = [
            raspberry-pi-nix.nixosModules.raspberry-pi
            basic-config
            { raspberry-pi-nix.uboot.enable = false; }

            # Home Manager
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.amor = { pkgs, ... }: {
                home.username = "amor";
                home.homeDirectory = "/home/amor";
                home.packages = [
                  # Terminal
                  pkgs.neofetch
                  pkgs.zsh
                  pkgs.oh-my-zsh
                  pkgs.zellij
                  pkgs.alacritty
                  pkgs.zoxide
                  pkgs.nushell
                  pkgs.git
                  pkgs.jq

                  # LSPs
                  pkgs.rust-analyzer
                  pkgs.nil
                  pkgs.nixpkgs-fmt
                ];

                programs.home-manager.enable = true;
                programs.jq.enable = true;

                # Helix
                programs.helix = {
                  enable = true;
                  defaultEditor = true;
                  extraPackages = with pkgs; [
                    rust-analyzer
                    nil
                    nixpkgs-fmt
                  ];
                  languages = {
                    language-server.rust-analyzer.config.check = {
                      command = "clippy";
                    };

                    language = [
                      {
                        name = "rust";
                        auto-format = true;
                        language-servers = [
                          { name = "rust-analyzer"; }
                        ];
                      }
                      {
                        name = "nix";
                        formatter = {
                          command = "nixpkgs-fmt";
                        };
                      }
                    ];
                  };
                  settings = {
                    theme = "dark_plus";
                    editor = {
                      line-number = "relative";
                      lsp.display-messages = true;
                    };
                    keys.normal = {
                      space.space = "file_picker";
                      space.W = "rotate_view";
                      space.V = "vsplit";
                      space.H = "hsplit";
                      space.w = ":w";
                      space.q = ":q";
                      esc = [ "collapse_selection" "keep_primary_selection" ];
                    };
                  };
                };

                # Zsh
                programs.zsh = {
                  enable = true;
                  shellAliases = {
                    cd = "z";
                  };
                  oh-my-zsh = {
                    enable = true;
                    plugins = [];
                    theme = "af-magic";
                  };
                };

                # Nushell
                programs.nushell = {
                  enable = true;
                  shellAliases = {
                    cd = "z";
                  };
                };

                # Git
                programs.git = {
                  enable = true;
                  userName = "Akshay Mor";
                  userEmail = "akshay.morx@gmail.com";
                };

                # Zellij
                programs.zellij = {
                  enable = true;
                  enableZshIntegration = true;
                  settings = {
                    theme = "rose-pine";
                    rose-pine.bg = "#403d52";
                    rose-pine.fg = "#e0def4";
                    rose-pine.red = "#eb6f92";
                    rose-pine.green = "#31748f";
                    rose-pine.blue = "#9ccfd8";
                    rose-pine.yellow = "#f6c177";
                    rose-pine.magenta = "#c4a7e7";
                    rose-pine.orange = "#fe640b";
                    rose-pine.cyan = "#ebbcba";
                    rose-pine.black = "#26233a";
                    rose-pine.white = "#e0def4";
                  };
                };

                # Zoxide
                programs.zoxide = {
                  enable = true;
                  enableZshIntegration = true;
                  enableNushellIntegration = true;
                };

                home.stateVersion = "23.11";
              };
            }
          ];
        };
      };
    };
}
