// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'deck.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Deck _$DeckFromJson(Map<String, dynamic> json) {
  return _Deck.fromJson(json);
}

/// @nodoc
mixin _$Deck {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  DeckType get type => throw _privateConstructorUsedError;
  int get accentColorIndex => throw _privateConstructorUsedError;
  int get totalItems => throw _privateConstructorUsedError;
  int get dueToday => throw _privateConstructorUsedError;
  int get learned => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get emoji => throw _privateConstructorUsedError; // SRS breakdown
  int get newCount => throw _privateConstructorUsedError;
  int get learningCount => throw _privateConstructorUsedError;
  int get reviewCount => throw _privateConstructorUsedError; // Retention stats
  int get totalReviews => throw _privateConstructorUsedError;
  double get averageEase => throw _privateConstructorUsedError;

  /// Serializes this Deck to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Deck
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeckCopyWith<Deck> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeckCopyWith<$Res> {
  factory $DeckCopyWith(Deck value, $Res Function(Deck) then) =
      _$DeckCopyWithImpl<$Res, Deck>;
  @useResult
  $Res call({
    String id,
    String name,
    String description,
    DeckType type,
    int accentColorIndex,
    int totalItems,
    int dueToday,
    int learned,
    DateTime createdAt,
    String? emoji,
    int newCount,
    int learningCount,
    int reviewCount,
    int totalReviews,
    double averageEase,
  });
}

/// @nodoc
class _$DeckCopyWithImpl<$Res, $Val extends Deck>
    implements $DeckCopyWith<$Res> {
  _$DeckCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Deck
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? type = null,
    Object? accentColorIndex = null,
    Object? totalItems = null,
    Object? dueToday = null,
    Object? learned = null,
    Object? createdAt = null,
    Object? emoji = freezed,
    Object? newCount = null,
    Object? learningCount = null,
    Object? reviewCount = null,
    Object? totalReviews = null,
    Object? averageEase = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as DeckType,
            accentColorIndex: null == accentColorIndex
                ? _value.accentColorIndex
                : accentColorIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            totalItems: null == totalItems
                ? _value.totalItems
                : totalItems // ignore: cast_nullable_to_non_nullable
                      as int,
            dueToday: null == dueToday
                ? _value.dueToday
                : dueToday // ignore: cast_nullable_to_non_nullable
                      as int,
            learned: null == learned
                ? _value.learned
                : learned // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            emoji: freezed == emoji
                ? _value.emoji
                : emoji // ignore: cast_nullable_to_non_nullable
                      as String?,
            newCount: null == newCount
                ? _value.newCount
                : newCount // ignore: cast_nullable_to_non_nullable
                      as int,
            learningCount: null == learningCount
                ? _value.learningCount
                : learningCount // ignore: cast_nullable_to_non_nullable
                      as int,
            reviewCount: null == reviewCount
                ? _value.reviewCount
                : reviewCount // ignore: cast_nullable_to_non_nullable
                      as int,
            totalReviews: null == totalReviews
                ? _value.totalReviews
                : totalReviews // ignore: cast_nullable_to_non_nullable
                      as int,
            averageEase: null == averageEase
                ? _value.averageEase
                : averageEase // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DeckImplCopyWith<$Res> implements $DeckCopyWith<$Res> {
  factory _$$DeckImplCopyWith(
    _$DeckImpl value,
    $Res Function(_$DeckImpl) then,
  ) = __$$DeckImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String description,
    DeckType type,
    int accentColorIndex,
    int totalItems,
    int dueToday,
    int learned,
    DateTime createdAt,
    String? emoji,
    int newCount,
    int learningCount,
    int reviewCount,
    int totalReviews,
    double averageEase,
  });
}

