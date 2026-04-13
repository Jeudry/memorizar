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
    };

const _$DeckTypeEnumMap = {
  DeckType.bible: 'bible',
  DeckType.language: 'language',
  DeckType.general: 'general',
};
