import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_spacing.dart';

import '../widgets/google_sign_in_button.dart';
import '../widgets/legal_footer.dart';
import '../../../../shared/widgets/app_image.dart';

/// Welcome / sign-in screen. A full-bleed fight-night backdrop with a Skip
/// affordance, a Google sign-in CTA, and the legal footer.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _busy = false;

  // Sign-in leads into the "Build Your Corner" step (not straight to home).
  void _toCorner() => context.go(AppRoutes.buildCorner);

  Future<void> _signInWithGoogle() async {
    if (_busy) return;
    setState(() => _busy = true);
    // TODO: wire real Google auth (google_sign_in / Firebase). Stubbed for now.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _busy = false);
    if (mounted) _toCorner();
  }

  @override
  Widget build(BuildContext context) {
    final skipStyle = Theme.of(context)
        .textTheme
        .labelLarge
        ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Backdrop.
          Image(image: appImageProvider('assets/images/onboarding_bg.png'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          // Bottom scrim so the CTA + footer stay legible over the artwork.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0xE6000000)],
                stops: [0.45, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Skip, top-right.
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: TextButton(
                      onPressed: _busy ? null : _toCorner,
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      child: Text('Skip', style: skipStyle),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GoogleSignInButton(
                        onPressed: _signInWithGoogle,
                        isLoading: _busy,
                      ),
                      AppSpacing.vGapLg,
                      const LegalFooter(),
                    ],
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
