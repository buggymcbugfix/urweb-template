# NixOS module: runs the application as a FastCGI service behind nginx.
#
# In configuration.nix, with `npins add github <owner> <repo>` and the name
# from name.nix (hello-urweb here):
#
#   { pkgs, ... }:
#   let sources = import ./npins; in
#   {
#     imports = [ "${sources.hello-urweb}/module.nix" ];
#     services.hello-urweb = {
#       enable = true;
#       hostName = "hello.example.org";
#       gitRev = sources.hello-urweb.revision;
#     };
#     security.acme = { acceptTerms = true; defaults.email = "ops@example.org"; };
#   }
#
# The service gets its listening socket from systemd (StandardInput=socket),
# so no spawn-fcgi is involved. Anything not covered by the options below is
# set on `services.nginx.virtualHosts.<hostName>` as usual.
{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
let
  name = import ./name.nix;
  cfg = config.services.${name};
  inherit (lib)
    mkEnableOption
    mkIf
    mkDefault
    mkOption
    optional
    optionalString
    types
    ;
  stateDir = "/var/lib/${name}";
  dbPath = "${stateDir}/${name}.db";
  socketPath = "/run/${name}/fcgi.sock";
in
{
  options.services.${name} = {
    enable = mkEnableOption "${name}, an Ur/Web application served by nginx";

    package = mkOption {
      type = types.package;
      default = import ./default.nix { system = pkgs.stdenv.hostPlatform.system; };
      defaultText = lib.literalExpression "import ./default.nix { }";
      description = ''
        The application package (FastCGI build). Defaults to the build against
        the repository's pinned nixpkgs; to build against the host's, set
        `import sources.${name} { inherit pkgs; }`.
      '';
    };

    hostName = mkOption {
      type = types.str;
      example = "app.example.org";
      description = "Host name nginx serves the application on (`server_name`).";
    };

    serverAliases = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Server aliases";
    };

    https = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Serve over HTTPS and redirect HTTP to it.";
      };
      acme = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Obtain the certificate via ACME. Requires `security.acme.acceptTerms`
          and `security.acme.defaults.email`. Set to false and provide
          `services.nginx.virtualHosts.<hostName>.sslCertificate` and
          `sslCertificateKey` to use your own certificate.
        '';
      };
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Open port 80 (and 443 with HTTPS) in the firewall.";
    };

    basicAuthFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/etc/nixos/secrets/${name}.htpasswd";
      description = ''
        htpasswd file for HTTP basic authentication in front of the
        application. Applied to the application location only, so the ACME
        challenge path stays reachable. Must be readable by the nginx user.
      '';
    };

    rateLimit = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Rate-limit requests per client with nginx's `limit_req`.";
      };
      rate = mkOption {
        type = types.str;
        default = "10r/s";
        description = "Sustained request rate per key (`limit_req_zone` rate).";
      };
      burst = mkOption {
        type = types.ints.unsigned;
        default = 50;
        description = "Requests above the rate that are served without delay before returning 429.";
      };
      key = mkOption {
        type = types.str;
        default = "$binary_remote_addr";
        description = "nginx variable the limit is keyed on. Change when behind another proxy.";
      };
      zoneSize = mkOption {
        type = types.str;
        default = "10m";
        description = "Shared memory for the `limit_req_zone` (about 16000 keys per megabyte).";
      };
    };

    threads = mkOption {
      type = types.ints.positive;
      default = 4;
      description = "Request handler threads (`-t`). Each holds a database connection.";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra command-line arguments for the application binary.";
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Extra environment variables for the application.";
    };

    gitRev = mkOption {
      type = types.str;
      default = "unknown";
      example = lib.literalExpression "sources.${name}.revision";
      description = "Value of the GIT_REV environment variable, shown by the application.";
    };
  };

  config = mkIf cfg.enable {
    systemd.sockets.${name} = {
      description = "${name} FastCGI socket";
      wantedBy = [ "sockets.target" ];
      socketConfig = {
        ListenStream = socketPath;
        # Owned by root; the service receives the fd, nginx connects.
        SocketMode = "0660";
        SocketGroup = config.services.nginx.group;
      };
    };

    systemd.services.${name} = {
      description = "${name} (Ur/Web FastCGI application)";
      requires = [ "${name}.socket" ];
      after = [
        "network.target"
        "${name}.socket"
      ];
      # Start at boot rather than on the first connection, so the database
      # is initialised before anyone asks.
      wantedBy = [ "multi-user.target" ];

      environment = {
        URWEB_SQLITE_DB_PATH = dbPath;
        GIT_REV = cfg.gitRev;
      } // cfg.environment;

      preStart = ''
        if [ ! -e ${dbPath} ]; then
          ${lib.getExe' pkgs.sqlite "sqlite3"} ${dbPath} < ${cfg.package}/share/${name}/db/generated.sql
          ${lib.getExe' pkgs.sqlite "sqlite3"} ${dbPath} < ${stateDir}/override.sql
          ${lib.getExe' pkgs.sqlite "sqlite3"} ${dbPath} < ${stateDir}/triggers.sql
          ${lib.getExe' pkgs.sqlite "sqlite3"} ${dbPath} < ${stateDir}/data.sql
        fi
      '';

      serviceConfig = {
        ExecStart = utils.escapeSystemdExecArgs (
          [
            "${cfg.package}/bin/${name}"
            "-t"
            (toString cfg.threads)
          ]
          ++ cfg.extraArgs
        );
        # The FastCGI binary accepts connections on fd 0.
        StandardInput = "socket";
        StandardOutput = "journal";
        StandardError = "journal";

        DynamicUser = true;
        StateDirectory = name;
        WorkingDirectory = stateDir;
        UMask = "0077";
        Restart = "on-failure";
        RestartSec = 2;

        # Hardening. AF_INET/AF_INET6 are needed for outbound requests
        # (urweb-curl).
        CapabilityBoundingSet = "";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        RemoveIPC = true;
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
        ];
      };
    };

    services.nginx = {
      enable = true;
      recommendedTlsSettings = mkDefault true;
      recommendedGzipSettings = mkDefault true;
      recommendedOptimisation = mkDefault true;

      appendHttpConfig = optionalString cfg.rateLimit.enable ''
        limit_req_zone ${cfg.rateLimit.key} zone=${name}:${cfg.rateLimit.zoneSize} rate=${cfg.rateLimit.rate};
      '';

      virtualHosts.${cfg.hostName} = {
        serverAliases = cfg.serverAliases;
        forceSSL = cfg.https.enable;
        enableACME = cfg.https.enable && cfg.https.acme;
        locations."/" = {
          basicAuthFile = cfg.basicAuthFile;
          extraConfig = ''
            # fastcgi_params sets SCRIPT_NAME=$uri (no PATH_INFO), REQUEST_METHOD,
            # QUERY_STRING, CONTENT_*, REMOTE_ADDR and HTTPS: what the Ur/Web
            # FastCGI runtime expects with the default `prefix /`.
            include ${config.services.nginx.package}/conf/fastcgi_params;
            fastcgi_pass unix:${socketPath};
          ''
          + optionalString cfg.rateLimit.enable ''
            limit_req zone=${name} burst=${toString cfg.rateLimit.burst} nodelay;
            limit_req_status 429;
          '';
        };
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall ([ 80 ] ++ optional cfg.https.enable 443);
  };
}
