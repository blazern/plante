import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:plante/base/date_time_extensions.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/backend/backend_products_at_shop.dart';
import 'package:plante/outside/backend/cmds/product_presence_vote_cmd.dart';
import 'package:plante/outside/backend/cmds/products_at_shops_cmd.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_backend.dart';
import '../../z_fakes/fake_products_obtainer.dart';
import 'shops_manager_test_commons.dart';

void main() {
  late ShopsManagerTestCommons commons;
  late FakeBackend backend;
  late FakeProductsObtainer productsObtainer;
  late ShopsManager shopsManager;
  late FakeAnalytics analytics;

  late Map<OsmUID, Shop> fullShops;

  late List<BackendProduct> rangeBackendProducts;
  late List<Product> rangeProducts;

  late Shop shop;

  setUp(() async {
    commons = await ShopsManagerTestCommons.create();
    fullShops = commons.fullShops;
    rangeProducts = commons.rangeProducts;
    rangeBackendProducts = commons.rangeBackendProducts;

    backend = commons.backend;
    productsObtainer = commons.productsObtainer;
    shopsManager = commons.shopsManager;
    analytics = commons.analytics;

    shop = fullShops.values.first;
    // Set up the range
    final backendProductsAtShops = [
      BackendProductsAtShop((e) => e
        ..osmUID = shop.osmUID
        ..products.addAll(rangeBackendProducts)
        ..productsLastSeenUtc.addAll({
          for (final product in rangeBackendProducts) product.barcode: 123456
        })),
    ];
    backend.setResponse_testing(
        PRODUCTS_AT_SHOPS_CMD, backendProductsAtShops._toJsonResponse());

    // Let's put shop's products to cache by doing a fetch
    await shopsManager.fetchShops(commons.bounds);
    await shopsManager.fetchShopProductRange(shop);
    backend.resetRequests_testing();
  });

  tearDown(() async {
    await commons.dispose();
  });

  test('positive vote changes last seen time to now', () async {
    backend.setResponse_testing(
        PRODUCT_PRESENCE_VOTE_CMD, '{"deleted": false}');

    // Verify old time is old
    final rangeRes1 = await shopsManager.fetchShopProductRange(shop);
    expect(rangeRes1.isOk, isTrue);
    final targetProduct = rangeProducts.first;
    final now = DateTime.now().secondsSinceEpoch;
    const secondsInMinute = 60;
    final oldTime = rangeRes1.unwrap().lastSeenSecs(targetProduct);
    expect((now - oldTime).abs(), greaterThan(secondsInMinute));

    // Vote!
    final voteResult =
        await shopsManager.productPresenceVote(targetProduct, shop, true);
    expect(voteResult.isOk, isTrue);
    expect(voteResult.unwrap().productDeleted, isFalse);

    // Let's verify voting time change
    final rangeRes2 = await shopsManager.fetchShopProductRange(shop);
    expect(rangeRes2.isOk, isTrue);
    final newTime = rangeRes2.unwrap().lastSeenSecs(targetProduct);
    expect(newTime, isNot(equals(oldTime)));
    expect((now - newTime).abs(), lessThan(secondsInMinute));
  });

  test('positive vote does not changes last seen time on errors', () async {
    backend.setResponse_testing(PRODUCT_PRESENCE_VOTE_CMD, '',
        responseCode: 500);

    // Memorize old time
    final rangeRes1 = await shopsManager.fetchShopProductRange(shop);
    final targetProduct = rangeProducts.first;
    final oldSeenTime = rangeRes1.unwrap().lastSeenSecs(targetProduct);

    // Vote!
    final voteResult =
        await shopsManager.productPresenceVote(targetProduct, shop, true);
    expect(voteResult.isErr, isTrue);

    // Let's verify voting time DIDN'T change
    final rangeRes2 = await shopsManager.fetchShopProductRange(shop);
    final newSeenTime = rangeRes2.unwrap().lastSeenSecs(targetProduct);
    expect(newSeenTime, equals(oldSeenTime));
  });

  test('positive vote adds a product to the shop if it was not there',
      () async {
    const newBarcode = '1234567';
    expect(newBarcode,
        isNot(contains(rangeBackendProducts.map((e) => e.barcode))));
    expect(newBarcode, isNot(contains(rangeProducts.map((e) => e.barcode))));
    final newProduct = Product((e) => e.barcode = newBarcode);
    productsObtainer.addKnownProduct(newProduct);

    // Verify the product is not there initially
    final rangeRes1 = await shopsManager.fetchShopProductRange(shop);
    expect(rangeRes1.unwrap().products, isNot(contains(newProduct)));
    final shopsRes1 = await shopsManager.fetchShops(commons.bounds);
    final initialProductsCount = shopsRes1.unwrap()[shop.osmUID]!.productsCount;

    // Vote!
    backend.setResponse_testing(
        PRODUCT_PRESENCE_VOTE_CMD, '{"deleted": false}');
    final voteResult =
        await shopsManager.productPresenceVote(newProduct, shop, true);
    expect(voteResult.isOk, isTrue);
    expect(voteResult.unwrap().productDeleted, isFalse);

    // Verify the product now is there
    final rangeRes2 = await shopsManager.fetchShopProductRange(shop);
    expect(rangeRes2.unwrap().products, contains(newProduct));
    final shopsRes2 = await shopsManager.fetchShops(commons.bounds);
    final finalProductsCount = shopsRes2.unwrap()[shop.osmUID]!.productsCount;
    expect(finalProductsCount, equals(initialProductsCount + 1));
  });

  test('positive vote does not add a product to the shop on backend errors',
      () async {
    const newBarcode = '1234567';
    expect(newBarcode,
        isNot(contains(rangeBackendProducts.map((e) => e.barcode))));
    expect(newBarcode, isNot(contains(rangeProducts.map((e) => e.barcode))));
    final newProduct = Product((e) => e.barcode = newBarcode);
    productsObtainer.addKnownProduct(newProduct);

    // Verify the product is not there initially
    final rangeRes1 = await shopsManager.fetchShopProductRange(shop);
    expect(rangeRes1.unwrap().products, isNot(contains(newProduct)));
    final shopsRes1 = await shopsManager.fetchShops(commons.bounds);
    final initialProductsCount = shopsRes1.unwrap()[shop.osmUID]!.productsCount;

    // Vote!
    backend.setResponse_testing(PRODUCT_PRESENCE_VOTE_CMD, '',
        responseCode: 500);
    final voteResult =
        await shopsManager.productPresenceVote(newProduct, shop, true);
    expect(voteResult.isErr, isTrue);

    // Verify the product is still not there
    final rangeRes2 = await shopsManager.fetchShopProductRange(shop);
    expect(rangeRes2.unwrap().products, equals(rangeRes1.unwrap().products));
    final shopsRes2 = await shopsManager.fetchShops(commons.bounds);
    final finalProductsCount = shopsRes2.unwrap()[shop.osmUID]!.productsCount;
    expect(finalProductsCount, equals(initialProductsCount));
  });

  test('positive vote adds a barcode to cache if it was not there before',
      () async {
    backend.setResponse_testing(
        PRODUCT_PRESENCE_VOTE_CMD, '{"deleted": false}');

    final shopsRes = await shopsManager.fetchShops(commons.bounds);
    final uid = shopsRes.unwrap().values.first.osmUID;
    final newProduct = Product((e) => e.barcode = '777');

    expect(shopsManager.getBarcodesCacheFor1(uid),
        isNot(contains(newProduct.barcode)));

    // Vote!
    final voteResult =
        await shopsManager.productPresenceVote(newProduct, shop, true);
    expect(voteResult.isOk, isTrue);

    expect(await shopsManager.getBarcodesCacheFor1(uid),
        contains(newProduct.barcode));
  });

  test('positive vote does not add a barcode to cache if it is there already',
      () async {
    backend.setResponse_testing(
        PRODUCT_PRESENCE_VOTE_CMD, '{"deleted": false}');

    final shopsRes = await shopsManager.fetchShops(commons.bounds);
    final uid = shopsRes.unwrap().values.first.osmUID;

    expect(await shopsManager.getBarcodesCacheFor1(uid),
        equals(rangeProducts.map((e) => e.barcode).toList()));

    // Vote!
    final voteResult =
        await shopsManager.productPresenceVote(rangeProducts.first, shop, true);
    expect(voteResult.isOk, isTrue);

    // Same barcode as before
    expect(await shopsManager.getBarcodesCacheFor1(uid),
        equals(rangeProducts.map((e) => e.barcode).toList()));
  });

  test('negative vote deletes a product from a shop if backend says so',
      () async {
    final targetProduct = rangeProducts[0];
    // Verify the product is there initially
    final rangeRes1 = await shopsManager.fetchShopProductRange(shop);
    expect(rangeRes1.unwrap().products, contains(targetProduct));
    final shopsRes1 = await shopsManager.fetchShops(commons.bounds);
    final initialProductsCount = shopsRes1.unwrap()[shop.osmUID]!.productsCount;

    // Vote!
    backend.setResponse_testing(PRODUCT_PRESENCE_VOTE_CMD, '{"deleted": true}');
    final voteResult =
        await shopsManager.productPresenceVote(targetProduct, shop, false);
    expect(voteResult.isOk, isTrue);
    expect(voteResult.unwrap().productDeleted, isTrue);

    // Let's verify the product is not there anymore
    final rangeRes2 = await shopsManager.fetchShopProductRange(shop);
    expect(rangeRes2.unwrap().products, isNot(contains(targetProduct)));
    final shopsRes2 = await shopsManager.fetchShops(commons.bounds);
    final finalProductsCount = shopsRes2.unwrap()[shop.osmUID]!.productsCount;
    expect(finalProductsCount, equals(initialProductsCount - 1));
  });

  test(
      'negative vote does not delete a product from a shop if backend does not',
      () async {
    final targetProduct = rangeProducts[0];
    // Verify the product is there initially
    final rangeRes1 = await shopsManager.fetchShopProductRange(shop);
    expect(rangeRes1.unwrap().products, contains(targetProduct));
    final shopsRes1 = await shopsManager.fetchShops(commons.bounds);
    final initialProductsCount = shopsRes1.unwrap()[shop.osmUID]!.productsCount;

    // Vote!
    backend.setResponse_testing(
        PRODUCT_PRESENCE_VOTE_CMD, '{"deleted": false}');
    final voteResult =
        await shopsManager.productPresenceVote(targetProduct, shop, false);
    expect(voteResult.isOk, isTrue);
    expect(voteResult.unwrap().productDeleted, isFalse);

    // Let's verify the product is still there
    final rangeRes2 = await shopsManager.fetchShopProductRange(shop);
    expect(rangeRes2.unwrap().products, equals(rangeRes1.unwrap().products));
    final shopsRes2 = await shopsManager.fetchShops(commons.bounds);
    final finalProductsCount = shopsRes2.unwrap()[shop.osmUID]!.productsCount;
    expect(finalProductsCount, equals(initialProductsCount));
  });

  test('negative vote does not delete a product from a shop on backend errors',
      () async {
    final targetProduct = rangeProducts[0];
    // Verify the product is there initially
    final rangeRes1 = await shopsManager.fetchShopProductRange(shop);
    expect(rangeRes1.unwrap().products, contains(targetProduct));
    final shopsRes1 = await shopsManager.fetchShops(commons.bounds);
    final initialProductsCount = shopsRes1.unwrap()[shop.osmUID]!.productsCount;

    // Vote!
    backend.setResponse_testing(PRODUCT_PRESENCE_VOTE_CMD, '',
        responseCode: 500);
    final voteResult =
        await shopsManager.productPresenceVote(targetProduct, shop, false);
    expect(voteResult.isErr, isTrue);

    // Let's verify the product is still there
    final rangeRes2 = await shopsManager.fetchShopProductRange(shop);
    expect(rangeRes2.unwrap().products, equals(rangeRes1.unwrap().products));
    final shopsRes2 = await shopsManager.fetchShops(commons.bounds);
    final finalProductsCount = shopsRes2.unwrap()[shop.osmUID]!.productsCount;
    expect(finalProductsCount, equals(initialProductsCount));
  });

  test('negative vote removes a barcode from cache if backend did same',
      () async {
    backend.setResponse_testing(PRODUCT_PRESENCE_VOTE_CMD, '{"deleted": true}');

    final shopsRes = await shopsManager.fetchShops(commons.bounds);
    final uid = shopsRes.unwrap().values.first.osmUID;

    final expectedBarcodes = rangeProducts.map((e) => e.barcode).toList();
    expect(
        await shopsManager.getBarcodesCacheFor1(uid), equals(expectedBarcodes));

    // Vote!
    final voteResult = await shopsManager.productPresenceVote(
        rangeProducts.first, shop, false);
    expect(voteResult.isOk, isTrue);

    // The barcode expected to be deleted
    expectedBarcodes.removeAt(0);
    expect(
        await shopsManager.getBarcodesCacheFor1(uid), equals(expectedBarcodes));
  });

  test('negative vote does not remove a barcode from cache if backend did not',
      () async {
    backend.setResponse_testing(
        PRODUCT_PRESENCE_VOTE_CMD, '{"deleted": false}');

    final shopsRes = await shopsManager.fetchShops(commons.bounds);
    final uid = shopsRes.unwrap().values.first.osmUID;

    final expectedBarcodes = rangeProducts.map((e) => e.barcode).toList();
    expect(
        await shopsManager.getBarcodesCacheFor1(uid), equals(expectedBarcodes));

    // Vote!
    final voteResult = await shopsManager.productPresenceVote(
        rangeProducts.first, shop, false);
    expect(voteResult.isOk, isTrue);

    // The barcode expected to be still there
    expect(
        await shopsManager.getBarcodesCacheFor1(uid), equals(expectedBarcodes));
  });

  test('votes notify listeners', () async {
    final listener = MockShopsManagerListener();
    shopsManager.addListener(listener);

    backend.setResponse_testing(
        PRODUCT_PRESENCE_VOTE_CMD, '{"deleted": false}');

    final targetProduct = rangeProducts[0];

    // Vote!
    var voteResult =
        await shopsManager.productPresenceVote(targetProduct, shop, true);
    expect(voteResult.isOk, isTrue);

    verify(listener.onLocalShopsChange());
    clearInteractions(listener);

    // Vote again, this time against!
    voteResult =
        await shopsManager.productPresenceVote(targetProduct, shop, false);
    expect(voteResult.isOk, isTrue);
    // Observer is not expected to be notified because the
    // product was not deleted by the negative vote
    // and negative votes don't change the last-seen time
    verifyZeroInteractions(listener);

    // Vote against, once more!
    backend.setResponse_testing(PRODUCT_PRESENCE_VOTE_CMD, '{"deleted": true}');
    voteResult =
        await shopsManager.productPresenceVote(targetProduct, shop, false);
    expect(voteResult.isOk, isTrue);
    verify(listener.onLocalShopsChange());
  });

  test('vote analytics events', () async {
    backend.setResponse_testing(
        PRODUCT_PRESENCE_VOTE_CMD, '{"deleted": false}');

    expect(analytics.allEvents(), equals([]));

    final targetProduct = rangeProducts.first;
    await shopsManager.productPresenceVote(targetProduct, shop, true);
    expect(analytics.allEvents().length, equals(1));
    expect(
        analytics.firstSentEvent('product_presence_vote').second,
        equals({
          'barcode': targetProduct.barcode,
          'shop': shop.osmUID.toString(),
          'vote': true
        }));
    analytics.clearEvents();

    await shopsManager.productPresenceVote(targetProduct, shop, false);
    expect(analytics.allEvents().length, equals(1));
    expect(
        analytics.firstSentEvent('product_presence_vote').second,
        equals({
          'barcode': targetProduct.barcode,
          'shop': shop.osmUID.toString(),
          'vote': false
        }));
  });
}

extension on ShopsManager {
  Future<List<String>?> getBarcodesCacheFor1(OsmUID uid) async {
    return (await getBarcodesCacheFor([uid]))[uid];
  }
}

extension _ListProdutcsAtShop on List<BackendProductsAtShop> {
  String _toJsonResponse() {
    final map = {
      for (final value in this) value.osmUID.toString(): value.toJson()
    };
    return jsonEncode({PRODUCTS_AT_SHOPS_CMD_RESULT_FIELD: map});
  }
}
