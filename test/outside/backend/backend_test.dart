import 'dart:convert';
import 'dart:io';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:test/test.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/outside/backend/backend_product.dart';

import '../../fake_http_client.dart';
import '../../fake_settings.dart';
import '../../fake_user_params_controller.dart';
import 'backend_test.mocks.dart';

@GenerateMocks([BackendObserver])
void main() {
  final fakeSettings = FakeSettings();
  
  setUp(() {
  });

  test('successful registration', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient, fakeSettings);

    httpClient.setResponse('.*register_user.*', '''
      {
        "user_id": "123",
        "client_token": "321"
      }
    ''');

    final result = await backend.loginOrRegister('google ID');
    final expectedParams = UserParams((v) => v
      ..backendId = '123'
      ..backendClientToken = '321');
    expect(result.unwrap(), equals(expectedParams));
  });

  test('successful login', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient, fakeSettings);

    httpClient.setResponse('.*register_user.*', '''
      {
        "error": "already_registered"
      }
    ''');
    httpClient.setResponse('.*login_user.*', '''
      {
        "user_id": "123",
        "client_token": "321"
      }
    ''');

    final result = await backend.loginOrRegister('google ID');
    final expectedParams = UserParams((v) => v
      ..backendId = '123'
      ..backendClientToken = '321');
    expect(result.unwrap(), equals(expectedParams));
  });

  test('check whether logged in', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient, fakeSettings);

    expect(await backend.isLoggedIn(), isFalse);
    await userParamsController.setUserParams(UserParams((v) => v.backendId = '123'));
    expect(await backend.isLoggedIn(), isFalse);
    await userParamsController.setUserParams(UserParams((v) => v.backendClientToken = '321'));
    expect(await backend.isLoggedIn(), isTrue);
  });

  test('login when already logged in', () async {
    final httpClient = FakeHttpClient();
    final existingParams = UserParams((v) => v
      ..backendId = '123'
      ..backendClientToken = '321'
      ..name = 'Bob');
    final userParamsController = FakeUserParamsController();
    await userParamsController.setUserParams(existingParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    final result = await backend.loginOrRegister('google ID');
    expect(result.unwrap(), equals(existingParams));
  });

  test('registration failure - email not verified', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient, fakeSettings);

    httpClient.setResponse('.*register_user.*', '''
      {
        "error": "google_email_not_verified"
      }
    ''');

    final result = await backend.loginOrRegister('google ID');
    expect(
        result.unwrapErr().errorKind, equals(
        BackendErrorKind.GOOGLE_EMAIL_NOT_VERIFIED));
  });

  test('registration request not 200', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse('.*register_user.*', '', responseCode: 500);
    final result = await backend.loginOrRegister('google ID');
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.OTHER));
  });

  test('registration request bad json', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse('.*register_user.*', '{{{{bad bad bad}');
    final result = await backend.loginOrRegister('google ID');
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.INVALID_JSON));
  });

  test('registration request json error', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse('.*register_user.*', '''
      {
        "error": "some_error"
      }
    ''');
    final result = await backend.loginOrRegister('google ID');
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.OTHER));
  });

  test('login request not 200', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse('.*register_user.*', '''
      {
        "error": "already_registered"
      }
    ''');
    httpClient.setResponse('.*login_user.*', '', responseCode: 500);
    final result = await backend.loginOrRegister('google ID');
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.OTHER));
  });

  test('login request bad json', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse('.*register_user.*', '''
      {
        "error": "already_registered"
      }
    ''');
    httpClient.setResponse('.*login_user.*', '{{{{bad bad bad}');
    final result = await backend.loginOrRegister('google ID');
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.INVALID_JSON));
  });

  test('login request json error', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse('.*register_user.*', '''
      {
        "error": "already_registered"
      }
    ''');
    httpClient.setResponse('.*login_user.*', '''
      {
        "error": "some_error"
      }
    ''');
    final result = await backend.loginOrRegister('google ID');
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.OTHER));
  });

  test('registration network error', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponseException('.*register_user.*', const SocketException(''));
    final result = await backend.loginOrRegister('google ID');
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.NETWORK_ERROR));
  });

  test('login network error', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse('.*register_user.*', '''
      {
        "error": "already_registered"
      }
    ''');
    httpClient.setResponseException('.*register_user.*', const SocketException(''));
    final result = await backend.loginOrRegister('google ID');
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.NETWORK_ERROR));
  });

  test('observer notified about server errors', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final backend = Backend(userParamsController, httpClient, fakeSettings);
    final observer = MockBackendObserver();
    backend.addObserver(observer);

    httpClient.setResponse('.*register_user.*', '''
      {
        "error": "some_error"
      }
    ''');

    verifyNever(observer.onBackendError(any));
    await backend.loginOrRegister('google ID');
    verify(observer.onBackendError(any));
  });

  test('update user params', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob'
      ..backendClientToken = 'aaa');
    await userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse('.*update_user_data.*', ''' { "result": "ok" } ''');

    final updatedParams = initialParams.rebuild((v) => v
      ..name = 'Jack'
      ..genderStr = 'male'
      ..birthdayStr = '20.07.1993'
      ..eatsMilk = false
      ..eatsEggs = false
      ..eatsHoney = true);
    final result = await backend.updateUserParams(updatedParams);
    expect(result.isOk, isTrue);

    final requests = httpClient.getRequestsMatching('.*update_user_data.*');
    expect(requests.length, equals(1));
    final request = requests[0];

    expect(request.url.queryParameters['name'], equals('Jack'));
    expect(request.url.queryParameters['gender'], equals('male'));
    expect(request.url.queryParameters['birthday'], equals('20.07.1993'));
    expect(request.url.queryParameters['eatsMilk'], equals('false'));
    expect(request.url.queryParameters['eatsEggs'], equals('false'));
    expect(request.url.queryParameters['eatsHoney'], equals('true'));
  });

  test('update user params has client token', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob'
      ..backendClientToken = 'my_token');
    await userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse('.*update_user_data.*', ''' { "result": "ok" } ''');

    await backend.updateUserParams(initialParams.rebuild((v) => v.name = 'Nora'));
    final request = httpClient.getRequestsMatching('.*update_user_data.*')[0];

    expect(request.headers['Authorization'], equals('Bearer my_token'));
  });

  test('update user params when not authorized', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob');
    await userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse('.*update_user_data.*', ''' { "result": "ok" } ''');

    await backend.updateUserParams(initialParams.rebuild((v) => v.name = 'Nora'));
    final request = httpClient.getRequestsMatching('.*update_user_data.*')[0];

    expect(request.headers['Authorization'], equals(null));
  });

  test('update user params network error', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob'
      ..backendClientToken = 'aaa');
    await userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponseException('.*update_user_data.*', const HttpException(''));

    final updatedParams = initialParams.rebuild((v) => v
      ..name = 'Jack'
      ..genderStr = 'male'
      ..birthdayStr = '20.07.1993');
    final result = await backend.updateUserParams(updatedParams);
    expect(result.unwrapErr().errorKind, BackendErrorKind.NETWORK_ERROR);
  });

  test('request product', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob'
      ..backendClientToken = 'aaa');
    await userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse('.*product_data.*', '''
     {
       "barcode": "123",
       "vegetarian_status": "${VegStatus.positive.name}",
       "vegetarian_status_source": "${VegStatusSource.community.name}",
       "vegan_status": "${VegStatus.negative.name}",
       "vegan_status_source": "${VegStatusSource.moderator.name}"
     }
      ''');

    final result = await backend.requestProduct('123');
    final product = result.unwrap();
    final expectedProduct = BackendProduct((v) => v
      ..barcode = '123'
      ..vegetarianStatus = VegStatus.positive.name
      ..vegetarianStatusSource = VegStatusSource.community.name
      ..veganStatus = VegStatus.negative.name
      ..veganStatusSource = VegStatusSource.moderator.name);
    expect(product, equals(expectedProduct));

    final requests = httpClient.getRequestsMatching('.*product_data.*');
    expect(requests.length, equals(1));
    final request = requests[0];
    expect(request.headers['Authorization'], equals('Bearer aaa'));
  });

  test('request product not found', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob'
      ..backendClientToken = 'aaa');
    await userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse('.*product_data.*', '''
     {
       "error": "product_not_found"
     }
      ''');

    final result = await backend.requestProduct('123');
    final product = result.unwrap();
    expect(product, isNull);
  });

  test('request product http error', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob'
      ..backendClientToken = 'aaa');
    await userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse('.*product_data.*', '', responseCode: 500);

    final result = await backend.requestProduct('123');
    expect(result.isErr, isTrue);

    final requests = httpClient.getRequestsMatching('.*product_data.*');
    expect(requests.length, equals(1));
    final request = requests[0];
    expect(request.headers['Authorization'], equals('Bearer aaa'));
  });

  test('request product invalid JSON', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob'
      ..backendClientToken = 'aaa');
    await userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse('.*product_data.*', '''
     {{{{{{{{{{{{
       "barcode": "123",
       "vegetarian_status": "${VegStatus.positive.name}",
       "vegetarian_status_source": "${VegStatusSource.community.name}",
       "vegan_status": "${VegStatus.negative.name}",
       "vegan_status_source": "${VegStatusSource.moderator.name}"
     }
      ''');

    final result = await backend.requestProduct('123');
    expect(result.unwrapErr().errorKind, BackendErrorKind.INVALID_JSON);

    final requests = httpClient.getRequestsMatching('.*product_data.*');
    expect(requests.length, equals(1));
    final request = requests[0];
    expect(request.headers['Authorization'], equals('Bearer aaa'));
  });

  test('request product network exception', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob'
      ..backendClientToken = 'aaa');
    await userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponseException('.*product_data.*', const SocketException(''));

    final result = await backend.requestProduct('123');
    expect(result.unwrapErr().errorKind, BackendErrorKind.NETWORK_ERROR);
  });

  test('create update product', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob'
      ..backendClientToken = 'aaa');
    await userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse(
        '.*create_update_product.*',
        ''' { "result": "ok" } ''');

    final result = await backend.createUpdateProduct(
        '123',
        vegetarianStatus: VegStatus.positive,
        veganStatus: VegStatus.negative);
    expect(result.isOk, isTrue);

    final requests = httpClient.getRequestsMatching('.*create_update_product.*');
    expect(requests.length, equals(1));
    final request = requests[0];
    expect(
        request.url.queryParameters['vegetarianStatus'],
        equals(VegStatus.positive.name));
    expect(
        request.url.queryParameters['veganStatus'],
        equals(VegStatus.negative.name));
    expect(request.headers['Authorization'], equals('Bearer aaa'));
  });

  test('create update product vegetarian status only', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob'
      ..backendClientToken = 'aaa');
    await userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse(
        '.*create_update_product.*',
        ''' { "result": "ok" } ''');

    final result = await backend.createUpdateProduct(
        '123',
        vegetarianStatus: VegStatus.positive);
    expect(result.isOk, isTrue);

    final requests = httpClient.getRequestsMatching('.*create_update_product.*');
    expect(requests.length, equals(1));
    final request = requests[0];
    expect(
        request.url.queryParameters['vegetarianStatus'],
        equals(VegStatus.positive.name));
    expect(
        request.url.queryParameters['veganStatus'],
        isNull);
    expect(request.headers['Authorization'], equals('Bearer aaa'));
  });

  test('create update product vegan status only', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob'
      ..backendClientToken = 'aaa');
    await userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse(
        '.*create_update_product.*',
        ''' { "result": "ok" } ''');

    final result = await backend.createUpdateProduct(
        '123',
        veganStatus: VegStatus.negative);
    expect(result.isOk, isTrue);

    final requests = httpClient.getRequestsMatching('.*create_update_product.*');
    expect(requests.length, equals(1));
    final request = requests[0];
    expect(
        request.url.queryParameters['vegetarianStatus'],
        isNull);
    expect(
        request.url.queryParameters['veganStatus'],
        equals(VegStatus.negative.name));
    expect(request.headers['Authorization'], equals('Bearer aaa'));
  });

  test('create update product http error', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob'
      ..backendClientToken = 'aaa');
    await userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse('.*create_update_product.*', '', responseCode: 500);

    final result = await backend.createUpdateProduct(
        '123',
        vegetarianStatus: VegStatus.positive,
        veganStatus: VegStatus.negative);
    expect(result.isErr, isTrue);
  });

  test('create update product invalid JSON response', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob'
      ..backendClientToken = 'aaa');
    await userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse('.*create_update_product.*', '{{{{}');

    final result = await backend.createUpdateProduct(
        '123',
        vegetarianStatus: VegStatus.positive,
        veganStatus: VegStatus.negative);
    expect(result.isErr, isTrue);
  });

  test('create update product network error', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob'
      ..backendClientToken = 'aaa');
    await userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponseException(
        '.*create_update_product.*', const SocketException(''));

    final result = await backend.createUpdateProduct(
        '123',
        vegetarianStatus: VegStatus.positive,
        veganStatus: VegStatus.negative);
    expect(result.unwrapErr().errorKind, BackendErrorKind.NETWORK_ERROR);
  });

  test('send report', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob'
      ..backendClientToken = 'aaa');
    await userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse(
        '.*make_report.*',
        ''' { "result": "ok" } ''');

    final result = await backend.sendReport(
        '123',
        "that's a baaaad product");
    expect(result.isOk, isTrue);
  });

  test('send report network error', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob'
      ..backendClientToken = 'aaa');
    await userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponseException('.*make_report.*', const SocketException(''));

    final result = await backend.sendReport(
        '123',
        "that's a baaaad product");
    expect(result.unwrapErr().errorKind, BackendErrorKind.NETWORK_ERROR);
  });

  test('user data obtaining', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob'
      ..backendClientToken = 'aaa');
    await userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse(
        '.*user_data.*',
        ''' { "name": "Bob Kelso", "user_id": "123" } ''');

    final result = await backend.userData();
    expect(result.isOk, isTrue);

    final obtainedParams = result.unwrap();
    expect(obtainedParams.name, equals('Bob Kelso'));
    expect(obtainedParams.backendId, equals('123'));
    // NOTE: client token was not present in the response, but
    // the Backend class knows the token and can set it.
    expect(obtainedParams.backendClientToken, equals('aaa'));
  });

  test('user data obtaining invalid JSON response', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob'
      ..backendClientToken = 'aaa');
    await userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse(
        '.*user_data.*',
        ''' {{{{{{{{{{{ "name": "Bob Kelso", "user_id": "123" } ''');

    final result = await backend.userData();
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.INVALID_JSON));
  });

  test('user data obtaining network error', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob'
      ..backendClientToken = 'aaa');
    await userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponseException(
        '.*user_data.*', const SocketException(''));

    final result = await backend.userData();
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.NETWORK_ERROR));
  });

  test('requesting shops', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob'
      ..backendClientToken = 'aaa');
    await userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse(
        '.*products_at_shops_data.*',
        '''
          {
            "results" : {
              "8711880917" : {
                "shop_osm_id" : "8711880917",
                "products" : [ {
                  "server_id" : 23,
                  "barcode" : "4605932001284",
                  "vegetarian_status" : "positive",
                  "vegan_status" : "positive",
                  "vegetarian_status_source" : "community",
                  "vegan_status_source" : "community"
                } ],
                "products_last_seen_utc" : { }
              },
              "8771781029" : {
                "shop_osm_id" : "8771781029",
                "products" : [ {
                  "server_id" : 16,
                  "barcode" : "4612742721165",
                  "vegetarian_status" : "positive",
                  "vegan_status" : "positive",
                  "vegetarian_status_source" : "community",
                  "vegan_status_source" : "community"
                }, {
                  "server_id" : 17,
                  "barcode" : "9001414603703",
                  "vegetarian_status" : "positive",
                  "vegan_status" : "positive",
                  "vegetarian_status_source" : "community",
                  "vegan_status_source" : "community"
                } ],
                "products_last_seen_utc" : {
                  "4612742721165": 123456
                }
              }
            }
          }
        ''');

    final result = await backend.requestShops(['8711880917', '8771781029']);
    expect(result.isOk, isTrue);

    final shops = result.unwrap();
    expect(shops.length, equals(2));

    final BackendShop shop1;
    final BackendShop shop2;
    if (shops[0].osmId == '8711880917') {
      shop1 = shops[0];
      shop2 = shops[1];
    } else {
      shop1 = shops[1];
      shop2 = shops[0];
    }

    final expectedProduct1 = BackendProduct.fromJson(jsonDecode('''
    {
      "server_id" : 23,
      "barcode" : "4605932001284",
      "vegetarian_status" : "positive",
      "vegan_status" : "positive",
      "vegetarian_status_source" : "community",
      "vegan_status_source" : "community"
    }''') as Map<String, dynamic>);
    final expectedProduct2 = BackendProduct.fromJson(jsonDecode('''
    {
      "server_id" : 16,
      "barcode" : "4612742721165",
      "vegetarian_status" : "positive",
      "vegan_status" : "positive",
      "vegetarian_status_source" : "community",
      "vegan_status_source" : "community"
    }''') as Map<String, dynamic>);
    final expectedProduct3 = BackendProduct.fromJson(jsonDecode('''
    {
      "server_id" : 17,
      "barcode" : "9001414603703",
      "vegetarian_status" : "positive",
      "vegan_status" : "positive",
      "vegetarian_status_source" : "community",
      "vegan_status_source" : "community"
    }''') as Map<String, dynamic>);

    expect(shop1.products.length, equals(1));
    expect(shop1.products[0], equals(expectedProduct1));

    expect(shop2.products.length, equals(2));
    expect(shop2.products[0], equals(expectedProduct2));
    expect(shop2.products[1], equals(expectedProduct3));

    expect(shop1.productsLastSeenUtc.length, equals(0));
    expect(shop2.productsLastSeenUtc.length, equals(1));
    expect(shop2.productsLastSeenUtc['4612742721165'], equals(123456));
  });

  test('requesting shops empty response', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob'
      ..backendClientToken = 'aaa');
    await userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse(
        '.*products_at_shops_data.*',
        '''
          {
            "results" : {}
          }
        ''');

    final result = await backend.requestShops(['8711880917', '8771781029']);
    expect(result.unwrap().length, equals(0));
  });

  test('requesting shops invalid JSON response', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob'
      ..backendClientToken = 'aaa');
    await userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse(
        '.*products_at_shops_data.*',
        '''
          {{{{{{{{{{{{{{{{{{{{{{
            "results" : {
              "8711880917" : {
                "shop_osm_id" : "8711880917",
                "products" : [ {
                  "server_id" : 23,
                  "barcode" : "4605932001284",
                  "vegetarian_status" : "positive",
                  "vegan_status" : "positive",
                  "vegetarian_status_source" : "community",
                  "vegan_status_source" : "community"
                } ],
                "products_last_seen_utc" : { }
              }
            }
          }
        ''');

    final result = await backend.requestShops(['8711880917', '8771781029']);
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.INVALID_JSON));
  });

  test('requesting shops JSON without results response', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob'
      ..backendClientToken = 'aaa');
    await userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponse(
        '.*products_at_shops_data.*',
        '''
          {
            "rezzzults" : {}
          }
        ''');

    final result = await backend.requestShops(['8711880917', '8771781029']);
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.INVALID_JSON));
  });

  test('requesting shops network error', () async {
    final httpClient = FakeHttpClient();
    final userParamsController = FakeUserParamsController();
    final initialParams = UserParams((v) => v
      ..backendId = '123'
      ..name = 'Bob'
      ..backendClientToken = 'aaa');
    await userParamsController.setUserParams(initialParams);

    final backend = Backend(userParamsController, httpClient, fakeSettings);
    httpClient.setResponseException(
        '.*products_at_shops_data.*', const SocketException(''));

    final result = await backend.requestShops(['8711880917', '8771781029']);
    expect(result.unwrapErr().errorKind, equals(BackendErrorKind.NETWORK_ERROR));
  });
}
