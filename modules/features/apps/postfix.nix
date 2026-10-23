{
  # Send-only mail relay. Only reachable over the tailnet, so the panel on beta
  # can hand off mail here and tunneler (which has the public IP and the mail
  # PTR/DNS records) does the actual delivery to the internet.
  flake.modules.nixos.postfix = {
    services.postfix = {
      enable = true;
      rootAlias = "me@yanpla.nl";
      postmasterAlias = "root";

      settings.main = {
        myhostname = "mail.yanpla.nl";
        mydomain = "yanpla.nl";
        myorigin = "yanpla.nl"; # bare local senders become user@yanpla.nl

        # Nothing is delivered locally except bounces/postmaster mail.
        mydestination = [ "localhost" ];

        # Relaying is allowed from mynetworks only (postfix's default
        # smtpd_relay_restrictions rejects everything else). The whole tailnet
        # CGNAT range, since tailnet IPs aren't statically assigned here; the
        # firewall is what actually keeps this off the public interface.
        mynetworks = [
          "127.0.0.0/8"
          "[::1]/128"
          "100.64.0.0/10"
        ];

        inet_protocols = "ipv4"; # no IPv6 on this host; avoids delivery stalls

        # The panel submits mail without a Message-ID, and Gmail rejects that
        # outright (550 5.7.1 RFC 5322). Let cleanup fill in Message-ID/Date/From
        # when they're missing instead of relaying non-compliant mail.
        always_add_missing_headers = "yes";

        # Opportunistic TLS outbound.
        smtp_tls_security_level = "may";
        smtp_tls_note_starttls_offer = "yes";

        # Sign everything with opendkim. tempfail (not accept) so mail queues
        # instead of going out unsigned if opendkim is down.
        smtpd_milters = "local:/run/opendkim/opendkim.sock";
        non_smtpd_milters = "local:/run/opendkim/opendkim.sock";
        milter_default_action = "tempfail";

        # Bounces/DSNs are generated internally and skip the milters by default,
        # so they went out unsigned and cloudflare's inbound routing refused them
        # (550 5.7.26). A null-sender bounce can't pass SPF either (that check
        # falls back to the HELO name, which has no SPF record), so DKIM is the
        # only thing that can authenticate it. Safe to filter here because
        # opendkim only signs — it never rejects, so there's no bounce loop.
        internal_mail_filter_classes = "bounce,notify";
      };
    };

    # DKIM signing. The keypair is generated on first start into
    # /var/lib/opendkim/keys; publish /var/lib/opendkim/keys/mail.txt as the
    # mail._domainkey.yanpla.nl TXT record.
    services.opendkim = {
      enable = true;
      selector = "mail";
      domains = "csl:yanpla.nl";
      settings = {
        Mode = "s"; # sign only, never verify — this host receives no mail
        Canonicalization = "relaxed/simple";
        UMask = "0002"; # let the opendkim group read the milter socket
      };
    };
    users.users.postfix.extraGroups = [ "opendkim" ];
  };
}
