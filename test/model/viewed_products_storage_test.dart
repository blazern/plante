import 'package:flutter_test/flutter_test.dart';
import 'package:plante/base/base.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/viewed_products_storage.dart';

void main() {
  late ViewedProductsStorage storage;

  setUp(() async {
    storage = ViewedProductsStorage(
        loadPersistentProducts: false,
        storageFileName: '${randInt(0, 9999999)}');
    await storage.purgeForTesting();
  });

  tearDown(() async {
    await storage.dispose();
  });

  test('add and obtain products', () async {
    final p1 = Product((e) => e.barcode = '123');
    final p2 = Product((e) => e.barcode = '321');
    final p3 = Product((e) => e.barcode = '222');
    await storage.addProduct(p1);
    await storage.addProduct(p2);
    await storage.addProduct(p3);
    expect(storage.getProducts(), equals([p1, p2, p3]));
  });

  test('products have limit', () async {
    const productsNumber = 2 * ViewedProductsStorage.STORED_PRODUCTS_MAX;
    for (var i = 0; i < productsNumber; ++i) {
      await storage.addProduct(Product((e) => e.barcode = '$i'));
    }

    final expectedProducts = <Product>[];
    for (var i = ViewedProductsStorage.STORED_PRODUCTS_MAX;
        i < productsNumber;
        ++i) {
      expectedProducts.add(Product((e) => e.barcode = '$i'));
    }

    expect(storage.getProducts(), equals(expectedProducts));
  });

  test('listen to products updates', () async {
    var updatesCount = 0;
    storage.updates().listen((_) {
      updatesCount += 1;
    });

    expect(updatesCount, equals(0));

    await storage.addProduct(Product((e) => e.barcode = '1'));
    await Future.delayed(const Duration(microseconds: 1));
    expect(updatesCount, equals(1));

    await storage.addProduct(Product((e) => e.barcode = '2'));
    await Future.delayed(const Duration(microseconds: 1));
    expect(updatesCount, equals(2));
  });

  test('persistent products storage', () async {
    final storageFileName = '${randInt(0, 9999999)}';
    final storage = ViewedProductsStorage(
        loadPersistentProducts: false, storageFileName: storageFileName);
    final p1 = Product((e) => e.barcode = '123');
    final p2 = Product((e) => e.barcode = '321');
    final p3 = Product((e) => e.barcode = '222');
    await storage.addProduct(p1);
    await storage.addProduct(p2);
    await storage.addProduct(p3);
    await storage.dispose();

    final anotherStorage = ViewedProductsStorage(
        loadPersistentProducts: false, storageFileName: storageFileName);
    await anotherStorage.loadPersistentProductsForTesting();
    expect(anotherStorage.getProducts(), equals([p1, p2, p3]));
  });

  test('listen notification when persistent products first loaded', () async {
    final storageFileName = '${randInt(0, 9999999)}';
    final storage = ViewedProductsStorage(
        loadPersistentProducts: false, storageFileName: storageFileName);

    await storage.addProduct(Product((e) => e.barcode = '123'));
    await storage.dispose();

    final anotherStorage = ViewedProductsStorage(
        loadPersistentProducts: false, storageFileName: storageFileName);
    var updatesCount = 0;
    anotherStorage.updates().listen((_) {
      updatesCount += 1;
    });
    expect(updatesCount, equals(0));
    await anotherStorage.loadPersistentProductsForTesting();
    await Future.delayed(const Duration(seconds: 1));
    expect(updatesCount, equals(1));
  });

  test('existing viewed product moved when is viewed again', () async {
    final p1 = Product((e) => e.barcode = '123');
    final p2 = Product((e) => e.barcode = '321');
    final p3 = Product((e) => e.barcode = '222');
    await storage.addProduct(p1);
    await storage.addProduct(p2);
    await storage.addProduct(p3);
    expect(storage.getProducts(), equals([p1, p2, p3]));

    final p2Updated = p2.rebuild((e) => e.nameLangs[LangCode.en] = 'new name');
    await storage.addProduct(p2Updated);
    expect(storage.getProducts(), equals([p1, p3, p2Updated]));
  });
}
