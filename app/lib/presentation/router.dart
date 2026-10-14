import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/dates.dart';
import 'pages/auth/forgot_password_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/auth/verify_email_page.dart';
import 'pages/calendar/calendar_page.dart';
import 'pages/event/event_form_page.dart';
import 'pages/groups/group_detail_page.dart';
import 'pages/groups/groups_page.dart';
import 'pages/home_shell.dart';
import 'pages/settings/notification_settings_page.dart';
import 'pages/settings/settings_page.dart';
import 'pages/settings/theme_settings_page.dart';
import 'providers/auth_controller.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

const _authRoutes = {'/login', '/register', '/verify', '/forgot'};

final routerProvider = Provider<GoRouter>((ref) {
  final status = ValueNotifier(ref.read(authProvider).status);
  ref.listen(authProvider, (_, next) => status.value = next.status);
  ref.onDispose(status.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/calendar',
    refreshListenable: status,
    redirect: (context, state) {
      final signedIn = status.value == AuthStatus.signedIn;
      final onAuthRoute = _authRoutes.contains(state.matchedLocation);
      if (!signedIn && !onAuthRoute) return '/login';
      if (signedIn && onAuthRoute) return '/calendar';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterPage()),
      GoRoute(
        path: '/verify',
        builder: (_, state) => VerifyEmailPage(email: state.uri.queryParameters['email'] ?? ''),
      ),
      GoRoute(
        path: '/forgot',
        builder: (_, state) => ForgotPasswordPage(email: state.uri.queryParameters['email'] ?? ''),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/calendar', builder: (_, _) => const CalendarPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/groups',
              builder: (_, _) => const GroupsPage(),
              routes: [
                GoRoute(path: ':id', builder: (_, state) => GroupDetailPage(groupId: state.pathParameters['id']!)),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const SettingsPage(),
              routes: [
                GoRoute(path: 'theme', builder: (_, _) => const ThemeSettingsPage()),
                GoRoute(path: 'notifications', builder: (_, _) => const NotificationSettingsPage()),
              ],
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/event/new',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, state) {
          final date = state.uri.queryParameters['date'];
          return MaterialPage(
            fullscreenDialog: true,
            child: EventFormPage(
              initialDate: date == null ? null : Dates.parseKey(date),
              initialTitle: state.uri.queryParameters['title'],
            ),
          );
        },
      ),
      GoRoute(
        path: '/event/:id/edit',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, state) {
          final occurrence = state.uri.queryParameters['occurrence'];
          return MaterialPage(
            fullscreenDialog: true,
            child: EventFormPage(
              eventId: state.pathParameters['id'],
              occurrenceDate: occurrence == null ? null : Dates.parseKey(occurrence),
            ),
          );
        },
      ),
    ],
  );
});
