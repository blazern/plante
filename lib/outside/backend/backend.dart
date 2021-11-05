import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:plante/base/device_info.dart';
import 'package:plante/base/result.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/gender.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/backend/backend_products_at_shop.dart';
import 'package:plante/outside/backend/backend_response.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/backend/fake_backend.dart';
import 'package:plante/outside/backend/mobile_app_config.dart';
import 'package:plante/outside/backend/product_presence_vote_result.dart';
import 'package:plante/outside/backend/requested_products_result.dart';
import 'package:plante/outside/http_client.dart';
import 'package:plante/outside/map/osm_uid.dart';

const BACKEND_ADDRESS = 'planteapp.com';
const _LOCAL_BACKEND_ADDRESS = 'localhost:8080';
const _CONNECT_TO_LOCAL_SERVER = kIsWeb && kDebugMode;

const PREF_BACKEND_CLIENT_TOKEN = 'BACKEND_CLIENT_TOKEN';

class BackendObserver {
  void onBackendError(BackendError error) {}
}

class Backend {
  late final Backend _fakeBackend;
  final Analytics _analytics;
  final UserParamsController _userParamsController;
  final HttpClient _http;
  final Settings _settings;

  final _observers = <BackendObserver>[];

  Backend(
      this._analytics, this._userParamsController, this._http, this._settings) {
    _fakeBackend = FakeBackend(_settings);
  }

  void addObserver(BackendObserver observer) => _observers.add(observer);
  void removeObserver(BackendObserver observer) => _observers.remove(observer);

  Future<bool> isLoggedIn() async {
    if (await _settings.testingBackends()) {
      return await _fakeBackend.isLoggedIn();
    }
    final userParams = await _userParamsController.getUserParams();
    return userParams?.backendClientToken != null;
  }

  Future<Result<UserParams, BackendError>> loginOrRegister(
      {String? googleIdToken, String? appleAuthorizationCode}) async {
    if (await _settings.testingBackends()) {
      return await _fakeBackend.loginOrRegister(
          googleIdToken: googleIdToken,
          appleAuthorizationCode: appleAuthorizationCode);
    }

    if (await isLoggedIn()) {
      final userParams = await _userParamsController.getUserParams();
      return Ok(userParams!);
    }

    final deviceId = (await DeviceInfo.get()).deviceID;
    final queryParams = {
      'deviceId': deviceId,
    };
    if (googleIdToken != null) {
      queryParams['googleIdToken'] = googleIdToken;
    }
    if (appleAuthorizationCode != null) {
      queryParams['appleAuthorizationCode'] = appleAuthorizationCode;
    }
    final jsonRes =
        await _backendGetJson('login_or_register_user/', queryParams);
    if (jsonRes.isOk) {
      final userParams = UserParams.fromJson(jsonRes.unwrap())!;
      Log.i('Backend: user logged in or registered: ${userParams.toString()}');
      return Ok(userParams);
    } else {
      return Err(jsonRes.unwrapErr());
    }
  }

  Future<Result<bool, BackendError>> updateUserParams(UserParams userParams,
      {String? backendClientTokenOverride}) async {
    if (await _settings.testingBackends()) {
      return await _fakeBackend.updateUserParams(userParams,
          backendClientTokenOverride: backendClientTokenOverride);
    }

    final params = <String, dynamic>{};
    if (userParams.name != null && userParams.name!.isNotEmpty) {
      params['name'] = userParams.name;
    }
    if (userParams.gender != null) {
      params['gender'] = userParams.gender!.name;
    }
    if (userParams.birthday != null) {
      params['birthday'] = userParams.birthdayStr;
    }
    if (userParams.eatsMilk != null) {
      params['eatsMilk'] = userParams.eatsMilk!.toString();
    }
    if (userParams.eatsEggs != null) {
      params['eatsEggs'] = userParams.eatsEggs!.toString();
    }
    if (userParams.eatsHoney != null) {
      params['eatsHoney'] = userParams.eatsHoney!.toString();
    }
    if (userParams.langsPrioritized != null &&
        userParams.langsPrioritized!.isNotEmpty) {
      params['langsPrioritized'] = userParams.langsPrioritized;
    }
    if (params.isEmpty) {
      return Ok(false);
    }

    final response = await _backendGet('update_user_data/', params,
        backendClientTokenOverride: backendClientTokenOverride);
    if (response.isOk) {
      return Ok(true);
    } else {
      return Err(_errFromResp(response));
    }
  }

