import 'package:flutter/material.dart';

/// Legacy enum kept for backwards compatibility.
enum AuthTab { signIn, smsOtp, createAccount, forgot }

/// Deprecated: Segmented auth tab bar has been completely removed in favor of
/// a standard navigable auth flow. This widget renders nothing.
class AuthTabBar extends StatelessWidget {
  final AuthTab current;

  const AuthTabBar({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
