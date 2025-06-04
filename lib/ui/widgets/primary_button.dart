import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/button_styles.dart';
import '../../core/text_styles.dart';

class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final String text;
  final TextStyle? textStyle;
  final ButtonStyle? style;
  final Widget? child;

  const PrimaryButton({
    Key? key,
    required this.onPressed,
    double? height,
    String? text,
    bool? isLoading,
    this.style,
    this.textStyle,
    this.child,
  })  : isLoading = isLoading ?? false,
        text = text ?? '',
        height = height ?? 48;

  factory PrimaryButton.primary({
    required VoidCallback? onPressed,
    String? text,
    double? height,
    bool? isLoading,
    Widget? child,
    ButtonStyle? style,
    TextStyle? textStyle,
  }) =>
      PrimaryButton(
        style: style ?? primaryRounded9,
        onPressed: onPressed,
        height: height,
        isLoading: isLoading,
        text: text,
        textStyle: textStyle,
        child: child,
      );

  factory PrimaryButton.secondary({
    required VoidCallback? onPressed,
    String? text,
    TextStyle? textStyle,
    bool? isLoading,
    Widget? child,
    ButtonStyle? style,
  }) =>
      PrimaryButton(
        style: style ?? greyscale10Rounded12,
        onPressed: onPressed,
        isLoading: isLoading,
        // textStyle: textStyle ?? text600Size14Greyscale100Manrope,
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
        child: ElevatedButton(
          style: style,
          onPressed: onPressed,
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : child ??
                  Text(
                    text,
                    style: textStyle ?? text400Size16Black,
                  ),
        ),
      ),
    );
  }
}
