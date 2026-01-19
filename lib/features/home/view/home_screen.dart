import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/home/stats_row.dart';
import '../../../core/widgets/home/header.dart';
import '../../../features/auth/viewmodel/auth_viewmodel.dart';
import '../../../features/profile/viewmodel/profile_viewmodel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileViewModel = context.read<ProfileViewmodel>();
      if (profileViewModel.user == null) {
        profileViewModel.loadProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Consumer<AuthViewmodel>(
            builder: (context, authVm, child) {
              return IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () => authVm.logout(context),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Consumer<ProfileViewmodel>(
              builder: (context, viewModel, child) {
                final user = viewModel.user;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Header(),

                    const SizedBox(height: 20),

                    user != null 
                        ? StatsRow(user: user)
                        : const Center(child: CircularProgressIndicator()),
            
                    const SizedBox(height: 40),

                    // Placeholder for player specific features
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.sports_basketball, size: 80, color: Colors.amber.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text(
                            'Player Dashboard',
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Your stats and matches will appear here.',
                            style: TextStyle(color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
