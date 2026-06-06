enum SpamStatus { clean, spam, ambiguous }

enum TranslationState { none, loading, ready }

class EmailAddress {
  final String address;
  final String? name;
  const EmailAddress({required this.address, this.name});

  String get displayName => name?.isNotEmpty == true ? name! : address;

  @override
  String toString() => name != null ? '$name <$address>' : address;
}

class EmailAttachment {
  final String filename;
  final String mimeType;
  final int sizeBytes;
  final String? localPath; // set after download
  final String contentId; // for inline images

  const EmailAttachment({
    required this.filename,
    required this.mimeType,
    required this.sizeBytes,
    this.localPath,
    this.contentId = '',
  });
}

class EmailMessage {
  final String id;              // server UID as string
  final String accountId;
  final String folder;          // e.g. "INBOX"
  final String subject;
  final EmailAddress from;
  final List<EmailAddress> to;
  final List<EmailAddress> cc;
  final List<EmailAddress> bcc;
  final DateTime date;
  final String bodyText;        // plain text
  final String bodyHtml;        // HTML (may be empty)
  final List<EmailAttachment> attachments;
  final bool isRead;
  final bool isStarred;
  final List<String> labels;    // custom labels / Gmail labels
  final SpamStatus spamStatus;
  final String? translatedBodyJa; // cached Japanese translation
  final TranslationState translationState;
  final String? messageId;      // RFC Message-ID header for threading
  final String? inReplyTo;

  const EmailMessage({
    required this.id,
    required this.accountId,
    required this.folder,
    required this.subject,
    required this.from,
    this.to = const [],
    this.cc = const [],
    this.bcc = const [],
    required this.date,
    this.bodyText = '',
    this.bodyHtml = '',
    this.attachments = const [],
    this.isRead = false,
    this.isStarred = false,
    this.labels = const [],
    this.spamStatus = SpamStatus.clean,
    this.translatedBodyJa,
    this.translationState = TranslationState.none,
    this.messageId,
    this.inReplyTo,
  });

  bool get hasHtml => bodyHtml.isNotEmpty;
  bool get hasAttachments => attachments.isNotEmpty;

  /// True when the sender is English-dominant (heuristic: ASCII ratio > 0.85)
  bool get looksEnglish {
    final text = bodyText;
    if (text.isEmpty) return false;
    final ascii = text.codeUnits.where((c) => c < 128).length;
    return ascii / text.length > 0.85;
  }

  EmailMessage copyWith({
    bool? isRead,
    bool? isStarred,
    SpamStatus? spamStatus,
    String? translatedBodyJa,
    TranslationState? translationState,
    List<String>? labels,
  }) =>
      EmailMessage(
        id: id,
        accountId: accountId,
        folder: folder,
        subject: subject,
        from: from,
        to: to,
        cc: cc,
        bcc: bcc,
        date: date,
        bodyText: bodyText,
        bodyHtml: bodyHtml,
        attachments: attachments,
        isRead: isRead ?? this.isRead,
        isStarred: isStarred ?? this.isStarred,
        labels: labels ?? this.labels,
        spamStatus: spamStatus ?? this.spamStatus,
        translatedBodyJa: translatedBodyJa ?? this.translatedBodyJa,
        translationState: translationState ?? this.translationState,
        messageId: messageId,
        inReplyTo: inReplyTo,
      );
}

// Navigation arg for compose screen
class ComposeArgs {
  final EmailMessage? replyTo;
  final EmailMessage? forwardOf;
  final String? accountId;

  const ComposeArgs({this.replyTo, this.forwardOf, this.accountId});

  bool get isReply => replyTo != null;
  bool get isForward => forwardOf != null;
}
