import 'package:flutter/material.dart';
import '../../core/constants/bedrock_constants.dart';
import '../../core/theme/bedrock_theme.dart';

// ---------------------------------------------------------
// Buttons (AMOLED Tactile Scale Micro-Interactions)
// ---------------------------------------------------------

class BedrockPrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const BedrockPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<BedrockPrimaryButton> createState() => _BedrockPrimaryButtonState();
}

class _BedrockPrimaryButtonState extends State<BedrockPrimaryButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    if (!widget.isLoading) {
      setState(() => _scale = 0.96);
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    // GestureDetector detects visual touches/gestures (taps, drags, scales).
    // Reference: https://docs.flutter.dev/cookbook/gestures/handling-taps
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      // AnimatedScale is an implicit animation widget.
      // Whenever the scale value changes, it automatically animates from old to new value.
      // Reference: https://api.flutter.dev/flutter/widgets/AnimatedScale-class.html
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: Semantics(
                      label: 'Loading',
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Text(
                    widget.text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class BedrockSecondaryButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const BedrockSecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  State<BedrockSecondaryButton> createState() => _BedrockSecondaryButtonState();
}

class _BedrockSecondaryButtonState extends State<BedrockSecondaryButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C1C1E),
              foregroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              widget.text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// Inputs (Theme-configured focused highlight)
// ---------------------------------------------------------

class BedrockTextField extends StatefulWidget {
  final String label;
  final String? hintText;
  final String? errorText;
  final bool isPassword;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final List<String>? autofillHints;
  final int? maxLines;

  const BedrockTextField({
    super.key,
    required this.label,
    this.hintText,
    this.errorText,
    this.isPassword = false,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.validator,
    this.autofillHints,
    this.maxLines = 1,
  });

  @override
  State<BedrockTextField> createState() => _BedrockTextFieldState();
}

class _BedrockTextFieldState extends State<BedrockTextField> {
  late final TextEditingController _controller;
  String? _localError;
  bool _hasBeenEdited = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_validateInput);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_validateInput);
    }
    super.dispose();
  }

  void _validateInput() {
    if (_controller.text.isEmpty) {
      if (mounted) {
        setState(() {
          _localError = null;
          _hasBeenEdited = false;
        });
      }
      return;
    }
    if (widget.validator != null) {
      final validationResult = widget.validator!(_controller.text);
      if (mounted) {
        setState(() {
          _localError = validationResult;
          _hasBeenEdited = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _hasBeenEdited && _localError == null;
    final isInvalid = _hasBeenEdited && _localError != null;

    Widget? suffix;
    if (isValid) {
      suffix = const Icon(
        Icons.check_circle_rounded,
        color: BedrockTheme.hazardSafeDark,
        size: 20,
      );
    } else if (isInvalid) {
      suffix = const Icon(
        Icons.error_rounded,
        color: BedrockTheme.hazardCriticalDark,
        size: 20,
      );
    }

    return TextFormField(
      controller: _controller,
      obscureText: widget.isPassword,
      onChanged: widget.onChanged,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      autofillHints: widget.autofillHints,
      maxLines: widget.maxLines,
      decoration: InputDecoration(
        hintText: widget.hintText ?? widget.label,
        errorText: widget.errorText ?? _localError,
        suffixIcon: suffix != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: suffix,
              )
            : null,
      ),
    );
  }
}

class BedrockPasswordField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  const BedrockPasswordField({
    super.key,
    required this.label,
    this.controller,
    this.onChanged,
    this.validator,
  });

  @override
  State<BedrockPasswordField> createState() => _BedrockPasswordFieldState();
}

class _BedrockPasswordFieldState extends State<BedrockPasswordField> {
  bool _obscure = true;
  late final TextEditingController _controller;
  String? _localError;
  bool _hasBeenEdited = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_validateInput);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_validateInput);
    }
    super.dispose();
  }

  void _validateInput() {
    if (_controller.text.isEmpty) {
      if (mounted) {
        setState(() {
          _localError = null;
          _hasBeenEdited = false;
        });
      }
      return;
    }
    if (widget.validator != null) {
      final validationResult = widget.validator!(_controller.text);
      if (mounted) {
        setState(() {
          _localError = validationResult;
          _hasBeenEdited = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _hasBeenEdited && _localError == null;
    final isInvalid = _hasBeenEdited && _localError != null;

    Color getIconColor() {
      if (isValid) return BedrockTheme.hazardSafeDark;
      if (isInvalid) return BedrockTheme.hazardCriticalDark;
      return Theme.of(context).colorScheme.onSurface.withOpacity(0.4);
    }

    return TextFormField(
      controller: _controller,
      obscureText: _obscure,
      onChanged: widget.onChanged,
      validator: widget.validator,
      autofillHints: const [AutofillHints.password],
      decoration: InputDecoration(
        hintText: widget.label,
        errorText: _localError,
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off : Icons.visibility,
            color: getIconColor(),
          ),
          tooltip: _obscure ? 'Show password' : 'Hide password',
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// Cards (AMOLED Outline Border & InkWell Ripple support)
// ---------------------------------------------------------

class BedrockSolidCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const BedrockSolidCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(BedrockConstants.space16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: BedrockTheme.cardDark,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: BedrockTheme.borderSubtle, width: 1.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

// ---------------------------------------------------------
// Shimmer Skeletons (Pulsing micro-animation)
// ---------------------------------------------------------

class BedrockLoadingShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const BedrockLoadingShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = BedrockConstants.radiusMedium,
  });

  @override
  State<BedrockLoadingShimmer> createState() => _BedrockLoadingShimmerState();
}

class _BedrockLoadingShimmerState extends State<BedrockLoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // The controller is initialized to run over 1200 milliseconds.
    // repeat(reverse: true) makes the animation loop endlessly back-and-forth.
    // Reference: https://api.flutter.dev/flutter/animation/AnimationController/repeat.html
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Tween maps 0.0-1.0 progress values to a custom scale range (0.25 opacity to 0.75 opacity).
    // Reference: https://docs.flutter.dev/ui/animations/tutorial
    _animation = Tween<double>(
      begin: 0.25,
      end: 0.75,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    // Tickers must be cleared to avoid memory leaks when widget is destroyed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FadeTransition is an animation widget that automatically updates its opacity
    // based on the animated double values without manual setState rebuilds.
    // Reference: https://api.flutter.dev/flutter/widgets/FadeTransition-class.html
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: BedrockTheme.borderSubtle,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}
