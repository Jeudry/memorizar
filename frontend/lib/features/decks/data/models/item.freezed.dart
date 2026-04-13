// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Item _$ItemFromJson(Map<String, dynamic> json) {
  return _Item.fromJson(json);
}

/// @nodoc
mixin _$Item {
  String get id => throw _privateConstructorUsedError;
  String get deckId => throw _privateConstructorUsedError;
  String get front => throw _privateConstructorUsedError;
  String get back => throw _privateConstructorUsedError; // SRS fields (SM-2)
  double get easeFactor => throw _privateConstructorUsedError;
  int get interval => throw _privateConstructorUsedError;
  int get repetitions => throw _privateConstructorUsedError;
  DateTime? get nextReviewAt => throw _privateConstructorUsedError;
  DateTime? get lastReviewedAt =>
      throw _privateConstructorUsedError; // Bible-specific metadata (null for non-bible decks)
  String? get book => throw _privateConstructorUsedError;
  int? get chapter => throw _privateConstructorUsedError;
  int? get verse => throw _privateConstructorUsedError;

  /// Serializes this Item to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Item
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItemCopyWith<Item> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemCopyWith<$Res> {
  factory $ItemCopyWith(Item value, $Res Function(Item) then) =
      _$ItemCopyWithImpl<$Res, Item>;
  @useResult
  $Res call({
    String id,
    String deckId,
    String front,
    String back,
    double easeFactor,
    int interval,
    int repetitions,
    DateTime? nextReviewAt,
    DateTime? lastReviewedAt,
    String? book,
    int? chapter,
    int? verse,
  });
}

/// @nodoc
class _$ItemCopyWithImpl<$Res, $Val extends Item>
    implements $ItemCopyWith<$Res> {
  _$ItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Item
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? deckId = null,
    Object? front = null,
    Object? back = null,
    Object? easeFactor = null,
    Object? interval = null,
    Object? repetitions = null,
    Object? nextReviewAt = freezed,
    Object? lastReviewedAt = freezed,
    Object? book = freezed,
    Object? chapter = freezed,
    Object? verse = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            deckId: null == deckId
                ? _value.deckId
                : deckId // ignore: cast_nullable_to_non_nullable
                      as String,
            front: null == front
                ? _value.front
                : front // ignore: cast_nullable_to_non_nullable
                      as String,
            back: null == back
                ? _value.back
                : back // ignore: cast_nullable_to_non_nullable
                      as String,
            easeFactor: null == easeFactor
                ? _value.easeFactor
                : easeFactor // ignore: cast_nullable_to_non_nullable
                      as double,
            interval: null == interval
                ? _value.interval
                : interval // ignore: cast_nullable_to_non_nullable
                      as int,
            repetitions: null == repetitions
                ? _value.repetitions
                : repetitions // ignore: cast_nullable_to_non_nullable
                      as int,
            nextReviewAt: freezed == nextReviewAt
                ? _value.nextReviewAt
                : nextReviewAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            lastReviewedAt: freezed == lastReviewedAt
                ? _value.lastReviewedAt
                : lastReviewedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            book: freezed == book
                ? _value.book
                : book // ignore: cast_nullable_to_non_nullable
                      as String?,
            chapter: freezed == chapter
                ? _value.chapter
                : chapter // ignore: cast_nullable_to_non_nullable
                      as int?,
            verse: freezed == verse
                ? _value.verse
                : verse // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ItemImplCopyWith<$Res> implements $ItemCopyWith<$Res> {
  factory _$$ItemImplCopyWith(
    _$ItemImpl value,
    $Res Function(_$ItemImpl) then,
  ) = __$$ItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String deckId,
    String front,
    String back,
    double easeFactor,
    int interval,
    int repetitions,
    DateTime? nextReviewAt,
    DateTime? lastReviewedAt,
    String? book,
    int? chapter,
    int? verse,
  });
}

