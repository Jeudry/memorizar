// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ItemImpl _$$ItemImplFromJson(Map<String, dynamic> json) => _$ItemImpl(
  id: json['id'] as String,
  deckId: json['deckId'] as String,
  front: json['front'] as String,
  back: json['back'] as String,
  easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
  interval: (json['interval'] as num?)?.toInt() ?? 0,
  repetitions: (json['repetitions'] as num?)?.toInt() ?? 0,
  nextReviewAt: json['nextReviewAt'] == null
      ? null
      : DateTime.parse(json['nextReviewAt'] as String),
  lastReviewedAt: json['lastReviewedAt'] == null
      ? null
      : DateTime.parse(json['lastReviewedAt'] as String),
  book: json['book'] as String?,
  chapter: (json['chapter'] as num?)?.toInt(),
  verse: (json['verse'] as num?)?.toInt(),
);

Map<String, dynamic> _$$ItemImplToJson(_$ItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deckId': instance.deckId,
      'front': instance.front,
      'back': instance.back,
      'easeFactor': instance.easeFactor,
      'interval': instance.interval,
      'repetitions': instance.repetitions,
      'nextReviewAt': instance.nextReviewAt?.toIso8601String(),
      'lastReviewedAt': instance.lastReviewedAt?.toIso8601String(),
      'book': instance.book,
      'chapter': instance.chapter,
      'verse': instance.verse,
    };
