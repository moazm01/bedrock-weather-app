// BedrockConstants establishes a centralized design system.
// By defining constraints as static const values, we ensure visual consistency across screens
// and improve widget layout compile-time performance.
// Reference: https://docs.flutter.dev/ui/layout
class BedrockConstants {
  // HCI Tap Targets (Fitts's Law touch compliance)
  // Reference: https://docs.flutter.dev/ui/accessibility-and-localization/accessibility
  static const double minTapTarget = 44.0;
  static const double standardFabSize = 56.0;

  // Spacing (Apple 4dp Grid System)
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // Corner Radii
  static const double radiusSmall = 8.0;
  static const double radiusMedium =
      14.0; // Apple/Samsung standard card corner radius
  static const double radiusLarge = 20.0;
  static const double radiusPill = 999.0;

  // Global Animation Durations
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animStandard = Duration(milliseconds: 300);
  static const Duration debounceTime = Duration(milliseconds: 500);
}
