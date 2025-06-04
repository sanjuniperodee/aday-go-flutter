import 'package:flutter/material.dart';

TextEditingController createTextEditingController({
  String initialText = '',
  Function(String)? onChanged,
}) {
  TextEditingController textEditingController = TextEditingController(
    text: initialText,
  );

  textEditingController.addListener(() {
    onChanged?.call(textEditingController.text);
  });

  return textEditingController;
}