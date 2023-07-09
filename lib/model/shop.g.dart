// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Shop> _$shopSerializer = new _$ShopSerializer();

class _$ShopSerializer implements StructuredSerializer<Shop> {
  @override
  final Iterable<Type> types = const [Shop, _$Shop];
  @override
  final String wireName = 'Shop';

  @override
  Iterable<Object?> serialize(Serializers serializers, Shop object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'osmShop',
      serializers.serialize(object.osmShop,
          specifiedType: const FullType(OsmShop)),
    ];
    Object? value;
    value = object.backendShop;
    if (value != null) {
      result
        ..add('backendShop')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(BackendShop)));
    }
    return result;
  }

  @override
  Shop deserialize(Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ShopBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'osmShop':
          result.osmShop.replace(serializers.deserialize(value,
              specifiedType: const FullType(OsmShop))! as OsmShop);
          break;
        case 'backendShop':
          result.backendShop.replace(serializers.deserialize(value,
              specifiedType: const FullType(BackendShop))! as BackendShop);
          break;
      }
    }

    return result.build();
  }
}

class _$Shop extends Shop {
  @override
  final OsmShop osmShop;
  @override
  final BackendShop? backendShop;

  factory _$Shop([void Function(ShopBuilder)? updates]) =>
      (new ShopBuilder()..update(updates))._build();

  _$Shop._({required this.osmShop, this.backendShop}) : super._() {
    BuiltValueNullFieldError.checkNotNull(osmShop, r'Shop', 'osmShop');
  }

  @override
  Shop rebuild(void Function(ShopBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ShopBuilder toBuilder() => new ShopBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Shop &&
        osmShop == other.osmShop &&
        backendShop == other.backendShop;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, osmShop.hashCode);
    _$hash = $jc(_$hash, backendShop.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Shop')
          ..add('osmShop', osmShop)
          ..add('backendShop', backendShop))
        .toString();
  }
}

class ShopBuilder implements Builder<Shop, ShopBuilder> {
  _$Shop? _$v;

  OsmShopBuilder? _osmShop;
  OsmShopBuilder get osmShop => _$this._osmShop ??= new OsmShopBuilder();
  set osmShop(OsmShopBuilder? osmShop) => _$this._osmShop = osmShop;

  BackendShopBuilder? _backendShop;
  BackendShopBuilder get backendShop =>
      _$this._backendShop ??= new BackendShopBuilder();
  set backendShop(BackendShopBuilder? backendShop) =>
      _$this._backendShop = backendShop;

  ShopBuilder();

  ShopBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _osmShop = $v.osmShop.toBuilder();
      _backendShop = $v.backendShop?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Shop other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$Shop;
  }

  @override
  void update(void Function(ShopBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Shop build() => _build();

  _$Shop _build() {
    _$Shop _$result;
    try {
      _$result = _$v ??
          new _$Shop._(
              osmShop: osmShop.build(), backendShop: _backendShop?.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'osmShop';
        osmShop.build();
        _$failedField = 'backendShop';
        _backendShop?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'Shop', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
