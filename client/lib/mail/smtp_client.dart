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
    final builder = em.MessageBuilder.prepareReplyToMessage;

    final msg = em.MessageBuilder()
      ..subject = subject
      ..from = [em.MailAddress(account.displayName, account.email)]
      ..to = to.map((a) => em.MailAddress(a.name ?? '', a.address)).toList()
      ..cc = cc.map((a) => em.MailAddress(a.name ?? '', a.address)).toList()
      ..bcc = bcc.map((a) => em.MailAddress(a.name ?? '', a.address)).toList();

    if (replyTo != null) {
      msg
        ..inReplyTo = replyTo.messageId
        ..references = [replyTo.messageId ?? ''];
    }

    final fullHtml = bodyHtml.isNotEmpty
        ? '$bodyHtml${signatureHtml.isNotEmpty ? '<br><br>$signatureHtml' : ''}'
        : '';

    if (fullHtml.isNotEmpty) {
      msg.addTextHtml(fullHtml);
      msg.addTextPlain(bodyText);
    } else {
      msg.addTextPlain(bodyText);
    }

    for (final file in attachments) {
      await msg.addFile(file);
    }

    final mimeMsg = msg.buildMimeMessage();

    final client = em.SmtpClient(account.smtpHost, isLogEnabled: false);
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
      await client.authenticate(account.email, password,
          em.AuthMechanism.plain);
      final sendResult = await client.sendMessage(mimeMsg);
      if (!sendResult.isOkStatus) {
        throw Exception('SMTP send failed: ${sendResult.message}');
      }
    } finally {
      client.disconnect();
    }
  }
}
