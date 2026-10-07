import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/stitch_theme.dart';

class RadialMenuItem {
  final String label;
  final IconData icon;
  final Color color;
  final String categoryName;

  RadialMenuItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.categoryName,
  });
}

class RadialMenuOverlay extends StatefulWidget {
  final Offset touchPosition;
  final Function(String category) onCategorySelected;
  final VoidCallback onDismiss;
  final Duration animationDuration;

  const RadialMenuOverlay({
    Key? key,
    required this.touchPosition,
    required this.onCategorySelected,
    required this.onDismiss,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  State<RadialMenuOverlay> createState() => _RadialMenuOverlayState();
}

class _RadialMenuOverlayState extends State<RadialMenuOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;

  // The 7 Required Categories (+ Mixed Feed option)
  final List<RadialMenuItem> _items = [
    RadialMenuItem(
      label: 'Events',
      icon: Icons.calendar_month_rounded,
      color: StitchTheme.primaryCyan,
      categoryName: 'Events',
    ),
    RadialMenuItem(
      label: 'Hackathons',
      icon: Icons.code_rounded,
      color: StitchTheme.secondaryPurple,
      categoryName: 'Hackathons',
    ),
    RadialMenuItem(
      label: 'Internships',
      icon: Icons.work_outline_rounded,
      color: StitchTheme.primaryCyan,
      categoryName: 'Internships',
    ),
    RadialMenuItem(
      label: 'Clubs',
      icon: Icons.emoji_events_rounded,
      color: Colors.amber,
      categoryName: 'Clubs',
    ),
    RadialMenuItem(
      label: 'Student Posts',
      icon: Icons.school_rounded,
      color: Colors.pinkAccent,
      categoryName: 'Student Posts',
    ),
    RadialMenuItem(
      label: 'Announcements',
      icon: Icons.campaign_rounded,
      color: Colors.orangeAccent,
      categoryName: 'Announcements',
    ),
    RadialMenuItem(
      label: 'Opportunities',
      icon: Icons.rocket_launch_rounded,
      color: Colors.greenAccent,
      categoryName: 'Opportunities',
    ),
    RadialMenuItem(
      label: 'Mixed Feed',
      icon: Icons.dynamic_feed_rounded,
      color: Colors.white,
      categoryName: 'Mixed Feed',
    ),
  ];

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _rotationAnimation = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSelect(String cat) async {
    await _controller.reverse();
    widget.onCategorySelected(cat);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final touch = widget.touchPosition;

    return GestureDetector(
      onTap: () async {
        await _controller.reverse();
        widget.onDismiss();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withOpacity(0.75),
        child: Stack(
          children: [
            // Center Touch Glow Ring
            Positioned(
              left: touch.dx - 110,
              top: touch.dy - 110,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: StitchTheme.primaryCyan.withOpacity(0.6),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: StitchTheme.primaryCyan.withOpacity(0.35),
                              blurRadius: 35,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 7 Radial Category Buttons Positioned 360-degrees around exact touch position
            ...List.generate(_items.length, (index) {
              final item = _items[index];
              const radius = 120.0;

              // Distribute items in a full circle around touch point
              final angleStep = (2 * math.pi) / _items.length;
              final angle = (index * angleStep) - (math.pi / 2);

              final rawX = touch.dx + radius * math.cos(angle) - 30;
              final rawY = touch.dy + radius * math.sin(angle) - 30;

              // Automatic edge clamping to prevent buttons from overflowing visible screen
              final clampedX = rawX.clamp(16.0, screenSize.width - 76.0);
              final clampedY = rawY.clamp(60.0, screenSize.height - 90.0);

              return Positioned(
                left: clampedX,
                top: clampedY,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: InkWell(
                            onTap: () => _handleSelect(item.categoryName),
                            borderRadius: BorderRadius.circular(30),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: StitchTheme.cardBg,
                                    border: Border.all(color: item.color, width: 2.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: item.color.withOpacity(0.6),
                                        blurRadius: 14,
                                        spreadRadius: 2,
                                      )
                                    ],
                                  ),
                                  child: Icon(item.icon, color: item.color, size: 24),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: item.color.withOpacity(0.4)),
                                  ),
                                  child: Text(
                                    item.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
