import 'package:aktau_go/core/colors.dart';
import 'package:aktau_go/core/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpCodeTextField extends StatefulWidget {
  final Function(String)? onCompleted;
  final TextEditingController? controller;
  final bool autoFocus;

  const OtpCodeTextField({
    Key? key,
    this.onCompleted,
    this.controller,
    this.autoFocus = false,
  });

  @override
  State<OtpCodeTextField> createState() => _OtpCodeTextFieldState();
}

class _OtpCodeTextFieldState extends State<OtpCodeTextField> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double boxWidth = constraints.maxWidth / 4 - 16;
      return PinCodeTextField(
        appContext: context,
        length: 4,
        controller: widget.controller,
        autoFocus: widget.autoFocus,
        pinTheme: PinTheme(
          borderRadius: BorderRadius.circular(12),

          /// Field Box Sizes
          fieldHeight: 72,
          fieldWidth: boxWidth,

          /// BORDER
          activeBorderWidth: 1,
          selectedColor: greyscale10,
          activeColor: Colors.transparent,
          inactiveColor: greyscale10,
          errorBorderColor: primaryColor,

          /// Background Color
          activeFillColor: Colors.white,
          selectedFillColor: Colors.white,
          inactiveFillColor: Colors.white,

          /// Shape
          shape: PinCodeFieldShape.box,
        ),

        /// TEXT STYLE
        textStyle: text400Size16Black,

        useHapticFeedback: false,
        keyboardType: TextInputType.number,
        enableActiveFill: true,

        onCompleted: (value) {
          HapticFeedback.lightImpact();
          widget.onCompleted?.call(value);
        },
        onChanged: (value) {
          if (value.isNotEmpty) {
            HapticFeedback.selectionClick();
          }
        },
      );
    });
  }
}
