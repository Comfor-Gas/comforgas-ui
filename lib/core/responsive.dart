import 'package:flutter/widgets.dart';

class Responsive {
  Responsive._();

  static const double desktopBreakpoint = 900;

  static bool isDesktop(BoxConstraints constraints) =>
      constraints.maxWidth >= desktopBreakpoint;

  static bool isDesktopContext(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;
}