import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/events_provider.dart';
import 'providers/passport_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/root_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

/// Root widget: wires up every provider and decides the start screen.
///
/// [PassportProvider] depends on [EventsProvider] (it flips an event from
/// "RSVP'd" to "attended" on check-in), so we hand it the same instance via
/// [ChangeNotifierProxyProvider] rather than letting it construct its own.
class AnzaApp extends StatelessWidget {
  final StorageService storageService;

  const AnzaApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        ChangeNotifierProvider(create: (_) => AuthProvider(storageService)),
        ChangeNotifierProvider(create: (_) => EventsProvider(storageService)),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProxyProvider<EventsProvider, PassportProvider>(
          create: (context) => PassportProvider(storageService, context.read<EventsProvider>()),
          update: (_, _, previous) => previous!,
        ),
      ],
      child: MaterialApp(
        title: 'Anza',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _StartScreen(),
      ),
    );
  }
}

/// Picks the first screen based on persisted state:
///   • signed in already → straight into the app shell (RSVPs re-applied)
///   • seen onboarding before but signed out → sign in / sign up
///   • brand new device → onboarding intro
class _StartScreen extends StatefulWidget {
  const _StartScreen();

  @override
  State<_StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<_StartScreen> {
  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      // Re-apply this user's persisted RSVPs onto the freshly seeded
      // events — must happen after the first frame so provider creation
      // (and its listeners) has settled.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<EventsProvider>().hydrateRsvpsForUser(user.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final storage = context.read<StorageService>();

    if (auth.isSignedIn) return const RootScreen();
    if (storage.hasCompletedOnboarding) return const AuthScreen();
    return const OnboardingScreen();
  }
}