/// @nodoc
class __$$ItemImplCopyWithImpl<$Res>
    extends _$ItemCopyWithImpl<$Res, _$ItemImpl>
    implements _$$ItemImplCopyWith<$Res> {
  __$$ItemImplCopyWithImpl(_$ItemImpl _value, $Res Function(_$ItemImpl) _then)
    : super(_value, _then);

  /// Create a copy of Item
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? deckId = null,
    Object? front = null,
    Object? back = null,
    Object? easeFactor = null,
    Object? interval = null,
    Object? repetitions = null,
    Object? nextReviewAt = freezed,
    Object? lastReviewedAt = freezed,
    Object? book = freezed,
    Object? chapter = freezed,
    Object? verse = freezed,
  }) {
    return _then(
      _$ItemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        deckId: null == deckId
            ? _value.deckId
            : deckId // ignore: cast_nullable_to_non_nullable
                  as String,
        front: null == front
            ? _value.front
            : front // ignore: cast_nullable_to_non_nullable
                  as String,
        back: null == back
            ? _value.back
            : back // ignore: cast_nullable_to_non_nullable
                  as String,
        easeFactor: null == easeFactor
            ? _value.easeFactor
            : easeFactor // ignore: cast_nullable_to_non_nullable
                  as double,
        interval: null == interval
            ? _value.interval
            : interval // ignore: cast_nullable_to_non_nullable
                  as int,
        repetitions: null == repetitions
            ? _value.repetitions
            : repetitions // ignore: cast_nullable_to_non_nullable
                  as int,
        nextReviewAt: freezed == nextReviewAt
            ? _value.nextReviewAt
            : nextReviewAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastReviewedAt: freezed == lastReviewedAt
            ? _value.lastReviewedAt
            : lastReviewedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        book: freezed == book
            ? _value.book
            : book // ignore: cast_nullable_to_non_nullable
                  as String?,
        chapter: freezed == chapter
            ? _value.chapter
            : chapter // ignore: cast_nullable_to_non_nullable
                  as int?,
        verse: freezed == verse
            ? _value.verse
            : verse // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ItemImpl implements _Item {
  const _$ItemImpl({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    this.easeFactor = 2.5,
    this.interval = 0,
    this.repetitions = 0,
    this.nextReviewAt,
    this.lastReviewedAt,
    this.book,
    this.chapter,
    this.verse,
  });

  factory _$ItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItemImplFromJson(json);

  @override
  final String id;
  @override
  final String deckId;
  @override
  final String front;
  @override
  final String back;
  // SRS fields (SM-2)
  @override
  @JsonKey()
  final double easeFactor;
  @override
  @JsonKey()
  final int interval;
  @override
  @JsonKey()
  final int repetitions;
  @override
  final DateTime? nextReviewAt;
  @override
  final DateTime? lastReviewedAt;
  // Bible-specific metadata (null for non-bible decks)
  @override
  final String? book;
  @override
  final int? chapter;
  @override
  final int? verse;

  @override
  String toString() {
    return 'Item(id: $id, deckId: $deckId, front: $front, back: $back, easeFactor: $easeFactor, interval: $interval, repetitions: $repetitions, nextReviewAt: $nextReviewAt, lastReviewedAt: $lastReviewedAt, book: $book, chapter: $chapter, verse: $verse)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.deckId, deckId) || other.deckId == deckId) &&
            (identical(other.front, front) || other.front == front) &&
            (identical(other.back, back) || other.back == back) &&
            (identical(other.easeFactor, easeFactor) ||
                other.easeFactor == easeFactor) &&
            (identical(other.interval, interval) ||
                other.interval == interval) &&
            (identical(other.repetitions, repetitions) ||
                other.repetitions == repetitions) &&
            (identical(other.nextReviewAt, nextReviewAt) ||
                other.nextReviewAt == nextReviewAt) &&
            (identical(other.lastReviewedAt, lastReviewedAt) ||
                other.lastReviewedAt == lastReviewedAt) &&
            (identical(other.book, book) || other.book == book) &&
            (identical(other.chapter, chapter) || other.chapter == chapter) &&
            (identical(other.verse, verse) || other.verse == verse));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    deckId,
    front,
    back,
    easeFactor,
    interval,
    repetitions,
    nextReviewAt,
    lastReviewedAt,
    book,
    chapter,
    verse,
  );

  /// Create a copy of Item
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItemImplCopyWith<_$ItemImpl> get copyWith =>
      __$$ItemImplCopyWithImpl<_$ItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItemImplToJson(this);
  }
}

abstract class _Item implements Item {
  const factory _Item({
    required final String id,
    required final String deckId,
    required final String front,
    required final String back,
    final double easeFactor,
    final int interval,
    final int repetitions,
    final DateTime? nextReviewAt,
    final DateTime? lastReviewedAt,
    final String? book,
    final int? chapter,
    final int? verse,
  }) = _$ItemImpl;

  factory _Item.fromJson(Map<String, dynamic> json) = _$ItemImpl.fromJson;

  @override
  String get id;
  @override
  String get deckId;
  @override
  String get front;
  @override
  String get back; // SRS fields (SM-2)
  @override
  double get easeFactor;
  @override
  int get interval;
  @override
  int get repetitions;
  @override
  DateTime? get nextReviewAt;
  @override
  DateTime? get lastReviewedAt; // Bible-specific metadata (null for non-bible decks)
  @override
  String? get book;
  @override
  int? get chapter;
  @override
  int? get verse;

  /// Create a copy of Item
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItemImplCopyWith<_$ItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
