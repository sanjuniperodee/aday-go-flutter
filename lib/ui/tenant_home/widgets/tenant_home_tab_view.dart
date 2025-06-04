import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../core/text_styles.dart';
import '../../widgets/text_locale.dart';

class TenantHomeTabView extends StatelessWidget {
  final bool isActive;
  final String label;
  final String asset;

  const TenantHomeTabView({
    super.key,
    this.isActive = false,
    required this.label,
    required this.asset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: ShapeDecoration(
        color: isActive ? Color(0xFFF73C4E) : Colors.white,
        shape: RoundedRectangleBorder(
          side: isActive
              ? BorderSide.none
              : BorderSide(
                  width: 1,
                  color: Color(0xFFB4AAA9),
                ),
          borderRadius: BorderRadius.circular(100),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            asset,
            color: isActive ? Colors.white : Colors.grey,
          ),
          const SizedBox(width: 8),
          TextLocale(
            label,
            style: isActive ? text400Size16White : text400Size16Greyscale30,
          )
        ],
      ),
    );
  }
}
