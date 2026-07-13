import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/bedrock_constants.dart';
import '../../core/theme/bedrock_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../ui_components/foundation_widgets.dart';
import '../ui_components/auth_widgets.dart';
import '../../core/services/biometric_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // GlobalKey uniquely identifies this Form widget across the app.
  // It allows us to access the state of the Form (FormState) to trigger field validations.
  // Reference: https://docs.flutter.dev/cookbook/forms/validation
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometricLogin();
    });
  }

  void _checkBiometricLogin() async {
    final biometricService = BiometricService();
    final enabled = await biometricService.isBiometricsEnabled();
    if (enabled) {
      final authenticated = await biometricService.authenticate();
      if (authenticated) {
        final credentials = await biometricService.getStoredCredentials();
        if (credentials != null) {
          final email = credentials['email']!;
          final password = credentials['password']!;

          if (!mounted) return;
          setState(() => _isLoading = true);
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          final success = await authProvider.signIn(email, password);

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
                content: Text(
                  authProvider.errorMessage ?? 'Biometric login failed.',
                ),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    }
  }

  void _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      setState(() => _isLoading = true);

      final success = await authProvider.signIn(
        _emailController.text,
        _passwordController.text,
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
            content: Text(
              authProvider.errorMessage ?? 'Authentication failed.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
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
        // CustomScrollView with SliverFillRemaining prevents keyboard layout overflows.
        // hasScrollBody: false expands the form to fill the screen but allows scrolling when
        // the keyboard is shown.
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
                            Icons.shield_outlined,
                            size: 40,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: BedrockConstants.space24),
                      Text(
                        'Sign In',
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
                        'Access live Abbottabad weather reports and disaster feeds.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: BedrockTheme.labelSecondaryDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: BedrockConstants.space32),

                      // Inputs
                      BedrockTextField(
                        label: 'Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Email is required';
                          }
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
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
                          if (v == null || v.isEmpty)
                            return 'Password is required';
                          if (v.length < 6)
                            return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(
                            context,
                          ).pushNamed('/forgot_password'),
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: BedrockConstants.space8),

                      Row(
                        children: [
                          Expanded(
                            child: BedrockPrimaryButton(
                              text: 'Sign In',
                              isLoading: _isLoading,
                              onPressed: _handleLogin,
                            ),
                          ),
                          FutureBuilder<bool>(
                            future: BiometricService().isBiometricsEnabled(),
                            builder: (context, snapshot) {
                              if (snapshot.data == true) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: BedrockTheme.borderSubtle
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.fingerprint_rounded,
                                        color: Colors.white70,
                                      ),
                                      onPressed: _checkBiometricLogin,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
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
                              'Don\'t have an account?',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: BedrockTheme.labelSecondaryDark,
                                  ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pushNamed('/signup'),
                              child: Text(
                                'Sign Up',
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
