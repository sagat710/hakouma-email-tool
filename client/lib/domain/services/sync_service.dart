import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/email_account.dart';
import '../models/email_message.dart';
import '../repositories/account_repository.dart';
import '../repositories/email_repository.dart';
import '../../mail/imap_client.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class SyncState {
  final bool isSyncing;
  final DateTime? lastSynced;
  final String? error;

  const SyncState({
    this.isSyncing = false,
    this.lastSynced,
    this.error,
  });

  SyncState copyWith({bool? isSyncing, DateTime? lastSynced, String? error}) =>
      SyncState(
        isSyncing: isSyncing ?? this.isSyncing,
        lastSynced: lastSynced ?? this.lastSynced,
        error: error,
      );
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});

// Per-account sync state
final accountSyncStateProvider = StateProvider.family<SyncState, String>(
  (ref, accountId) => const SyncState(),
);

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class SyncService {
  final Ref _ref;
  final Map<String, ImapClient> _activeClients = {};

  SyncService(this._ref);

  AppDatabase get _db => _ref.read(appDatabaseProvider);
  AccountRepository get _accounts => _ref.read(accountRepositoryProvider);

  // Sync all accounts
  Future<void> syncAll() async {
    final accounts = await _accounts.listAccounts();
    await Future.wait(accounts.map((a) => syncAccount(a.id)));
  }

  // Sync single account
  Future<void> syncAccount(String accountId) async {
    final account = await _accounts.getAccount(accountId);
    if (account == null) return;

    _ref.read(accountSyncStateProvider(accountId).notifier).state =
        const SyncState(isSyncing: true);

    try {
      final password = await _accounts.readPassword(accountId);
      final client = ImapClient(account: account, password: password);
      await client.connect();
      _activeClients[accountId] = client;

      final messages = await client.fetchMessages(folder: 'INBOX', pageSize: 100);
      await _upsertMessages(messages);

      _ref.read(accountSyncStateProvider(accountId).notifier).state =
          SyncState(isSyncing: false, lastSynced: DateTime.now());

      // Start IDLE to watch for new mail
      client.startIdle(() => syncAccount(accountId));
    } catch (e) {
      _ref.read(accountSyncStateProvider(accountId).notifier).state =
          SyncState(error: e.toString());
    }
  }

  Future<void> loadFullMessage(EmailMessage msg) async {
    final client = _activeClients[msg.accountId];
    if (client == null || !client.isConnected) return;
    final full = await client.fetchFullMessage(msg.id, msg.folder);
    if (full == null) return;
    await _upsertMessages([full]);
  }

  Future<void> markRead(EmailMessage msg, {required bool read}) async {
    await _db.markRead(msg.id, msg.accountId, read: read);
    final client = _activeClients[msg.accountId];
    await client?.setRead(msg.id, read: read);
  }

  Future<void> markStarred(EmailMessage msg, {required bool starred}) async {
    await _db.markStarred(msg.id, msg.accountId, starred: starred);
    final client = _activeClients[msg.accountId];
    await client?.setFlagged(msg.id, flagged: starred);
  }

  Future<void> stopAll() async {
    for (final client in _activeClients.values) {
      await client.disconnect();
    }
    _activeClients.clear();
  }

  // ---------------------------------------------------------------------------

  Future<void> _upsertMessages(List<EmailMessage> messages) async {
    final companions = messages.map((m) => MessagesTableCompanion(
          id: Value(m.id),
          accountId: Value(m.accountId),
          folder: Value(m.folder),
          subject: Value(m.subject),
          fromAddress: Value(m.from.address),
          fromName: Value(m.from.name ?? ''),
          toAddresses: Value(_encodeAddrs(m.to)),
          ccAddresses: Value(_encodeAddrs(m.cc)),
          dateEpochMs: Value(m.date.millisecondsSinceEpoch),
          bodyText: Value(m.bodyText),
          bodyHtml: Value(m.bodyHtml),
          isRead: Value(m.isRead),
          isStarred: Value(m.isStarred),
          labels: Value(jsonEncode(m.labels)),
          spamStatus: Value(m.spamStatus.name),
          messageId: Value(m.messageId),
          inReplyTo: Value(m.inReplyTo),
        ));
    await _db.upsertMessages(companions.toList());
  }

  static String _encodeAddrs(List<EmailAddress> addrs) => jsonEncode(
      addrs.map((a) => {'address': a.address, 'name': a.name ?? ''}).toList());
}
