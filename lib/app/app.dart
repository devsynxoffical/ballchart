import 'package:flutter/material.dart';
import 'package:ballchart/app/theme.dart';
import 'package:ballchart/features/splash/view/splash_screen.dart';

import '../routes/app_routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BallChart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Use `home` (not initialRoute '/splash') so Flutter does not also
      // push a bare '/' route that becomes the "Route not found" screen
      // sitting under the whole app and showing up on back.
      home: const SplashScreen(),
      onGenerateRoute: AppRoutes.generate,
    );
  }
}
