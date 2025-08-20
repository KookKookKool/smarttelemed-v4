import 'package:flutter/material.dart';

class ResponsiveSizer {
  final BuildContext context;
  final MediaQueryData mq;

  ResponsiveSizer(this.context) : mq = MediaQuery.of(context);

  double get w => mq.size.width;
  double get h => mq.size.height;

  /// Scale a width value (based on 375 design width)
  double sw(double px) => px * (w / 375.0);

  /// Scale a height value (based on 812 design height)
  double sh(double px) => px * (h / 812.0);

  /// Scale font size modestly using width
  double sf(double px) => px * (w / 375.0);
}