/// @nodoc
class __$$DeckImplCopyWithImpl<$Res>
    extends _$DeckCopyWithImpl<$Res, _$DeckImpl>
    implements _$$DeckImplCopyWith<$Res> {
  __$$DeckImplCopyWithImpl(_$DeckImpl _value, $Res Function(_$DeckImpl) _then)
    : super(_value, _then);

  /// Create a copy of Deck
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? type = null,
    Object? accentColorIndex = null,
    Object? totalItems = null,
    Object? dueToday = null,
    Object? learned = null,
    Object? createdAt = null,
    Object? emoji = freezed,
    Object? newCount = null,
    Object? learningCount = null,
    Object? reviewCount = null,
    Object? totalReviews = null,
    Object? averageEase = null,
  }) {
    return _then(
      _$DeckImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as DeckType,
        accentColorIndex: null == accentColorIndex
            ? _value.accentColorIndex
            : accentColorIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        totalItems: null == totalItems
            ? _value.totalItems
            : totalItems // ignore: cast_nullable_to_non_nullable
                  as int,
        dueToday: null == dueToday
            ? _value.dueToday
            : dueToday // ignore: cast_nullable_to_non_nullable
                  as int,
        learned: null == learned
            ? _value.learned
            : learned // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        emoji: freezed == emoji
            ? _value.emoji
            : emoji // ignore: cast_nullable_to_non_nullable
                  as String?,
        newCount: null == newCount
            ? _value.newCount
            : newCount // ignore: cast_nullable_to_non_nullable
                  as int,
        learningCount: null == learningCount
            ? _value.learningCount
            : learningCount // ignore: cast_nullable_to_non_nullable
                  as int,
        reviewCount: null == reviewCount
            ? _value.reviewCount
            : reviewCount // ignore: cast_nullable_to_non_nullable
                  as int,
        totalReviews: null == totalReviews
            ? _value.totalReviews
            : totalReviews // ignore: cast_nullable_to_non_nullable
                  as int,
        averageEase: null == averageEase
            ? _value.averageEase
            : averageEase // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DeckImpl implements _Deck {
  const _$DeckImpl({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.accentColorIndex,
    required this.totalItems,
    required this.dueToday,
    required this.learned,
    required this.createdAt,
    this.emoji,
    this.newCount = 0,
    this.learningCount = 0,
    this.reviewCount = 0,
    this.totalReviews = 0,
    this.averageEase = 0.0,
  });

  factory _$DeckImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeckImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final DeckType type;
  @override
  final int accentColorIndex;
  @override
  final int totalItems;
  @override
  final int dueToday;
  @override
  final int learned;
  @override
  final DateTime createdAt;
  @override
  final String? emoji;
  // SRS breakdown
  @override
  @JsonKey()
  final int newCount;
  @override
  @JsonKey()
  final int learningCount;
  @override
  @JsonKey()
  final int reviewCount;
  // Retention stats
  @override
  @JsonKey()
  final int totalReviews;
  @override
  @JsonKey()
  final double averageEase;

  @override
  String toString() {
    return 'Deck(id: $id, name: $name, description: $description, type: $type, accentColorIndex: $accentColorIndex, totalItems: $totalItems, dueToday: $dueToday, learned: $learned, createdAt: $createdAt, emoji: $emoji, newCount: $newCount, learningCount: $learningCount, reviewCount: $reviewCount, totalReviews: $totalReviews, averageEase: $averageEase)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeckImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.accentColorIndex, accentColorIndex) ||
                other.accentColorIndex == accentColorIndex) &&
            (identical(other.totalItems, totalItems) ||
                other.totalItems == totalItems) &&
            (identical(other.dueToday, dueToday) ||
                other.dueToday == dueToday) &&
            (identical(other.learned, learned) || other.learned == learned) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.emoji, emoji) || other.emoji == emoji) &&
            (identical(other.newCount, newCount) ||
                other.newCount == newCount) &&
            (identical(other.learningCount, learningCount) ||
                other.learningCount == learningCount) &&
            (identical(other.reviewCount, reviewCount) ||
                other.reviewCount == reviewCount) &&
            (identical(other.totalReviews, totalReviews) ||
                other.totalReviews == totalReviews) &&
            (identical(other.averageEase, averageEase) ||
                other.averageEase == averageEase));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    description,
    type,
    accentColorIndex,
    totalItems,
    dueToday,
    learned,
    createdAt,
    emoji,
    newCount,
    learningCount,
    reviewCount,
    totalReviews,
    averageEase,
  );

  /// Create a copy of Deck
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeckImplCopyWith<_$DeckImpl> get copyWith =>
      __$$DeckImplCopyWithImpl<_$DeckImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DeckImplToJson(this);
  }
}

abstract class _Deck implements Deck {
  const factory _Deck({
    required final String id,
    required final String name,
    required final String description,
    required final DeckType type,
    required final int accentColorIndex,
    required final int totalItems,
    required final int dueToday,
    required final int learned,
    required final DateTime createdAt,
    final String? emoji,
    final int newCount,
    final int learningCount,
    final int reviewCount,
    final int totalReviews,
    final double averageEase,
  }) = _$DeckImpl;

  factory _Deck.fromJson(Map<String, dynamic> json) = _$DeckImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;
  @override
  DeckType get type;
  @override
  int get accentColorIndex;
  @override
  int get totalItems;
  @override
  int get dueToday;
  @override
  int get learned;
  @override
  DateTime get createdAt;
  @override
  String? get emoji; // SRS breakdown
  @override
  int get newCount;
  @override
  int get learningCount;
  @override
  int get reviewCount; // Retention stats
  @override
  int get totalReviews;
  @override
  double get averageEase;

  /// Create a copy of Deck
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeckImplCopyWith<_$DeckImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
