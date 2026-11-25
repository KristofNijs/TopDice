import 'package:flutter/material.dart';

import 'casino_theme.dart';

/// Vaste balk onderaan elk scherm, gereserveerd voor advertentiecontent.
///
/// Tijdens ontwikkeling toont de balk een placeholder; zodra er een echt
/// advertentienetwerk gekoppeld wordt, kan via [child] de content worden
/// meegegeven zonder dat de schermen veranderen.
class AdBanner extends StatelessWidget {
  const AdBanner({super.key, this.height = 56, this.child});

  /// Vaste hoogte van de balk in logical pixels.
  final double height;

  /// Optionele advertentiecontent; bij null wordt een placeholder getoond.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final Widget content = child ??
        Text(
          'Advertentie',
          style: TextStyle(color: CasinoColors.ivory.withValues(alpha: 0.6)),
        );

    return Container(
      key: const Key('ad-banner'),
      width: double.infinity,
      height: height,
      color: CasinoColors.tableGreenDark,
      alignment: Alignment.center,
      child: content,
    );
  }
}
