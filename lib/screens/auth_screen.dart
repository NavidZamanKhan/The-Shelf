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

/// Screen/modal presenting Minimalist Sign In / Sign Up tabs + Google Sign-In options.
class AuthScreen extends StatefulWidget {
  final AuthTab initialTab;

  const AuthScreen({
    super.key,
    this.initialTab = AuthTab.signIn,
  });

  static Future<void> show(BuildContext context, {AuthTab initialTab = AuthTab.signIn}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AuthScreen(initialTab: initialTab),
    );
  }

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late AuthTab _selectedTab;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

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
            SignInWithEmailPasswordRequested(
              email: email,
              password: password,
            ),
          );
    } else {
      final name = _nameController.text.trim();
      context.read<AuthBloc>().add(
            SignUpWithEmailPasswordRequested(
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
        if (state is Authenticated) {
          Navigator.of(context).pop();
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 16,
          left: 24,
          right: 24,
        ),
        decoration: BoxDecoration(
          color: activePalette.cardBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: Border.all(color: activePalette.cardBorder, width: 1),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: activePalette.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Book Header Icon Badge ---
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: activePalette.subtleBadgeBackground,
                  borderRadius: AppTheme.asymmetricBadgeRadius,
                  border: Border.all(color: activePalette.cardBorder, width: 1.2),
                ),
                child: Icon(
                  PhosphorIcons.books,
                  size: 32,
                  color: activePalette.primaryAccent,
                ),
              ),
              const SizedBox(height: 12),

              // Title & Subtitle
              Text(
                'The Shelf',
                style: TextStyle(
                  fontFamily: AppTheme.serifFontFamily,
                  fontSize: 24,
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
              const SizedBox(height: 20),

              // --- Minimalist Tab Switcher ---
              _buildTabSwitcher(activePalette),
              const SizedBox(height: 20),

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
                    _obscurePassword ? PhosphorIcons.eyeClosed : PhosphorIcons.eye,
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
              const SizedBox(height: 20),

              // --- Submit CTA Button ---
              _buildSubmitButton(activePalette),
              const SizedBox(height: 20),

              // --- Divider ---
              Row(
                children: [
                  Expanded(child: Divider(color: activePalette.cardBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR CONTINUE WITH',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: activePalette.desaturatedEmptyText,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: activePalette.cardBorder)),
                ],
              ),
              const SizedBox(height: 16),

              // --- Google Sign-In Button ---
              _buildGoogleSignInButton(activePalette),
              const SizedBox(height: 16),

              // Continue as Guest CTA
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Continue as Guest',
                  style: TextStyle(
                    fontFamily: AppTheme.serifFontFamily,
                    fontSize: 14,
                    color: activePalette.secondaryText,
                  ),
                ),
              ),
            ],
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
                            color: activePalette.primaryText.withValues(alpha: 0.05),
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
                            color: activePalette.primaryText.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  'Create Account',
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
        color: activePalette.background,
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
          child: AnimatedScale(
            scale: 1.0,
            duration: const Duration(milliseconds: 120),
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
          ),
        );
      },
    );
  }

  Widget _buildGoogleSignInButton(AppColorPalette activePalette) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return GestureDetector(
          onTap: isLoading
              ? null
              : () {
                  context.read<AuthBloc>().add(const SignInWithGoogleRequested());
                },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: activePalette.cardBackground,
              borderRadius: AppTheme.asymmetricCardRadius,
              border: Border.all(
                color: activePalette.cardBorder,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIcons.googleLogo,
                  size: 18,
                  color: activePalette.primaryAccent,
                ),
                const SizedBox(width: 10),
                Text(
                  'Continue with Google',
                  style: TextStyle(
                    fontFamily: AppTheme.serifFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: activePalette.primaryText,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
