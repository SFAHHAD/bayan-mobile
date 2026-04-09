import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/config/supabase_config.dart';
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

  runApp(const ProviderScope(child: BayanApp()));
}

class BayanApp extends StatelessWidget {
  const BayanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bayan',
      debugShowCheckedModeBanner: false,
      theme: BayanTheme.dark,
      locale: const Locale('ar', 'KW'),
      supportedLocales: const [Locale('ar', 'KW')],
      localizationsDelegates: const [
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
