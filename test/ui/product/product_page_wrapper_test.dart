import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/model/location_controller.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/model/viewed_products_storage.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/ui/photos_taker.dart';
import 'package:plante/ui/product/display_product_page.dart';
import 'package:plante/ui/product/init_product_page.dart';
import 'package:plante/ui/product/product_page_wrapper.dart';

import '../../fake_user_params_controller.dart';
import '../../widget_tester_extension.dart';
import 'product_page_wrapper_test.mocks.dart';

@GenerateMocks([ProductsManager, ShopsManager, LocationController, PhotosTaker])
void main() {
  setUp(() async {
    await GetIt.I.reset();

    final userParamsController = FakeUserParamsController();
    final user = UserParams((v) => v
      ..backendClientToken = '123'
      ..backendId = '321'
      ..name = 'Bob'
      ..eatsEggs = false
      ..eatsMilk = false
      ..eatsHoney = false);
    await userParamsController.setUserParams(user);
    GetIt.I.registerSingleton<UserParamsController>(userParamsController);
    GetIt.I.registerSingleton<ViewedProductsStorage>(ViewedProductsStorage(loadPersistentProducts: false));
    GetIt.I.registerSingleton<ShopsManager>(MockShopsManager());
    final locationController = MockLocationController();
    when(locationController.lastKnownPositionInstant()).thenReturn(null);
    GetIt.I.registerSingleton<LocationController>(locationController);

    final photosTaker = MockPhotosTaker();
    GetIt.I.registerSingleton<PhotosTaker>(photosTaker);
    when(photosTaker.retrieveLostPhoto()).thenAnswer((realInvocation) async => null);
  });

  testWidgets('init page is shown when product is not filled', (WidgetTester tester) async {
    GetIt.I.registerSingleton<ProductsManager>(MockProductsManager());
    final initialProduct = Product((v) => v.barcode = '123');
    await tester.superPump(ProductPageWrapper.createForTesting(initialProduct));
    expect(find.byType(InitProductPage), findsOneWidget);
    expect(find.byType(DisplayProductPage), findsNothing);
  });

  testWidgets('init page is not shown when product is filled', (WidgetTester tester) async {
    GetIt.I.registerSingleton<ProductsManager>(MockProductsManager());
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..name = 'name'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.community
      ..ingredientsText = '1, 2, 3'
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path));
    await tester.superPump(ProductPageWrapper.createForTesting(initialProduct));
    expect(find.byType(InitProductPage), findsNothing);
    expect(find.byType(DisplayProductPage), findsOneWidget);
  });

  testWidgets('init page is not shown when product is filled but lacks ingredients text', (WidgetTester tester) async {
    GetIt.I.registerSingleton<ProductsManager>(MockProductsManager());
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..name = 'name'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.community
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.community
      ..ingredientsText = null // !!!!!!!!
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path));
    await tester.superPump(ProductPageWrapper.createForTesting(initialProduct));
    expect(find.byType(InitProductPage), findsNothing);
    expect(find.byType(DisplayProductPage), findsOneWidget);
  });

  testWidgets('init_product_page is not shown when '
              'veg-statuses are filled by OFF', (WidgetTester tester) async {
    GetIt.I.registerSingleton<ProductsManager>(MockProductsManager());
    final initialProduct = Product((v) => v
      ..barcode = '123'
      ..name = 'name'
      ..vegetarianStatus = VegStatus.positive
      ..vegetarianStatusSource = VegStatusSource.open_food_facts // OFF!
      ..veganStatus = VegStatus.negative
      ..veganStatusSource = VegStatusSource.open_food_facts // OFF!
      ..ingredientsText = '1, 2, 3'
      ..imageIngredients = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path));
    await tester.superPump(ProductPageWrapper.createForTesting(initialProduct));
    expect(find.byType(InitProductPage), findsNothing);
    expect(find.byType(DisplayProductPage), findsOneWidget);
  });
}
