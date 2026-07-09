# Professional Video Walkthrough Script: Bedrock Abbottabad

This script is a comprehensive, scene-by-scene presentation guide. It is written in **professional English** only. Use this guide while showing your **IDE** on the left side of the screen and the **Running Application** on the right side.

---

## 📋 The Presentation Order
1.  **Global App Config**: `main.dart`, `bedrock_theme.dart`, `bedrock_constants.dart`, `domain_enums.dart`, `domain_models.dart`
2.  **App Entry & Intro Flow**: `splash_screen.dart` ➡️ `onboarding_screen.dart` ➡️ `permission_primer_screen.dart`
3.  **Authentication Section**: `login_screen.dart` ➡️ `signup_screen.dart` ➡️ `auth_widgets.dart` ➡️ `forgot_password_screen.dart`
4.  **Navigation Scaffolding**: `main_shell.dart`
5.  **Weather Dashboard**: `weather_screen.dart`
6.  **Interactive Vector Map**: `home_screen.dart` ➡️ `home_widgets.dart`
7.  **Alert Feeds & Details**: `hazard_feed_screen.dart` ➡️ `crowdsourcing_widgets.dart` ➡️ `hazard_detail_screen.dart`
8.  **Disaster Reporting**: `hazard_report_screen.dart`
9.  **User Preferences**: `settings_screen.dart`
10. **Profiles & Gamification**: `profile_screen.dart` ➡️ `profile_widgets.dart`
11. **Component Sandbox Lab**: `flutter_widgets_lab_screen.dart`
12. **Shared Visual Primitives**: `foundation_widgets.dart`

---

## 🎬 Section 1: Global Configurations & Domain Layer
*   **[IDE Action]**: Open `lib/main.dart`, `lib/core/theme/bedrock_theme.dart`, `lib/core/constants/bedrock_constants.dart`, `lib/domain/enums/domain_enums.dart`, and `lib/domain/models/domain_models.dart`.
*   **[App Action]**: Show the application running in the browser/emulator on the starting splash screen.
*   **[Voiceover Speech]**:
    "Welcome to the technical walkthrough of Bedrock Abbottabad. We will start by examining the core configuration files in the IDE.
    
    First, in `main.dart`, we initialize the framework bindings and declare a centralized `routes` map. This enables decoupled navigation using path string keys, which satisfies the routing requirements of Phase 2. We also declare the default landing route as the splash screen and lock the application to our custom dark theme.
    
    Next, in `bedrock_theme.dart`, we define our dark AMOLED design system. We explicitly override the `Scaffold` background color to pure black `#000000` to save battery on OLED screens. We also configure `InputDecorationTheme` to style all form fields with subtle borders, style dialog shapes using `DialogThemeData`, and configure `PageTransitionsTheme` to use `ZoomPageTransitionsBuilder` for platform-agnostic page transitions.
    
    In `bedrock_constants.dart`, we standardize our layout constraints: spacing increments based on a 4dp grid (4, 8, 12, 16, 24, 32, 48), corner radii definitions, and a touch target size of 44.0 logical pixels to comply with Fitts's Law touch target standards.
    
    In `domain_enums.dart`, we declare enums that represent hazard states: `SafetyStatus` (safe, caution, critical), `HazardType` (such as landslide, flood, fog), `VoteState`, and `ReputationTier`. The `HazardTypeX` extension maps enum states to localized display strings (like 'Dense Fog') and graphical emojis (like '🌫️' or '⛰️') to avoid hardcoding strings in the presentation layer.
    
    Finally, in `domain_models.dart`, we specify immutable data classes: `HazardDisplayModel`, `UserProfileModel`, and `OnboardingStepModel`. All fields are marked `final` and constructors are marked `const` to prevent runtime mutation bugs."

---

## 🎬 Section 2: Splash, Onboarding Carousel & Permission Primer
*   **[IDE Action]**: Open `lib/presentation/screens/splash_screen.dart`, `onboarding_screen.dart`, and `permission_primer_screen.dart`.
*   **[App Action]**: Reload the application to trigger the Splash animation. Then, swipe horizontally through the three onboarding slides. Click the "Get Started" button to open the Location Permission screen.
*   **[Voiceover Speech]**:
    "Now let's examine the entry flow.
    
    In `splash_screen.dart`, we have a `StatefulWidget` using `SingleTickerProviderStateMixin`. This mixin provides a single `Ticker` that ticks once per frame to drive our `AnimationController`. We define two animations: a scale animation using `Tween<double>(begin: 0.85, end: 1.0)` and a fade animation from `0.0` to `1.0`. We wrap our vector shield logo in `FadeTransition` and `ScaleTransition` widgets to build the staggered entry effect. A 2.2-second `Timer` triggers `Navigator.of(context).pushReplacementNamed('/onboarding')` to remove the splash screen from the history stack.
    
    In `onboarding_screen.dart`, we render a slide carousel using `PageView.builder`. It uses a `PageController` to track slide index offsets. We calculate responsive padding parameters dynamically based on the device width using `MediaQuery.of(context).size`. The dots indicator row maps circles to the data length, changing color based on the active index.
    
    In `permission_primer_screen.dart`, we display an informational permission prompt. To prevent overflow issues when the keyboard slides up or when screens are small, we wrap the content inside a `CustomScrollView` using a `SliverFillRemaining` widget with `hasScrollBody` set to `false`. This keeps the layout fill-screen by default but allows vertical scrolling if space is constrained."

