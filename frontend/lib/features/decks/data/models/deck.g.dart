// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deck.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DeckImpl _$$DeckImplFromJson(Map<String, dynamic> json) => _$DeckImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  type: $enumDecode(_$DeckTypeEnumMap, json['type']),
  accentColorIndex: (json['accentColorIndex'] as num).toInt(),
  totalItems: (json['totalItems'] as num).toInt(),
  dueToday: (json['dueToday'] as num).toInt(),
  learned: (json['learned'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  emoji: json['emoji'] as String?,
  newCount: (json['newCount'] as num?)?.toInt() ?? 0,
  learningCount: (json['learningCount'] as num?)?.toInt() ?? 0,
  reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
  totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
  averageEase: (json['averageEase'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$$DeckImplToJson(_$DeckImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': _$DeckTypeEnumMap[instance.type]!,
      'accentColorIndex': instance.accentColorIndex,
      'totalItems': instance.totalItems,
      'dueToday': instance.dueToday,
      'learned': instance.learned,
      'createdAt': instance.createdAt.toIso8601String(),
      'emoji': instance.emoji,
      'newCount': instance.newCount,
      'learningCount': instance.learningCount,
      'reviewCount': instance.reviewCount,
      'totalReviews': instance.totalReviews,
      'averageEase': instance.averageEase,
    };

const _$DeckTypeEnumMap = {
  DeckType.bible: 'bible',
  DeckType.language: 'language',
  DeckType.general: 'general',
};
