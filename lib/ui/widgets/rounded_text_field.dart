import 'package:aktau_go/core/colors.dart';
import 'package:aktau_go/core/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RoundedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String labelText;
  final int minLines;
  final int maxLines;
  final BorderRadius borderRadius;
  final Color backgroundColor;
  final TextStyle hintStyle;
  final bool enabled;
  final bool obscure;
  final Widget? trailingWidget;
  final List<TextInputFormatter>? inputFormatters;
  final InputDecoration decoration;
  final TextInputType keyboardType;
  final Function(String?)? onSubmitted;
  final FocusNode? focusNode;

  RoundedTextField({
    Key? key,
    required this.controller,
    this.trailingWidget,
    this.hintText = '',
    this.labelText = '',
    this.minLines = 1,
    this.maxLines = 1,
    this.enabled = true,
    this.obscure = false,
    this.inputFormatters = const [],
    this.decoration = const InputDecoration(),
    this.backgroundColor = greyscale10,
    this.keyboardType = TextInputType.text,
    TextStyle? hintStyle,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.onSubmitted,
    this.focusNode,
  }) : hintStyle = hintStyle ?? text400Size16Black;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: greyscale30,
        ),
        borderRadius: borderRadius,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              minLines: minLines,
              maxLines: maxLines,
              enabled: enabled,
              obscureText: obscure,
              onFieldSubmitted: onSubmitted,
              decoration: decoration.copyWith(
                hintText: hintText,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                hintMaxLines: 2,
                isCollapsed: true,
                labelText: hintText,
                alignLabelWithHint: true,
                labelStyle: hintStyle,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintStyle: hintStyle,
                prefixStyle: text400Size16Black,
              ),
              style: text400Size16Black,
            ),
          ),
          if (trailingWidget != null) trailingWidget!
        ],
      ),
    );
  }
}