---

## 🎬 Section 3: Authentication, Form Validation & State Switchers
*   **[IDE Action]**: Open `lib/presentation/screens/login_screen.dart`, `signup_screen.dart`, `forgot_password_screen.dart`, and `lib/presentation/ui_components/auth_widgets.dart`.
*   **[App Action]**: In the app, tap the location buttons to reach Login. Type an invalid email, click the login button to show the validation message. Then switch to Signup and type passwords of different lengths to show the strength meter. Go back and tap "Forgot Password", enter an email, click "Reset Password", and watch the form smoothly crossfade to a success icon.
*   **[Voiceover Speech]**:
    "Next is our authentication layout.
    
    In `login_screen.dart`, we manage user inputs. We wrap our input column inside a `Form` widget and assign a `GlobalKey<FormState>` parameter. Each input uses a custom `BedrockTextField` wrapper around `TextFormField`. When the submit button is tapped, `_formKey.currentState!.validate()` is executed, checking our email validation regex and returning error strings.
    
    In `signup_screen.dart`, we include similar validation controls and integrate our `PasswordStrengthMeter` from `auth_widgets.dart`. In the code, this meter calculates a strength score (0 to 3) based on password length. The UI displays three horizontal bars built with `AnimatedContainer` widgets. When the password text changes, these bars automatically transition their decorations and colors (red for weak, orange for medium, green for strong) over 200ms.
    
    In `forgot_password_screen.dart`, we handle password recovery. When the user submits their email, we toggle the state of `_emailSent` to `true`. To animate this layout switch without disjointed page transitions, we wrap the form and the success view inside an `AnimatedSwitcher`. Both children have unique `ValueKey` properties. Flutter uses these keys to perform a smooth crossfade animation when the layout is swapped."

---

## 🎬 Section 4: Main Shell Scaffolding & State Preservation
*   **[IDE Action]**: Open `lib/presentation/screens/main_shell.dart`.
*   **[App Action]**: Complete the login flow. Tap the top-left menu icon to show the slide-out Drawer. Close it and switch back and forth between the bottom navigation tabs.
*   **[Voiceover Speech]**:
    "Once authenticated, the user enters `main_shell.dart`, which manages the core application scaffold.
    
    The screen wraps a `BottomNavigationBar` and a slide-out `Drawer` menu. To prevent screens from rebuilding and losing viewport scroll/zoom coordinates when switching navigation tabs, the body of the `Scaffold` is wrapped inside an `IndexedStack`. This stack keeps all child screens alive in the widget tree memory but only displays the one matching our current index. We also include a custom navigation drawer configured with list tiles that redirect to secondary routes."

---

## 🎬 Section 5: Weather Tab (Dashboard Grid & Canvas Drawing)
*   **[IDE Action]**: Open `lib/presentation/screens/weather_screen.dart`.
*   **[App Action]**: Open the "Weather" tab. Scroll down to show the weather grids, the custom temperature spline chart, and the Sunrise/Sunset card.
*   **[Voiceover Speech]**:
    "Now let's examine the Weather tab, designed as a dashboard.
    
    In the code, the key weather metrics (like wind speed, UV index, and humidity) are arranged in a responsive grid using a `GridView.count` widget.
    
    Beneath this, we render our custom temperature spline graph and solar arc. Both are custom vector graphics drawn using `CustomPaint` with a `CustomPainter` class. In the `WeatherGraphPainter`, we calculate X and Y coordinates on a canvas grid based on temperature data points. We draw straight lines connecting these coordinates using a `Path` object with `path.lineTo` and paint the temperature values using `TextPainter`.
    
    In the `SunriseArcPainter`, we draw a dashed curve using `canvas.drawArc`. To position the sun icon along this arc, we use basic trigonometry. We calculate the sun's X and Y coordinates along the arc using: `centerX + radiusX * cos(angle)` and `centerY + radiusY * sin(angle)`."

---

