import 'dart:convert';

import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/backend/cmds/create_shop_cmd.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager_backend_worker.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_backend.dart';
import 'shops_manager_backend_worker_test_commons.dart';

void main() {
  late ShopsManagerBackendWorkerTestCommons commons;
  late FakeBackend backend;
  late MockProductsObtainer productsObtainer;
  late ShopsManagerBackendWorker shopsManagerBackendWorker;

  setUp(() async {
    commons = ShopsManagerBackendWorkerTestCommons();
    backend = commons.backend;
    productsObtainer = commons.productsObtainer;
    shopsManagerBackendWorker =
        ShopsManagerBackendWorker(backend, productsObtainer);
  });

  test('createShop good scenario', () async {
    backend.setResponse_testing(CREATE_SHOP_CMD,
        jsonEncode({'osm_uid': OsmUID.parse('1:123456').toString()}));

    final result = await shopsManagerBackendWorker.createShop(
        name: 'Horns and Hooves',
        coord: Coord(lat: 20, lon: 10),
        type: ShopType.supermarket);
    expect(result.isOk, isTrue);

    final expectedResult = Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:123456')
        ..longitude = 10
        ..latitude = 20
        ..name = 'Horns and Hooves'
        ..type = ShopType.supermarket.osmName))
      ..backendShop.replace(BackendShop((e) => e
        ..osmUID = OsmUID.parse('1:123456')
        ..productsCount = 0)));
    expect(result.unwrap(), equals(expectedResult));
  });

  test('createShop error', () async {
    backend.setResponse_testing(CREATE_SHOP_CMD, '', responseCode: 500);

    final result = await shopsManagerBackendWorker.createShop(
        name: 'Horns and Hooves',
        coord: Coord(lat: 20, lon: 10),
        type: ShopType.supermarket);
    // Expecting an error
    expect(result.unwrapErr(), equals(ShopsManagerError.OTHER));
  });
}