  Future<Result<RequestedProductsResult, BackendError>> requestProducts(
      List<String> barcodes, int page) async {
    if (await _settings.testingBackends()) {
      return await _fakeBackend.requestProducts(barcodes, page);
    }

    final jsonRes = await _backendGetJson(
        'products_data/', {'barcodes': barcodes, 'page': '$page'});
    if (jsonRes.isErr) {
      return Err(jsonRes.unwrapErr());
    }
    final json = jsonRes.unwrap();
    if (!json.containsKey('products') || !json.containsKey('last_page')) {
      Log.w('Invalid product_data response: $json');
      return Err(BackendError.invalidDecodedJson(json));
    }

    final result = <BackendProduct>[];
    final productsJson = json['products'] as List<dynamic>;
    for (final productJson in productsJson) {
      final product =
          BackendProduct.fromJson(productJson as Map<String, dynamic>);
      if (product == null) {
        Log.w('Product could not pe parsed: $productJson');
        continue;
      }
      result.add(product);
    }
    return Ok(RequestedProductsResult(result, page, json['last_page'] as bool));
  }

  Future<Result<None, BackendError>> createUpdateProduct(String barcode,
      {VegStatus? vegetarianStatus,
      VegStatus? veganStatus,
      List<LangCode>? changedLangs}) async {
    if (await _settings.testingBackends()) {
      return await _fakeBackend.createUpdateProduct(barcode,
          vegetarianStatus: vegetarianStatus, veganStatus: veganStatus);
    }

    final params = <String, dynamic>{};
    params['barcode'] = barcode;
    if (vegetarianStatus != null) {
      params['vegetarianStatus'] = vegetarianStatus.name;
    }
    if (veganStatus != null) {
      params['veganStatus'] = veganStatus.name;
    }
    if (changedLangs != null && changedLangs.isNotEmpty) {
      params['langs'] = changedLangs.map((e) => e.name).toList();
    }
    final response = await _backendGet('create_update_product/', params);
    return _noneOrErrorFrom(response);
  }

  Future<Result<None, BackendError>> sendReport(
      String barcode, String reportText) async {
    _analytics
        .sendEvent('report_sent', {'barcode': barcode, 'report': reportText});
    if (await _settings.testingBackends()) {
      return await _fakeBackend.sendReport(barcode, reportText);
    }

    final params = <String, String>{};
    params['barcode'] = barcode;
    params['text'] = reportText;
    final response = await _backendGet('make_report/', params);
    return _noneOrErrorFrom(response);
  }

  Future<Result<None, BackendError>> sendProductScan(String barcode) async {
    if (await _settings.testingBackends()) {
      return await _fakeBackend.sendProductScan(barcode);
    }

    final params = <String, String>{};
    params['barcode'] = barcode;
    final response = await _backendGet('product_scan/', params);
    return _noneOrErrorFrom(response);
  }

  Future<Result<MobileAppConfig, BackendError>> mobileAppConfig() async {
    if (await _settings.testingBackends()) {
      return await _fakeBackend.mobileAppConfig();
    }
    final jsonRes = await _backendGetJson('mobile_app_config/', {});
    if (jsonRes.isErr) {
      return Err(jsonRes.unwrapErr());
    }
    final json = jsonRes.unwrap();
    return Ok(MobileAppConfig.fromJson(json)!);
  }

  Future<Result<List<BackendProductsAtShop>, BackendError>>
      requestProductsAtShops(Iterable<OsmUID> osmUIDs) async {
    if (await _settings.testingBackends()) {
      return await _fakeBackend.requestProductsAtShops(osmUIDs);
    }

    final jsonRes = await _backendGetJson('products_at_shops_data/',
        {'osmShopsUIDs': osmUIDs.map((e) => e.toString())});
    if (jsonRes.isErr) {
      return Err(jsonRes.unwrapErr());
    }
    final json = jsonRes.unwrap();

    if (!json.containsKey('results_v2')) {
      Log.w('Invalid products_at_shops_data response: $json');
      return Err(BackendError.invalidDecodedJson(json));
    }

    final results = json['results_v2'] as Map<String, dynamic>;
    final productsAtShops = <BackendProductsAtShop>[];
    for (final result in results.values) {
      final productsAtShop =
          BackendProductsAtShop.fromJson(result as Map<String, dynamic>);
      if (productsAtShop != null) {
        productsAtShops.add(productsAtShop);
      }
    }
    return Ok(productsAtShops);
  }

