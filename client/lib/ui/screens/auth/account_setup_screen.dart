import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/email_account.dart';
import '../../../domain/repositories/account_repository.dart';

class AccountSetupScreen extends ConsumerStatefulWidget {
  const AccountSetupScreen({super.key});

  @override
  ConsumerState<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends ConsumerState<AccountSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _incomingHostCtrl = TextEditingController();
  final _incomingPortCtrl = TextEditingController(text: '993');
  final _smtpHostCtrl = TextEditingController();
  final _smtpPortCtrl = TextEditingController(text: '587');

  bool _incomingTls = true;
  bool _smtpTls = true;
  bool _showAdvanced = false;
  bool _saving = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    for (final c in [
      _emailCtrl, _passwordCtrl, _displayNameCtrl,
      _incomingHostCtrl, _incomingPortCtrl,
      _smtpHostCtrl, _smtpPortCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _autoFill(String email) {
    final domain = email.split('@').lastOrNull ?? '';
    // Common provider auto-detect
    final map = {
      'gmail.com': ('imap.gmail.com', 'smtp.gmail.com'),
      'outlook.com': ('outlook.office365.com', 'smtp.office365.com'),
      'hotmail.com': ('outlook.office365.com', 'smtp.office365.com'),
      'icloud.com': ('imap.mail.me.com', 'smtp.mail.me.com'),
      'yahoo.com': ('imap.mail.yahoo.com', 'smtp.mail.yahoo.com'),
      'yahoo.co.jp': ('imap.mail.yahoo.co.jp', 'smtp.mail.yahoo.co.jp'),
    };
    final detected = map[domain];
    if (detected != null) {
      _incomingHostCtrl.text = detected.$1;
      _smtpHostCtrl.text = detected.$2;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final account = EmailAccount(
      id: newAccountId(),
      email: _emailCtrl.text.trim(),
      displayName: _displayNameCtrl.text.trim().isEmpty
          ? _emailCtrl.text.trim()
          : _displayNameCtrl.text.trim(),
      incomingHost: _incomingHostCtrl.text.trim(),
      incomingPort: int.tryParse(_incomingPortCtrl.text) ?? 993,
      incomingTls: _incomingTls,
      smtpHost: _smtpHostCtrl.text.trim(),
      smtpPort: int.tryParse(_smtpPortCtrl.text) ?? 587,
      smtpTls: _smtpTls,
      isDefault: true,
    );

    try {
      await ref.read(accountRepositoryProvider).saveAccount(
            account,
            password: _passwordCtrl.text,
          );
      // Invalidate cached accounts list
      ref.invalidate(accountsProvider);
      if (mounted) context.go('/inbox');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('アカウントを追加')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'メールアドレス',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || !v.contains('@') ? '有効なメールアドレスを入力してください' : null,
                onChanged: _autoFill,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'パスワード / アプリパスワード',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'パスワードを入力してください' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _displayNameCtrl,
                decoration: const InputDecoration(
                  labelText: '表示名（任意）',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
                icon: Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more),
                label: Text(_showAdvanced ? 'サーバー設定を隠す' : 'サーバー設定を表示（IMAP/SMTP）'),
              ),
              if (_showAdvanced) ...[
                const SizedBox(height: 16),
                _sectionLabel('受信サーバー（IMAP）'),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _incomingHostCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ホスト',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? '必須' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _incomingPortCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ポート',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(children: [
                    const Text('TLS', style: TextStyle(fontSize: 12)),
                    Switch(
                      value: _incomingTls,
                      onChanged: (v) => setState(() => _incomingTls = v),
                    ),
                  ]),
                ]),
                const SizedBox(height: 16),
                _sectionLabel('送信サーバー（SMTP）'),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _smtpHostCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ホスト',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? '必須' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _smtpPortCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ポート',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(children: [
                    const Text('TLS', style: TextStyle(fontSize: 12)),
                    Switch(
                      value: _smtpTls,
                      onChanged: (v) => setState(() => _smtpTls = v),
                    ),
                  ]),
                ]),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('アカウントを追加'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: Theme.of(context).textTheme.labelLarge,
      );
}
