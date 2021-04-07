// Mocks generated by Mockito 5.0.3 from annotations
// in untitled_vegan_app/test/ui/product/product_page_wrapper_test.dart.
// Do not manually edit this file.

import 'dart:async' as _i4;

import 'package:mockito/mockito.dart' as _i1;
import 'package:untitled_vegan_app/model/product.dart' as _i2;
import 'package:untitled_vegan_app/outside/products_manager.dart' as _i3;

// ignore_for_file: comment_references
// ignore_for_file: unnecessary_parenthesis

class _FakeProduct extends _i1.Fake implements _i2.Product {}

class _FakeProductWithOCRIngredients extends _i1.Fake
    implements _i3.ProductWithOCRIngredients {}

/// A class which mocks [ProductsManager].
///
/// See the documentation for Mockito's code generation for more information.
class MockProductsManager extends _i1.Mock implements _i3.ProductsManager {
  MockProductsManager() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Future<_i2.Product?> getProduct(String? barcodeRaw, String? langCode) =>
      (super.noSuchMethod(
              Invocation.method(#getProduct, [barcodeRaw, langCode]),
              returnValue: Future.value(_FakeProduct()))
          as _i4.Future<_i2.Product?>);
  @override
  _i4.Future<_i2.Product?> createUpdateProduct(
          _i2.Product? product, String? langCode) =>
      (super.noSuchMethod(
              Invocation.method(#createUpdateProduct, [product, langCode]),
              returnValue: Future.value(_FakeProduct()))
          as _i4.Future<_i2.Product?>);
  @override
  _i4.Future<_i3.ProductWithOCRIngredients?> updateProductAndExtractIngredients(
          _i2.Product? product, String? langCode) =>
      (super.noSuchMethod(
              Invocation.method(
                  #updateProductAndExtractIngredients, [product, langCode]),
              returnValue: Future.value(_FakeProductWithOCRIngredients()))
          as _i4.Future<_i3.ProductWithOCRIngredients?>);
}
