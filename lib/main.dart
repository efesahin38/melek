import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_DE', null);
  runApp(const MelekApp());
}

class MelekApp extends StatelessWidget {
  const MelekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'MELEK',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        builder: (context, child) {
          return Container(
            color: Colors.black,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgDark,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldPrimary.withOpacity(0.05),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                    border: Border(
                      left: BorderSide(color: AppTheme.borderGold.withOpacity(0.2), width: 1),
                      right: BorderSide(color: AppTheme.borderGold.withOpacity(0.2), width: 1),
                    ),
                  ),
                  child: ClipRect(child: child),
                ),
              ),
            ),
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}
