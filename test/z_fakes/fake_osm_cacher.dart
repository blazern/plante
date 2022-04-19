import 'package:plante/base/result.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/outside/map/osm/osm_cached_territory.dart';
import 'package:plante/outside/map/osm/osm_road.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_territory_cacher.dart';
import 'package:sqflite_common/sqlite_api.dart';

class FakeOsmCacher implements OsmTerritoryCacher {
  var _lastId = 0;
  final _cachedShops = <OsmCachedTerritory<OsmShop>>[];
  final _cachedRoads = <OsmCachedTerritory<OsmRoad>>[];

  Future<List<OsmShop>> getAllOsmShopsForTests() async {
    final result = <OsmShop>[];
    for (final territory in await getCachedShops()) {
      result.addAll(territory.entities);
    }
    return result;
  }

  @override
  Future<Database> get dbForTesting => throw UnimplementedError();

  @override
  Future<String> dbFilePath() {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteDatabase() {
    throw UnimplementedError();
  }

  @override
  Future<OsmCachedTerritory<OsmShop>> cacheShops(DateTime whenObtained,
      CoordsBounds bounds, Iterable<OsmShop> shops) async {
    final shopsCopy = shops.toList();
    final result =
        OsmCachedTerritory(++_lastId, whenObtained, bounds, shopsCopy);
    _cachedShops.add(result);
    return result;
  }

  @override
  Future<void> deleteCachedTerritory(int territoryId) {
    _cachedShops.removeWhere((e) => e.id == territoryId);
    _cachedRoads.removeWhere((e) => e.id == territoryId);
    return Future.value();
  }

  @override
  Future<List<OsmCachedTerritory<OsmShop>>> getCachedShops() async {
    return _cachedShops.toList(growable: false);
  }

  @override
  Future<Result<OsmCachedTerritory<OsmShop>, OsmCacherError>> addShopToCache(
      int territoryId, OsmShop shop) async {
    final territories = _cachedShops.where((e) => e.id == territoryId);
    if (territories.isEmpty) {
      return Err(OsmCacherError.TERRITORY_NOT_FOUND);
    }
    var territory = territories.first;
    _cachedShops.remove(territory);
    territory = territory.add(shop);
    _cachedShops.add(territory);
    return Ok(territory);
  }

  @override
  Future<OsmCachedTerritory<OsmRoad>> cacheRoads(
      DateTime whenObtained, CoordsBounds bounds, List<OsmRoad> roads) async {
    final result = OsmCachedTerritory(++_lastId, whenObtained, bounds, roads);
    _cachedRoads.add(result);
    return result;
  }

  @override
  Future<List<OsmCachedTerritory<OsmRoad>>> getCachedRoads() async {
    return _cachedRoads.toList(growable: false);
  }

  @override
  Future<Result<OsmCachedTerritory<OsmRoad>, OsmCacherError>> addRoadToCache(
      int territoryId, OsmRoad road) async {
    final territories = _cachedRoads.where((e) => e.id == territoryId);
    if (territories.isEmpty) {
      return Err(OsmCacherError.TERRITORY_NOT_FOUND);
    }
    var territory = territories.first;
    _cachedRoads.remove(territory);
    territory = territory.add(road);
    _cachedRoads.add(territory);
    return Ok(territory);
  }
}
