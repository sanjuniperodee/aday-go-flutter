import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class TextLocale extends StatelessWidget {
  final String text;
  final String? gender;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Map<String, String>? namedArgs;

  const TextLocale(
      this.text, {
        Key? key,
        this.gender,
        this.style,
        this.textAlign,
        this.namedArgs,
      }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.tr(
        gender: gender,
        namedArgs: namedArgs,
      ),
      style: style,
      textAlign: textAlign,
    );
  }
}
