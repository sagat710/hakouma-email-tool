enum MailProtocol { imap, pop3 }

class EmailAccount {
  final String id;
  final String email;
  final String displayName;
  final String signatureHtml;
  final MailProtocol protocol;

  // Incoming (IMAP / POP3)
  final String incomingHost;
  final int incomingPort;
  final bool incomingTls;

  // Outgoing (SMTP)
  final String smtpHost;
  final int smtpPort;
  final bool smtpTls;

  final bool isGmail;       // use Gmail API when true
  final bool isOutlook;     // use Graph API when true
  final int sortOrder;
  final bool isDefault;

  const EmailAccount({
    required this.id,
    required this.email,
    required this.displayName,
    this.signatureHtml = '',
    this.protocol = MailProtocol.imap,
    required this.incomingHost,
    this.incomingPort = 993,
    this.incomingTls = true,
    required this.smtpHost,
    this.smtpPort = 587,
    this.smtpTls = true,
    this.isGmail = false,
    this.isOutlook = false,
    this.sortOrder = 0,
    this.isDefault = false,
  });

  EmailAccount copyWith({
    String? displayName,
    String? signatureHtml,
    bool? isDefault,
    int? sortOrder,
  }) =>
      EmailAccount(
        id: id,
        email: email,
        displayName: displayName ?? this.displayName,
        signatureHtml: signatureHtml ?? this.signatureHtml,
        protocol: protocol,
        incomingHost: incomingHost,
        incomingPort: incomingPort,
        incomingTls: incomingTls,
        smtpHost: smtpHost,
        smtpPort: smtpPort,
        smtpTls: smtpTls,
        isGmail: isGmail,
        isOutlook: isOutlook,
        sortOrder: sortOrder ?? this.sortOrder,
        isDefault: isDefault ?? this.isDefault,
      );
}
