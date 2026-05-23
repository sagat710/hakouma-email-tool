import 'dart:async';
import 'package:enough_mail/enough_mail.dart' as em;

import '../domain/models/email_account.dart';
import '../domain/models/email_message.dart';

class ImapClient {
  final EmailAccount account;
  final String password;

  em.ImapClient? _client;
  StreamSubscription? _idleSubscription;

  ImapClient({required this.account, required this.password});

  // ---------------------------------------------------------------------------
  // Connection
  // ---------------------------------------------------------------------------

  Future<void> connect() async {
    _client = em.ImapClient(isLogEnabled: false);
    await _client!.connectToServer(
      account.incomingHost,
      account.incomingPort,
      isSecure: account.incomingTls,
    );
    await _client!.login(account.email, password);
  }

  Future<void> disconnect() async {
    _idleSubscription?.cancel();
    _idleSubscription = null;
    try {
      await _client?.logout();
    } catch (_) {}
    _client = null;
  }

  bool get isConnected => _client?.isConnected ?? false;

  // ---------------------------------------------------------------------------
  // Folders
  // ---------------------------------------------------------------------------

  Future<List<em.Mailbox>> listFolders() async {
    return _client!.listMailboxes();
  }

  // ---------------------------------------------------------------------------
  // Message fetching
  // ---------------------------------------------------------------------------

  Future<List<EmailMessage>> fetchMessages({
    String folder = 'INBOX',
    int pageSize = 50,
    int page = 0,
  }) async {
    final mailbox = await _client!.selectMailboxByPath(folder);
    final total = mailbox.messagesExists;
    if (total == 0) return [];

    final from = (total - (page + 1) * pageSize).clamp(1, total);
    final sequence = em.MessageSequence.fromRangeToLast(from);

    final fetchResult = await _client!.fetchMessages(
      sequence,
      '(UID FLAGS ENVELOPE INTERNALDATE)',
    );

    return fetchResult.messages
        .map((msg) => _toEmailMessage(msg, folder))
        .whereType<EmailMessage>()
        .toList()
        .reversed
        .toList();
  }

  Future<EmailMessage?> fetchFullMessage(String uid, String folder) async {
    await _client!.selectMailboxByPath(folder);
    final seq = em.MessageSequence.fromId(int.parse(uid), isUid: true);
    final result = await _client!.uidFetchMessages(seq, 'BODY.PEEK[]');
    if (result.messages.isEmpty) return null;
    return _toEmailMessage(result.messages.first, folder, full: true);
  }

  // ---------------------------------------------------------------------------
  // Flags (UID-based)
  // ---------------------------------------------------------------------------

  Future<void> setRead(String uid, {required bool read}) async {
    final seq = em.MessageSequence.fromId(int.parse(uid), isUid: true);
    if (read) {
      await _client!.uidMarkSeen(seq);
    } else {
      await _client!.uidMarkUnseen(seq);
    }
  }

  Future<void> setFlagged(String uid, {required bool flagged}) async {
    final seq = em.MessageSequence.fromId(int.parse(uid), isUid: true);
    if (flagged) {
      await _client!.uidMarkFlagged(seq);
    } else {
      await _client!.uidMarkUnflagged(seq);
    }
  }

  Future<void> moveToFolder(String uid, String targetFolder) async {
    final seq = em.MessageSequence.fromId(int.parse(uid), isUid: true);
    final mailboxes = await _client!.listMailboxes();
    final target = mailboxes
        .where((m) => m.path == targetFolder || m.name == targetFolder)
        .firstOrNull;
    if (target != null) {
      await _client!.uidMove(seq, targetMailbox: target);
    } else {
      await _client!.uidMove(seq, targetMailboxPath: targetFolder);
    }
  }

  Future<void> deleteMessage(String uid) async {
    await moveToFolder(uid, 'Trash');
  }

  // ---------------------------------------------------------------------------
  // IMAP IDLE
  // ---------------------------------------------------------------------------

  void startIdle(void Function() onNewMail) {
    _idleSubscription =
        _client!.eventBus.on<em.ImapEvent>().listen((event) {
      if (event is em.ImapMessagesExistEvent) {
        onNewMail();
      }
    });
    unawaited(_client!.idleStart());
  }

  Future<void> stopIdle() async {
    await _client?.idleDone();
  }

  // ---------------------------------------------------------------------------
  // Mapping
  // ---------------------------------------------------------------------------

  EmailMessage? _toEmailMessage(em.MimeMessage msg, String folder,
      {bool full = false}) {
    final uid = msg.uid;
    if (uid == null) return null;

    final envelope = msg.envelope;
    final fromAddr = envelope?.from?.isNotEmpty == true
        ? EmailAddress(
            address: envelope!.from!.first.email ?? '',
            name: envelope.from!.first.personalName,
          )
        : const EmailAddress(address: 'unknown');

    List<EmailAddress> mapAddrs(List<em.MailAddress>? list) =>
        (list ?? [])
            .map((a) => EmailAddress(address: a.email ?? '', name: a.personalName))
            .toList();

    final date = msg.decodeDate() ?? DateTime.now();
    final subject = msg.decodeSubject() ?? '';

    final bodyText = full ? (msg.decodeTextPlainPart() ?? '') : '';
    final bodyHtml = full ? (msg.decodeTextHtmlPart() ?? '') : '';

    final attachments = <EmailAttachment>[];
    if (full) {
      for (final part in msg.allPartsFlattened) {
        final disp = part.getHeaderValue('content-disposition') ?? '';
        if (disp.contains('attachment')) {
          attachments.add(EmailAttachment(
            filename: part.decodeFileName() ?? 'attachment',
            mimeType: part.mediaType.text,
            sizeBytes: part.size ?? 0,
            contentId: part.getHeaderValue('content-id') ?? '',
          ));
        }
      }
    }

    return EmailMessage(
      id: uid.toString(),
      accountId: account.id,
      folder: folder,
      subject: subject,
      from: fromAddr,
      to: mapAddrs(envelope?.to),
      cc: mapAddrs(envelope?.cc),
      date: date,
      bodyText: bodyText,
      bodyHtml: bodyHtml,
      attachments: attachments,
      isRead: msg.isSeen,
      isStarred: msg.isFlagged,
      messageId: envelope?.messageId,
      inReplyTo: envelope?.inReplyTo,
    );
  }
}
