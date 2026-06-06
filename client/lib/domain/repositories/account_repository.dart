import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/email_account.dart';

const _kAccountsKey = 'hakouma_accounts';
const _kPasswordPrefix = 'pwd_';

final _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(),
);

final accountsProvider = FutureProvider<List<EmailAccount>>(
  (ref) => ref.watch(accountRepositoryProvider).listAccounts(),
);

final hasAccountsProvider = Provider<bool>((ref) {
  final accounts = ref.watch(accountsProvider);
  return accounts.maybeWhen(data: (list) => list.isNotEmpty, orElse: () => false);
});

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

class AccountRepository {
  Future<List<EmailAccount>> listAccounts() async {
    final raw = await _storage.read(key: _kAccountsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<EmailAccount?> getAccount(String id) async {
    final list = await listAccounts();
    try {
      return list.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<String> readPassword(String accountId) async {
    return await _storage.read(key: '$_kPasswordPrefix$accountId') ?? '';
  }

  Future<void> saveAccount(EmailAccount account, {required String password}) async {
    final list = await listAccounts();
    final index = list.indexWhere((a) => a.id == account.id);
    if (index >= 0) {
      list[index] = account;
    } else {
      list.add(account);
    }
    await _storage.write(
      key: _kAccountsKey,
      value: jsonEncode(list.map(_toJson).toList()),
    );
    await _storage.write(
      key: '$_kPasswordPrefix${account.id}',
      value: password,
    );
  }

  Future<void> deleteAccount(String id) async {
    final list = await listAccounts();
    list.removeWhere((a) => a.id == id);
    await _storage.write(
      key: _kAccountsKey,
      value: jsonEncode(list.map(_toJson).toList()),
    );
    await _storage.delete(key: '$_kPasswordPrefix$id');
  }

  // -------------------------------------------------------------------------
  // Serialization
  // -------------------------------------------------------------------------

  static Map<String, dynamic> _toJson(EmailAccount a) => {
        'id': a.id,
        'email': a.email,
        'displayName': a.displayName,
        'signatureHtml': a.signatureHtml,
        'protocol': a.protocol.name,
        'incomingHost': a.incomingHost,
        'incomingPort': a.incomingPort,
        'incomingTls': a.incomingTls,
        'smtpHost': a.smtpHost,
        'smtpPort': a.smtpPort,
        'smtpTls': a.smtpTls,
        'isGmail': a.isGmail,
        'isOutlook': a.isOutlook,
        'sortOrder': a.sortOrder,
        'isDefault': a.isDefault,
      };

  static EmailAccount _fromJson(Map<String, dynamic> m) => EmailAccount(
        id: m['id'] as String,
        email: m['email'] as String,
        displayName: m['displayName'] as String? ?? '',
        signatureHtml: m['signatureHtml'] as String? ?? '',
        protocol: MailProtocol.values.byName(m['protocol'] as String? ?? 'imap'),
        incomingHost: m['incomingHost'] as String,
        incomingPort: m['incomingPort'] as int? ?? 993,
        incomingTls: m['incomingTls'] as bool? ?? true,
        smtpHost: m['smtpHost'] as String,
        smtpPort: m['smtpPort'] as int? ?? 587,
        smtpTls: m['smtpTls'] as bool? ?? true,
        isGmail: m['isGmail'] as bool? ?? false,
        isOutlook: m['isOutlook'] as bool? ?? false,
        sortOrder: m['sortOrder'] as int? ?? 0,
        isDefault: m['isDefault'] as bool? ?? false,
      );
}

String newAccountId() => const Uuid().v4();
