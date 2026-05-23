// ignore_for_file: type=lint
part of 'email_repository.dart';

// *** MessagesTable ***

class MessagesTableData extends DataClass
    implements Insertable<MessagesTableData> {
  final String id;
  final String accountId;
  final String folder;
  final String subject;
  final String fromAddress;
  final String fromName;
  final String toAddresses;
  final String ccAddresses;
  final int dateEpochMs;
  final String bodyText;
  final String bodyHtml;
  final bool isRead;
  final bool isStarred;
  final String labels;
  final String spamStatus;
  final String? translatedBodyJa;
  final String? messageId;
  final String? inReplyTo;

  const MessagesTableData({
    required this.id,
    required this.accountId,
    required this.folder,
    required this.subject,
    required this.fromAddress,
    required this.fromName,
    required this.toAddresses,
    required this.ccAddresses,
    required this.dateEpochMs,
    required this.bodyText,
    required this.bodyHtml,
    required this.isRead,
    required this.isStarred,
    required this.labels,
    required this.spamStatus,
    this.translatedBodyJa,
    this.messageId,
    this.inReplyTo,
  });

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['folder'] = Variable<String>(folder);
    map['subject'] = Variable<String>(subject);
    map['from_address'] = Variable<String>(fromAddress);
    map['from_name'] = Variable<String>(fromName);
    map['to_addresses'] = Variable<String>(toAddresses);
    map['cc_addresses'] = Variable<String>(ccAddresses);
    map['date_epoch_ms'] = Variable<int>(dateEpochMs);
    map['body_text'] = Variable<String>(bodyText);
    map['body_html'] = Variable<String>(bodyHtml);
    map['is_read'] = Variable<bool>(isRead);
    map['is_starred'] = Variable<bool>(isStarred);
    map['labels'] = Variable<String>(labels);
    map['spam_status'] = Variable<String>(spamStatus);
    if (!nullToAbsent || translatedBodyJa != null) {
      map['translated_body_ja'] = Variable<String>(translatedBodyJa);
    }
    if (!nullToAbsent || messageId != null) {
      map['message_id'] = Variable<String>(messageId);
    }
    if (!nullToAbsent || inReplyTo != null) {
      map['in_reply_to'] = Variable<String>(inReplyTo);
    }
    return map;
  }

  MessagesTableCompanion toCompanion(bool nullToAbsent) {
    return MessagesTableCompanion(
      id: Value(id),
      accountId: Value(accountId),
      folder: Value(folder),
      subject: Value(subject),
      fromAddress: Value(fromAddress),
      fromName: Value(fromName),
      toAddresses: Value(toAddresses),
      ccAddresses: Value(ccAddresses),
      dateEpochMs: Value(dateEpochMs),
      bodyText: Value(bodyText),
      bodyHtml: Value(bodyHtml),
      isRead: Value(isRead),
      isStarred: Value(isStarred),
      labels: Value(labels),
      spamStatus: Value(spamStatus),
      translatedBodyJa: translatedBodyJa == null && nullToAbsent
          ? const Value.absent()
          : Value(translatedBodyJa),
      messageId:
          messageId == null && nullToAbsent ? const Value.absent() : Value(messageId),
      inReplyTo:
          inReplyTo == null && nullToAbsent ? const Value.absent() : Value(inReplyTo),
    );
  }

  factory MessagesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessagesTableData(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['account_id']),
      folder: serializer.fromJson<String>(json['folder']),
      subject: serializer.fromJson<String>(json['subject']),
      fromAddress: serializer.fromJson<String>(json['from_address']),
      fromName: serializer.fromJson<String>(json['from_name']),
      toAddresses: serializer.fromJson<String>(json['to_addresses']),
      ccAddresses: serializer.fromJson<String>(json['cc_addresses']),
      dateEpochMs: serializer.fromJson<int>(json['date_epoch_ms']),
      bodyText: serializer.fromJson<String>(json['body_text']),
      bodyHtml: serializer.fromJson<String>(json['body_html']),
      isRead: serializer.fromJson<bool>(json['is_read']),
      isStarred: serializer.fromJson<bool>(json['is_starred']),
      labels: serializer.fromJson<String>(json['labels']),
      spamStatus: serializer.fromJson<String>(json['spam_status']),
      translatedBodyJa:
          serializer.fromJson<String?>(json['translated_body_ja']),
      messageId: serializer.fromJson<String?>(json['message_id']),
      inReplyTo: serializer.fromJson<String?>(json['in_reply_to']),
    );
  }

  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'account_id': serializer.toJson<String>(accountId),
      'folder': serializer.toJson<String>(folder),
      'subject': serializer.toJson<String>(subject),
      'from_address': serializer.toJson<String>(fromAddress),
      'from_name': serializer.toJson<String>(fromName),
      'to_addresses': serializer.toJson<String>(toAddresses),
      'cc_addresses': serializer.toJson<String>(ccAddresses),
      'date_epoch_ms': serializer.toJson<int>(dateEpochMs),
      'body_text': serializer.toJson<String>(bodyText),
      'body_html': serializer.toJson<String>(bodyHtml),
      'is_read': serializer.toJson<bool>(isRead),
      'is_starred': serializer.toJson<bool>(isStarred),
      'labels': serializer.toJson<String>(labels),
      'spam_status': serializer.toJson<String>(spamStatus),
      'translated_body_ja': serializer.toJson<String?>(translatedBodyJa),
      'message_id': serializer.toJson<String?>(messageId),
      'in_reply_to': serializer.toJson<String?>(inReplyTo),
    };
  }

  MessagesTableData copyWith({
    String? id,
    String? accountId,
    String? folder,
    String? subject,
    String? fromAddress,
    String? fromName,
    String? toAddresses,
    String? ccAddresses,
    int? dateEpochMs,
    String? bodyText,
    String? bodyHtml,
    bool? isRead,
    bool? isStarred,
    String? labels,
    String? spamStatus,
    Value<String?> translatedBodyJa = const Value.absent(),
    Value<String?> messageId = const Value.absent(),
    Value<String?> inReplyTo = const Value.absent(),
  }) =>
      MessagesTableData(
        id: id ?? this.id,
        accountId: accountId ?? this.accountId,
        folder: folder ?? this.folder,
        subject: subject ?? this.subject,
        fromAddress: fromAddress ?? this.fromAddress,
        fromName: fromName ?? this.fromName,
        toAddresses: toAddresses ?? this.toAddresses,
        ccAddresses: ccAddresses ?? this.ccAddresses,
        dateEpochMs: dateEpochMs ?? this.dateEpochMs,
        bodyText: bodyText ?? this.bodyText,
        bodyHtml: bodyHtml ?? this.bodyHtml,
        isRead: isRead ?? this.isRead,
        isStarred: isStarred ?? this.isStarred,
        labels: labels ?? this.labels,
        spamStatus: spamStatus ?? this.spamStatus,
        translatedBodyJa: translatedBodyJa.present
            ? translatedBodyJa.value
            : this.translatedBodyJa,
        messageId: messageId.present ? messageId.value : this.messageId,
        inReplyTo: inReplyTo.present ? inReplyTo.value : this.inReplyTo,
      );

  MessagesTableData copyWithCompanion(MessagesTableCompanion data) {
    return MessagesTableData(
      id: data.id.present ? data.id.value : id,
      accountId: data.accountId.present ? data.accountId.value : accountId,
      folder: data.folder.present ? data.folder.value : folder,
      subject: data.subject.present ? data.subject.value : subject,
      fromAddress: data.fromAddress.present ? data.fromAddress.value : fromAddress,
      fromName: data.fromName.present ? data.fromName.value : fromName,
      toAddresses: data.toAddresses.present ? data.toAddresses.value : toAddresses,
      ccAddresses: data.ccAddresses.present ? data.ccAddresses.value : ccAddresses,
      dateEpochMs: data.dateEpochMs.present ? data.dateEpochMs.value : dateEpochMs,
      bodyText: data.bodyText.present ? data.bodyText.value : bodyText,
      bodyHtml: data.bodyHtml.present ? data.bodyHtml.value : bodyHtml,
      isRead: data.isRead.present ? data.isRead.value : isRead,
      isStarred: data.isStarred.present ? data.isStarred.value : isStarred,
      labels: data.labels.present ? data.labels.value : labels,
      spamStatus: data.spamStatus.present ? data.spamStatus.value : spamStatus,
      translatedBodyJa: data.translatedBodyJa.present
          ? data.translatedBodyJa.value
          : translatedBodyJa,
      messageId: data.messageId.present ? data.messageId.value : messageId,
      inReplyTo: data.inReplyTo.present ? data.inReplyTo.value : inReplyTo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessagesTableData(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('folder: $folder, ')
          ..write('subject: $subject, ')
          ..write('fromAddress: $fromAddress, ')
          ..write('fromName: $fromName, ')
          ..write('toAddresses: $toAddresses, ')
          ..write('ccAddresses: $ccAddresses, ')
          ..write('dateEpochMs: $dateEpochMs, ')
          ..write('bodyText: $bodyText, ')
          ..write('bodyHtml: $bodyHtml, ')
          ..write('isRead: $isRead, ')
          ..write('isStarred: $isStarred, ')
          ..write('labels: $labels, ')
          ..write('spamStatus: $spamStatus, ')
          ..write('translatedBodyJa: $translatedBodyJa, ')
          ..write('messageId: $messageId, ')
          ..write('inReplyTo: $inReplyTo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      accountId,
      folder,
      subject,
      fromAddress,
      fromName,
      toAddresses,
      ccAddresses,
      dateEpochMs,
      bodyText,
      bodyHtml,
      isRead,
      isStarred,
      labels,
      spamStatus,
      translatedBodyJa,
      messageId,
      inReplyTo);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessagesTableData &&
          other.id == id &&
          other.accountId == accountId &&
          other.folder == folder &&
          other.subject == subject &&
          other.fromAddress == fromAddress &&
          other.fromName == fromName &&
          other.toAddresses == toAddresses &&
          other.ccAddresses == ccAddresses &&
          other.dateEpochMs == dateEpochMs &&
          other.bodyText == bodyText &&
          other.bodyHtml == bodyHtml &&
          other.isRead == isRead &&
          other.isStarred == isStarred &&
          other.labels == labels &&
          other.spamStatus == spamStatus &&
          other.translatedBodyJa == translatedBodyJa &&
          other.messageId == messageId &&
          other.inReplyTo == inReplyTo);
}

class MessagesTableCompanion extends UpdateCompanion<MessagesTableData> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> folder;
  final Value<String> subject;
  final Value<String> fromAddress;
  final Value<String> fromName;
  final Value<String> toAddresses;
  final Value<String> ccAddresses;
  final Value<int> dateEpochMs;
  final Value<String> bodyText;
  final Value<String> bodyHtml;
  final Value<bool> isRead;
  final Value<bool> isStarred;
  final Value<String> labels;
  final Value<String> spamStatus;
  final Value<String?> translatedBodyJa;
  final Value<String?> messageId;
  final Value<String?> inReplyTo;
  final Value<int> rowid;

  const MessagesTableCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.folder = const Value.absent(),
    this.subject = const Value.absent(),
    this.fromAddress = const Value.absent(),
    this.fromName = const Value.absent(),
    this.toAddresses = const Value.absent(),
    this.ccAddresses = const Value.absent(),
    this.dateEpochMs = const Value.absent(),
    this.bodyText = const Value.absent(),
    this.bodyHtml = const Value.absent(),
    this.isRead = const Value.absent(),
    this.isStarred = const Value.absent(),
    this.labels = const Value.absent(),
    this.spamStatus = const Value.absent(),
    this.translatedBodyJa = const Value.absent(),
    this.messageId = const Value.absent(),
    this.inReplyTo = const Value.absent(),
    this.rowid = const Value.absent(),
  });

  MessagesTableCompanion.insert({
    required String id,
    required String accountId,
    this.folder = const Value.absent(),
    this.subject = const Value.absent(),
    required String fromAddress,
    this.fromName = const Value.absent(),
    this.toAddresses = const Value.absent(),
    this.ccAddresses = const Value.absent(),
    required int dateEpochMs,
    this.bodyText = const Value.absent(),
    this.bodyHtml = const Value.absent(),
    this.isRead = const Value.absent(),
    this.isStarred = const Value.absent(),
    this.labels = const Value.absent(),
    this.spamStatus = const Value.absent(),
    this.translatedBodyJa = const Value.absent(),
    this.messageId = const Value.absent(),
    this.inReplyTo = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        accountId = Value(accountId),
        fromAddress = Value(fromAddress),
        dateEpochMs = Value(dateEpochMs);

  static Insertable<MessagesTableData> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? folder,
    Expression<String>? subject,
    Expression<String>? fromAddress,
    Expression<String>? fromName,
    Expression<String>? toAddresses,
    Expression<String>? ccAddresses,
    Expression<int>? dateEpochMs,
    Expression<String>? bodyText,
    Expression<String>? bodyHtml,
    Expression<bool>? isRead,
    Expression<bool>? isStarred,
    Expression<String>? labels,
    Expression<String>? spamStatus,
    Expression<String>? translatedBodyJa,
    Expression<String>? messageId,
    Expression<String>? inReplyTo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (folder != null) 'folder': folder,
      if (subject != null) 'subject': subject,
      if (fromAddress != null) 'from_address': fromAddress,
      if (fromName != null) 'from_name': fromName,
      if (toAddresses != null) 'to_addresses': toAddresses,
      if (ccAddresses != null) 'cc_addresses': ccAddresses,
      if (dateEpochMs != null) 'date_epoch_ms': dateEpochMs,
      if (bodyText != null) 'body_text': bodyText,
      if (bodyHtml != null) 'body_html': bodyHtml,
      if (isRead != null) 'is_read': isRead,
      if (isStarred != null) 'is_starred': isStarred,
      if (labels != null) 'labels': labels,
      if (spamStatus != null) 'spam_status': spamStatus,
      if (translatedBodyJa != null) 'translated_body_ja': translatedBodyJa,
      if (messageId != null) 'message_id': messageId,
      if (inReplyTo != null) 'in_reply_to': inReplyTo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? folder,
    Value<String>? subject,
    Value<String>? fromAddress,
    Value<String>? fromName,
    Value<String>? toAddresses,
    Value<String>? ccAddresses,
    Value<int>? dateEpochMs,
    Value<String>? bodyText,
    Value<String>? bodyHtml,
    Value<bool>? isRead,
    Value<bool>? isStarred,
    Value<String>? labels,
    Value<String>? spamStatus,
    Value<String?>? translatedBodyJa,
    Value<String?>? messageId,
    Value<String?>? inReplyTo,
    Value<int>? rowid,
  }) {
    return MessagesTableCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      folder: folder ?? this.folder,
      subject: subject ?? this.subject,
      fromAddress: fromAddress ?? this.fromAddress,
      fromName: fromName ?? this.fromName,
      toAddresses: toAddresses ?? this.toAddresses,
      ccAddresses: ccAddresses ?? this.ccAddresses,
      dateEpochMs: dateEpochMs ?? this.dateEpochMs,
      bodyText: bodyText ?? this.bodyText,
      bodyHtml: bodyHtml ?? this.bodyHtml,
      isRead: isRead ?? this.isRead,
      isStarred: isStarred ?? this.isStarred,
      labels: labels ?? this.labels,
      spamStatus: spamStatus ?? this.spamStatus,
      translatedBodyJa: translatedBodyJa ?? this.translatedBodyJa,
      messageId: messageId ?? this.messageId,
      inReplyTo: inReplyTo ?? this.inReplyTo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) map['id'] = Variable<String>(id.value);
    if (accountId.present) map['account_id'] = Variable<String>(accountId.value);
    if (folder.present) map['folder'] = Variable<String>(folder.value);
    if (subject.present) map['subject'] = Variable<String>(subject.value);
    if (fromAddress.present) map['from_address'] = Variable<String>(fromAddress.value);
    if (fromName.present) map['from_name'] = Variable<String>(fromName.value);
    if (toAddresses.present) map['to_addresses'] = Variable<String>(toAddresses.value);
    if (ccAddresses.present) map['cc_addresses'] = Variable<String>(ccAddresses.value);
    if (dateEpochMs.present) map['date_epoch_ms'] = Variable<int>(dateEpochMs.value);
    if (bodyText.present) map['body_text'] = Variable<String>(bodyText.value);
    if (bodyHtml.present) map['body_html'] = Variable<String>(bodyHtml.value);
    if (isRead.present) map['is_read'] = Variable<bool>(isRead.value);
    if (isStarred.present) map['is_starred'] = Variable<bool>(isStarred.value);
    if (labels.present) map['labels'] = Variable<String>(labels.value);
    if (spamStatus.present) map['spam_status'] = Variable<String>(spamStatus.value);
    if (translatedBodyJa.present) {
      map['translated_body_ja'] = Variable<String>(translatedBodyJa.value);
    }
    if (messageId.present) map['message_id'] = Variable<String>(messageId.value);
    if (inReplyTo.present) map['in_reply_to'] = Variable<String>(inReplyTo.value);
    if (rowid.present) map['rowid'] = Variable<int>(rowid.value);
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesTableCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('folder: $folder, ')
          ..write('subject: $subject, ')
          ..write('fromAddress: $fromAddress, ')
          ..write('fromName: $fromName, ')
          ..write('toAddresses: $toAddresses, ')
          ..write('ccAddresses: $ccAddresses, ')
          ..write('dateEpochMs: $dateEpochMs, ')
          ..write('bodyText: $bodyText, ')
          ..write('bodyHtml: $bodyHtml, ')
          ..write('isRead: $isRead, ')
          ..write('isStarred: $isStarred, ')
          ..write('labels: $labels, ')
          ..write('spamStatus: $spamStatus, ')
          ..write('translatedBodyJa: $translatedBodyJa, ')
          ..write('messageId: $messageId, ')
          ..write('inReplyTo: $inReplyTo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTableTable extends MessagesTable
    with TableInfo<$MessagesTableTable, MessagesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;

  $MessagesTableTable(this.attachedDatabase, [this._alias]);

  static const VerificationMeta _idMeta = VerificationMeta('id');
  static const VerificationMeta _accountIdMeta = VerificationMeta('accountId');
  static const VerificationMeta _folderMeta = VerificationMeta('folder');
  static const VerificationMeta _subjectMeta = VerificationMeta('subject');
  static const VerificationMeta _fromAddressMeta =
      VerificationMeta('fromAddress');
  static const VerificationMeta _fromNameMeta = VerificationMeta('fromName');
  static const VerificationMeta _toAddressesMeta =
      VerificationMeta('toAddresses');
  static const VerificationMeta _ccAddressesMeta =
      VerificationMeta('ccAddresses');
  static const VerificationMeta _dateEpochMsMeta =
      VerificationMeta('dateEpochMs');
  static const VerificationMeta _bodyTextMeta = VerificationMeta('bodyText');
  static const VerificationMeta _bodyHtmlMeta = VerificationMeta('bodyHtml');
  static const VerificationMeta _isReadMeta = VerificationMeta('isRead');
  static const VerificationMeta _isStarredMeta = VerificationMeta('isStarred');
  static const VerificationMeta _labelsMeta = VerificationMeta('labels');
  static const VerificationMeta _spamStatusMeta =
      VerificationMeta('spamStatus');
  static const VerificationMeta _translatedBodyJaMeta =
      VerificationMeta('translatedBodyJa');
  static const VerificationMeta _messageIdMeta = VerificationMeta('messageId');
  static const VerificationMeta _inReplyToMeta = VerificationMeta('inReplyTo');

  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);

  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);

  @override
  late final GeneratedColumn<String> folder = GeneratedColumn<String>(
      'folder', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('INBOX'));

  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
      'subject', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));

  @override
  late final GeneratedColumn<String> fromAddress = GeneratedColumn<String>(
      'from_address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);

  @override
  late final GeneratedColumn<String> fromName = GeneratedColumn<String>(
      'from_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));

  @override
  late final GeneratedColumn<String> toAddresses = GeneratedColumn<String>(
      'to_addresses', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));

  @override
  late final GeneratedColumn<String> ccAddresses = GeneratedColumn<String>(
      'cc_addresses', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));

  @override
  late final GeneratedColumn<int> dateEpochMs = GeneratedColumn<int>(
      'date_epoch_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);

  @override
  late final GeneratedColumn<String> bodyText = GeneratedColumn<String>(
      'body_text', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));

  @override
  late final GeneratedColumn<String> bodyHtml = GeneratedColumn<String>(
      'body_html', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));

  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
      'is_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultValue: const Constant(false));

  @override
  late final GeneratedColumn<bool> isStarred = GeneratedColumn<bool>(
      'is_starred', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultValue: const Constant(false));

  @override
  late final GeneratedColumn<String> labels = GeneratedColumn<String>(
      'labels', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));

  @override
  late final GeneratedColumn<String> spamStatus = GeneratedColumn<String>(
      'spam_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('clean'));

  @override
  late final GeneratedColumn<String> translatedBodyJa = GeneratedColumn<String>(
      'translated_body_ja', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);

  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);

  @override
  late final GeneratedColumn<String> inReplyTo = GeneratedColumn<String>(
      'in_reply_to', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);

  @override
  List<GeneratedColumn> get $columns => [
        id,
        accountId,
        folder,
        subject,
        fromAddress,
        fromName,
        toAddresses,
        ccAddresses,
        dateEpochMs,
        bodyText,
        bodyHtml,
        isRead,
        isStarred,
        labels,
        spamStatus,
        translatedBodyJa,
        messageId,
        inReplyTo,
      ];

  @override
  String get aliasedName => _alias ?? actualTableName;

  @override
  String get actualTableName => $name;
  static const String $name = 'messages_table';

  @override
  VerificationContext validateIntegrity(
      Insertable<MessagesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('folder')) {
      context.handle(_folderMeta,
          folder.isAcceptableOrUnknown(data['folder']!, _folderMeta));
    }
    if (data.containsKey('subject')) {
      context.handle(_subjectMeta,
          subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta));
    }
    if (data.containsKey('from_address')) {
      context.handle(
          _fromAddressMeta,
          fromAddress.isAcceptableOrUnknown(
              data['from_address']!, _fromAddressMeta));
    } else if (isInserting) {
      context.missing(_fromAddressMeta);
    }
    if (data.containsKey('from_name')) {
      context.handle(_fromNameMeta,
          fromName.isAcceptableOrUnknown(data['from_name']!, _fromNameMeta));
    }
    if (data.containsKey('to_addresses')) {
      context.handle(
          _toAddressesMeta,
          toAddresses.isAcceptableOrUnknown(
              data['to_addresses']!, _toAddressesMeta));
    }
    if (data.containsKey('cc_addresses')) {
      context.handle(
          _ccAddressesMeta,
          ccAddresses.isAcceptableOrUnknown(
              data['cc_addresses']!, _ccAddressesMeta));
    }
    if (data.containsKey('date_epoch_ms')) {
      context.handle(
          _dateEpochMsMeta,
          dateEpochMs.isAcceptableOrUnknown(
              data['date_epoch_ms']!, _dateEpochMsMeta));
    } else if (isInserting) {
      context.missing(_dateEpochMsMeta);
    }
    if (data.containsKey('body_text')) {
      context.handle(_bodyTextMeta,
          bodyText.isAcceptableOrUnknown(data['body_text']!, _bodyTextMeta));
    }
    if (data.containsKey('body_html')) {
      context.handle(_bodyHtmlMeta,
          bodyHtml.isAcceptableOrUnknown(data['body_html']!, _bodyHtmlMeta));
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    }
    if (data.containsKey('is_starred')) {
      context.handle(_isStarredMeta,
          isStarred.isAcceptableOrUnknown(data['is_starred']!, _isStarredMeta));
    }
    if (data.containsKey('labels')) {
      context.handle(_labelsMeta,
          labels.isAcceptableOrUnknown(data['labels']!, _labelsMeta));
    }
    if (data.containsKey('spam_status')) {
      context.handle(
          _spamStatusMeta,
          spamStatus.isAcceptableOrUnknown(
              data['spam_status']!, _spamStatusMeta));
    }
    if (data.containsKey('translated_body_ja')) {
      context.handle(
          _translatedBodyJaMeta,
          translatedBodyJa.isAcceptableOrUnknown(
              data['translated_body_ja']!, _translatedBodyJaMeta));
    }
    if (data.containsKey('message_id')) {
      context.handle(
          _messageIdMeta,
          messageId.isAcceptableOrUnknown(
              data['message_id']!, _messageIdMeta));
    }
    if (data.containsKey('in_reply_to')) {
      context.handle(
          _inReplyToMeta,
          inReplyTo.isAcceptableOrUnknown(
              data['in_reply_to']!, _inReplyToMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id, accountId};

  @override
  MessagesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessagesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      folder: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folder'])!,
      subject: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject'])!,
      fromAddress: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}from_address'])!,
      fromName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}from_name'])!,
      toAddresses: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}to_addresses'])!,
      ccAddresses: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cc_addresses'])!,
      dateEpochMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}date_epoch_ms'])!,
      bodyText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body_text'])!,
      bodyHtml: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body_html'])!,
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_read'])!,
      isStarred: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_starred'])!,
      labels: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}labels'])!,
      spamStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}spam_status'])!,
      translatedBodyJa: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}translated_body_ja']),
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id']),
      inReplyTo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}in_reply_to']),
    );
  }

  @override
  $MessagesTableTable createAlias(String alias) {
    return $MessagesTableTable(attachedDatabase, alias);
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);

  late final $MessagesTableTable messagesTable = $MessagesTableTable(this);

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [messagesTable];
}
