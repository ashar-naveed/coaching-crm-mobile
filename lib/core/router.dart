import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/shell/coach_shell.dart';
import '../features/shell/client_shell.dart';
import '../features/coach/home_screen.dart' as coach_home;
import '../features/coach/clients_screen.dart' as coach_clients;
import '../features/coach/sessions_screen.dart' as coach_sessions;
import '../features/coach/chat_screen.dart' as coach_chat;
import '../features/coach/profile_screen.dart' as coach_profile;
import '../features/coach/actions_screen.dart';
import '../features/coach/announcements_screen.dart';
import '../features/coach/settings_screen.dart';
import '../features/client/home_screen.dart' as client_home;
import '../features/client/goals_screen.dart' as client_goals;
import '../features/client/sessions_screen.dart' as client_sessions;
import '../features/client/chat_screen.dart' as client_chat;
import '../features/client/profile_screen.dart' as client_profile;

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final user = authState.value;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      if (user == null && !isAuthRoute) return '/login';
      if (user != null && isAuthRoute) return '/loading';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/loading', builder: (_, __) => const RoleRedirectScreen()),

      ShellRoute(
        builder: (context, state, child) => CoachShell(child: child),
        routes: [
          GoRoute(
            path: '/coach/home',
            builder: (_, __) => const coach_home.CoachHomeScreen(),
          ),
          GoRoute(
            path: '/coach/clients',
            builder: (_, __) => const coach_clients.CoachClientsScreen(),
          ),
          GoRoute(
            path: '/coach/sessions',
            builder: (_, __) => const coach_sessions.CoachSessionsScreen(),
          ),
          GoRoute(
            path: '/coach/chat',
            builder: (_, __) => const coach_chat.CoachChatScreen(),
          ),
          GoRoute(
            path: '/coach/profile',
            builder: (_, __) => const coach_profile.CoachProfileScreen(),
          ),
          GoRoute(
            path: '/coach/actions',
            builder: (_, __) => const ActionsScreen(),
          ),
          GoRoute(
            path: '/coach/announcements',
            builder: (_, __) => const AnnouncementsScreen(),
          ),
          GoRoute(
            path: '/coach/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),

      ShellRoute(
        builder: (context, state, child) => ClientShell(child: child),
        routes: [
          GoRoute(
            path: '/client/home',
            builder: (_, __) => const client_home.ClientHomeScreen(),
          ),
          GoRoute(
            path: '/client/goals',
            builder: (_, __) => const client_goals.ClientGoalsScreen(),
          ),
          GoRoute(
            path: '/client/sessions',
            builder: (_, __) => const client_sessions.ClientSessionsScreen(),
          ),
          GoRoute(
            path: '/client/chat',
            builder: (_, __) => const client_chat.ClientChatScreen(),
          ),
          GoRoute(
            path: '/client/profile',
            builder: (_, __) => const client_profile.ClientProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

class RoleRedirectScreen extends ConsumerWidget {
  const RoleRedirectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => _spinner(),
      error: (_, __) => _error('Auth error.'),
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => context.go('/login'),
          );
          return _spinner();
        }
        final userDoc = ref.watch(userDocProvider(user.uid));
        return userDoc.when(
          loading: () => _spinner(),
          error: (_, __) => _error('Failed to load profile.'),
          data: (data) {
            if (data == null) return _error('User profile not found.');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final role = data['role'] as String?;
              if (role == 'coach')
                context.go('/coach/home');
              else if (role == 'client')
                context.go('/client/home');
              else
                context.go('/login');
            });
            return _spinner();
          },
        );
      },
    );
  }

  Widget _spinner() =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
  Widget _error(String msg) => Scaffold(
    body: Center(
      child: Text(msg, style: const TextStyle(color: Colors.red)),
    ),
  );
}
