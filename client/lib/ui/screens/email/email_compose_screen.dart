import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/email_account.dart';
import '../../../domain/models/email_message.dart';
import '../../../domain/repositories/account_repository.dart';
import '../../../mail/smtp_client.dart';

class EmailComposeScreen extends ConsumerStatefulWidget {
  final ComposeArgs args;
  const EmailComposeScreen({super.key, required this.args});

  @override
  ConsumerState<EmailComposeScreen> createState() => _EmailComposeScreenState();
}

class _EmailComposeScreenState extends ConsumerState<EmailComposeScreen> {
  final _toCtrl = TextEditingController();
  final _ccCtrl = TextEditingController();
  final _bccCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  bool _showCcBcc = false;
  bool _sending = false;
  final List<File> _attachments = [];
  EmailAccount? _selectedAccount;

  @override
  void initState() {
    super.initState();
    final replyTo = widget.args.replyTo;
    final forward = widget.args.forwardOf;

    if (replyTo != null) {
      _toCtrl.text = replyTo.from.address;
      _subjectCtrl.text = replyTo.subject.startsWith('Re:')
          ? replyTo.subject
          : 'Re: ${replyTo.subject}';
      _bodyCtrl.text = '\n\n---\n${replyTo.from.displayName} wrote:\n${replyTo.bodyText}';
    } else if (forward != null) {
      _subjectCtrl.text = forward.subject.startsWith('Fwd:')
          ? forward.subject
          : 'Fwd: ${forward.subject}';
      _bodyCtrl.text = '\n\n--- Forwarded message ---\n${forward.bodyText}';
    }
  }

  @override
  void dispose() {
    for (final c in [_toCtrl, _ccCtrl, _bccCtrl, _subjectCtrl, _bodyCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  List<EmailAddress> _parseAddrs(String raw) => raw
      .split(RegExp(r'[,;]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .map((s) => EmailAddress(address: s))
      .toList();

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;
    setState(() {
      _attachments.addAll(result.paths.whereType<String>().map(File.new));
    });
  }

  Future<void> _send() async {
    final account = _selectedAccount;
    if (account == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('送信アカウントを選択してください')));
      return;
    }
    if (_toCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('宛先を入力してください')));
      return;
    }

    setState(() => _sending = true);
    try {
      final password = await ref
          .read(accountRepositoryProvider)
          .readPassword(account.id);
      final client = SmtpEmailClient(account: account, password: password);
      await client.sendMessage(
        to: _parseAddrs(_toCtrl.text),
        cc: _parseAddrs(_ccCtrl.text),
        bcc: _parseAddrs(_bccCtrl.text),
        subject: _subjectCtrl.text,
        bodyText: _bodyCtrl.text,
        replyTo: widget.args.replyTo,
        forwardOf: widget.args.forwardOf,
        attachments: _attachments,
        signatureHtml: account.signatureHtml,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('送信しました')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('送信失敗: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.args.isReply
            ? '返信'
            : widget.args.isForward
                ? '転送'
                : '新規作成'),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _pickAttachment,
          ),
          IconButton(
            icon: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            onPressed: _sending ? null : _send,
          ),
        ],
      ),
      body: Column(
        children: [
          // Account selector
          accountsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (accounts) {
              _selectedAccount ??=
                  accounts.firstWhere((a) => a.isDefault, orElse: () => accounts.first);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButton<EmailAccount>(
                  isExpanded: true,
                  value: _selectedAccount,
                  items: accounts
                      .map((a) => DropdownMenuItem(
                            value: a,
                            child: Text(a.email),
                          ))
                      .toList(),
                  onChanged: (a) => setState(() => _selectedAccount = a),
                ),
              );
            },
          ),
          _AddressField(label: 'To', controller: _toCtrl),
          Row(children: [
            Expanded(
              child: TextButton(
                onPressed: () =>
                    setState(() => _showCcBcc = !_showCcBcc),
                child: Text(_showCcBcc ? 'Cc/Bcc を隠す' : 'Cc/Bcc を追加'),
              ),
            ),
          ]),
          if (_showCcBcc) ...[
            _AddressField(label: 'Cc', controller: _ccCtrl),
            _AddressField(label: 'Bcc', controller: _bccCtrl),
          ],
          const Divider(height: 1),
          _SubjectField(controller: _subjectCtrl),
          const Divider(height: 1),
          if (_attachments.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: _attachments.map((f) {
                  return Chip(
                    label: Text(f.path.split('/').last),
                    onDeleted: () =>
                        setState(() => _attachments.remove(f)),
                  );
                }).toList(),
              ),
            ),
          Expanded(
            child: TextField(
              controller: _bodyCtrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(16),
                border: InputBorder.none,
                hintText: 'メッセージを入力...',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _AddressField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(label,
                style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectField extends StatelessWidget {
  final TextEditingController controller;
  const _SubjectField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        SizedBox(
          width: 40,
          child: Text('件名', style: Theme.of(context).textTheme.labelMedium),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
      ]),
    );
  }
}
