import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'ui/screens/auth/account_setup_screen.dart';
import 'ui/screens/inbox/inbox_screen.dart';
import 'ui/screens/email/email_view_screen.dart';
import 'ui/screens/email/email_compose_screen.dart';
import 'ui/screens/settings/settings_screen.dart';
import 'domain/models/email_message.dart';
import 'domain/repositories/account_repository.dart';

final _router = GoRouter(
  initialLocation: '/inbox',
  redirect: (context, state) {
    final container = ProviderScope.containerOf(context);
    final hasAccounts = container.read(hasAccountsProvider);
    if (!hasAccounts && state.matchedLocation != '/setup') return '/setup';
    return null;
  },
  routes: [
    GoRoute(
      path: '/setup',
      builder: (_, __) => const AccountSetupScreen(),
    ),
    GoRoute(
      path: '/inbox',
      builder: (_, __) => const InboxScreen(),
      routes: [
        GoRoute(
          path: 'email/:id',
          builder: (_, state) => EmailViewScreen(
            messageId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: 'compose',
          builder: (_, state) {
            final extra = state.extra as ComposeArgs?;
            return EmailComposeScreen(args: extra ?? const ComposeArgs());
          },
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      builder: (_, __) => const SettingsScreen(),
    ),
  ],
);

class HakoumaMailApp extends ConsumerWidget {
  const HakoumaMailApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Hakouma Mail',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }

  ThemeData _lightTheme() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  ThemeData _darkTheme() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      );
}
