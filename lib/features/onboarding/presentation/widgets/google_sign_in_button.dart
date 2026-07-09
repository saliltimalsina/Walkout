import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_shadows.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/shared/widgets/pressable.dart';

/// White "Sign In with Google" pill CTA with the multicolor Google mark and a
/// loading state. Styled for legibility on top of the fight-night backdrop.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback onPressed;
  final bool isLoading;

  static const _ink = Color(0xFF1F1F1F);

  @override
  Widget build(BuildContext context) {
    return Pressable(
      enabled: !isLoading,
      onTap: onPressed,
      borderRadius: AppRadius.brPill,
      semanticLabel: 'Sign in with Google',
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.brPill,
          boxShadow: AppShadows.md,
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(_ink),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/icons/google_g.svg',
                    width: 22,
                    height: 22,
                  ),
                  AppSpacing.hGapSm,
                  const Text(
                    'Sign In with Google',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
