import 'package:flutter/material.dart';
import '../../design/farol_colors.dart' as tokens;

class OnboardingSlideData {
  final String eyebrowKey;
  final String titleKey;
  final List<String> featureKeys;
  final List<IconData> featureIcons;
  final IconData heroIcon;
  final Color auroraColor;

  const OnboardingSlideData({
    required this.eyebrowKey,
    required this.titleKey,
    required this.featureKeys,
    required this.featureIcons,
    required this.heroIcon,
    required this.auroraColor,
  });
}

const kOnboardingSlides = [
  OnboardingSlideData(
    eyebrowKey: 'onboarding_s1_eyebrow',
    titleKey: 'onboarding_s1_title',
    featureKeys: ['onboarding_s1_f1', 'onboarding_s1_f2', 'onboarding_s1_f3'],
    featureIcons: [
      Icons.wallet_outlined,
      Icons.stacked_line_chart_rounded,
      Icons.repeat_rounded,
    ],
    heroIcon: Icons.donut_large_rounded,
    auroraColor: tokens.FarolColors.beam,
  ),
  OnboardingSlideData(
    eyebrowKey: 'onboarding_s2_eyebrow',
    titleKey: 'onboarding_s2_title',
    featureKeys: ['onboarding_s2_f1', 'onboarding_s2_f2', 'onboarding_s2_f3'],
    featureIcons: [
      Icons.local_fire_department_outlined,
      Icons.show_chart_rounded,
      Icons.notifications_active_outlined,
    ],
    heroIcon: Icons.trending_up_rounded,
    auroraColor: tokens.FarolColors.tide,
  ),
  OnboardingSlideData(
    eyebrowKey: 'onboarding_s3_eyebrow',
    titleKey: 'onboarding_s3_title',
    featureKeys: ['onboarding_s3_f1', 'onboarding_s3_f2', 'onboarding_s3_f3'],
    featureIcons: [
      Icons.group_outlined,
      Icons.favorite_border_rounded,
      Icons.badge_outlined,
    ],
    heroIcon: Icons.hub_rounded,
    auroraColor: tokens.FarolColors.beam,
  ),
];
