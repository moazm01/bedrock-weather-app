import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/bedrock_constants.dart';
import '../../core/theme/bedrock_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../ui_components/foundation_widgets.dart';
import '../ui_components/auth_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // GlobalKey uniquely identifies this Form widget.
  // Reference: https://docs.flutter.dev/cookbook/forms/validation
  final _formKey = GlobalKey<FormState>();

  // TextEditingController allows us to read input values.
  // Reference: https://docs.flutter.dev/cookbook/forms/retrieve-value
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleSignup() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      setState(() => _isLoading = true);

      final success = await authProvider.signUp(
        _emailController.text,
        _passwordController.text,
        _usernameController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        final uid = authProvider.currentUserId;
        if (uid != null) {
          Provider.of<UserProfileProvider>(
            context,
            listen: false,
          ).startListening(uid);
        }
        Navigator.of(context).pushReplacementNamed('/main');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Registration failed.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).size.width > 600
        ? BedrockConstants.space32
        : BedrockConstants.space24;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        // CustomScrollView with SliverFillRemaining expands the form to fill the viewport
        // without overflowing when keyboard rises.
        // Reference: https://api.flutter.dev/flutter/widgets/SliverFillRemaining-class.html
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),

                      // Apple style circular logo container
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: BedrockTheme.cardDark,
                            border: Border.all(
                              color: BedrockTheme.borderSubtle,
                              width: 1.0,
                            ),
                          ),
                          child: Icon(
                            Icons.person_add_outlined,
                            size: 40,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: BedrockConstants.space24),
                      Text(
                        'Create Account',
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: BedrockConstants.space8),
                      Text(
                        'Join contributors reporting severe weather and road conditions.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: BedrockTheme.labelSecondaryDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: BedrockConstants.space32),

                      // Inputs
                      BedrockTextField(
                        label: 'Username',
                        controller: _usernameController,
                        autofillHints: const [AutofillHints.newUsername],
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Username is required';
                          }
                          if (v.length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                          if (v.length > 20) {
                            return 'Username must be less than 20 characters';
                          }
                          if (!RegExp(r'^[a-zA-Z]').hasMatch(v)) {
                            return 'Username must start with a letter';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
                            return 'Use only letters, numbers, and underscores';
                          }
                          if (v.contains('__')) {
                            return 'Username cannot contain consecutive underscores';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: BedrockConstants.space16),
                      BedrockTextField(
                        label: 'Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Email is required';
                          }
                          if (v.length > 100) {
                            return 'Email must be less than 100 characters';
                          }
                          final emailRegex = RegExp(
                            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                          );
                          if (!emailRegex.hasMatch(v)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: BedrockConstants.space16),
                      BedrockPasswordField(
                        label: 'Password',
                        controller: _passwordController,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password is required';
                          }
                          if (v.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          if (!RegExp(r'[A-Z]').hasMatch(v)) {
                            return 'Must contain at least 1 uppercase letter';
                          }
                          if (!RegExp(r'[a-z]').hasMatch(v)) {
                            return 'Must contain at least 1 lowercase letter';
                          }
                          if (!RegExp(r'[0-9]').hasMatch(v)) {
                            return 'Must contain at least 1 digit';
                          }
                          if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(v)) {
                            return 'Must contain at least 1 special character';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: BedrockConstants.space12),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _passwordController,
                        builder: (context, value, child) {
                          return PasswordStrengthMeter(password: value.text);
                        },
                      ),
                      const SizedBox(height: BedrockConstants.space24),

                      BedrockPrimaryButton(
                        text: 'Register Account',
                        isLoading: _isLoading,
                        onPressed: _handleSignup,
                      ),
                      const SizedBox(height: BedrockConstants.space24),
                      const BedrockDividerWithLabel(label: 'OR'),
                      const SizedBox(height: BedrockConstants.space24),
                      BedrockOAuthButton(
                        onPressed: () async {
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
                          final navigator = Navigator.of(context);

                          final success = await auth.signInWithGoogle();
                          if (success) {
                            final uid = auth.currentUserId;
                            if (uid != null) {
                              userProfileProvider.startListening(uid);
                            }
                            navigator.pushReplacementNamed('/main');
                          }
                        },
                      ),

                      const Spacer(),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: BedrockConstants.space16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account?',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: BedrockTheme.labelSecondaryDark,
                                  ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
