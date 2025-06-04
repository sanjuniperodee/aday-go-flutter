import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/button_styles.dart';
import '../../core/colors.dart';
import '../../core/common_strings.dart';
import '../../core/text_styles.dart';

class PrimaryOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool showBadge;
  final double height;
  final String text;
  final TextStyle? textStyle;
  final ButtonStyle? style;
  final Widget? child;

  const PrimaryOutlinedButton({
    Key? key,
    required this.onPressed,
    double? height,
    String? text,
    bool? isLoading,
    this.showBadge = false,
    this.style,
    this.textStyle,
    this.child,
  })  : isLoading = isLoading ?? false,
        text = text ?? emptyString,
        height = height ?? 48;

  factory PrimaryOutlinedButton.primary({
    required VoidCallback? onPressed,
    String? text,
    double? height,
    bool? isLoading,
    bool showBadge = false,
    Widget? child,
    ButtonStyle? style,
    TextStyle? textStyle,
  }) =>
      PrimaryOutlinedButton(
        style: style ?? outlinedRounded9,
        onPressed: onPressed,
        height: height,
        isLoading: isLoading,
        showBadge: showBadge,
        text: text,
        textStyle: textStyle,
        child: child,
      );

  factory PrimaryOutlinedButton.secondary({
    required VoidCallback? onPressed,
    String? text,
    TextStyle? textStyle,
    bool? isLoading,
    bool showBadge = false,
    Widget? child,
    ButtonStyle? style,
  }) =>
      PrimaryOutlinedButton(
        style: style ?? greyscale10Rounded12,
        onPressed: onPressed,
        isLoading: isLoading,
        showBadge: showBadge,
        textStyle: textStyle,
        text: text,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: isLoading,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: OutlinedButton(
          style: style,
          onPressed: onPressed,
          child: Badge(
            smallSize: 8,
            alignment: Alignment(
                1.2, -1
            ),
            backgroundColor: showBadge ? Colors.red : Colors.transparent,
            child: isLoading
                ? Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
                : child ??
                Text(
                  text,
                  style: textStyle ?? text600Size16White,
                ).tr(),
          ),
        ),
      ),
    );
  }
}
