import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import 'package:courtiq/features/login/viewmodel/login_viewmodel.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/user_model.dart';
import '../../../routes/routes_names.dart';
import '../../../core/widgets/auth/custom_textfield_createaccount.dart';
import '../../../core/widgets/custom_button.dart';
import '../../management/viewmodel/academy_provider.dart';
import '../../profile/viewmodel/profile_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  late String _currentRole;

  static const List<String> _roles = ['head_coach', 'coach', 'assistant_coach', 'player'];

  String _roleLabel(String role) {
    switch (role) {
      case 'head_coach':
        return 'Admin';
      case 'assistant_coach':
        return 'Assistant Coach';
      case 'player':
        return 'Player';
      default:
        return 'Coach';
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'head_coach':
        return const Color(0xFFF97316);
      case 'assistant_coach':
        return const Color(0xFF8B5CF6);
      case 'player':
        return AppColors.blue;
      default:
        return AppColors.yellow;
    }
  }

  void _goToRoleRoute(BuildContext context, String role) {
    final academyProvider = context.read<AcademyProvider>();
    final profileVm = context.read<ProfileViewmodel>();

    UserModel buildLocalUser(String roleValue, String defaultName) {
      return UserModel(
        id: 'local_${roleValue}_${DateTime.now().millisecondsSinceEpoch}',
        username: defaultName,
        email: '${roleValue}@ballchart.local',
        role: roleValue,
        profileCompleted: true,
        teamName: roleValue == 'head_coach' ? academyProvider.academy.name : null,
        assignedTeams: academyProvider.academy.teams.map((t) => t.name).toList(),
      );
    }

    if (role == 'head_coach') {
      academyProvider.loginByRole('academy_owner');
      profileVm.setUser(buildLocalUser('head_coach', 'Academy Owner'));
      Navigator.pushNamed(context, RouteNames.academyDashboard);
      return;
    }
    if (role == 'player') {
      academyProvider.loginByRole('player');
      profileVm.setUser(buildLocalUser('player', academyProvider.currentUser?.name ?? 'Player'));
      Navigator.pushNamed(context, RouteNames.mainApp, arguments: 'player');
      return;
    }
    academyProvider.loginByRole('coach');
    profileVm.setUser(buildLocalUser(role, role == 'assistant_coach' ? 'Assistant Coach' : 'Coach'));
    Navigator.pushNamed(context, RouteNames.mainApp, arguments: role);
  }

  @override
  void initState() {
    super.initState();
    _currentRole = _roles.contains(widget.role) ? widget.role : 'coach';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Exit App', style: TextStyle(color: Colors.white)),
        content: const Text('Do you want to exit the application?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewmodel>(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitDialog(context);
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF020617),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title Section
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _roleColor(_currentRole),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_roleLabel(_currentRole)} Sign In',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Quick Role Routes',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _roles.map((role) {
                      final bool isSelected = _currentRole == role;
                      final Color color = _roleColor(role);
                      return ElevatedButton(
                        onPressed: () {
                          setState(() => _currentRole = role);
                          _goToRoleRoute(context, role);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isSelected ? color : color.withValues(alpha: 0.16),
                          foregroundColor: isSelected ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _roleLabel(role),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),

                  // Email
                  CustomTextFieldCreateAccount(
                    label: 'Email',
                    hintText: 'your@email.com',
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController,
                  ),

                  const SizedBox(height: 20),

                  // Password
                  CustomTextFieldCreateAccount(
                    label: 'Password',
                    hintText: 'Create a strong password',
                    obscureText: !_isPasswordVisible,
                    controller: _passwordController,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white60,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  if (authViewModel.isLoading)
                    const CircularProgressIndicator()
                  else
                    CustomButton(
                      text: 'Sign In',
                      textColor: _currentRole == 'coach'
                          ? AppColors.black
                          : AppColors.white,
                      backgroundColor: _roleColor(_currentRole),
                      onPressed: () {
                        authViewModel.login(
                          context,
                          _emailController.text.trim(),
                          _passwordController.text.trim(),
                          _currentRole,
                        );
                      },
                    ),

                  const SizedBox(height: 15),

                  InkWell(
                    onTap: (){
                      LoginViewmodel.goToResetPassword(context, _currentRole);
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.yellow,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  GestureDetector(
                    onTap: () {
                       Navigator.pushReplacementNamed(context, RouteNames.auth, arguments: _currentRole);
                    },
                    child: RichText(
                      text: TextSpan(
                      text: 'Create an account? ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(
                            color: AppColors.yellow,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
