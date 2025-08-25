import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final String text;
  final String? icon;
  final IconData? iconData;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.text,
    this.icon,
    this.iconData,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.white,
          side: BorderSide(
            color: borderColor ?? theme.colorScheme.outline,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? theme.colorScheme.onSurface,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Image.asset(
                      icon!,
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          iconData ?? Icons.login,
                          size: 24,
                          color: textColor ?? theme.colorScheme.onSurface,
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                  ] else if (iconData != null) ...[
                    Icon(
                      iconData,
                      size: 24,
                      color: textColor ?? theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// Google Sign-In Button
class GoogleSignInButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SocialLoginButton(
      text: text,
      iconData: Icons.g_mobiledata,
      onPressed: onPressed,
      isLoading: isLoading,
      backgroundColor: Colors.white,
      textColor: Colors.black87,
      borderColor: Colors.grey[300],
    );
  }
}

// Facebook Sign-In Button
class FacebookSignInButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const FacebookSignInButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SocialLoginButton(
      text: text,
      iconData: Icons.facebook,
      onPressed: onPressed,
      isLoading: isLoading,
      backgroundColor: const Color(0xFF1877F2),
      textColor: Colors.white,
      borderColor: const Color(0xFF1877F2),
    );
  }
}

// Apple Sign-In Button
class AppleSignInButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AppleSignInButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SocialLoginButton(
      text: text,
      iconData: Icons.apple,
      onPressed: onPressed,
      isLoading: isLoading,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      borderColor: Colors.black,
    );
  }
}
