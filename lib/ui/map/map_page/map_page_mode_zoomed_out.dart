import 'package:plante/l10n/strings.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/ui/map/map_page/map_page_mode.dart';
import 'package:plante/ui/map/map_page/map_page_mode_default.dart';

class MapPageModeZoomedOut extends MapPageMode {
  static const MIN_ZOOM = MapPageModeDefault.MIN_ZOOM;
  static const _ZOOM_HINT_ID = 'MapPageModeZoomedOut_ZOOM_HINT';

  MapPageModeZoomedOut(MapPageModeParams params)
      : super(params, nameForAnalytics: 'zoomed_out');

  @override
  void init(MapPageMode? previousMode) {
    super.init(previousMode);
    hintsController.addHint(
        _ZOOM_HINT_ID, context.strings.map_page_zoom_in_to_see_shops);
    shouldLoadNewShops.setValue(false);
  }

  @override
  void deinit() {
    hintsController.removeHint(_ZOOM_HINT_ID);
    super.deinit();
  }

  @override
  Iterable<Shop> filter(Iterable<Shop> shops) => const [];

  @override
  double minZoom() => MIN_ZOOM;

  @override
  void onCameraMove(Coord coord) {
    if (zoom.cachedVal >= super.minZoom()) {
      switchModeTo(MapPageModeDefault(params));
    }
  }
}
