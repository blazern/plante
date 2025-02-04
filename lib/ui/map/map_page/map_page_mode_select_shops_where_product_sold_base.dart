import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/button_text_plante.dart';
import 'package:plante/ui/base/components/shop_card.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/map/components/fab_add_shop.dart';
import 'package:plante/ui/map/map_page/map_page_mode.dart';
import 'package:plante/ui/map/map_page/map_page_mode_shops_card_base.dart';

const MAP_PAGE_MODE_SELECTED_SHOPS_MAX = 10;

abstract class MapPageModeSelectShopsWhereProductSoldBase
    extends MapPageModeShopsCardBase {
  static const _HINT_ID = 'MapPageModeSelectShopsWhereProductSoldBase hint 1';
  final _selectedShops = <Shop>{};
  final _unselectedShops = <Shop>{};

  MapPageModeSelectShopsWhereProductSoldBase(MapPageModeParams params,
      {required String nameForAnalytics})
      : super(params, nameForAnalytics: nameForAnalytics) {
    _selectedShops.addAll(widget.initialSelectedShops);
  }

  @protected
  void onDoneClick();
  @protected
  void onAddShopClicked();

  @override
  Set<Shop> selectedShops() => _selectedShops;

  @mustCallSuper
  @override
  void init(MapPageMode? previousMode) {
    super.init(previousMode);

    if (previousMode != null) {
      _selectedShops.addAll(
          previousMode.selectedShops().take(MAP_PAGE_MODE_SELECTED_SHOPS_MAX));
    }

    hintsController.addHint(
        _HINT_ID, context.strings.map_page_click_on_shop_where_product_sold);
    onDisplayedShopsChange(displayedShops);
  }

  @mustCallSuper
  @override
  void deinit() {
    hintsController.removeHint(_HINT_ID);
    setBottomHintSimple(null);
    super.deinit();
  }

  @override
  ShopCard createCardFor(Shop shop, FutureShortAddress address,
      ArgCallback<Shop>? cancelCallback) {
    final Product product;
    if (widget.product != null) {
      product = widget.product!;
    } else {
      product = Product((e) => e.barcode = 'fake_product');
    }

    bool? isSold;
    if (_selectedShops.contains(shop)) {
      isSold = true;
    } else if (_unselectedShops.contains(shop)) {
      isSold = false;
    }

    return ShopCard.askIfProductIsSold(
        product: product,
        shop: shop,
        address: address,
        isProductSold: isSold,
        onIsProductSoldChanged: _onProductSoldChange,
        cancelCallback: cancelCallback);
  }

  void _onProductSoldChange(Shop shop, bool? isSold) {
    _selectedShops.remove(shop);
    _unselectedShops.remove(shop);
    if (isSold == true) {
      if (_selectedShops.length < MAP_PAGE_MODE_SELECTED_SHOPS_MAX) {
        _selectedShops.add(shop);
      } else {
        Log.w('Not allowing to select more than 10 shops');
      }
    } else if (isSold == false) {
      _unselectedShops.add(shop);
    }
    hideShopsCard();
  }

  @override
  Widget buildOverlay() {
    return Stack(children: [shopsCardsWidget()]);
  }

  @override
  List<Widget> buildFABs() {
    return [
      FabAddShop(
          key: const Key('add_shop_fab'),
          onPressed: !model.loading ? onAddShopClicked : null)
    ];
  }

  @override
  List<Widget> buildBottomActions() {
    return [
      SizedBox(
          key: const Key('map_page_cancel'),
          width: double.infinity,
          child: Padding(
              padding: const EdgeInsets.only(left: 26, right: 26, bottom: 8),
              child: ButtonTextPlante(context.strings.global_cancel,
                  onPressed: _onCancelClick))),
      SizedBox(
          key: const Key('map_page_done'),
          width: double.infinity,
          child: Padding(
              padding: const EdgeInsets.only(left: 26, right: 26, bottom: 24),
              child: ButtonFilledPlante.withText(context.strings.global_done,
                  onPressed: selectedShops().isNotEmpty && !model.loading
                      ? onDoneClick
                      : null))),
    ];
  }

  void _onCancelClick() async {
    if (selectedShops().isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    await showYesNoDialog(
        context, context.strings.map_page_cancel_putting_product_q, () {
      Navigator.of(context).pop();
    });
  }

  @override
  Future<bool> onWillPop() async {
    final superAllowedPop = await super.onWillPop();
    if (!superAllowedPop) {
      return superAllowedPop;
    }
    if (selectedShops().isNotEmpty) {
      _onCancelClick();
      return false;
    }
    return true;
  }

  @override
  void onDisplayedShopsChange(Iterable<Shop> shops) {
    if (shops.isEmpty) {
      setBottomHintSimple(
          context.strings.map_page_no_shops_hint_in_select_shops_mode);
    } else {
      setBottomHintSimple(null);
    }
  }
}
