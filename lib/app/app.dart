import 'package:flutter/material.dart';
import 'package:courtiq/app/theme.dart';

import '../routes/app_routes.dart';
import '../routes/routes_names.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CourtIQ',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.darkTheme,

      initialRoute: RouteNames.splash,

      onGenerateRoute: AppRoutes.generate,
    );
  }
}
