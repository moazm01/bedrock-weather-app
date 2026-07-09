import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/bedrock_constants.dart';
import '../../core/theme/bedrock_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../ui_components/foundation_widgets.dart';

// ForgotPasswordScreen is a StatefulWidget because we modify the screen layout state
// dynamically (swapping from input form to success state) when instructions are sent.
// Reference: https://docs.flutter.dev/ui/interactivity
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // GlobalKey identifies the Form state to trigger validators.
  // Reference: https://docs.flutter.dev/cookbook/forms/validation
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  void _handleReset() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      setState(() => _isLoading = true);

      final success = await authProvider.resetPassword(_emailController.text);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        setState(() {
          _emailSent = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Password reset failed.',
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).size.width > 600
        ? BedrockConstants.space32
        : BedrockConstants.space24;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          // pop dismisses the current screen and returns back to the previous route in the stack.
          // Reference: https://docs.flutter.dev/cookbook/navigation/navigation-basics
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                // AnimatedSwitcher automatically animates transitions between two distinct layouts
                // whenever the child changes (determined by checking the ValueKeys).
                // Reference: https://api.flutter.dev/flutter/widgets/AnimatedSwitcher-class.html
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _emailSent
                      ? Column(
                          key: const ValueKey('success_state'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Spacer(),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: BedrockTheme.hazardSafeDark
                                      .withOpacity(0.05),
                                  border: Border.all(
                                    color: BedrockTheme.hazardSafeDark
                                        .withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.mark_email_read_outlined,
                                  size: 64,
                                  color: BedrockTheme.hazardSafeDark,
                                ),
                              ),
                            ),
                            const SizedBox(height: BedrockConstants.space32),
                            Text(
                              'Instructions Sent',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: BedrockConstants.space16),
                            Text(
                              'Check your inbox. We have sent password reset instructions to your registered email address.',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: BedrockTheme.labelSecondaryDark,
                                    fontSize: 15,
                                    height: 1.45,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: BedrockConstants.space32),
                            BedrockPrimaryButton(
                              text: 'Back to Login',
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const Spacer(),
                          ],
                        )
                      : Form(
                          key: _formKey,
                          child: Column(
                            key: const ValueKey('form_state'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Spacer(),
                              Text(
                                'Forgot Password',
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
                                'We will send reset instructions to your email.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: BedrockTheme.labelSecondaryDark,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: BedrockConstants.space32),
                              BedrockTextField(
                                label: 'Email',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Email is required';
                                  if (!v.contains('@') || !v.contains('.'))
                                    return 'Enter a valid email address';
                                  return null;
                                },
                              ),
                              const SizedBox(height: BedrockConstants.space32),
                              BedrockPrimaryButton(
                                text: 'Reset Password',
                                isLoading: _isLoading,
                                onPressed: _handleReset,
                              ),
                              const Spacer(),
                            ],
                          ),
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
