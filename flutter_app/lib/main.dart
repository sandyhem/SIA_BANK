import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize dependencies here (Hive, SharedPreferences, etc.)
  runApp(const ProviderScope(child: SiaBankApp()));
}

class SiaBankApp extends StatelessWidget {
  const SiaBankApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'SIA Bank',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          navigatorKey: GlobalKey<NavigatorState>(),
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/splash':
                return MaterialPageRoute(builder: (_) => const SplashScreen());
              case '/login':
                return MaterialPageRoute(builder: (_) => const LoginScreen());
              case '/home':
                return MaterialPageRoute(builder: (_) => const HomeScreen());
              default:
                return MaterialPageRoute(builder: (_) => const SplashScreen());
            }
          },
          home: child,
        );
      },
      child: const SplashScreen(),
    );
  }
}
