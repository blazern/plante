import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/svg_utils.dart';
import 'package:plante/ui/base/ui_utils.dart';

typedef SwitchPlanteCallback = void Function(bool leftSelected);

class SwitchPlante extends StatefulWidget {
  final bool leftSelected;
  final double width;
  final double height;
  final String leftSvgAsset;
  final String rightSvgAsset;
  final SwitchPlanteCallback callback;

  final Color colorBackground;
  final Color colorActive;
  final BoxShadow? boxShadow;

  const SwitchPlante({
    Key? key,
    required this.leftSelected,
    required this.leftSvgAsset,
    required this.rightSvgAsset,
    required this.callback,
    this.colorBackground = Colors.white,
    this.colorActive = ColorsPlante.primary,
    this.width = 190,
    this.height = 39,
    this.boxShadow,
  }) : super(key: key);

  @override
  _SwitchPlanteState createState() => _SwitchPlanteState(leftSelected);
}

class _SwitchPlanteState extends State<SwitchPlante>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _colorLeft;
  late Animation<Color?> _colorRight;
  bool leftSelected;

  _SwitchPlanteState(this.leftSelected);

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: DURATION_DEFAULT);
    _colorLeft =
        ColorTween(begin: widget.colorBackground, end: widget.colorActive)
            .animate(_animationController);
    _colorRight =
        ColorTween(begin: widget.colorActive, end: widget.colorBackground)
            .animate(_animationController);
  }

  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
  }

  @override
  void didUpdateWidget(SwitchPlante oldWidget) {
    super.didUpdateWidget(oldWidget);
    leftSelected = widget.leftSelected;
    assert(oldWidget.colorBackground == widget.colorBackground);
    assert(oldWidget.colorActive == widget.colorActive);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(children: [
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.colorBackground,
            borderRadius: BorderRadius.circular(8),
            boxShadow: widget.boxShadow != null ? [widget.boxShadow!] : null,
          ),
        ),
        AnimatedAlign(
            duration: DURATION_DEFAULT,
            alignment:
                leftSelected ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
                width: widget.width / 2,
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.colorActive,
                  borderRadius: BorderRadius.circular(8),
                ))),
        SizedBox(
            height: widget.height,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (_, child) {
                return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SvgPicture.asset(widget.leftSvgAsset,
                          colorFilter: _colorLeft.value.toColorFilter()),
                      SvgPicture.asset(widget.rightSvgAsset,
                          colorFilter: _colorRight.value.toColorFilter()),
                    ]);
              },
            )),
        Material(
            color: Colors.transparent,
            child: InkWell(
              overlayColor: MaterialStateProperty.all(
                  ColorsPlante.splashColor.withAlpha(50)),
              onTap: switchClicked,
              borderRadius: BorderRadius.circular(8),
            ))
      ]),
    );
  }

  void switchClicked() {
    setState(() {
      leftSelected = !leftSelected;
      if (leftSelected) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    });
    widget.callback.call(leftSelected);
  }
}