  Future<Result<List<BackendShop>, BackendError>> requestShopsByOsmUIDs(
      Iterable<OsmUID> osmUIDs) async {
    if (await _settings.testingBackends()) {
      return await _fakeBackend.requestShopsByOsmUIDs(osmUIDs);
    }

    final jsonRes = await _backendGetJson('shops_data/', {},
        body:
            jsonEncode({'osm_uids': osmUIDs.map((e) => e.toString()).toList()}),
        contentType: 'application/json');
    if (jsonRes.isErr) {
      return Err(jsonRes.unwrapErr());
    }
    final json = jsonRes.unwrap();

    if (!json.containsKey('results_v2')) {
      Log.w('Invalid shops_data response: $json');
      return Err(BackendError.invalidDecodedJson(json));
    }

    final results = json['results_v2'] as Map<String, dynamic>;
    final shops = <BackendShop>[];
    for (final result in results.values) {
      final shop = BackendShop.fromJson(result as Map<String, dynamic>);
      if (shop != null) {
        shops.add(shop);
      }
    }
    return Ok(shops);
  }

  Future<Result<List<BackendShop>, BackendError>> requestShopsWithin(
      CoordsBounds bounds) async {
    if (await _settings.testingBackends()) {
      return await _fakeBackend.requestShopsWithin(bounds);
    }

    final jsonRes = await _backendGetJson('/shops_in_bounds_data/', {
      'north': '${bounds.north}',
      'south': '${bounds.south}',
      'west': '${bounds.west}',
      'east': '${bounds.east}',
    });
    if (jsonRes.isErr) {
      return Err(jsonRes.unwrapErr());
    }
    final json = jsonRes.unwrap();

    if (!json.containsKey('results')) {
      Log.w('Invalid shops_in_bounds_data response: $json');
      return Err(BackendError.invalidDecodedJson(json));
    }

    final results = json['results'] as Map<String, dynamic>;
    final shops = <BackendShop>[];
    for (final result in results.values) {
      final shop = BackendShop.fromJson(result as Map<String, dynamic>);
      if (shop != null) {
        shops.add(shop);
      }
    }
    return Ok(shops);
  }

  Future<Result<ProductPresenceVoteResult, BackendError>> productPresenceVote(
      String barcode, OsmUID osmUID, bool positive) async {
    _analytics.sendEvent('product_presence_vote',
        {'barcode': barcode, 'shop': osmUID.toString(), 'vote': positive});
    if (await _settings.testingBackends()) {
      return await _fakeBackend.productPresenceVote(barcode, osmUID, positive);
    }

    final response = await _backendGetJson('product_presence_vote/', {
      'barcode': barcode,
      'shopOsmUID': osmUID.toString(),
      'voteVal': positive ? '1' : '0',
    });
    if (response.isErr) {
      return Err(response.unwrapErr());
    }
    final json = response.unwrap();
    final deleted = json['deleted'] as bool?;
    return Ok(ProductPresenceVoteResult(productDeleted: deleted ?? false));
  }

  Future<Result<None, BackendError>> putProductToShop(
      String barcode, Shop shop) async {
    if (await _settings.testingBackends()) {
      return await _fakeBackend.putProductToShop(barcode, shop);
    }

    final response = await _backendGet('put_product_to_shop/', {
      'barcode': barcode,
      'shopOsmUID': shop.osmUID.toString(),
      'lon': shop.coord.lon.toString(),
      'lat': shop.coord.lat.toString(),
    });
    return _noneOrErrorFrom(response);
  }

  Future<Result<BackendShop, BackendError>> createShop(
      {required String name,
      required Coord coord,
      required String type}) async {
    if (await _settings.testingBackends()) {
      return await _fakeBackend.createShop(
          name: name, coord: coord, type: type);
    }

    final jsonRes = await _backendGetJson('create_shop/', {
      'lon': coord.lon.toString(),
      'lat': coord.lat.toString(),
      'name': name,
      'type': type
    });
    if (jsonRes.isErr) {
      return Err(jsonRes.unwrapErr());
    }
    final json = jsonRes.unwrap();
    if (!json.containsKey('osm_uid')) {
      return Err(BackendError.invalidDecodedJson(json));
    }
    return Ok(BackendShop((e) => e
      ..osmUID = OsmUID.parse(json['osm_uid'] as String)
      ..productsCount = 0));
  }

