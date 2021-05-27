// Mocks generated by Mockito 5.0.3 from annotations
// in plante/test/ui/first_screen/external_auth_page_test.dart.
// Do not manually edit this file.

import 'dart:async' as _i5;

import 'package:mockito/mockito.dart' as _i1;
import 'package:plante/base/result.dart' as _i3;
import 'package:plante/model/user_params.dart' as _i7;
import 'package:plante/model/veg_status.dart' as _i10;
import 'package:plante/outside/backend/backend.dart' as _i6;
import 'package:plante/outside/backend/backend_error.dart' as _i8;
import 'package:plante/outside/backend/backend_product.dart' as _i9;
import 'package:plante/outside/backend/backend_shop.dart' as _i11;
import 'package:plante/outside/identity/google_authorizer.dart' as _i4;
import 'package:plante/outside/identity/google_user.dart' as _i2;

// ignore_for_file: comment_references
// ignore_for_file: unnecessary_parenthesis

class _FakeGoogleUser extends _i1.Fake implements _i2.GoogleUser {}

class _FakeResult<OK, ERR> extends _i1.Fake implements _i3.Result<OK, ERR> {}

/// A class which mocks [GoogleAuthorizer].
///
/// See the documentation for Mockito's code generation for more information.
class MockGoogleAuthorizer extends _i1.Mock implements _i4.GoogleAuthorizer {
  MockGoogleAuthorizer() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i5.Future<_i2.GoogleUser?> auth() =>
      (super.noSuchMethod(Invocation.method(#auth, []),
              returnValue: Future.value(_FakeGoogleUser()))
          as _i5.Future<_i2.GoogleUser?>);
}

/// A class which mocks [Backend].
///
/// See the documentation for Mockito's code generation for more information.
class MockBackend extends _i1.Mock implements _i6.Backend {
  MockBackend() {
    _i1.throwOnMissingStub(this);
  }

  @override
  void addObserver(_i6.BackendObserver? observer) =>
      super.noSuchMethod(Invocation.method(#addObserver, [observer]),
          returnValueForMissingStub: null);
  @override
  void removeObserver(_i6.BackendObserver? observer) =>
      super.noSuchMethod(Invocation.method(#removeObserver, [observer]),
          returnValueForMissingStub: null);
  @override
  _i5.Future<bool> isLoggedIn() =>
      (super.noSuchMethod(Invocation.method(#isLoggedIn, []),
          returnValue: Future.value(false)) as _i5.Future<bool>);
  @override
  _i5.Future<_i3.Result<_i7.UserParams, _i8.BackendError>> loginOrRegister(
          String? googleIdToken) =>
      (super.noSuchMethod(Invocation.method(#loginOrRegister, [googleIdToken]),
              returnValue:
                  Future.value(_FakeResult<_i7.UserParams, _i8.BackendError>()))
          as _i5.Future<_i3.Result<_i7.UserParams, _i8.BackendError>>);
  @override
  _i5.Future<_i3.Result<bool, _i8.BackendError>> updateUserParams(
          _i7.UserParams? userParams,
          {String? backendClientTokenOverride}) =>
      (super.noSuchMethod(
              Invocation.method(#updateUserParams, [userParams],
                  {#backendClientTokenOverride: backendClientTokenOverride}),
              returnValue: Future.value(_FakeResult<bool, _i8.BackendError>()))
          as _i5.Future<_i3.Result<bool, _i8.BackendError>>);
  @override
  _i5.Future<_i3.Result<_i9.BackendProduct?, _i8.BackendError>> requestProduct(
          String? barcode) =>
      (super.noSuchMethod(Invocation.method(#requestProduct, [barcode]),
              returnValue: Future.value(
                  _FakeResult<_i9.BackendProduct?, _i8.BackendError>()))
          as _i5.Future<_i3.Result<_i9.BackendProduct?, _i8.BackendError>>);
  @override
  _i5.Future<_i3.Result<_i3.None, _i8.BackendError>> createUpdateProduct(
          String? barcode,
          {_i10.VegStatus? vegetarianStatus,
          _i10.VegStatus? veganStatus}) =>
      (super.noSuchMethod(
              Invocation.method(#createUpdateProduct, [
                barcode
              ], {
                #vegetarianStatus: vegetarianStatus,
                #veganStatus: veganStatus
              }),
              returnValue:
                  Future.value(_FakeResult<_i3.None, _i8.BackendError>()))
          as _i5.Future<_i3.Result<_i3.None, _i8.BackendError>>);
  @override
  _i5.Future<_i3.Result<_i3.None, _i8.BackendError>> sendReport(
          String? barcode, String? reportText) =>
      (super.noSuchMethod(Invocation.method(#sendReport, [barcode, reportText]),
              returnValue:
                  Future.value(_FakeResult<_i3.None, _i8.BackendError>()))
          as _i5.Future<_i3.Result<_i3.None, _i8.BackendError>>);
  @override
  _i5.Future<_i3.Result<_i3.None, _i8.BackendError>> sendProductScan(
          String? barcode) =>
      (super.noSuchMethod(Invocation.method(#sendProductScan, [barcode]),
              returnValue:
                  Future.value(_FakeResult<_i3.None, _i8.BackendError>()))
          as _i5.Future<_i3.Result<_i3.None, _i8.BackendError>>);
  @override
  _i5.Future<_i3.Result<_i7.UserParams, _i8.BackendError>> userData() =>
      (super.noSuchMethod(Invocation.method(#userData, []),
              returnValue:
                  Future.value(_FakeResult<_i7.UserParams, _i8.BackendError>()))
          as _i5.Future<_i3.Result<_i7.UserParams, _i8.BackendError>>);
  @override
  _i5.Future<_i3.Result<List<_i11.BackendShop>, _i8.BackendError>> requestShops(
          Iterable<String>? osmIds) =>
      (super.noSuchMethod(Invocation.method(#requestShops, [osmIds]),
              returnValue: Future.value(
                  _FakeResult<List<_i11.BackendShop>, _i8.BackendError>()))
          as _i5.Future<_i3.Result<List<_i11.BackendShop>, _i8.BackendError>>);
}
