{ config, pkgs, ... }:

{
  home.file.gpg-conf = {
    source = ./gpg.conf;
    target = ".gnupg/gpg.conf";
  };
  home.file.gpg-agent-conf = {
    text = ''
      # https://github.com/drduh/config/blob/master/gpg-agent.conf
      # https://www.gnupg.org/documentation/manuals/gnupg/Agent-Options.html
      allow-emacs-pinentry
      allow-loopback-pinentry
      enable-ssh-support
      default-cache-ttl 60
      max-cache-ttl 120
      ${if pkgs.stdenvNoCC.isLinux then
        "pinentry-program ${pkgs.pinentry}/bin/pinentry-curses"
        else
          "pinentry-program ${pkgs.pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac"}
    '';
    target = ".gnupg/gpg-agent.conf";
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.git = {
    enable = true;
    extraConfig = {
      core = {
        autocrlf = "input";
        editor = "emacsclient";
      };
      hub = {
        protocol = "https";
      };
    };
    userEmail = if pkgs.stdenvNoCC.isLinux
                then "gdcosta@gmail.com"
                else "gaelan@tulip.com";
    userName = "Gaelan D'costa";
  };

  # programs.keychain = {
  #   enable = true;
  #   enableXsessionIntegration = true;
  #   enableZshIntegration = true;
  #   agents = ["gpg-agent"];
  # };

  programs.ssh = {
    enable = true;
    compression = true;
    controlMaster = "auto";
    forwardAgent = false;

    matchBlocks = {
      "bastion pfsense cisco" = {
        hostname = "192.168.20.2";
        localForwards = [
          {
            bind.port = 4200;
            host.address = "192.168.10.1";
            host.port = 80;
          }
          {
            bind.port = 4201;
            host.address = "192.168.10.2";
            host.port = 80;
          }
        ];
      };
      jails = {
        hostname = "192.168.10.4";
        proxyJump = "bastion";
      };
      docker = {
        hostname = "192.168.10.50";
        proxyJump = "bastion";
      };
      "bastion01-tulip-prod" = {
        hostname = "34.192.243.137";
        user = "welladmin";
      };
      tulip-servers = {
        host = "*.dev *.staging *.demo *.prod *.internal";
        proxyCommand = "ssh -q bastion01-tulip-prod -- /usr/local/bin/central_ssh.sh %h";
        user = "welladmin";
      };
    };
  };

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    defaultKeymap = "emacs";

    shellAliases = {
      tdl = "tdocker login";
      e = "$VISUAL";
      killemacs = "emacsclient -e '(kill-emacs)'";
      pgrep = "pgrep -a";
      ls = "ls -FGh";
      grep = "grep --colour=auto";
      nix-install = "nix-env -f '<nixpkgs>' -iA";
      nix-upgrade = if pkgs.stdenvNoCC.isLinux
        then ""
        else "sudo -i sh -c 'nix-channel --update && nix-env -iA nixpkgs.nix && launchctl remove org.nixos.nix-daemon && launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist'";
    };
  };

  # We need git's config found in a legacy place because of how certain devtools tooling
  # mounts it into dockerized tools.
  home.activation.gitConfigSymlink = config.lib.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD ln -sf $VERBOSE_ARG \
    $HOME/.config/git/config $HOME/.gitconfig
  '';

  home.file.emacsConfig = {
    source = <dotfiles/overlays/20-emacs/emacs/config.el>;
    target = ".emacs.d/init.el";
  };

  home.file.xmobarConfig = {
    source = <dotfiles/setup/user/xmobarrc>;
    target = ".xmobarrc";
  };
}
    
