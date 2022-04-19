import 'package:plante/base/base.dart';
import 'package:plante/base/coord_utils.dart';
import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/outside/map/osm/open_street_map.dart';
import 'package:plante/outside/map/osm/osm_cached_territory.dart';
import 'package:plante/outside/map/osm/osm_overpass.dart';
import 'package:plante/outside/map/osm/osm_road.dart';
import 'package:plante/outside/map/osm/osm_territory_cacher.dart';

enum RoadsManagerError {
  NETWORK,
  OTHER,
}

class RoadsManager {
  // Let's assume new roads don't appear often.
  static const DAYS_BEFORE_CACHE_ANCIENT = 365;
  // Let's not overload the DB with too many roads.
  // And since cities have A LOT of roads in them, let the limit be small.
  static const CACHED_TERRITORIES_LIMIT = 2;
  static const REQUESTED_RADIUS_KM = 30.0;
  static final requestedRadios = kmToGrad(REQUESTED_RADIUS_KM);

  final OpenStreetMap _osm;
  final OsmTerritoryCacher _cacher;

  RoadsManager(this._osm, this._cacher);

  /// Fetches roads within the given bounds and nearby them if available.
  /// Given bounds must have sides smaller than [REQUESTED_RADIUS_KM].
  Future<Result<List<OsmRoad>, RoadsManagerError>> fetchRoadsWithinAndNearby(
      CoordsBounds bounds) async {
    if (bounds.width > requestedRadios || bounds.height > requestedRadios) {
      Log.e(
          'fetchRoadsWithinAndNearby: bounds $bounds are bigger than $requestedRadios');
    }

    final existingCache = await _fetchCachedRoads(bounds);
    if (existingCache != null) {
      return Ok(existingCache);
    }
    return _osm.withOverpass(
        (overpass) async => await _fetchRoadsImpl(overpass, bounds));
  }

  Future<List<OsmRoad>?> _fetchCachedRoads(CoordsBounds bounds) async {
    final territories = (await _cacher.getCachedRoads()).toList();
    territories.sort((lhs, rhs) =>
        rhs.whenObtained.millisecondsSinceEpoch -
        lhs.whenObtained.millisecondsSinceEpoch);
    _deleteExtras(territories);

    for (final territory in territories) {
      if (territory.bounds.containsBounds(bounds)) {
        Log.i('OSM roads from cache are used');
        return territory.entities;
      }
    }
    return null;
  }

  void _deleteExtras(List<OsmCachedTerritory<OsmRoad>> territories) {
    final deleted = <OsmCachedTerritory<OsmRoad>>{};

    for (var index = CACHED_TERRITORIES_LIMIT;
        index < territories.length;
        ++index) {
      final territory = territories[index];
      unawaited(_cacher.deleteCachedTerritory(territory.id));
      deleted.add(territory);
    }

    for (final territory in territories) {
      if (DAYS_BEFORE_CACHE_ANCIENT <
          DateTime.now().difference(territory.whenObtained).inDays) {
        unawaited(_cacher.deleteCachedTerritory(territory.id));
        deleted.add(territory);
      }
    }

    territories.removeWhere(deleted.contains);
    if (deleted.isNotEmpty) {
      Log.i('OSM extra roads are deleted');
    }
  }

  Future<Result<List<OsmRoad>, RoadsManagerError>> _fetchRoadsImpl(
      OsmOverpass overpass, CoordsBounds bounds) async {
    final existingCache = await _fetchCachedRoads(bounds);
    if (existingCache != null) {
      return Ok(existingCache);
    }

    final requestedBounds = bounds.center.makeSquare(requestedRadios);
    final result = await overpass.fetchRoads(requestedBounds);
    if (result.isOk) {
      final roads = result.unwrap();
      unawaited(_cacher.cacheRoads(DateTime.now(), requestedBounds, roads));
      return Ok(roads);
    } else {
      return Err(_convertOsmErr(result.unwrapErr()));
    }
  }
}

RoadsManagerError _convertOsmErr(OpenStreetMapError error) {
  switch (error) {
    case OpenStreetMapError.NETWORK:
      return RoadsManagerError.NETWORK;
    case OpenStreetMapError.OTHER:
      return RoadsManagerError.OTHER;
  }
}
