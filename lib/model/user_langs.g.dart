// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_langs.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<UserLangs> _$userLangsSerializer = new _$UserLangsSerializer();

class _$UserLangsSerializer implements StructuredSerializer<UserLangs> {
  @override
  final Iterable<Type> types = const [UserLangs, _$UserLangs];
  @override
  final String wireName = 'UserLangs';

  @override
  Iterable<Object?> serialize(Serializers serializers, UserLangs object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'langs',
      serializers.serialize(object.langs,
          specifiedType:
              const FullType(BuiltList, const [const FullType(LangCode)])),
      'auto',
      serializers.serialize(object.auto, specifiedType: const FullType(bool)),
    ];
    Object? value;
    value = object.sysLang;
    if (value != null) {
      result
        ..add('sysLang')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(LangCode)));
    }
    return result;
  }

  @override
  UserLangs deserialize(Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new UserLangsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'langs':
          result.langs.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(LangCode)]))!
              as BuiltList<Object?>);
          break;
        case 'sysLang':
          result.sysLang = serializers.deserialize(value,
              specifiedType: const FullType(LangCode)) as LangCode?;
          break;
        case 'auto':
          result.auto = serializers.deserialize(value,
              specifiedType: const FullType(bool))! as bool;
          break;
      }
    }

    return result.build();
  }
}

class _$UserLangs extends UserLangs {
  @override
  final BuiltList<LangCode> langs;
  @override
  final LangCode? sysLang;
  @override
  final bool auto;

  factory _$UserLangs([void Function(UserLangsBuilder)? updates]) =>
      (new UserLangsBuilder()..update(updates))._build();

  _$UserLangs._({required this.langs, this.sysLang, required this.auto})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(langs, r'UserLangs', 'langs');
    BuiltValueNullFieldError.checkNotNull(auto, r'UserLangs', 'auto');
  }

  @override
  UserLangs rebuild(void Function(UserLangsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserLangsBuilder toBuilder() => new UserLangsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserLangs &&
        langs == other.langs &&
        sysLang == other.sysLang &&
        auto == other.auto;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, langs.hashCode);
    _$hash = $jc(_$hash, sysLang.hashCode);
    _$hash = $jc(_$hash, auto.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UserLangs')
          ..add('langs', langs)
          ..add('sysLang', sysLang)
          ..add('auto', auto))
        .toString();
  }
}

class UserLangsBuilder implements Builder<UserLangs, UserLangsBuilder> {
  _$UserLangs? _$v;

  ListBuilder<LangCode>? _langs;
  ListBuilder<LangCode> get langs =>
      _$this._langs ??= new ListBuilder<LangCode>();
  set langs(ListBuilder<LangCode>? langs) => _$this._langs = langs;

  LangCode? _sysLang;
  LangCode? get sysLang => _$this._sysLang;
  set sysLang(LangCode? sysLang) => _$this._sysLang = sysLang;

  bool? _auto;
  bool? get auto => _$this._auto;
  set auto(bool? auto) => _$this._auto = auto;

  UserLangsBuilder();

  UserLangsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _langs = $v.langs.toBuilder();
      _sysLang = $v.sysLang;
      _auto = $v.auto;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserLangs other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$UserLangs;
  }

  @override
  void update(void Function(UserLangsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UserLangs build() => _build();

  _$UserLangs _build() {
    _$UserLangs _$result;
    try {
      _$result = _$v ??
          new _$UserLangs._(
              langs: langs.build(),
              sysLang: sysLang,
              auto: BuiltValueNullFieldError.checkNotNull(
                  auto, r'UserLangs', 'auto'));
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'langs';
        langs.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'UserLangs', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
