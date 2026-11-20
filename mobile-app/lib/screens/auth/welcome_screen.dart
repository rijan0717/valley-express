import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../widgets/auth_animations.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// First screen after the splash. Three animated panels introduce the service,
/// then the customer picks how to get in.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pages = PageController();
  int _index = 0;

  static const _panels = [
    _Panel(
      title: 'Kathmandu Valley, delivered',
      body: 'Snacks, soft drinks, ice and mixers at your door across Kathmandu, Lalitpur and Bhaktapur.',
      art: _PanelArt.brand,
    ),
    _Panel(
      title: 'Cold drinks, warm evenings',
      body: 'Stock up for the gathering without leaving it. Chilled and on the way in minutes.',
      art: _PanelArt.cheers,
    ),
    _Panel(
      title: 'Track every step',
      body: 'Watch your order move from the hub to your door, and message dispatch any time.',
      art: _PanelArt.delivery,
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _panels.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _buildPanel(_panels[i]),
              ),
            ),

            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _panels.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _index ? AppTheme.accent : AppTheme.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => _go(const RegisterScreen()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Create an account',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ).authEntrance(index: 0),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () => _go(const LoginScreen()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.brandBlue,
                        side: const BorderSide(color: AppTheme.brandBlue, width: 1.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'I already have an account',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ).authEntrance(index: 1),
                  // OTP sign-in is still reachable from the login screen
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel(_Panel panel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 230,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AmbientHalo(
                  size: 250,
                  color: panel.art == _PanelArt.cheers
                      ? AppTheme.warning
                      : AppTheme.accent,
                ),
                switch (panel.art) {
                  _PanelArt.delivery => const DeliveryRunAnimation(height: 150),
                  _PanelArt.cheers => const CheersAnimation(size: 110),
                  // The shipped brand SVG, with the entrance driven from Dart
                  _PanelArt.brand => const ValleyLogoMark(height: 108)
                      .animate()
                      .fadeIn(duration: 420.ms)
                      .scale(
                        duration: 560.ms,
                        curve: Curves.easeOutBack,
                        begin: const Offset(0.72, 0.72),
                        end: const Offset(1, 1),
                      ),
                },
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            panel.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMain,
              height: 1.25,
            ),
          ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: 12),
          Text(
            panel.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppTheme.textMuted,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ).animate(delay: 120.ms).fadeIn(duration: 420.ms).slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }
}

enum _PanelArt { delivery, cheers, brand }

class _Panel {
  final String title;
  final String body;
  final _PanelArt art;

  const _Panel({required this.title, required this.body, required this.art});
}
