import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/stitch_theme.dart';
import 'services/auth_service.dart';
import 'features/auth/login_screen.dart';
import 'navigation/bottom_nav_bar.dart';

class UniriseApp extends StatelessWidget {
  const UniriseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'UNIRISE',
        debugShowCheckedModeBanner: false,
        theme: StitchTheme.darkTheme,
        home: Consumer<AuthService>(
          builder: (context, auth, _) {
            if (auth.isLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: StitchTheme.primaryCyan),
                ),
              );
            }
            if (auth.isAuthenticated) {
              return const MainNavigationScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
