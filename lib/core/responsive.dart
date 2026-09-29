import 'package:flutter/widgets.dart';

class Responsive {
  Responsive._();

  static const double desktopBreakpoint = 900;
  static const double mobileBreakpoint = 700;

  static bool isMobile(BoxConstraints constraints) =>
      constraints.maxWidth < mobileBreakpoint;

  static bool isMobileContext(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  static bool isDesktop(BoxConstraints constraints) =>
      constraints.maxWidth >= desktopBreakpoint;

  static bool isDesktopContext(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;
}