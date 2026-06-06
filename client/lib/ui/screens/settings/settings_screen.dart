import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/models/email_account.dart';
import '../../../domain/repositories/account_repository.dart';
import '../../../domain/services/sync_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          // Accounts section
          const _SectionHeader(title: 'アカウント'),
          accountsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ListTile(
              title: Text('エラー: $e'),
              leading: const Icon(Icons.error, color: Colors.red),
            ),
            data: (accounts) => Column(
              children: [
                ...accounts.map((account) => _AccountTile(account: account)),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('アカウントを追加'),
                  onTap: () => context.push('/setup'),
                ),
              ],
            ),
          ),
          const Divider(),

          // Notifications section
          const _SectionHeader(title: '通知'),
          const _NotificationToggle(),
          const Divider(),

          // AI features section
          const _SectionHeader(title: 'AI機能'),
          const _AiToggle(
            prefKey: 'ai_spam',
            title: '迷惑メール自動分類',
            subtitle: 'ローカルで動作。メールはサーバーに送信されません',
          ),
          const _AiToggle(
            prefKey: 'ai_translate',
            title: '英語メールの日本語翻訳タブ',
            subtitle: 'サーバー経由でClaudeに送信されます',
          ),
          const _AiToggle(
            prefKey: 'ai_tasks',
            title: 'タスク・予定の自動提案',
            subtitle: 'サーバー経由でClaudeに送信されます',
          ),
          const Divider(),

          // App info
          const _SectionHeader(title: 'アプリ情報'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('バージョン'),
            trailing: Text('0.1.0'),
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends ConsumerWidget {
  final EmailAccount account;
  const _AccountTile({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(accountSyncStateProvider(account.id));

    return ListTile(
      leading: CircleAvatar(
        child: Text(account.displayName.isNotEmpty
            ? account.displayName[0].toUpperCase()
            : '?'),
      ),
      title: Text(account.displayName),
      subtitle: Text(account.email),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (syncState.isSyncing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (syncState.error != null)
            const Icon(Icons.error_outline, color: Colors.red, size: 18),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('アカウントを削除'),
        content: Text('${account.email} を削除しますか？\nローカルのキャッシュも削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(accountRepositoryProvider).deleteAccount(account.id);
    ref.invalidate(accountsProvider);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _NotificationToggle extends StatefulWidget {
  const _NotificationToggle();

  @override
  State<_NotificationToggle> createState() => _NotificationToggleState();
}

class _NotificationToggleState extends State<_NotificationToggle> {
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _enabled = p.getBool('notif_enabled') ?? true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('新着メール通知'),
      value: _enabled,
      onChanged: (v) async {
        setState(() => _enabled = v);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notif_enabled', v);
      },
    );
  }
}

class _AiToggle extends StatefulWidget {
  final String prefKey;
  final String title;
  final String subtitle;

  const _AiToggle({
    required this.prefKey,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_AiToggle> createState() => _AiToggleState();
}

class _AiToggleState extends State<_AiToggle> {
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _enabled = p.getBool(widget.prefKey) ?? true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(widget.title),
      subtitle: Text(widget.subtitle),
      value: _enabled,
      onChanged: (v) async {
        setState(() => _enabled = v);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(widget.prefKey, v);
      },
    );
  }
}
