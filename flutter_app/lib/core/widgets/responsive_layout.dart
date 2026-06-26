import 'package:flutter/material.dart';

/// Breakpoints FlotteCam
/// - Mobile  : < 600px  (téléphone)
/// - Tablet  : 600–1024px (tablette)
/// - Desktop : > 1024px  (ordinateur)
class Breakpoints {
  static const double mobile  = 600;
  static const double tablet  = 1024;
}

/// Widget responsive qui adapte le layout selon la largeur d'écran
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < Breakpoints.mobile;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= Breakpoints.mobile && w < Breakpoints.tablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= Breakpoints.tablet;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= Breakpoints.mobile;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= Breakpoints.tablet && desktop != null) return desktop!;
    if (width >= Breakpoints.mobile && tablet != null)  return tablet!;
    return mobile;
  }
}

/// Padding adaptatif selon la taille d'écran
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    EdgeInsets padding;
    if (width >= Breakpoints.tablet) {
      padding = desktopPadding ?? const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    } else if (width >= Breakpoints.mobile) {
      padding = tabletPadding ?? const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
    } else {
      padding = mobilePadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    }

    return Padding(padding: padding, child: child);
  }
}

/// Grille responsive pour les cards (dashboard, liste camions, etc.)
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  int _crossAxisCount(double width) {
    if (width >= Breakpoints.tablet) return 3;
    if (width >= Breakpoints.mobile) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final count = _crossAxisCount(width);

    return LayoutBuilder(builder: (context, constraints) {
      final itemWidth = (constraints.maxWidth - spacing * (count - 1)) / count;
      return Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        children: children.map((child) =>
          SizedBox(width: itemWidth, child: child)
        ).toList(),
      );
    });
  }
}

/// Centre le contenu avec une largeur max sur les grands écrans
class MaxWidthContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const MaxWidthContainer({
    super.key,
    required this.child,
    this.maxWidth = 1400,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
