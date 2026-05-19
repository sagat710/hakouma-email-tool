import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import '../models/email_message.dart';

part 'email_repository.g.dart';

// ---------------------------------------------------------------------------
// Drift tables
// ---------------------------------------------------------------------------

class MessagesTable extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text()();
  TextColumn get folder => text().withDefault(const Constant('INBOX'))();
  TextColumn get subject => text().withDefault(const Constant(''))();
  TextColumn get fromAddress => text()();
  TextColumn get fromName => text().withDefault(const Constant(''))();
  TextColumn get toAddresses => text().withDefault(const Constant('[]'))(); // JSON
  TextColumn get ccAddresses => text().withDefault(const Constant('[]'))(); // JSON
  IntColumn get dateEpochMs => integer()();
  TextColumn get bodyText => text().withDefault(const Constant(''))();
  TextColumn get bodyHtml => text().withDefault(const Constant(''))();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  BoolColumn get isStarred => boolean().withDefault(const Constant(false))();
  TextColumn get labels => text().withDefault(const Constant('[]'))(); // JSON
  TextColumn get spamStatus =>
      text().withDefault(const Constant('clean'))();
  TextColumn get translatedBodyJa =>
      text().nullable()();
  TextColumn get messageId => text().nullable()();
  TextColumn get inReplyTo => text().nullable()();

  @override
  Set<Column> get primaryKey => {id, accountId};
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(tables: [MessagesTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  Future<List<MessagesTableData>> getMessages(
    String accountId, {
    String folder = 'INBOX',
    int limit = 50,
    int offset = 0,
    SpamStatus? excludeSpam,
  }) {
    final query = select(messagesTable)
      ..where((t) =>
          t.accountId.equals(accountId) &
          t.folder.equals(folder) &
          (excludeSpam != null
              ? t.spamStatus.isNotIn(
                  [if (excludeSpam == SpamStatus.spam) 'spam'])
              : const CustomExpression('1')))
      ..orderBy([(t) => OrderingTerm.desc(t.dateEpochMs)])
      ..limit(limit, offset: offset);
    return query.get();
  }

  Future<MessagesTableData?> getMessage(String id, String accountId) =>
      (select(messagesTable)
            ..where((t) => t.id.equals(id) & t.accountId.equals(accountId)))
          .getSingleOrNull();

  Future<void> upsertMessages(List<MessagesTableCompanion> rows) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(messagesTable, rows);
    });
  }

  Future<void> markRead(String id, String accountId, {required bool read}) =>
      (update(messagesTable)
            ..where((t) => t.id.equals(id) & t.accountId.equals(accountId)))
          .write(MessagesTableCompanion(isRead: Value(read)));

  Future<void> markStarred(String id, String accountId,
          {required bool starred}) =>
      (update(messagesTable)
            ..where((t) => t.id.equals(id) & t.accountId.equals(accountId)))
          .write(MessagesTableCompanion(isStarred: Value(starred)));

  Future<void> setSpamStatus(
          String id, String accountId, SpamStatus status) =>
      (update(messagesTable)
            ..where((t) => t.id.equals(id) & t.accountId.equals(accountId)))
          .write(MessagesTableCompanion(
              spamStatus: Value(status.name)));

  Future<void> setTranslation(
          String id, String accountId, String translatedJa) =>
      (update(messagesTable)
            ..where((t) => t.id.equals(id) & t.accountId.equals(accountId)))
          .write(MessagesTableCompanion(
              translatedBodyJa: Value(translatedJa)));

  Future<int> getUnreadCount(String accountId) async {
    final count = messagesTable.id.count();
    final query = selectOnly(messagesTable)
      ..addColumns([count])
      ..where(messagesTable.accountId.equals(accountId) &
          messagesTable.isRead.equals(false) &
          messagesTable.spamStatus.isNotIn(['spam']));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Override in ProviderScope override');
});

Future<AppDatabase> openDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dir.path, 'hakouma_mail.db');
  return AppDatabase(NativeDatabase(File(dbPath)));
}
