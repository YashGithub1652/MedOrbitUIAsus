import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  final _pages = const [
    _PageData(
      title: 'Understand Your\n',
      highlight: 'Symptoms',
      after: '',
      subtitle:
          'AI-powered analysis across 12 health domains for a clearer picture of your wellness.',
      chips: ['RESPIRATORY', 'CARDIAC', 'NEUROLOGICAL'],
      iconData: Icons.psychology_outlined,
      iconColor: Color(0xFF8B5CF6),
    ),
    _PageData(
      title: 'Medication &\n',
      highlight: 'Monitoring',
      after: '',
      subtitle:
          'Smart reminders and interaction checking to keep your treatment plan safe and on schedule.',
      chips: ['REMINDERS', 'INTERACTIONS', 'TRACKING'],
      iconData: Icons.medication_outlined,
      iconColor: Color(0xFFEC4899),
    ),
    _PageData(
      title: 'All Your Health in\n',
      highlight: 'One Place',
      after: '',
      subtitle:
          'A comprehensive overview of your wellness journey, updated in real-time.',
      chips: ['VITALS', 'HISTORY', 'AI INSIGHTS'],
      iconData: Icons.dashboard_outlined,
      iconColor: Color(0xFF2563EB),
      isLast: true,
    ),
  ];

  Future<void> _markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut);
    } else {
      _markSeen();
      context.go('/register');
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CrevaColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CREVA',
                    style: TextStyle(
                      color: CrevaColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      letterSpacing: 1,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _markSeen();
                      context.go('/register');
                    },
                    child: const Text('Skip',
                        style: TextStyle(color: CrevaColors.textSecondary)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _OnboardPage(data: _pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _page ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? CrevaColors.primary
                              : CrevaColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CrevaColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _page == _pages.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward,
                              color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                  if (_page == _pages.length - 1) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        _markSeen();
                        context.go('/login');
                      },
                      child: const Text.rich(TextSpan(children: [
                        TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(
                                color: CrevaColors.textSecondary)),
                        TextSpan(
                            text: 'Log In',
                            style: TextStyle(
                                color: CrevaColors.primary,
                                fontWeight: FontWeight.w600)),
                      ])),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageData {
  final String title;
  final String highlight;
  final String after;
  final String subtitle;
  final List<String> chips;
  final IconData iconData;
  final Color iconColor;
  final bool isLast;

  const _PageData({
    required this.title,
    required this.highlight,
    required this.after,
    required this.subtitle,
    required this.chips,
    required this.iconData,
    required this.iconColor,
    this.isLast = false,
  });
}

class _OnboardPage extends StatelessWidget {
  final _PageData data;
  const _OnboardPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    data.iconColor.withValues(alpha: 0.08),
                    data.iconColor.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: data.iconColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(data.iconData,
                        size: 52, color: data.iconColor),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: data.chips
                        .map((c) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.06),
                                    blurRadius: 8,
                                  )
                                ],
                              ),
                              child: Text(c,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: data.iconColor,
                                      letterSpacing: 0.5)),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: data.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: CrevaColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    TextSpan(
                      text: data.highlight,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: CrevaColors.primary,
                        height: 1.2,
                      ),
                    ),
                  ]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  data.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: CrevaColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}