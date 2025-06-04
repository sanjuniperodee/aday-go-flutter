import 'package:flutter/material.dart';

class PrimaryBottomSheet extends StatelessWidget {
  const PrimaryBottomSheet({
    Key? key,
    required this.child,
    this.height,
    this.contentPadding,
  }) : super(key: key);

  final Widget child;
  final double? height;
  final EdgeInsets? contentPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Wrap(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            clipBehavior: Clip.hardEdge,
            child: Container(
              color: Colors.transparent,
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  color: Colors.white,
                ),
                padding: contentPadding ??
                    EdgeInsets.symmetric(
                      horizontal: 38,
                    ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
