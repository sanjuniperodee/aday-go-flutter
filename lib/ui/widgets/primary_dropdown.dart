import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PrimaryDropdown<T> extends StatefulWidget {
  const PrimaryDropdown({
    Key? key,
    this.initialOption,
    this.hintText,
    required this.options,
    required this.onChanged,
    this.icon,
    this.error = '',
    this.leading,
    this.width,
    this.height = 42,
    this.fillColor = Colors.white,
    this.textStyle,
    this.elevation = 1,
    this.borderWidth = 1,
    this.borderRadius,
    this.borderColor = const Color(0xFFD8D8D8),
    this.contentPadding =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    this.hidesUnderline = true,
    this.disabled = false,
  });

  final T? initialOption;
  final String? hintText;
  final String error;
  final List<SelectOption<T>> options;
  final void Function(SelectOption?) onChanged;
  final Widget? icon;
  final Widget? leading;
  final double? width;
  final double height;
  final Color fillColor;
  final TextStyle? textStyle;
  final double elevation;
  final double borderWidth;
  final BorderRadius? borderRadius;
  final Color borderColor;
  final EdgeInsetsGeometry contentPadding;
  final bool hidesUnderline;
  final bool disabled;

  @override
  State<PrimaryDropdown> createState() => _PrimaryDropdownState<T>();
}

class _PrimaryDropdownState<T> extends State<PrimaryDropdown> {
  T? dropDownValue;

  List<SelectOption<T>> get effectiveOptions =>
      widget.options as List<SelectOption<T>>;

  @override
  void initState() {
    super.initState();
    dropDownValue = widget.initialOption;
  }

  @override
  Widget build(BuildContext context) {
    final dropdownWidget = DropdownButton<SelectOption<T>>(
      value: effectiveOptions
          .firstWhereOrNull((element) => element.value == widget.initialOption),
      hint: widget.hintText != null
          ? Text(widget.hintText!, style: widget.textStyle)
          : null,
      items: effectiveOptions
          .map((e) => DropdownMenuItem(
                value: e,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (e.leading != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: e.leading!,
                      ),
                    Text(
                      e.getLabel,
                      style: widget.textStyle,
                    ),
                  ],
                ),
              ))
          .toList(),
      elevation: widget.elevation.toInt(),
      selectedItemBuilder: (_) => effectiveOptions
          .map((e) => Align(
                alignment: Alignment.centerLeft,
                child: e.leading ??
                    Text(
                      e.getLabel,
                      style: widget.textStyle,
                    ),
              ))
          .toList(),
      onChanged: widget.disabled
          ? null
          : (value) {
              dropDownValue = value?.value;
              widget.onChanged(value);
            },
      isExpanded: true,
      dropdownColor: widget.fillColor,
      focusColor: Colors.transparent,
    );
    effectiveOptions.firstWhereOrNull((element) {
      return element.value == widget.initialOption;
    });

    final childWidget = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        border: Border.all(
          color: widget.error.isNotEmpty ? Colors.red : widget.borderColor,
          width: widget.borderWidth,
        ),
        color: widget.fillColor,
      ),
      child: Row(
        children: [
          if (widget.leading != null) widget.leading!,
          Expanded(
            child: Padding(
              padding: widget.contentPadding,
              child: widget.hidesUnderline
                  ? DropdownButtonHideUnderline(child: dropdownWidget)
                  : dropdownWidget,
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: widget.width,
            height: double.infinity,
            child: childWidget,
          ),
        ),
        if (widget.error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 10),
            child: Text(
              widget.error,
              style: TextStyle(color: Colors.red),
            ),
          )
      ],
    );
  }
}

class SelectOption<T> {
  final String? label;
  final Widget? leading;
  final Widget? smallLeading;
  final T? value;

  SelectOption({
    this.label,
    this.leading,
    this.smallLeading,
    this.value,
  });

  String get getLabel => this.label ?? '';
}
