{ config, lib, ... }:
let
  tailnet = "taila84e31.ts.net";
  hosts = lib.attrNames config.hosts;
in
{
  # Prometheus + Grafana, tailnet-only via `tailscale serve`. Dashboards live in
  # ./monitoring/dashboards; edit in the UI, then export the JSON back here.
  flake.modules.nixos.monitoring =
    { config, pkgs, ... }:
    let
      fqdn = "${config.networking.hostName}.${tailnet}";
      grafanaPort = 3000;

      alertRule =
        {
          uid,
          title,
          expr,
          op,
          threshold,
          for,
          summary,
        }:
        {
          inherit uid title for;
          condition = "C";
          data = [
            {
              refId = "A";
              relativeTimeRange = {
                from = 600;
                to = 0;
              };
              datasourceUid = "prometheus";
              model = {
                refId = "A";
                inherit expr;
                instant = true;
              };
            }
            {
              refId = "C";
              datasourceUid = "__expr__";
              model = {
                refId = "C";
                type = "threshold";
                expression = "A";
                conditions = [ { evaluator = { type = op; params = [ threshold ]; }; } ];
              };
            }
          ];
          noDataState = "OK";
          execErrState = "Error";
          annotations.summary = summary;
        };
    in
    {
      services.prometheus = {
        enable = true;
        listenAddress = "127.0.0.1";
        retentionTime = "90d";
        globalConfig.scrape_interval = "30s";
        scrapeConfigs = [
          {
            job_name = "node";
            static_configs = map (host: {
              targets = [ "${host}.${tailnet}:9100" ];
              labels.instance = host;
            }) hosts;
          }
        ];
      };

      # TSDB on the data disk rather than the eMMC.
      systemd.tmpfiles.rules = [ "d /mnt/data/prometheus 0700 prometheus prometheus" ];
      fileSystems."/var/lib/prometheus2" = {
        device = "/mnt/data/prometheus";
        fsType = "none";
        options = [ "bind" ];
        depends = [ "/mnt/data" ];
      };

      services.grafana = {
        enable = true;
        settings = {
          server = {
            http_addr = "127.0.0.1";
            http_port = grafanaPort;
            domain = fqdn;
            root_url = "https://${fqdn}/";
          };
          security.secret_key = "$__file{/var/lib/grafana/secret_key}";
          "auth.proxy" = {
            enabled = true;
            header_name = "Tailscale-User-Login";
            header_property = "username";
            headers = "Name:Tailscale-User-Name";
            auto_sign_up = true;
            whitelist = "127.0.0.1"; # only tailscale serve may set the header
          };
          auth.disable_login_form = true;
          users.auto_assign_org_role = "Admin";
          dashboards.default_home_dashboard_path = "${./monitoring/dashboards/hosts.json}";
          analytics.reporting_enabled = false;
        };
        provision = {
          datasources.settings.datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              uid = "prometheus";
              url = "http://127.0.0.1:${toString config.services.prometheus.port}";
              isDefault = true;
            }
          ];
          dashboards.settings.providers = [
            {
              name = "infra";
              options.path = ./monitoring/dashboards;
            }
          ];

          alerting.rules.settings.groups = [
            {
              orgId = 1;
              name = "hosts";
              folder = "Infra";
              interval = "1m";
              rules = [
                (alertRule {
                  uid = "host-down";
                  title = "Host down";
                  expr = ''up{job="node"}'';
                  op = "lt";
                  threshold = 1;
                  for = "2m";
                  summary = "{{ .Labels.instance }} is down";
                })
                (alertRule {
                  uid = "unit-failed";
                  title = "Systemd unit failed";
                  expr = ''node_systemd_unit_state{state="failed"} == 1'';
                  op = "gt";
                  threshold = 0;
                  for = "5m";
                  summary = "{{ .Labels.instance }}: {{ .Labels.name }} failed";
                })
                (alertRule {
                  uid = "disk-full";
                  title = "Disk almost full";
                  expr = ''100 * (1 - node_filesystem_avail_bytes{mountpoint=~"/|/home|/var|/mnt/[^/]+"} / node_filesystem_size_bytes)'';
                  op = "gt";
                  threshold = 90;
                  for = "10m";
                  summary = ''{{ .Labels.instance }}: {{ .Labels.mountpoint }} is {{ printf "%.0f" .Values.A.Value }}% full'';
                })
              ];
            }
          ];

          # Hark wants its own JSON shape, so the webhook payload is templated.
          # Provisioning interpolates $VARS, hence no $ in the template.
          alerting.contactPoints.settings.contactPoints = [
            {
              orgId = 1;
              name = "hark";
              receivers = [
                {
                  uid = "hark";
                  type = "webhook";
                  settings = {
                    url = "$HARK_WEBHOOK_URL";
                    payload.template = ''
                      {{ coll.Dict "title" "Infra" "body" (tmpl.Inline `{{ range .Alerts }}{{ if eq .Status "firing" }}🔴{{ else }}✅{{ end }} {{ .Annotations.summary }}
                      {{ end }}` .) "url" .ExternalURL | data.ToJSON }}'';
                  };
                }
              ];
            }
          ];
          alerting.policies.settings.policies = [
            {
              orgId = 1;
              receiver = "hark";
              group_by = [ "alertname" ];
              group_wait = "30s";
              group_interval = "5m";
              repeat_interval = "12h";
            }
          ];
        };
      };
      systemd.services.grafana = {
        preStart = ''
          [ -s secret_key ] || ${pkgs.openssl}/bin/openssl rand -hex 32 > secret_key
        '';
        # HARK_WEBHOOK_URL=https://hark.fyi/hooks/whk_...
        serviceConfig.EnvironmentFile = "/root/secrets/hark.env";
      };

      systemd.services.grafana-tailscale-serve = {
        description = "Expose Grafana on the tailnet over HTTPS";
        after = [ "tailscaled.service" ];
        wants = [ "tailscaled.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${lib.getExe config.services.tailscale.package} serve --bg --https=443 http://127.0.0.1:${toString grafanaPort}";
        };
      };
    };
}
