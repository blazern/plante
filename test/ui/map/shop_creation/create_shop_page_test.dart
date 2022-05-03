import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/osm/osm_address.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/ui/map/shop_creation/create_shop_page.dart';

import '../../../common_mocks.mocks.dart';
import '../../../test_di_registry.dart';
import '../../../widget_tester_extension.dart';

void main() {
  late MockShopsManager shopsManager;
  late MockAddressObtainer addressObtainer;

  final readyAddress = OsmAddress((e) => e..road = 'Broadway');
  final coord = Coord(lat: 3.4, lon: 1.2);

  setUp(() async {
    shopsManager = MockShopsManager();
    addressObtainer = MockAddressObtainer();

    await TestDiRegistry.register((r) {
      r.register<ShopsManager>(shopsManager);
      r.register<AddressObtainer>(addressObtainer);
    });

    when(shopsManager.createShop(
            name: anyNamed('name'),
            coord: anyNamed('coord'),
            type: anyNamed('type')))
        .thenAnswer((invc) async {
      final name = invc.namedArguments[const Symbol('name')] as String;
      final coords = invc.namedArguments[const Symbol('coord')] as Coord;
      final id = OsmUID.parse('1:${randInt(100, 500)}');
      return Ok(Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = id
          ..longitude = coords.lon
          ..latitude = coords.lat
          ..name = name))
        ..backendShop.replace(BackendShop((e) => e
          ..osmUID = id
          ..productsCount = 0))));
    });
    when(addressObtainer.addressOfCoords(any))
        .thenAnswer((_) async => Ok(readyAddress));
    when(addressObtainer.shortAddressOfCoords(any))
        .thenAnswer((_) async => Ok(readyAddress.toShort()));
  });

  Future<void> createShopTestImpl(WidgetTester tester,
      {String? shopName, ShopType? shopType}) async {
    final context = await tester.superPump(CreateShopPage(shopCoord: coord));

    if (shopName != null) {
      await tester.enterText(
          find.byKey(const Key('new_shop_name_input')), shopName);
      await tester.pumpAndSettle();
    }

    if (shopType != null) {
      await tester.superTap(find.byKey(const Key('shop_type_dropdown')));
      await tester.superTapDropDownItem(shopType.localize(context));
    }

    await tester.tap(find.text(context.strings.global_done));
    await tester.pumpAndSettle();
  }

  testWidgets('create shop', (WidgetTester tester) async {
    verifyNever(shopsManager.createShop(
        name: anyNamed('name'),
        coord: anyNamed('coord'),
        type: anyNamed('type')));

    await createShopTestImpl(tester,
        shopName: 'new shop', shopType: ShopType.deli);

    // Shop is created
    verify(shopsManager.createShop(
        name: 'new shop', coord: coord, type: ShopType.deli));
  });

  testWidgets('cannot create shop when shop name is not set',
      (WidgetTester tester) async {
    await createShopTestImpl(tester, shopName: null, shopType: ShopType.deli);

    verifyNever(shopsManager.createShop(
        name: anyNamed('name'),
        coord: anyNamed('coord'),
        type: anyNamed('type')));
  });

  testWidgets('cannot create shop when shop type is not set',
      (WidgetTester tester) async {
    await createShopTestImpl(tester, shopName: 'shop name', shopType: null);

    verifyNever(shopsManager.createShop(
        name: anyNamed('name'),
        coord: anyNamed('coord'),
        type: anyNamed('type')));
  });

  testWidgets(
      'only 1 shop is created when the done button is clicked many times with slow network',
      (WidgetTester tester) async {
    final context = await tester.superPump(CreateShopPage(shopCoord: coord));

    await tester.superEnterText(
        find.byKey(const Key('new_shop_name_input')), 'Sparta');
    await tester.superTap(find.byKey(const Key('shop_type_dropdown')));
    await tester.superTapDropDownItem(ShopType.deli.localize(context));

    final completer = Completer<Shop>();
    when(shopsManager.createShop(
            name: anyNamed('name'),
            coord: anyNamed('coord'),
            type: anyNamed('type')))
        .thenAnswer((invc) async {
      return Ok(await completer.future);
    });

    await tester.superTap(find.text(context.strings.global_done));
    await tester.superTap(find.text(context.strings.global_done));
    await tester.superTap(find.text(context.strings.global_done));

    completer.complete(Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:${randInt(100, 500)}')
        ..longitude = 123
        ..latitude = 321
        ..name = 'Sparta'))
      ..backendShop.replace(BackendShop((e) => e
        ..osmUID = OsmUID.parse('1:${randInt(100, 500)}')
        ..productsCount = 0))));

    verify(shopsManager.createShop(
            name: anyNamed('name'),
            coord: anyNamed('coord'),
            type: anyNamed('type')))
        .called(1);
  });
}
