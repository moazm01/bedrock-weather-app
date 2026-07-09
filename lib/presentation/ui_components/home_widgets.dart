import 'package:flutter/material.dart';
import '../../core/theme/bedrock_theme.dart';
import '../../core/constants/bedrock_constants.dart';
import '../../domain/enums/domain_enums.dart';

// 1. BedrockSafetyStatusCard
class BedrockSafetyStatusCard extends StatelessWidget {
  final SafetyStatus status;
  final String title;
  final String description;
  final VoidCallback? onClose;

  const BedrockSafetyStatusCard({
    super.key,
    required this.status,
    required this.title,
    required this.description,
    this.onClose,
  });

  Color _getStatusColor(BuildContext context, SafetyStatus status) {
    switch (status) {
      case SafetyStatus.safe:
        return BedrockTheme.hazardSafeDark;
      case SafetyStatus.caution:
        return BedrockTheme.hazardWarningDark;
      case SafetyStatus.critical:
        return BedrockTheme.hazardCriticalDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context, status);

    return Container(
      padding: const EdgeInsets.all(BedrockConstants.space16),
      decoration: BoxDecoration(
        color: BedrockTheme.cardDark,
        borderRadius: BorderRadius.circular(BedrockConstants.radiusMedium),
        border: Border.all(color: BedrockTheme.borderSubtle, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, color: statusColor, size: 24),
              const SizedBox(width: BedrockConstants.space12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (onClose != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onClose,
                  child: SizedBox(
                    width: BedrockConstants.minTapTarget,
                    height: BedrockConstants.minTapTarget,
                    child: Center(
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: BedrockConstants.space8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.3,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// 2. BedrockThreatBanner
class BedrockThreatBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  const BedrockThreatBanner({
    super.key,
    required this.message,
    this.onTap,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    const warningColor = BedrockTheme.hazardCriticalDark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: BedrockConstants.space16,
          vertical: BedrockConstants.space8,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: BedrockConstants.space16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: warningColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(BedrockConstants.radiusMedium),
          border: Border.all(color: warningColor.withOpacity(0.3), width: 1.0),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: warningColor,
              size: 20,
            ),
            const SizedBox(width: BedrockConstants.space12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: warningColor,
                ),
              ),
            ),
            if (onClose != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
                child: const SizedBox(
                  width: BedrockConstants.minTapTarget,
                  height: BedrockConstants.minTapTarget,
                  child: Center(
                    child: Icon(
                      Icons.close_rounded,
                      color: warningColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ] else ...[
              const Icon(
                Icons.chevron_right_rounded,
                color: warningColor,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// 3. BedrockEmergencyFAB
class BedrockEmergencyFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const BedrockEmergencyFAB({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    const fabColor = BedrockTheme.hazardCriticalDark;
    const double fabSize = BedrockConstants.standardFabSize + 8.0;

    return SizedBox(
      width: fabSize,
      height: fabSize,
      child: FloatingActionButton(
        heroTag: 'emergency_fab_tag',
        onPressed: onPressed,
        backgroundColor: fabColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(fabSize / 2),
          side: const BorderSide(color: Colors.white24, width: 1.0),
        ),
        child: const Icon(
          Icons.emergency_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}

// 4. BedrockBottomDrawer
class BedrockBottomDrawer extends StatelessWidget {
  final Widget child;

  const BedrockBottomDrawer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: BedrockTheme.cardDark,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BedrockConstants.radiusLarge),
        ),
        border: Border(
          top: BorderSide(color: BedrockTheme.borderSubtle, width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(
                top: BedrockConstants.space12,
                bottom: BedrockConstants.space8,
              ),
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(
                  BedrockConstants.radiusPill,
                ),
              ),
            ),
          ),
          // Content
          Flexible(child: child),
        ],
      ),
    );
  }
}

// 5. BedrockMapPlaceholder (AMOLED Vector Mockup of Abbottabad)
// This is a StatefulWidget because it creates and manages an AnimationController
// to animate the pulsing location rings and active warning signals on the map.
class BedrockMapPlaceholder extends StatefulWidget {
  final double
  zoomScale; // Current zoom factor controlled by the parent screen.

  const BedrockMapPlaceholder({super.key, this.zoomScale = 1.0});

  @override
  State<BedrockMapPlaceholder> createState() => _BedrockMapPlaceholderState();
}

// SingleTickerProviderStateMixin provides the vsync (ticker) that drives the animation controller.
class _BedrockMapPlaceholderState extends State<BedrockMapPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Initialize the controller to animate linearly from 0.0 to 1.0 over 3 seconds,
    // repeating indefinitely to drive the map's pulsing visual effects.
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    // Crucial: dispose the controller to prevent memory leaks when screen is destroyed.
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder listens to the controller and triggers a redraw of its subtree
    // every time the animation ticker updates, keeping animations smooth.
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Styled Vector Background Map Painter
            Positioned.fill(
              child: CustomPaint(
                painter: AbbottabadVectorMapPainter(
                  pulseValue:
                      _animationController.value, // Passes animated 0.0 -> 1.0
                  zoomScale: widget.zoomScale, // Passes zoom scale (0.5 -> 2.5)
                ),
              ),
            ),

            // HUD HUD Grid Overlay Text Info (Sleek Apple style top-left indicator)
            Positioned(
              top: 8,
              left: 16,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    'GPS LOCK: 34.1688° N, 73.2215° E\nGRID OFFSET: 0.124 SEC',
                    style: TextStyle(
                      fontFamily:
                          'monospace', // Monospace font for "system terminal" look.
                      fontSize: 10,
                      color: Colors.blueAccent.shade100,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ),

            // Apple style floating compass needle indicator in top-right.
            Positioned(
              top: 8,
              right: 16,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Icon(
                    Icons.explore_outlined,
                    size: 20,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ),

            // Map Legend (Floating card overlay explaining the colors)
            Positioned(
              bottom: 110,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: BedrockTheme.cardDark.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: BedrockTheme.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLegendItem(Colors.blue, 'My Location'),
                    const SizedBox(height: 4),
                    _buildLegendItem(Colors.red, 'Active Flood'),
                    const SizedBox(height: 4),
                    _buildLegendItem(Colors.orange, 'Road Block'),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Builder helper to render legend colors and labels cleanly.
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white70),
        ),
      ],
    );
  }
}

// AbbottabadVectorMapPainter paints a simplified vector map of Abbottabad roads and hazard hot spots.
// We use a CustomPainter to draw offline vector maps that are performant and visually consistent.
// Reference: https://api.flutter.dev/flutter/widgets/CustomPainter-class.html
class AbbottabadVectorMapPainter extends CustomPainter {
  final double zoomScale;
  final double pulseValue;

  AbbottabadVectorMapPainter({
    required this.zoomScale,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Fill the background layout canvas.
    canvas.drawRect(Offset.zero & size, bgPaint);

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    // Save canvas matrix state before applying scale/translate transformations.
    // Reference: https://api.flutter.dev/flutter/graphics/Canvas/save.html
    canvas.save();

    // Zoom algorithm: Translate center coordinate of canvas to 0,0, apply scale,
    // and translate back. This causes zooming to expand from the center of the map.
    canvas.translate(centerX, centerY);
    canvas.scale(zoomScale);
    canvas.translate(-centerX, -centerY);

    // 1. Draw Grid Lines (Coordinate Grid Overlay)
    final gridPaint = Paint()
      ..color = const Color(0xFF161622).withOpacity(0.3)
      ..strokeWidth = 1;

    const double step = 40; // Space between grid lines.
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Draw Vector Roads representing Abbottabad
    final roadPaint = Paint()
      ..color = const Color(0xFF252538)
      ..strokeCap = StrokeCap
          .round // Round capping at endpoints.
      ..style = PaintingStyle.stroke;

    // Karakoram Highway (N-35) - Drawn as a cubic Bezier curve.
    final kkhPath = Path()
      ..moveTo(0, size.height * 0.7)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.65,
        size.width * 0.6,
        size.height * 0.35,
        size.width,
        size.height * 0.2,
      );

    roadPaint.strokeWidth = 8; // Main highway gets a thick width.
    canvas.drawPath(kkhPath, roadPaint);

    // Road center dashes (Sleek inner outline color)
    final roadDashPaint = Paint()
      ..color = const Color(0xFF101015)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(kkhPath, roadDashPaint);

    // Kakul Road (Secondary road drawn as a quadratic Bezier curve intersecting KKH)
    final kakulPath = Path()
      ..moveTo(size.width * 0.5, size.height)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.6,
        size.width * 0.8,
        size.height * 0.1,
      );

    roadPaint.strokeWidth = 5;
    roadPaint.color = const Color(0xFF1C1C28);
    canvas.drawPath(kakulPath, roadPaint);

    // Mandian Chowk Connection (Straight line link)
    final mandianPath = Path()
      ..moveTo(0, size.height * 0.2)
      ..lineTo(size.width * 0.5, size.height * 0.45);
    canvas.drawPath(mandianPath, roadPaint);

    // 3. Road Names labels (Rendered text on canvas using TextPainter)
    _drawText(
      canvas,
      'Karakoram Hwy (N-35)',
      Offset(size.width * 0.15, size.height * 0.61),
      8,
    );
    _drawText(
      canvas,
      'Kakul Road',
      Offset(size.width * 0.53, size.height * 0.7),
      8,
    );
    _drawText(
      canvas,
      'Mandian Link',
      Offset(size.width * 0.1, size.height * 0.27),
      8,
    );

    // 4. User Current Location (Blue Pulsing Indicator)
    final double userX = size.width * 0.45;
    final double userY = size.height * 0.52;

    // Expanding pulse ring (opacity fades as size increases from 8 to 32)
    final userPulsePaint = Paint()
      ..color = const Color(0xFF0A84FF).withOpacity(1.0 - pulseValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(
      Offset(userX, userY),
      8 + (pulseValue * 24),
      userPulsePaint,
    );

    // Solid blue location core dot
    final userCorePaint = Paint()..color = const Color(0xFF0A84FF);
    canvas.drawCircle(Offset(userX, userY), 6, userCorePaint);

    // Center white dot for GPS lock aesthetic
    final userWhitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(userX, userY), 2.5, userWhitePaint);

    // 5. Active Hazards Blinking Spots
    // Hazard 1: Kakul Road Stream (Flooding) - Red Pulse
    final double h1X = size.width * 0.62;
    final double h1Y = size.height * 0.38;
    final double h1Pulse =
        (pulseValue + 0.5) % 1.0; // Offset animation phase by 50%

    final h1PulsePaint = Paint()
      ..color = const Color(0xFFFF453A).withOpacity(1.0 - h1Pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(h1X, h1Y), 6 + (h1Pulse * 28), h1PulsePaint);

    final h1CorePaint = Paint()..color = const Color(0xFFFF453A);
    canvas.drawCircle(Offset(h1X, h1Y), 7, h1CorePaint);

    // Draw warning exclamation (!) inside the core red dot
    _drawText(
      canvas,
      '!',
      Offset(h1X - 2.5, h1Y - 6.5),
      11,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    );

    // Hazard 2: Mandian Chowk Intersection (Road Block) - Orange Pulse
    final double h2X = size.width * 0.25;
    final double h2Y = size.height * 0.32;
    final double h2Pulse = pulseValue;

    final h2PulsePaint = Paint()
      ..color = const Color(0xFFFF9F0A).withOpacity(1.0 - h2Pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(h2X, h2Y), 6 + (h2Pulse * 22), h2PulsePaint);

    final h2CorePaint = Paint()..color = const Color(0xFFFF9F0A);
    canvas.drawCircle(Offset(h2X, h2Y), 6, h2CorePaint);
    // Draw block mark (X) inside the orange dot
    _drawText(
      canvas,
      'X',
      Offset(h2X - 3.5, h2Y - 5.5),
      8,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    );

    // Restore canvas matrix transformation states.
    canvas.restore();
  }

  // Text drawing helper method using TextPainter to layout and draw text layers on canvas.
  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    double fontSize, {
    Color color = const Color(0xFF48484A),
    FontWeight fontWeight = FontWeight.normal,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset);
  }

  @override
  // Redraw only when the pulse animation value or user-modified zoomScale changes.
  bool shouldRepaint(covariant AbbottabadVectorMapPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.zoomScale != zoomScale;
  }
}
