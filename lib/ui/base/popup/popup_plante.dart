import 'package:flutter/material.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/ui/base/popup/pseudo_popup_menu_item.dart';

enum PlantePopupPosition {
  BOTTOM_LEFT,
  TOP_LEFT,
  TOP_RIGHT,
}

Future<T?> showMenuPlante<T>(
    {required GlobalKey target,
    required BuildContext context,
    required List<T> values,
    PlantePopupPosition position = PlantePopupPosition.BOTTOM_LEFT,
    double offsetFromTarget = 0,
    required List<Widget> children}) async {
  assert(values.length == children.length);

  final items = <PopupMenuItem<T>>[];
  for (var index = 0; index < values.length; ++index) {
    items.add(PopupMenuItem<T>(
      value: values[index],
      child: children[index],
    ));
  }

  return await _showPopupPlante(
    target: target,
    context: context,
    position: position,
    offsetFromTarget: offsetFromTarget,
    items: items,
  );
}

/// Uses Flutter's [showMenu] functions to display a completely custom child.
/// Note that Flutter's popup menu has a limited width, which _cannot_ be
/// enlarged - the custom pop up won't be able to be wider than
/// a half of the screen.
Future<void> showCustomPopUp(
    {required GlobalKey target,
    required BuildContext context,
    double offsetFromTarget = 0,
    required Widget child}) async {
  return await _showPopupPlante(
    target: target,
    context: context,
    position: PlantePopupPosition.BOTTOM_LEFT,
    offsetFromTarget: offsetFromTarget,
    items: [
      PseudoPopupMenuItem(child: child),
    ],
  );
}

Future<T?> _showPopupPlante<T>({
  required GlobalKey target,
  required BuildContext context,
  required PlantePopupPosition position,
  required double offsetFromTarget,
  required List<PopupMenuEntry<T>> items,
}) async {
  final targetBox = target.currentContext?.findRenderObject() as RenderBox?;
  if (targetBox == null) {
    Log.e('showMenuPlante is called when no render box is available. '
        'Did you forget to actually pass the GlobalKey as a key?');
    return null;
  }
  final targetPosition = targetBox.localToGlobal(Offset.zero);

  final RelativeRect rectPosition;
  switch (position) {
    case PlantePopupPosition.BOTTOM_LEFT:
      rectPosition = RelativeRect.fromLTRB(
          targetPosition.dx - targetBox.size.width,
          targetPosition.dy + targetBox.size.height + offsetFromTarget,
          targetPosition.dx,
          targetPosition.dy + targetBox.size.height + offsetFromTarget);
      break;
    case PlantePopupPosition.TOP_LEFT:
      final height = _calculateItemsHeight(items);
      rectPosition = RelativeRect.fromLTRB(
          targetPosition.dx - targetBox.size.width,
          targetPosition.dy - height - offsetFromTarget,
          targetPosition.dx,
          targetPosition.dy - height - offsetFromTarget);
      break;
    case PlantePopupPosition.TOP_RIGHT:
      final height = _calculateItemsHeight(items);
      rectPosition = RelativeRect.fromLTRB(
          targetPosition.dx,
          targetPosition.dy - height - offsetFromTarget,
          targetPosition.dx + targetBox.size.width,
          targetPosition.dy - height - offsetFromTarget);
      break;
  }

  return await showMenu(
    context: context,
    position: rectPosition,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    items: items,
  );
}

double _calculateItemsHeight(List<PopupMenuEntry<dynamic>> items) {
  const systemPopupVerticalPaddings = 17; // Approximate
  final height = systemPopupVerticalPaddings +
      items.map((e) => e.height).reduce((lhs, rhs) => lhs + rhs);
  return height;
}
