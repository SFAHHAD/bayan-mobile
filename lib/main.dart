import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/config/supabase_config.dart';
import 'package:bayan/l10n/app_localizations.dart';
import 'package:bayan/core/providers/core_providers.dart';
import 'package:bayan/core/providers/locale_provider.dart';
import 'package:bayan/core/repositories/log_repository.dart';
import 'package:bayan/core/services/cache_service.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/features/waitlist/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: BayanColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await CacheService.init();

  final sessionId = _generateSessionId();
  LogRepository.configure(
    appVersion: '1.5.0',
    platform: 'flutter',
    sessionId: sessionId,
  );

  final container = ProviderContainer();
  final logRepo = container.read(logRepositoryProvider);
  logRepo.installGlobalHandlers();

  await container.read(crashRecoveryServiceProvider).onAppStart(sessionId);

  runApp(
    UncontrolledProviderScope(container: container, child: const BayanApp()),
  );
}

String _generateSessionId() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rand = Random.secure();
  return List.generate(16, (_) => chars[rand.nextInt(chars.length)]).join();
}

class BayanApp extends ConsumerWidget {
  const BayanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      title: 'Bayan',
      debugShowCheckedModeBanner: false,
      theme: BayanTheme.dark,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      home: const SplashScreen(),
    );
  }
}
