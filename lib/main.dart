import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/viewmodel/auth_viewmodel.dart';
import 'features/battle/viewmodel/battle_viewmodel.dart';
import 'app/app.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewmodel()),
        ChangeNotifierProvider(create: (_) => BattleViewmodel()),
      ],
      child: const MyApp(),
    ),
  );
}


