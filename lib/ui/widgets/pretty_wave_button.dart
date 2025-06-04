import 'package:aktau_go/core/colors.dart';
import 'package:flutter/material.dart';

/// [PrettyWaveButton] is a custom button that creates wave effect when pressed
/// You can tweak wave length effect by using [waveLength] property
/// Adjust width and height of the container by using [verticalPadding] and [horizontalPadding] properties
/// Define animation duration using [duration] and animation curve by [curve]
class PrettyWaveButton extends StatefulWidget {
  const PrettyWaveButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.borderRadius = 9,
    this.backgroundColor = primaryColor,
    this.verticalPadding = 14,
    this.horizontalPadding = 24,
    this.duration = const Duration(milliseconds: 1000),
    this.curve = Curves.easeInOut,
    this.waveLength = 6,
  });
  final VoidCallback onPressed;
  final double borderRadius;
  final Color backgroundColor;
  final double verticalPadding;
  final double horizontalPadding;
  final Duration duration;
  final Curve curve;
  final double waveLength;
  final Widget child;
  @override
  State<PrettyWaveButton> createState() => _PrettyWaveButtonState();
}

class _PrettyWaveButtonState extends State<PrettyWaveButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.addStatusListener(controllerListener);
  }

  void controllerListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _controller.reset();
    }
  }

  @override
  void didUpdateWidget(covariant PrettyWaveButton oldWidget) {
    if (oldWidget.child != widget.child) {
      _controller.forward();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        widget.onPressed();
      },
      child: <Widget>[
        AnimatedBorderButton(
          animation: _controller,
          curve: widget.curve,
          verticalPadding: widget.verticalPadding,
          horizontalPadding: widget.horizontalPadding,
          waveLength: widget.waveLength,
          backgroundColor: widget.backgroundColor,
          borderRadius: widget.borderRadius,
          child: widget.child,
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius + 2),
            color: widget.backgroundColor,
          ),
          padding: EdgeInsets.symmetric(
            vertical: widget.verticalPadding,
            horizontal: widget.horizontalPadding,
          ),
          margin: EdgeInsets.all(widget.waveLength),
          child: widget.child,
        ),
      ].addStack(
        alignment: Alignment.center,
      ),
    );
  }
}

class AnimatedBorderButton extends AnimatedWidget {
  const AnimatedBorderButton({
    super.key,
    required this.animation,
    required this.curve,
    required this.verticalPadding,
    required this.horizontalPadding,
    required this.borderRadius,
    required this.waveLength,
    required this.backgroundColor,
    required this.child,
  }) : super(
    listenable: animation,
  );
  final Animation<double> animation;
  final Curve curve;
  final double verticalPadding;
  final double horizontalPadding;
  final double borderRadius;
  final double waveLength;
  final Color backgroundColor;
  final Widget child;

  Animation<double> get verticalBorderAnimation => Tween<double>(
    begin: verticalPadding - waveLength,
    end: verticalPadding + waveLength,
  ).animate(curvedAnimation);

  Animation<double> get horizontalBorderAnimation => Tween<double>(
    begin: horizontalPadding - waveLength,
    end: horizontalPadding + waveLength,
  ).animate(curvedAnimation);

  Animation<double> get borderAnimation =>
      Tween<double>(begin: waveLength, end: 0).animate(curvedAnimation);

  Animation<double> get curvedAnimation => CurvedAnimation(
    parent: animation,
    curve: curve,
  );
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: backgroundColor,
          width: borderAnimation.value,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        color: Colors.transparent,
      ),
      padding: EdgeInsets.symmetric(
        vertical: verticalBorderAnimation.value,
        horizontal: horizontalBorderAnimation.value,
      ),
      child: child,
    );
  }
}

extension WidgetEx on Widget {
  Padding addPadding({required EdgeInsetsGeometry edgeInsets}) {
    return Padding(
      padding: edgeInsets,
      child: this,
    );
  }

  Widget addCenter() {
    return Center(
      child: this,
    );
  }

  Widget addExpanded() {
    return Expanded(
      child: this,
    );
  }

  Widget addAlign({
    required AlignmentGeometry alignment,
  }) {
    return Align(
      alignment: alignment,
      child: this,
    );
  }

  Widget addSizedBox({
    double? width,
    double? height,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: this,
    );
  }

  Widget addContainer({
    double? width,
    double? height,
    Color? color,
    BoxDecoration? decoration,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: decoration,
      color: color,
      margin: margin,
      padding: padding,
      child: this,
    );
  }

  Widget addHero({required Object tag}) {
    return Hero(
      tag: tag,
      child: this,
    );
  }

  Widget addOpacity({required double opacity}) {
    return Opacity(
      opacity: opacity,
      child: this,
    );
  }

  Widget addInkWell({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: this,
    );
  }

  Widget addScrollView() {
    return SingleChildScrollView(
      child: this,
    );
  }
}

extension WidgetListEx on List<Widget> {
  Widget addStack({AlignmentGeometry? alignment}) {
    return Stack(
      alignment: alignment ?? AlignmentDirectional.topStart,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      children: this,
    );
  }

  Widget addColumn({
    MainAxisAlignment? mainAxisAlignment,
    CrossAxisAlignment? crossAxisAlignment,
    MainAxisSize? mainAxisSize,
  }) {
    return Column(
      mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
      mainAxisSize: mainAxisSize ?? MainAxisSize.max,
      children: this,
    );
  }

  Widget addRow({
    MainAxisAlignment? mainAxisAlignment,
    CrossAxisAlignment? crossAxisAlignment,
    MainAxisSize? mainAxisSize,
  }) {
    return Row(
      mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
      mainAxisSize: mainAxisSize ?? MainAxisSize.max,
      children: this,
    );
  }

  Widget addWrap() {
    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: this,
    );
  }

  Widget addListView({
    Axis? scrollDirection,
    ScrollPhysics? physics,
    bool? shrinkWrap,
    EdgeInsetsGeometry? padding,
  }) {
    return ListView(
      scrollDirection: scrollDirection ?? Axis.vertical,
      physics: physics,
      shrinkWrap: shrinkWrap ?? false,
      padding: padding,
      children: this,
    );
  }
}
