import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/stitch_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _selectedRole = 'admin'; // Default role: 'admin' (College)

  final _emailController = TextEditingController(text: AppConstants.adminEmail);
  final _passwordController = TextEditingController(text: AppConstants.adminPass);

  void _selectRole(String role) {
    debugPrint("----------------------------------------");
    if (role == 'admin') {
      debugPrint("COLLEGE BUTTON CLICKED");
      debugPrint("SELECTED ROLE: admin (College)");
      debugPrint("STARTING COLLEGE LOGIN FLOW");
      debugPrint("NAVIGATING TO COLLEGE LOGIN");
    } else if (role == 'club_coordinator') {
      debugPrint("CLUB COORDINATOR BUTTON CLICKED");
      debugPrint("SELECTED ROLE: club_coordinator");
    } else {
      debugPrint("STUDENT BUTTON CLICKED");
      debugPrint("SELECTED ROLE: student");
    }
    debugPrint("----------------------------------------");

    setState(() {
      _selectedRole = role;
      if (role == 'admin') {
        _emailController.text = AppConstants.adminEmail;
        _passwordController.text = AppConstants.adminPass;
      } else if (role == 'club_coordinator') {
        _emailController.text = AppConstants.coordinatorEmail;
        _passwordController.text = AppConstants.coordinatorPass;
      } else {
        _emailController.text = AppConstants.studentEmail;
        _passwordController.text = AppConstants.studentPass;
      }
    });
  }

  void _handleLogin() async {
    debugPrint("SUBMITTING LOGIN FOR ROLE: $_selectedRole");
    final auth = Provider.of<AuthService>(context, listen: false);
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Invalid email or password'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    final isCollege = _selectedRole == 'admin';
    final isStudent = _selectedRole == 'student';
    final isCoord = _selectedRole == 'club_coordinator';

    final roleLabel = isCollege ? 'COLLEGE' : (isCoord ? 'CLUB COORDINATOR' : 'STUDENT');

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Stylized UNIRISE Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: StitchTheme.primaryCyan.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 14),
                    ShaderMask(
                      shaderCallback: (bounds) => StitchTheme.primaryGradient.createShader(bounds),
                      child: const Text(
                        'UNIRISE',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.black,
                          letterSpacing: 2.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  AppConstants.appTagline,
                  style: TextStyle(color: StitchTheme.textSecondary, fontSize: 16, letterSpacing: 0.5, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 36),

                // Account Type Selection Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: StitchTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: StitchTheme.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SELECT ACCOUNT TYPE',
                            style: TextStyle(
                              color: StitchTheme.primaryCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCollege ? Colors.amber.withOpacity(0.2) : StitchTheme.primaryCyan.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isCollege ? Colors.amber : StitchTheme.primaryCyan),
                            ),
                            child: Text(
                              roleLabel,
                              style: TextStyle(
                                color: isCollege ? Colors.amber : StitchTheme.primaryCyan,
                                fontSize: 10,
                                fontWeight: FontWeight.extrabold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 3 Role Cards: College (🏫), Student (🎓), Club Coordinator (👥)
                      Row(
                        children: [
                          Expanded(
                            child: _roleCard(
                              roleKey: 'admin',
                              label: 'College',
                              icon: Icons.account_balance_rounded,
                              activeColor: Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _roleCard(
                              roleKey: 'student',
                              label: 'Student',
                              icon: Icons.school_rounded,
                              activeColor: StitchTheme.primaryCyan,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _roleCard(
                              roleKey: 'club_coordinator',
                              label: 'Coordinator',
                              icon: Icons.groups_rounded,
                              activeColor: StitchTheme.secondaryPurple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Selected Role Title Banner
                Text(
                  isCollege ? 'Official College Login' : (isCoord ? 'Club Coordinator Login' : 'Student Login'),
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Credentials Input Fields
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'College Email',
                    prefixIcon: Icon(Icons.email_outlined, color: StitchTheme.textMuted),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline_rounded, color: StitchTheme.textMuted),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCollege ? Colors.amber : StitchTheme.primaryCyan,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: auth.isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text(
                            isCollege ? 'CONTINUE AS COLLEGE' : (isCoord ? 'CONTINUE AS COORDINATOR' : 'CONTINUE AS STUDENT'),
                            style: const TextStyle(fontWeight: FontWeight.extrabold, letterSpacing: 1.0),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleCard({
    required String roleKey,
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _selectedRole == roleKey;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectRole(roleKey),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.22) : activeColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? activeColor : activeColor.withOpacity(0.3),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? activeColor : activeColor.withOpacity(0.7), size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : activeColor.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
