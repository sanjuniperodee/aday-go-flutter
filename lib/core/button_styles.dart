import 'package:flutter/material.dart';

import 'colors.dart';

final ButtonStyle primaryRounded9 = ElevatedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(9),
  ),
  elevation: 0,
  backgroundColor: primaryColor,
);

final ButtonStyle errorRounded9 = ElevatedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(9),
  ),
  elevation: 0,
  backgroundColor: primaryColor,
);

final ButtonStyle primaryRounded9Padding8 = ElevatedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(9),
  ),
  elevation: 0,
  padding: const EdgeInsets.all(8),
  backgroundColor: primaryColor,
);

final ButtonStyle primaryRounded9Opacity8 = ElevatedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(9),
  ),
  elevation: 0,
  backgroundColor: primaryColor,
  disabledBackgroundColor: primaryColor.withOpacity(0.08),
);

final ButtonStyle primaryRounded8Padding = ElevatedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
  padding: const EdgeInsets.symmetric(vertical: 6),
  elevation: 0,
  backgroundColor: primaryColor,
  disabledBackgroundColor: primaryColor.withOpacity(0.08),
);

final ButtonStyle primaryRounded12Opacity10 = ElevatedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  elevation: 0,
  backgroundColor: primaryColor.withOpacity(0.1),
  disabledBackgroundColor: primaryColor.withOpacity(0.08),
);

final ButtonStyle primaryRounded9Opacity10 = ElevatedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(9),
  ),
  elevation: 0,
  backgroundColor: greyscale10,
  disabledBackgroundColor: primaryColor.withOpacity(0.1),
);

final ButtonStyle primaryRounded12 = ElevatedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  elevation: 0,
  backgroundColor: primaryColor,
);

final ButtonStyle greyscale10Rounded9 = ElevatedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(9),
  ),
  elevation: 0,
  backgroundColor: greyscale10,
);

final ButtonStyle greyscale10Rounded12 = ElevatedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  elevation: 0,
  backgroundColor: greyscale10,
);

final ButtonStyle greyscale10Rounded12EdgeInsets12 = ElevatedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  elevation: 0,
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  backgroundColor: greyscale10,
);

final ButtonStyle greyscale20Rounded12 = ElevatedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  elevation: 0,
  // backgroundColor: greyscale20,
);

final ButtonStyle greyscale30Rounded9 = ElevatedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(9),
  ),
  elevation: 0,
  backgroundColor: greyscale30,
);

final ButtonStyle white20Rounded12 = ElevatedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  elevation: 0,
  backgroundColor: Colors.white,
);

/// OUTLINED BUTTON STYLES
final ButtonStyle outlinedRounded9 = OutlinedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(9),
  ),
  side: BorderSide(
    color: primaryColor,
  ),
  elevation: 0,
);
final ButtonStyle outlinedRounded12 = OutlinedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  backgroundColor: Colors.transparent,
  side: BorderSide(
    color: primaryColor,
  ),
  elevation: 0,
);
final ButtonStyle outlinedRounded12Green = OutlinedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  backgroundColor: Colors.green,
  elevation: 0,
);

final ButtonStyle outlinedRounded12BorderGreyscale30 = OutlinedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  backgroundColor: Colors.transparent,
  side: BorderSide(
    color: greyscale30,
  ),
  elevation: 0,
);

final ButtonStyle outlinedRounded100Greyscale10BorderGreyscale30 =
    OutlinedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(100),
  ),
  backgroundColor: greyscale10,
  side: BorderSide(
    color: greyscale30,
  ),
  elevation: 0,
);

final ButtonStyle outlinedRounded100Greyscale10BorderGreyscale30PaddingV10H12 =
    OutlinedButton.styleFrom(
  padding: const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  ),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(100),
  ),
  backgroundColor: greyscale10,
  side: BorderSide(
    color: greyscale30,
  ),
  elevation: 0,
);
