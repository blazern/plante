// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'osm_short_address.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<OsmShortAddress> _$osmShortAddressSerializer =
    new _$OsmShortAddressSerializer();

class _$OsmShortAddressSerializer
    implements StructuredSerializer<OsmShortAddress> {
  @override
  final Iterable<Type> types = const [OsmShortAddress, _$OsmShortAddress];
  @override
  final String wireName = 'OsmShortAddress';

  @override
  Iterable<Object?> serialize(Serializers serializers, OsmShortAddress object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[];
    Object? value;
    value = object.houseNumber;
    if (value != null) {
      result
        ..add('houseNumber')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.road;
    if (value != null) {
      result
        ..add('road')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.city;
    if (value != null) {
      result
        ..add('city')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  OsmShortAddress deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new OsmShortAddressBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'houseNumber':
          result.houseNumber = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'road':
          result.road = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'city':
          result.city = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
      }
    }

    return result.build();
  }
}

class _$OsmShortAddress extends OsmShortAddress {
  @override
  final String? houseNumber;
  @override
  final String? road;
  @override
  final String? city;

  factory _$OsmShortAddress([void Function(OsmShortAddressBuilder)? updates]) =>
      (new OsmShortAddressBuilder()..update(updates))._build();

  _$OsmShortAddress._({this.houseNumber, this.road, this.city}) : super._();

  @override
  OsmShortAddress rebuild(void Function(OsmShortAddressBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OsmShortAddressBuilder toBuilder() =>
      new OsmShortAddressBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OsmShortAddress &&
        houseNumber == other.houseNumber &&
        road == other.road &&
        city == other.city;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, houseNumber.hashCode);
    _$hash = $jc(_$hash, road.hashCode);
    _$hash = $jc(_$hash, city.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OsmShortAddress')
          ..add('houseNumber', houseNumber)
          ..add('road', road)
          ..add('city', city))
        .toString();
  }
}

class OsmShortAddressBuilder
    implements Builder<OsmShortAddress, OsmShortAddressBuilder> {
  _$OsmShortAddress? _$v;

  String? _houseNumber;
  String? get houseNumber => _$this._houseNumber;
  set houseNumber(String? houseNumber) => _$this._houseNumber = houseNumber;

  String? _road;
  String? get road => _$this._road;
  set road(String? road) => _$this._road = road;

  String? _city;
  String? get city => _$this._city;
  set city(String? city) => _$this._city = city;

  OsmShortAddressBuilder();

  OsmShortAddressBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _houseNumber = $v.houseNumber;
      _road = $v.road;
      _city = $v.city;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OsmShortAddress other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$OsmShortAddress;
  }

  @override
  void update(void Function(OsmShortAddressBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OsmShortAddress build() => _build();

  _$OsmShortAddress _build() {
    final _$result = _$v ??
        new _$OsmShortAddress._(
            houseNumber: houseNumber, road: road, city: city);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
