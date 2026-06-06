import 'dart:io';
import 'package:enough_mail/enough_mail.dart' as em;

import '../domain/models/email_account.dart';
import '../domain/models/email_message.dart';

class SmtpEmailClient {
  final EmailAccount account;
  final String password;

  SmtpEmailClient({required this.account, required this.password});

  Future<void> sendMessage({
    required List<EmailAddress> to,
    required List<EmailAddress> cc,
    required List<EmailAddress> bcc,
    required String subject,
    required String bodyText,
    String bodyHtml = '',
    EmailMessage? replyTo,
    EmailMessage? forwardOf,
    List<File> attachments = const [],
    String signatureHtml = '',
  }) async {
    final clientDomain = account.email.split('@').last;
    final msg = em.MessageBuilder()
      ..subject = subject
      ..from = [em.MailAddress(account.displayName, account.email)]
      ..to = to.map((a) => em.MailAddress(a.name ?? '', a.address)).toList()
      ..cc = cc.map((a) => em.MailAddress(a.name ?? '', a.address)).toList()
      ..bcc = bcc.map((a) => em.MailAddress(a.name ?? '', a.address)).toList();

    final fullHtml = bodyHtml.isNotEmpty
        ? '$bodyHtml${signatureHtml.isNotEmpty ? '<br><br>$signatureHtml' : ''}'
        : '';

    if (fullHtml.isNotEmpty) {
      msg.addTextPlain(bodyText);
      msg.addTextHtml(fullHtml);
    } else {
      msg.addTextPlain(bodyText);
    }

    for (final file in attachments) {
      final bytes = await file.readAsBytes();
      final filename = file.path.split('/').last;
      final mediaType = em.MediaType.guessFromFileName(filename);
      msg.addBinary(bytes, mediaType, filename: filename);
    }

    final mimeMsg = msg.buildMimeMessage();

    // Set reply threading headers directly on the built MIME message
    if (replyTo?.messageId != null) {
      mimeMsg.addHeader('In-Reply-To', replyTo!.messageId!);
      mimeMsg.addHeader('References', replyTo.messageId!);
    }

    final client = em.SmtpClient(clientDomain, isLogEnabled: false);
    try {
      await client.connectToServer(
        account.smtpHost,
        account.smtpPort,
        isSecure: account.smtpPort == 465,
      );
      if (account.smtpPort != 465) {
        await client.startTls();
      }
      await client.ehlo();
      await client.authenticate(account.email, password);
      final sendResult = await client.sendMessage(mimeMsg);
      if (!sendResult.isOkStatus) {
        throw Exception('SMTP send failed: ${sendResult.message}');
      }
    } finally {
      await client.disconnect();
    }
  }
}
