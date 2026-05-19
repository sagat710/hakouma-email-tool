import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../domain/models/email_message.dart';
import '../../../domain/repositories/email_repository.dart';
import '../../../domain/services/sync_service.dart';

final _emailViewProvider =
    FutureProvider.family<EmailMessage?, String>((ref, compositeId) async {
  final parts = compositeId.split('|');
  if (parts.length < 2) return null;
  final msgId = parts[0];
  final accountId = parts[1];
  final db = ref.watch(appDatabaseProvider);
  final row = await db.getMessage(msgId, accountId);
  if (row == null) return null;
  return _rowToMessage(row);
});

EmailMessage _rowToMessage(MessagesTableData r) {
  return EmailMessage(
    id: r.id,
    accountId: r.accountId,
    folder: r.folder,
    subject: r.subject,
    from: EmailAddress(address: r.fromAddress, name: r.fromName),
    date: DateTime.fromMillisecondsSinceEpoch(r.dateEpochMs),
    bodyText: r.bodyText,
    bodyHtml: r.bodyHtml,
    isRead: r.isRead,
    isStarred: r.isStarred,
    spamStatus: SpamStatus.values.byName(r.spamStatus),
    translatedBodyJa: r.translatedBodyJa,
    messageId: r.messageId,
    inReplyTo: r.inReplyTo,
  );
}

class EmailViewScreen extends ConsumerStatefulWidget {
  /// Format: "${messageId}|${accountId}"
  final String messageId;

  const EmailViewScreen({super.key, required this.messageId});

  @override
  ConsumerState<EmailViewScreen> createState() => _EmailViewScreenState();
}

class _EmailViewScreenState extends ConsumerState<EmailViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_emailViewProvider(widget.messageId));

    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('エラー: $e'))),
      data: (msg) {
        if (msg == null) {
          return const Scaffold(body: Center(child: Text('メールが見つかりません')));
        }
        return _buildContent(msg);
      },
    );
  }

  Widget _buildContent(EmailMessage msg) {
    final showTranslate = msg.looksEnglish;
    final tabCount = showTranslate ? 2 : 1;
    if (_tabController.length != tabCount) {
      _tabController.dispose();
      _tabController = TabController(length: tabCount, vsync: this);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(msg.subject, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(msg.isStarred ? Icons.star : Icons.star_border,
                color: msg.isStarred ? Colors.amber : null),
            onPressed: () => ref
                .read(syncServiceProvider)
                .markStarred(msg, starred: !msg.isStarred),
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'reply') {
                context.push('/inbox/compose',
                    extra: ComposeArgs(replyTo: msg));
              } else if (val == 'forward') {
                context.push('/inbox/compose',
                    extra: ComposeArgs(forwardOf: msg));
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'reply', child: Text('返信')),
              PopupMenuItem(value: 'forward', child: Text('転送')),
            ],
          ),
        ],
        bottom: showTranslate
            ? TabBar(
                controller: _tabController,
                tabs: const [Tab(text: '原文'), Tab(text: '日本語訳')],
              )
            : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderCard(msg: msg),
          Expanded(
            child: showTranslate
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _BodyView(msg: msg, translated: false),
                      _BodyView(msg: msg, translated: true),
                    ],
                  )
                : _BodyView(msg: msg, translated: false),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () =>
            context.push('/inbox/compose', extra: ComposeArgs(replyTo: msg)),
        child: const Icon(Icons.reply),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final EmailMessage msg;
  const _HeaderCard({required this.msg});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy/MM/dd HH:mm').format(msg.date.toLocal());
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(msg.subject,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 4),
          Row(children: [
            CircleAvatar(
              radius: 16,
              child: Text(
                msg.from.displayName.isNotEmpty
                    ? msg.from.displayName[0].toUpperCase()
                    : '?',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(msg.from.displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                  Text(msg.from.address,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Text(dateStr, style: Theme.of(context).textTheme.bodySmall),
          ]),
          if (msg.to.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 40),
              child: Text(
                'To: ${msg.to.map((a) => a.displayName).join(', ')}',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const Divider(height: 16),
        ],
      ),
    );
  }
}

class _BodyView extends StatelessWidget {
  final EmailMessage msg;
  final bool translated;
  const _BodyView({required this.msg, required this.translated});

  @override
  Widget build(BuildContext context) {
    if (translated) {
      final text = msg.translatedBodyJa;
      if (text == null || text.isEmpty) {
        return const Center(child: Text('翻訳がまだありません'));
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(text),
      );
    }

    if (msg.hasHtml) {
      return SingleChildScrollView(
        child: Html(data: msg.bodyHtml),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(msg.bodyText),
    );
  }
}
