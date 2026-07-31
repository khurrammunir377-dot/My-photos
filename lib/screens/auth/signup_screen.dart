import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/local_session_service.dart';
import '../../services/referral_service.dart';
import '../../services/user_directory_service.dart';
import '../../utils/constants.dart';
import '../folder/folder_select_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _authService = AuthService();
  final _localSession = LocalSessionService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _signup() async {
    if (!AppConstants.kFirebaseEnabled) {
      return _signupLocally();
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final credential = await _authService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      await _completeSignupBookkeeping(credential.user?.uid);
      _goToApp();
    } catch (e) {
      setState(() => _error = _authService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Simple on-device signup used while Firebase is disabled for testing -
  /// no real validation, referral codes are ignored (they need Firestore).
  Future<void> _signupLocally() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter any email to continue (test mode - no real account needed)');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    await _localSession.login(email);
    if (mounted) {
      setState(() => _loading = false);
      _goToApp();
    }
  }

  Future<void> _signupWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _authService.signInWithGoogle();
      if (result != null) {
        await _completeSignupBookkeeping(result.user?.uid);
        _goToApp();
      }
    } catch (e) {
      setState(() => _error = _authService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Creates the Firestore user profile and applies a referral code if one was entered.
  Future<void> _completeSignupBookkeeping(String? uid) async {
    if (uid == null) return;
    final user = _authService.currentUser;
    if (user == null) return;

    final referralCode = _referralController.text.trim();
    await UserDirectoryService().recordLogin(
      user,
      referredByCode: referralCode.isNotEmpty ? referralCode.toUpperCase() : null,
    );
    if (referralCode.isNotEmpty) {
      await ReferralService().applyReferralCode(uid, referralCode);
    }
  }

  void _goToApp() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const FolderSelectScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ListView(
            children: [
              const SizedBox(height: 12),
              const Text('Create your account', style: AppTextStyles.heading),
              const SizedBox(height: 6),
              Text(
                AppConstants.kFirebaseEnabled
                    ? 'Start organizing your photos in seconds'
                    : 'Test mode - type any email, no real account needed',
                style: AppTextStyles.subheading,
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              ),
              if (AppConstants.kFirebaseEnabled) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    helperText: 'At least 6 characters',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _referralController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Referral code (optional)',
                    hintText: 'e.g. A1B2C3D4',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.card_giftcard),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: _loading ? null : _signup,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Sign Up', style: AppTextStyles.button),
                ),
              ),
              if (AppConstants.kFirebaseEnabled) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _signupWithGoogle,
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: const Text('Continue with Google'),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text('Already have an account? Log in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