## 🎬 Section 6: Home Map (Vector Graphics & Animated HUDs)
*   **[IDE Action]**: Open `lib/presentation/screens/home_screen.dart` and `lib/presentation/ui_components/home_widgets.dart`.
*   **[App Action]**: Open the "Map" tab. Tap the zoom keys, interact with the red threat spot, and tap the FAB in the bottom right to slide open the Modal Sheet.
*   **[Voiceover Speech]**:
    "Next is the Map tab, which features a custom offline vector map.
    
    In `home_screen.dart`, we use a `Stack` to overlay widgets. The bottom layer is our custom map painter, `AbbottabadVectorMapPainter`.
    
    In `home_widgets.dart`, this painter draws roads, coordinate grids, and landmarks directly onto the canvas using vector paths. We implement a zoom algorithm that translates the center of the canvas, applies a scale transform based on `zoomScale`, and translates it back. The red hazard spot has a pulsing halo ring animated using a `pulseValue` double between `0.0` and `1.0`.
    
    The floating zoom controls use `GestureDetector` coupled with `AnimatedScale`. When pressed, the scale transforms down to `0.96` for tactile feedback. The emergency contact list is displayed in a bottom sheet using `showModalBottomSheet`. We wrap its content in a `SingleChildScrollView` to prevent render overflows on smaller screens."

---

## 🎬 Section 7: Alerts Feed & Details (Routing Argument Passing)
*   **[IDE Action]**: Open `lib/presentation/screens/hazard_feed_screen.dart`, `lib/presentation/ui_components/crowdsourcing_widgets.dart`, and `lib/presentation/screens/hazard_detail_screen.dart`.
*   **[App Action]**: Open the "Alerts" tab. Filter alerts by choosing category tabs at the top. Tap on an alert card to open the Detail Screen.
*   **[Voiceover Speech]**:
    "The Alerts Feed manages crowdsourced warning reports.
    
    In `hazard_feed_screen.dart`, we use a `TabController` bound to a `TabBar` and `TabBarView` to let users filter alerts by category. The feed is rendered lazily using `ListView.builder` for list performance.
    
    In `crowdsourcing_widgets.dart`, the `HazardCard` widget renders card summaries. It uses an `InkWell` wrapper to display a Material ink ripple when tapped.
    
    In `hazard_detail_screen.dart`, when a card is clicked, we push the route `/hazard_detail` and pass the `HazardDisplayModel` object. The detail page extracts this object dynamically from the build context using `ModalRoute.of(context)!.settings.arguments` to display description parameters, reporter names, and coordinates."

---

## 🎬 Section 8: Incident Reporting (Dropdown Forms & Dialogs)
*   **[IDE Action]**: Open `lib/presentation/screens/hazard_report_screen.dart`.
*   **[App Action]**: Tap the "+" button on the map. Select a hazard type, fill the form, click submit. On the pop-up modal, click "Confirm", and point out the confirmation SnackBar that appears at the bottom of the map.
*   **[Voiceover Speech]**:
    "If a user needs to report an incident, they open `hazard_report_screen.dart`.
    
    This page uses a `DropdownButtonFormField` to let the user select a hazard type. When they submit, we show a confirmation modal using `showDialog` with an `AlertDialog` widget. If the user clicks 'Confirm', we close the reporting screen and return a success parameter back to the parent route using `Navigator.of(context).pop('submitted')`. The Map page awaits this result and displays a confirmation SnackBar at the bottom of the screen."

---

## 🎬 Section 9: Settings, Profiles & Shared Primitives
*   **[IDE Action]**: Open `settings_screen.dart`, `profile_screen.dart`, `lib/presentation/ui_components/profile_widgets.dart`, and `lib/presentation/ui_components/foundation_widgets.dart`.
*   **[App Action]**: Go to Profile, open Settings, toggle switches, click "Log Out" to return to Login.
*   **[Voiceover Speech]**:
    "Finally, we have our user settings, profiles, and shared widgets.
    
    In `settings_screen.dart`, we use a `ListView` with `ListTile` widgets. The pushes use `Switch.adaptive` to adapt to iOS or Android platforms. Tapping 'Log Out' uses `pushNamedAndRemoveUntil` to clear all previous screens from the navigation stack.
    
    In `profile_screen.dart`, we display statistics. We use a custom progress bar to display verification ratings. The user's avatar border displays a gradient using `LinearGradient` if their reputation rank is high.
    
    Our shared UI components are defined in `foundation_widgets.dart`. Here, our custom buttons use `AnimatedScale` for press transitions, and our loading placeholders use a `FadeTransition` driven by a repeating animation controller to display a pulsing shimmer effect.
    
    This concludes our technical codebase walkthrough. All Phase 1 and Phase 2 requirements are fully implemented."

---