  Result<None, BackendError> _noneOrErrorFrom(BackendResponse response) {
    if (response.isError) {
      return Err(_errFromResp(response));
    }
    final json = _jsonDecodeSafe(response.body);
    if (json != null && !_isError(json)) {
      return Ok(None());
    } else {
      return Err(_errOther());
    }
  }

  Future<Result<Map<String, dynamic>, BackendError>> _backendGetJson(
      String path, Map<String, dynamic>? params,
      {Map<String, String>? headers,
      String? backendClientTokenOverride,
      String? body,
      String? contentType}) async {
    final response = await _backendGet(path, params,
        headers: headers,
        backendClientTokenOverride: backendClientTokenOverride,
        body: body,
        contentType: contentType);
    if (response.isError) {
      return Err(_errFromResp(response));
    }

    final json = _jsonDecodeSafe(response.body);
    if (json == null) {
      return Err(_errInvalidJson(response.body));
    }
    if (_isError(json)) {
      return Err(_errFromJson(json));
    }
    return Ok(json);
  }

  Future<BackendResponse> _backendGet(String path, Map<String, dynamic>? params,
      {Map<String, String>? headers,
      String? backendClientTokenOverride,
      String? body,
      String? contentType}) async {
    final userParams = await _userParamsController.getUserParams();
    final backendClientToken =
        backendClientTokenOverride ?? userParams?.backendClientToken;

    final headersReally =
        Map<String, String>.from(headers ?? <String, String>{});
    if (backendClientToken != null) {
      headersReally['Authorization'] = 'Bearer $backendClientToken';
    }
    if (contentType != null) {
      headersReally['Content-Type'] = contentType;
    }
    final String backendAddress;
    if (_CONNECT_TO_LOCAL_SERVER) {
      backendAddress = _LOCAL_BACKEND_ADDRESS;
    } else {
      backendAddress = BACKEND_ADDRESS;
    }
    final Uri url;
    if (_CONNECT_TO_LOCAL_SERVER) {
      url = Uri.http(backendAddress, '/$path', params);
    } else {
      url = Uri.https(backendAddress, '/backend/$path', params);
    }
    try {
      final request = http.Request('GET', url);
      request.headers.addAll(headersReally);

      if (body != null) {
        request.body = body;
      }

      final httpResponse =
          await http.Response.fromStream(await _http.send(request));
      return BackendResponse.fromHttpResponse(httpResponse);
    } on IOException catch (e) {
      return BackendResponse.fromError(e, url);
    }
  }

  bool _isError(Map<String, dynamic> json) {
    return BackendError.isError(json);
  }

  BackendError _errFromResp(BackendResponse response) {
    final error = BackendError.fromResp(response);
    _observers.forEach((obs) {
      obs.onBackendError(error);
    });
    return error;
  }

  BackendError _errFromJson(Map<String, dynamic> json) {
    final error = BackendError.fromJson(json);
    _observers.forEach((obs) {
      obs.onBackendError(error);
    });
    return error;
  }

  BackendError _errInvalidJson(String invalidJson) {
    final error = BackendError.invalidJson(invalidJson);
    _observers.forEach((obs) {
      obs.onBackendError(error);
    });
    return error;
  }

  BackendError _errOther() {
    final error = BackendError.other();
    _observers.forEach((obs) {
      obs.onBackendError(error);
    });
    return error;
  }

  Future<BackendResponse> customGet(String path,
      [Map<String, dynamic>? queryParams, Map<String, String>? headers]) async {
    if (!kIsWeb) {
      throw Exception('Backend.customGet must be called only from Web');
    }
    return await _backendGet(path, queryParams, headers: headers);
  }
}

Map<String, dynamic>? _jsonDecodeSafe(String str) {
  try {
    return jsonDecode(str) as Map<String, dynamic>?;
  } on FormatException catch (e) {
    Log.w("Backend: couldn't decode safe: %str", ex: e);
    return null;
  }
}
