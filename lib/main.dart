import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/viewmodel/auth_viewmodel.dart';
import 'features/battle/viewmodel/battle_viewmodel.dart';
import 'features/home/viewmodel/home_viewmodel.dart';
import 'features/profile/viewmodel/profile_viewmodel.dart';
import 'features/auth/completeyourprofile/viewmodel/profile_setup_viewmodel.dart';
import 'features/management/viewmodel/academy_provider.dart';
import 'app/app.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewmodel()),
        ChangeNotifierProvider(create: (_) => BattleViewmodel()),
        ChangeNotifierProvider(create: (_) => ProfileViewmodel()),
        ChangeNotifierProvider(create: (_) => ProfileSetupViewmodel()),
        ChangeNotifierProvider(create: (_) => AcademyProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
