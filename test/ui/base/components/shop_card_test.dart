import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/gender.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_product_range.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/ui/base/components/shop_card.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/base/lang_code_holder.dart';
import 'package:plante/ui/map/shop_product_range_page.dart';
import 'package:plante/ui/scan/barcode_scan_page.dart';

import '../../../fake_user_params_controller.dart';
import '../../../widget_tester_extension.dart';
import 'shop_card_test.mocks.dart';

@GenerateMocks([ShopsManager, UserParamsController, Backend, ProductsManager,
  PermissionsManager, RouteObserver])
void main() {
  late MockShopsManager shopsManager;
  late FakeUserParamsController userParamsController;
  late MockBackend backend;

  setUp(() async {
    await GetIt.I.reset();

    shopsManager = MockShopsManager();
    GetIt.I.registerSingleton<ShopsManager>(shopsManager);
    userParamsController = FakeUserParamsController();
    GetIt.I.registerSingleton<UserParamsController>(userParamsController);
    backend = MockBackend();
    GetIt.I.registerSingleton<Backend>(backend);

    final params = UserParams((v) => v
      ..name = 'Bob'
      ..genderStr = Gender.MALE.name
      ..eatsMilk = false
      ..eatsEggs = false
      ..eatsHoney = false);
    await userParamsController.setUserParams(params);

    GetIt.I.registerSingleton<ProductsManager>(MockProductsManager());
    GetIt.I.registerSingleton<LangCodeHolder>(LangCodeHolder.inited('ru'));
    GetIt.I.registerSingleton<RouteObserver<ModalRoute>>(MockRouteObserver());

    final permissionsManager = MockPermissionsManager();
    when(permissionsManager.status(any)).thenAnswer((_) async => PermissionState.granted);
    GetIt.I.registerSingleton<PermissionsManager>(permissionsManager);
  });

  testWidgets('card for empty shop', (WidgetTester tester) async {
    final shop = Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmId = '1'
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar'))
      ..backendShop.replace(BackendShop((e) => e
        ..osmId = '1'
        ..productsCount = 0)));
    final context = await tester.superPump(ShopCard(shop: shop));

    expect(find.text(shop.name), findsOneWidget);
    expect(find.text(context.strings.shop_card_no_products_in_shop), findsOneWidget);
    expect(find.text(context.strings.shop_card_there_are_products_in_shop), findsNothing);
    expect(find.text(context.strings.shop_card_open_shop_products), findsNothing);
    expect(find.text(context.strings.shop_card_add_product), findsOneWidget);
  });

  testWidgets('card for not empty shop', (WidgetTester tester) async {
    final shop = Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmId = '1'
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar'))
      ..backendShop.replace(BackendShop((e) => e
        ..osmId = '1'
        ..productsCount = 1)));
    final context = await tester.superPump(ShopCard(shop: shop));

    expect(find.text(shop.name), findsOneWidget);
    expect(find.text(context.strings.shop_card_no_products_in_shop), findsNothing);
    expect(find.text(context.strings.shop_card_there_are_products_in_shop), findsOneWidget);
    expect(find.text(context.strings.shop_card_open_shop_products), findsOneWidget);
    expect(find.text(context.strings.shop_card_add_product), findsNothing);
  });

  testWidgets('open products button click', (WidgetTester tester) async {
    final shop = Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmId = '1'
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar'))
      ..backendShop.replace(BackendShop((e) => e
        ..osmId = '1'
        ..productsCount = 1)));

    final range = ShopProductRange((e) => e.shop.replace(shop));
    when(shopsManager.fetchShopProductRange(any)).thenAnswer((_) async => Ok(range));

    final context = await tester.superPump(ShopCard(shop: shop));

    expect(find.byType(ShopProductRangePage), findsNothing);
    await tester.tap(find.text(context.strings.shop_card_open_shop_products));
    await tester.pumpAndSettle();
    expect(find.byType(ShopProductRangePage), findsOneWidget);
  });

  testWidgets('add product button click', (WidgetTester tester) async {
    final shop = Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmId = '1'
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar'))
      ..backendShop.replace(BackendShop((e) => e
        ..osmId = '1'
        ..productsCount = 0)));

    final range = ShopProductRange((e) => e.shop.replace(shop));
    when(shopsManager.fetchShopProductRange(any)).thenAnswer((_) async => Ok(range));

    final context = await tester.superPump(ShopCard(shop: shop));

    expect(find.byType(BarcodeScanPage), findsNothing);
    await tester.tap(find.text(context.strings.shop_card_add_product));
    await tester.pumpAndSettle();
    expect(find.byType(BarcodeScanPage), findsOneWidget);

    final scanPage = find.byType(BarcodeScanPage).evaluate().first.widget as BarcodeScanPage;
    expect(scanPage.addProductToShop, equals(shop));
  });
}
