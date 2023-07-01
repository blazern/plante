// Mocks generated by Mockito 5.4.1 from annotations
// in plante/test/lang/location_based_user_langs_manager_test.dart.
// Do not manually edit this file.

// @dart=2.19

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i3;

import 'package:mockito/mockito.dart' as _i1;
import 'package:plante/lang/location_based_user_langs_storage.dart' as _i2;
import 'package:plante/model/lang_code.dart' as _i4;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

/// A class which mocks [LocationBasedUserLangsStorage].
///
/// See the documentation for Mockito's code generation for more information.
class MockLocationBasedUserLangsStorage extends _i1.Mock
    implements _i2.LocationBasedUserLangsStorage {
  MockLocationBasedUserLangsStorage() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i3.Future<List<_i4.LangCode>?> userLangs() => (super.noSuchMethod(
        Invocation.method(
          #userLangs,
          [],
        ),
        returnValue: _i3.Future<List<_i4.LangCode>?>.value(),
      ) as _i3.Future<List<_i4.LangCode>?>);
  @override
  _i3.Future<void> setUserLangs(List<_i4.LangCode>? value) =>
      (super.noSuchMethod(
        Invocation.method(
          #setUserLangs,
          [value],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);
}
