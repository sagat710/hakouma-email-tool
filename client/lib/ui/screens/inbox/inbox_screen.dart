import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../domain/models/email_account.dart';
import '../../../domain/models/email_message.dart';
import '../../../domain/repositories/account_repository.dart';
import '../../../domain/repositories/email_repository.dart';
import '../../../domain/services/sync_service.dart';
import '../../../ai/spam_classifier.dart';

// ---------------------------------------------------------------------------
// Providers — message list per account + folder
// ---------------------------------------------------------------------------

final inboxMessagesProvider = FutureProvider.family<List<EmailMessage>,
    ({String accountId, String folder})>((ref, args) async {
  final db = ref.watch(appDatabaseProvider);
  final rows = await db.getMessages(
    args.accountId,
    folder: args.folder,
    limit: 60,
    excludeSpam: SpamStatus.spam,
  );
  return rows.map(_rowToMessage).toList();
});

final selectedAccountIndexProvider = StateProvider<int>((ref) => 0);

EmailMessage _rowToMessage(MessagesTableData r) => EmailMessage(
      id: r.id,
      accountId: r.accountId,
      folder: r.folder,
      subject: r.subject,
      from: EmailAddress(address: r.fromAddress, name: r.fromName),
      to: _decodeAddrs(r.toAddresses),
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

List<EmailAddress> _decodeAddrs(String raw) {
  try {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map((m) => EmailAddress(
              address: m['address'] as String,
              name: m['name'] as String?,
            ))
        .toList();
  } catch (_) {
    return [];
  }
}

// ---------------------------------------------------------------------------
// InboxScreen
// ---------------------------------------------------------------------------

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  @override
  void initState() {
    super.initState();
    // Kick off initial sync on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncServiceProvider).syncAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final selectedIdx = ref.watch(selectedAccountIndexProvider);

    return accountsAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (e, _) => Scaffold(body: Center(child: Text('エラー: $e'))),
      data: (accounts) {
        if (accounts.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('アカウントがありません')),
          );
        }
        final account = accounts[selectedIdx.clamp(0, accounts.length - 1)];
        return _InboxBody(account: account, accounts: accounts);
      },
    );
  }
}

class _InboxBody extends ConsumerWidget {
  final EmailAccount account;
  final List<EmailAccount> accounts;

  const _InboxBody({required this.account, required this.accounts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (accountId: account.id, folder: 'INBOX');
    final messagesAsync = ref.watch(inboxMessagesProvider(args));
    final syncState = ref.watch(accountSyncStateProvider(account.id));

    return Scaffold(
      appBar: AppBar(
        title: accounts.length == 1
            ? Text(account.displayName)
            : DropdownButton<int>(
                value: ref.watch(selectedAccountIndexProvider),
                underline: const SizedBox.shrink(),
                items: accounts
                    .asMap()
                    .entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value.displayName),
                        ))
                    .toList(),
                onChanged: (idx) {
                  if (idx != null) {
                    ref
                        .read(selectedAccountIndexProvider.notifier)
                        .state = idx;
                  }
                },
              ),
        actions: [
          if (syncState.isSyncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  ref.read(syncServiceProvider).syncAccount(account.id),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(syncServiceProvider).syncAccount(account.id),
        child: messagesAsync.when(
          loading: () => _ShimmerList(),
          error: (e, _) => Center(child: Text('$e')),
          data: (messages) {
            if (messages.isEmpty) {
              return const Center(child: Text('メールはありません'));
            }
            return ListView.separated(
              itemCount: messages.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (_, i) => _MessageTile(
                message: messages[i],
                accountId: account.id,
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/inbox/compose',
            extra: ComposeArgs(accountId: account.id)),
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message tile with swipe actions
// ---------------------------------------------------------------------------

class _MessageTile extends ConsumerWidget {
  final EmailMessage message;
  final String accountId;

  const _MessageTile({required this.message, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.read(syncServiceProvider);
    final isRead = message.isRead;
    final textStyle = TextStyle(
      fontWeight: isRead ? FontWeight.normal : FontWeight.w700,
    );

    return Slidable(
      key: ValueKey(message.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) =>
                sync.markRead(message, read: !isRead),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: isRead ? Icons.mark_email_unread : Icons.mark_email_read,
            label: isRead ? '未読' : '既読',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (_) =>
                sync.markStarred(message, starred: !message.isStarred),
            backgroundColor: Colors.amber,
            foregroundColor: Colors.white,
            icon: message.isStarred ? Icons.star_border : Icons.star,
            label: message.isStarred ? 'スター解除' : 'スター',
          ),
          SlidableAction(
            onPressed: (_) => _reportSpam(context, ref, message),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.report_outlined,
            label: 'スパム',
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          context.push('/inbox/email/${message.id}|${message.accountId}');
          if (!message.isRead) {
            sync.markRead(message, read: true);
          }
        },
        leading: CircleAvatar(
          child: Text(
            message.from.displayName.isNotEmpty
                ? message.from.displayName[0].toUpperCase()
                : '?',
          ),
        ),
        title: Row(children: [
          Expanded(
            child: Text(message.from.displayName,
                style: textStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Text(
            _formatDate(message.date),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                ),
          ),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.subject,
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            if (message.spamStatus == SpamStatus.ambiguous)
              const _SpamBadge(label: '怪しいメール', color: Colors.orange),
            if (message.spamStatus == SpamStatus.spam)
              const _SpamBadge(label: 'スパム', color: Colors.red),
          ],
        ),
        trailing: message.isStarred
            ? const Icon(Icons.star, color: Colors.amber, size: 18)
            : null,
      ),
    );
  }

  void _reportSpam(
      BuildContext context, WidgetRef ref, EmailMessage msg) async {
    await spamClassifierProvider.learn(msg, isSpam: true);
    ref.invalidate(inboxMessagesProvider);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return DateFormat.Hm().format(date.toLocal());
    if (diff.inDays < 7) return DateFormat.E('ja').format(date.toLocal());
    return DateFormat('MM/dd').format(date.toLocal());
  }
}

class _SpamBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _SpamBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading shimmer
// ---------------------------------------------------------------------------

class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 12,
        itemBuilder: (_, __) => ListTile(
          leading: const CircleAvatar(),
          title: Container(height: 12, color: Colors.white),
          subtitle: Container(height: 10, color: Colors.white),
        ),
      ),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
