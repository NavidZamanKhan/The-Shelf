import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/auth/auth_bloc.dart';
import 'package:the_shelf/blocs/auth/auth_event.dart';
import 'package:the_shelf/blocs/auth/auth_state.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/theme/app_color_palette.dart';
import 'package:the_shelf/theme/app_theme.dart';

enum AuthTab { signIn, signUp }

/// Full-screen authentication page (login / signup).
/// Users must authenticate before accessing the main app.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthTab _selectedTab = AuthTab.signIn;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedTab == AuthTab.signIn) {
      context.read<AuthBloc>().add(
            SignInRequested(email: email, password: password),
          );
    } else {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your name'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      context.read<AuthBloc>().add(
            SignUpRequested(
              email: email,
              password: password,
              displayName: name,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        // Authenticated state is handled by main.dart's BlocBuilder
      },
      child: Scaffold(
        backgroundColor: activePalette.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- Book Icon Badge ---
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: activePalette.subtleBadgeBackground,
                      borderRadius: AppTheme.asymmetricBadgeRadius,
                      border: Border.all(
                          color: activePalette.cardBorder, width: 1.2),
                    ),
                    child: Icon(
                      PhosphorIcons.books,
                      size: 36,
                      color: activePalette.primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // App title
                  Text(
                    'The Shelf',
                    style: TextStyle(
                      fontFamily: AppTheme.serifFontFamily,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: activePalette.primaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your personal reading companion',
                    style: TextStyle(
                      fontSize: 13,
                      color: activePalette.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // --- Tab Switcher ---
                  _buildTabSwitcher(activePalette),
                  const SizedBox(height: 24),

                  // --- Form Fields ---
                  if (_selectedTab == AuthTab.signUp) ...[
                    _buildInputField(
                      controller: _nameController,
                      icon: PhosphorIcons.user,
                      hintText: 'Full Name',
                      activePalette: activePalette,
                    ),
                    const SizedBox(height: 12),
                  ],

                  _buildInputField(
                    controller: _emailController,
                    icon: PhosphorIcons.envelopeSimple,
                    hintText: 'Email address',
                    keyboardType: TextInputType.emailAddress,
                    activePalette: activePalette,
                  ),
                  const SizedBox(height: 12),

                  _buildInputField(
                    controller: _passwordController,
                    icon: PhosphorIcons.lockSimple,
                    hintText: 'Password',
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? PhosphorIcons.eyeClosed
                            : PhosphorIcons.eye,
                        size: 18,
                        color: activePalette.secondaryText,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    activePalette: activePalette,
                  ),
                  const SizedBox(height: 24),

                  // --- Submit Button ---
                  _buildSubmitButton(activePalette),
                  const SizedBox(height: 20),

                  // --- Switch tab hint ---
                  _buildSwitchTabHint(activePalette),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabSwitcher(AppColorPalette activePalette) {
    return Container(
      decoration: BoxDecoration(
        color: activePalette.background,
        borderRadius: AppTheme.asymmetricBadgeRadius,
        border: Border.all(color: activePalette.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = AuthTab.signIn;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == AuthTab.signIn
                      ? activePalette.cardBackground
                      : Colors.transparent,
                  borderRadius: AppTheme.asymmetricBadgeRadius,
                  boxShadow: _selectedTab == AuthTab.signIn
                      ? [
                          BoxShadow(
                            color: activePalette.primaryText
                                .withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  'Sign In',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.serifFontFamily,
                    fontSize: 14,
                    fontWeight: _selectedTab == AuthTab.signIn
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: _selectedTab == AuthTab.signIn
                        ? activePalette.primaryText
                        : activePalette.secondaryText,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = AuthTab.signUp;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == AuthTab.signUp
                      ? activePalette.cardBackground
                      : Colors.transparent,
                  borderRadius: AppTheme.asymmetricBadgeRadius,
                  boxShadow: _selectedTab == AuthTab.signUp
                      ? [
                          BoxShadow(
                            color: activePalette.primaryText
                                .withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  'Sign Up',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.serifFontFamily,
                    fontSize: 14,
                    fontWeight: _selectedTab == AuthTab.signUp
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: _selectedTab == AuthTab.signUp
                        ? activePalette.primaryText
                        : activePalette.secondaryText,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    required AppColorPalette activePalette,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: activePalette.cardBackground,
        borderRadius: AppTheme.asymmetricBadgeRadius,
        border: Border.all(color: activePalette.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: activePalette.secondaryText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              style: TextStyle(
                fontSize: 14,
                color: activePalette.primaryText,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: activePalette.desaturatedEmptyText,
                ),
                border: InputBorder.none,
                suffixIcon: suffixIcon,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AppColorPalette activePalette) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return GestureDetector(
          onTap: isLoading ? null : _onSubmit,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: activePalette.primaryAccent,
              borderRadius: AppTheme.asymmetricCardRadius,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Text(
                    _selectedTab == AuthTab.signIn ? 'Sign In' : 'Create Account',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTheme.serifFontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSwitchTabHint(AppColorPalette activePalette) {
    final isSignIn = _selectedTab == AuthTab.signIn;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isSignIn ? "Don't have an account? " : 'Already have an account? ',
          style: TextStyle(
            fontSize: 13,
            color: activePalette.secondaryText,
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedTab = isSignIn ? AuthTab.signUp : AuthTab.signIn;
            });
          },
          child: Text(
            isSignIn ? 'Sign Up' : 'Sign In',
            style: TextStyle(
              fontFamily: AppTheme.serifFontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: activePalette.primaryAccent,
            ),
          ),
        ),
      ],
    );
  }
}
