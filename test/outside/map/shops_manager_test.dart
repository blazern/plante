import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:test/test.dart';

import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/shops_manager.dart';

import 'shops_manager_test.mocks.dart';

@GenerateMocks([OpenStreetMap, Backend])
void main() {
  late MockOpenStreetMap _osm;
  late MockBackend _backend;
  late ShopsManager _shopsManager;

  setUp(() async {
    _osm = MockOpenStreetMap();
    _backend = MockBackend();
    _shopsManager = ShopsManager(_osm, _backend);
  });

  test('fetchShops good scenario', () async {
    final osmShops = [
      OsmShop((e) => e
        ..osmId = '1'
        ..name = 'shop1'
        ..type = 'supermarket'
        ..longitude = 123
        ..latitude = 321),
      OsmShop((e) => e
        ..osmId = '2'
        ..name = 'shop2'
        ..type = 'convenience'
        ..longitude = 124
        ..latitude = 322),
    ];
    when(_osm.fetchShops(any, any)).thenAnswer((_) async => Ok(osmShops));

    final backendShops = [
      BackendShop((e) => e
        ..osmId = '1'
        ..products = ListBuilder([
          BackendProduct((e) => e.barcode = '123'),
          BackendProduct((e) => e.barcode = '124'),
        ])
        ..productsLastSeenUtc = MapBuilder({})),
      BackendShop((e) => e
        ..osmId = '2'
        ..products = ListBuilder([
          BackendProduct((e) => e.barcode = '123'),
        ])
        ..productsLastSeenUtc = MapBuilder({
          '123': 123456
        })),
    ];
    when(_backend.requestShops(any)).thenAnswer((_) async => Ok(backendShops));

    final expectedShops = [
      Shop((e) => e
        ..osmShop.replace(osmShops[0])
        ..backendShop.replace(backendShops[0])),
      Shop((e) => e
        ..osmShop.replace(osmShops[1])
        ..backendShop.replace(backendShops[1])),
    ];
    
    final shopsRes = await _shopsManager.fetchShops(const Point(0, 0), const Point(1, 1));
    final shops = shopsRes.unwrap();
    expect(shops, equals(expectedShops));
  });

  test('fetchShops osm error', () async {
    when(_osm.fetchShops(any, any)).thenAnswer((_) async =>
        Err(OpenStreetMapError.NETWORK));

    final backendShops = [
      BackendShop((e) => e
        ..osmId = '1'
        ..products = ListBuilder([
          BackendProduct((e) => e.barcode = '123'),
          BackendProduct((e) => e.barcode = '124'),
        ])
        ..productsLastSeenUtc = MapBuilder({}))
    ];
    when(_backend.requestShops(any)).thenAnswer((_) async => Ok(backendShops));

    final shopsRes = await _shopsManager.fetchShops(const Point(0, 0), const Point(1, 1));
    expect(shopsRes.unwrapErr(), equals(ShopsManagerError.NETWORK_ERROR));
  });

  test('fetchShops backend error', () async {
    final osmShops = [
      OsmShop((e) => e
        ..osmId = '1'
        ..name = 'shop1'
        ..type = 'supermarket'
        ..longitude = 123
        ..latitude = 321)
    ];
    when(_osm.fetchShops(any, any)).thenAnswer((_) async => Ok(osmShops));
    when(_backend.requestShops(any)).thenAnswer((_) async => Err(BackendError.other()));

    final shopsRes = await _shopsManager.fetchShops(const Point(0, 0), const Point(1, 1));
    expect(shopsRes.unwrapErr(), equals(ShopsManagerError.OTHER));
  });
}
