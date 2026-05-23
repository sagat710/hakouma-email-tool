import 'package:flutter_test/flutter_test.dart';
import 'package:hakouma_mail/domain/models/email_message.dart';

void main() {
  final epoch = DateTime.fromMillisecondsSinceEpoch(0);

  group('EmailMessage', () {
    test('looksEnglish returns true for ASCII-dominant text', () {
      final msg = EmailMessage(
        id: '1',
        accountId: 'acc1',
        folder: 'INBOX',
        subject: 'Hello',
        from: const EmailAddress(address: 'test@example.com'),
        date: epoch,
        bodyText: 'This is a plain English email body.',
      );
      expect(msg.looksEnglish, isTrue);
    });

    test('looksEnglish returns false for Japanese-dominant text', () {
      final msg = EmailMessage(
        id: '2',
        accountId: 'acc1',
        folder: 'INBOX',
        subject: 'こんにちは',
        from: const EmailAddress(address: 'test@example.com'),
        date: epoch,
        bodyText: 'これは日本語のメールです。テスト用のサンプルテキストです。',
      );
      expect(msg.looksEnglish, isFalse);
    });

    test('hasHtml is false when bodyHtml is empty', () {
      final msg = EmailMessage(
        id: '3',
        accountId: 'acc1',
        folder: 'INBOX',
        subject: 'Test',
        from: const EmailAddress(address: 'test@example.com'),
        date: epoch,
      );
      expect(msg.hasHtml, isFalse);
    });

    test('SpamStatus defaults to clean', () {
      final msg = EmailMessage(
        id: '4',
        accountId: 'acc1',
        folder: 'INBOX',
        subject: 'Test',
        from: const EmailAddress(address: 'test@example.com'),
        date: epoch,
      );
      expect(msg.spamStatus, SpamStatus.clean);
    });
  });
}
