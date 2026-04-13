// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'review_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ReviewSessionState {
  List<Item> get queue => throw _privateConstructorUsedError;
  int get currentIndex => throw _privateConstructorUsedError;
  bool get isRevealed => throw _privateConstructorUsedError;
  List<Item> get completed => throw _privateConstructorUsedError;
  bool get isFinished => throw _privateConstructorUsedError;

  /// Create a copy of ReviewSessionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReviewSessionStateCopyWith<ReviewSessionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReviewSessionStateCopyWith<$Res> {
  factory $ReviewSessionStateCopyWith(
    ReviewSessionState value,
    $Res Function(ReviewSessionState) then,
  ) = _$ReviewSessionStateCopyWithImpl<$Res, ReviewSessionState>;
  @useResult
  $Res call({
    List<Item> queue,
    int currentIndex,
    bool isRevealed,
    List<Item> completed,
    bool isFinished,
  });
}

/// @nodoc
class _$ReviewSessionStateCopyWithImpl<$Res, $Val extends ReviewSessionState>
    implements $ReviewSessionStateCopyWith<$Res> {
  _$ReviewSessionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReviewSessionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? queue = null,
    Object? currentIndex = null,
    Object? isRevealed = null,
    Object? completed = null,
    Object? isFinished = null,
  }) {
    return _then(
      _value.copyWith(
            queue: null == queue
                ? _value.queue
                : queue // ignore: cast_nullable_to_non_nullable
                      as List<Item>,
            currentIndex: null == currentIndex
                ? _value.currentIndex
                : currentIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            isRevealed: null == isRevealed
                ? _value.isRevealed
                : isRevealed // ignore: cast_nullable_to_non_nullable
                      as bool,
            completed: null == completed
                ? _value.completed
                : completed // ignore: cast_nullable_to_non_nullable
                      as List<Item>,
            isFinished: null == isFinished
                ? _value.isFinished
                : isFinished // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReviewSessionStateImplCopyWith<$Res>
    implements $ReviewSessionStateCopyWith<$Res> {
  factory _$$ReviewSessionStateImplCopyWith(
    _$ReviewSessionStateImpl value,
    $Res Function(_$ReviewSessionStateImpl) then,
  ) = __$$ReviewSessionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<Item> queue,
    int currentIndex,
    bool isRevealed,
    List<Item> completed,
    bool isFinished,
  });
}

/// @nodoc
class __$$ReviewSessionStateImplCopyWithImpl<$Res>
    extends _$ReviewSessionStateCopyWithImpl<$Res, _$ReviewSessionStateImpl>
    implements _$$ReviewSessionStateImplCopyWith<$Res> {
  __$$ReviewSessionStateImplCopyWithImpl(
    _$ReviewSessionStateImpl _value,
    $Res Function(_$ReviewSessionStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReviewSessionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? queue = null,
    Object? currentIndex = null,
    Object? isRevealed = null,
    Object? completed = null,
    Object? isFinished = null,
  }) {
    return _then(
      _$ReviewSessionStateImpl(
        queue: null == queue
            ? _value._queue
            : queue // ignore: cast_nullable_to_non_nullable
                  as List<Item>,
        currentIndex: null == currentIndex
            ? _value.currentIndex
            : currentIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        isRevealed: null == isRevealed
            ? _value.isRevealed
            : isRevealed // ignore: cast_nullable_to_non_nullable
                  as bool,
        completed: null == completed
            ? _value._completed
            : completed // ignore: cast_nullable_to_non_nullable
                  as List<Item>,
        isFinished: null == isFinished
            ? _value.isFinished
            : isFinished // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$ReviewSessionStateImpl implements _ReviewSessionState {
  const _$ReviewSessionStateImpl({
    required final List<Item> queue,
    required this.currentIndex,
    required this.isRevealed,
    required final List<Item> completed,
    required this.isFinished,
  }) : _queue = queue,
       _completed = completed;

  final List<Item> _queue;
  @override
  List<Item> get queue {
    if (_queue is EqualUnmodifiableListView) return _queue;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_queue);
  }

  @override
  final int currentIndex;
  @override
  final bool isRevealed;
  final List<Item> _completed;
  @override
  List<Item> get completed {
    if (_completed is EqualUnmodifiableListView) return _completed;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_completed);
  }

  @override
  final bool isFinished;

  @override
  String toString() {
    return 'ReviewSessionState(queue: $queue, currentIndex: $currentIndex, isRevealed: $isRevealed, completed: $completed, isFinished: $isFinished)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReviewSessionStateImpl &&
            const DeepCollectionEquality().equals(other._queue, _queue) &&
            (identical(other.currentIndex, currentIndex) ||
                other.currentIndex == currentIndex) &&
            (identical(other.isRevealed, isRevealed) ||
                other.isRevealed == isRevealed) &&
            const DeepCollectionEquality().equals(
              other._completed,
              _completed,
            ) &&
            (identical(other.isFinished, isFinished) ||
                other.isFinished == isFinished));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_queue),
    currentIndex,
    isRevealed,
    const DeepCollectionEquality().hash(_completed),
    isFinished,
  );

  /// Create a copy of ReviewSessionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReviewSessionStateImplCopyWith<_$ReviewSessionStateImpl> get copyWith =>
      __$$ReviewSessionStateImplCopyWithImpl<_$ReviewSessionStateImpl>(
        this,
        _$identity,
      );
}

abstract class _ReviewSessionState implements ReviewSessionState {
  const factory _ReviewSessionState({
    required final List<Item> queue,
    required final int currentIndex,
    required final bool isRevealed,
    required final List<Item> completed,
    required final bool isFinished,
  }) = _$ReviewSessionStateImpl;

  @override
  List<Item> get queue;
  @override
  int get currentIndex;
  @override
  bool get isRevealed;
  @override
  List<Item> get completed;
  @override
  bool get isFinished;

  /// Create a copy of ReviewSessionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReviewSessionStateImplCopyWith<_$ReviewSessionStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
