// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DecksTable extends Decks with TableInfo<$DecksTable, Deck> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DecksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accentColorIndexMeta = const VerificationMeta(
    'accentColorIndex',
  );
  @override
  late final GeneratedColumn<int> accentColorIndex = GeneratedColumn<int>(
    'accent_color_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    type,
    accentColorIndex,
    emoji,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'decks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Deck> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('accent_color_index')) {
      context.handle(
        _accentColorIndexMeta,
        accentColorIndex.isAcceptableOrUnknown(
          data['accent_color_index']!,
          _accentColorIndexMeta,
        ),
      );
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Deck map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Deck(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      accentColorIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}accent_color_index'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DecksTable createAlias(String alias) {
    return $DecksTable(attachedDatabase, alias);
  }
}

class Deck extends DataClass implements Insertable<Deck> {
  final String id;
  final String name;
  final String description;
  final String type;
  final int accentColorIndex;
  final String? emoji;
  final DateTime createdAt;
  const Deck({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.accentColorIndex,
    this.emoji,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['type'] = Variable<String>(type);
    map['accent_color_index'] = Variable<int>(accentColorIndex);
    if (!nullToAbsent || emoji != null) {
      map['emoji'] = Variable<String>(emoji);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DecksCompanion toCompanion(bool nullToAbsent) {
    return DecksCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      type: Value(type),
      accentColorIndex: Value(accentColorIndex),
      emoji: emoji == null && nullToAbsent
          ? const Value.absent()
          : Value(emoji),
      createdAt: Value(createdAt),
    );
  }

  factory Deck.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Deck(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      type: serializer.fromJson<String>(json['type']),
      accentColorIndex: serializer.fromJson<int>(json['accentColorIndex']),
      emoji: serializer.fromJson<String?>(json['emoji']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'type': serializer.toJson<String>(type),
      'accentColorIndex': serializer.toJson<int>(accentColorIndex),
      'emoji': serializer.toJson<String?>(emoji),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Deck copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    int? accentColorIndex,
    Value<String?> emoji = const Value.absent(),
    DateTime? createdAt,
  }) => Deck(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    type: type ?? this.type,
    accentColorIndex: accentColorIndex ?? this.accentColorIndex,
    emoji: emoji.present ? emoji.value : this.emoji,
    createdAt: createdAt ?? this.createdAt,
  );
  Deck copyWithCompanion(DecksCompanion data) {
    return Deck(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      type: data.type.present ? data.type.value : this.type,
      accentColorIndex: data.accentColorIndex.present
          ? data.accentColorIndex.value
          : this.accentColorIndex,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Deck(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('accentColorIndex: $accentColorIndex, ')
          ..write('emoji: $emoji, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    type,
    accentColorIndex,
    emoji,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Deck &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.type == this.type &&
          other.accentColorIndex == this.accentColorIndex &&
          other.emoji == this.emoji &&
          other.createdAt == this.createdAt);
}

class DecksCompanion extends UpdateCompanion<Deck> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> description;
  final Value<String> type;
  final Value<int> accentColorIndex;
  final Value<String?> emoji;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DecksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.accentColorIndex = const Value.absent(),
    this.emoji = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DecksCompanion.insert({
    required String id,
    required String name,
    required String description,
    required String type,
    this.accentColorIndex = const Value.absent(),
    this.emoji = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       description = Value(description),
       type = Value(type);
  static Insertable<Deck> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? type,
    Expression<int>? accentColorIndex,
    Expression<String>? emoji,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (accentColorIndex != null) 'accent_color_index': accentColorIndex,
      if (emoji != null) 'emoji': emoji,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DecksCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? description,
    Value<String>? type,
    Value<int>? accentColorIndex,
    Value<String?>? emoji,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return DecksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      accentColorIndex: accentColorIndex ?? this.accentColorIndex,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (accentColorIndex.present) {
      map['accent_color_index'] = Variable<int>(accentColorIndex.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DecksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('accentColorIndex: $accentColorIndex, ')
          ..write('emoji: $emoji, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemsTable extends Items with TableInfo<$ItemsTable, Item> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<String> deckId = GeneratedColumn<String>(
    'deck_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES decks (id)',
    ),
  );
  static const VerificationMeta _frontMeta = const VerificationMeta('front');
  @override
  late final GeneratedColumn<String> front = GeneratedColumn<String>(
    'front',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _backMeta = const VerificationMeta('back');
  @override
  late final GeneratedColumn<String> back = GeneratedColumn<String>(
    'back',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _easeFactorMeta = const VerificationMeta(
    'easeFactor',
  );
  @override
  late final GeneratedColumn<double> easeFactor = GeneratedColumn<double>(
    'ease_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.5),
  );
  static const VerificationMeta _intervalMeta = const VerificationMeta(
    'interval',
  );
  @override
  late final GeneratedColumn<int> interval = GeneratedColumn<int>(
    'interval',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _repetitionsMeta = const VerificationMeta(
    'repetitions',
  );
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
    'repetitions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextReviewAtMeta = const VerificationMeta(
    'nextReviewAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextReviewAt = GeneratedColumn<DateTime>(
    'next_review_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastReviewedAtMeta = const VerificationMeta(
    'lastReviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewedAt =
      GeneratedColumn<DateTime>(
        'last_reviewed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _bookMeta = const VerificationMeta('book');
  @override
  late final GeneratedColumn<String> book = GeneratedColumn<String>(
    'book',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  @override
  late final GeneratedColumn<int> chapter = GeneratedColumn<int>(
    'chapter',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _verseMeta = const VerificationMeta('verse');
  @override
  late final GeneratedColumn<int> verse = GeneratedColumn<int>(
    'verse',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
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
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(
    Insertable<Item> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('deck_id')) {
      context.handle(
        _deckIdMeta,
        deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('front')) {
      context.handle(
        _frontMeta,
        front.isAcceptableOrUnknown(data['front']!, _frontMeta),
      );
    } else if (isInserting) {
      context.missing(_frontMeta);
    }
    if (data.containsKey('back')) {
      context.handle(
        _backMeta,
        back.isAcceptableOrUnknown(data['back']!, _backMeta),
      );
    } else if (isInserting) {
      context.missing(_backMeta);
    }
    if (data.containsKey('ease_factor')) {
      context.handle(
        _easeFactorMeta,
        easeFactor.isAcceptableOrUnknown(data['ease_factor']!, _easeFactorMeta),
      );
    }
    if (data.containsKey('interval')) {
      context.handle(
        _intervalMeta,
        interval.isAcceptableOrUnknown(data['interval']!, _intervalMeta),
      );
    }
    if (data.containsKey('repetitions')) {
      context.handle(
        _repetitionsMeta,
        repetitions.isAcceptableOrUnknown(
          data['repetitions']!,
          _repetitionsMeta,
        ),
      );
    }
    if (data.containsKey('next_review_at')) {
      context.handle(
        _nextReviewAtMeta,
        nextReviewAt.isAcceptableOrUnknown(
          data['next_review_at']!,
          _nextReviewAtMeta,
        ),
      );
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
        _lastReviewedAtMeta,
        lastReviewedAt.isAcceptableOrUnknown(
          data['last_reviewed_at']!,
          _lastReviewedAtMeta,
        ),
      );
    }
    if (data.containsKey('book')) {
      context.handle(
        _bookMeta,
        book.isAcceptableOrUnknown(data['book']!, _bookMeta),
      );
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    }
    if (data.containsKey('verse')) {
      context.handle(
        _verseMeta,
        verse.isAcceptableOrUnknown(data['verse']!, _verseMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Item map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Item(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      deckId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deck_id'],
      )!,
      front: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}front'],
      )!,
      back: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}back'],
      )!,
      easeFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ease_factor'],
      )!,
      interval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval'],
      )!,
      repetitions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetitions'],
      )!,
      nextReviewAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_review_at'],
      ),
      lastReviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_reviewed_at'],
      ),
      book: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book'],
      ),
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter'],
      ),
      verse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}verse'],
      ),
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }
}

class Item extends DataClass implements Insertable<Item> {
  final String id;
  final String deckId;
  final String front;
  final String back;
  final double easeFactor;
  final int interval;
  final int repetitions;
  final DateTime? nextReviewAt;
  final DateTime? lastReviewedAt;
  final String? book;
  final int? chapter;
  final int? verse;
  const Item({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.easeFactor,
    required this.interval,
    required this.repetitions,
    this.nextReviewAt,
    this.lastReviewedAt,
    this.book,
    this.chapter,
    this.verse,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['deck_id'] = Variable<String>(deckId);
    map['front'] = Variable<String>(front);
    map['back'] = Variable<String>(back);
    map['ease_factor'] = Variable<double>(easeFactor);
    map['interval'] = Variable<int>(interval);
    map['repetitions'] = Variable<int>(repetitions);
    if (!nullToAbsent || nextReviewAt != null) {
      map['next_review_at'] = Variable<DateTime>(nextReviewAt);
    }
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt);
    }
    if (!nullToAbsent || book != null) {
      map['book'] = Variable<String>(book);
    }
    if (!nullToAbsent || chapter != null) {
      map['chapter'] = Variable<int>(chapter);
    }
    if (!nullToAbsent || verse != null) {
      map['verse'] = Variable<int>(verse);
    }
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      id: Value(id),
      deckId: Value(deckId),
      front: Value(front),
      back: Value(back),
      easeFactor: Value(easeFactor),
      interval: Value(interval),
      repetitions: Value(repetitions),
      nextReviewAt: nextReviewAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextReviewAt),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
      book: book == null && nullToAbsent ? const Value.absent() : Value(book),
      chapter: chapter == null && nullToAbsent
          ? const Value.absent()
          : Value(chapter),
      verse: verse == null && nullToAbsent
          ? const Value.absent()
          : Value(verse),
    );
  }

  factory Item.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Item(
      id: serializer.fromJson<String>(json['id']),
      deckId: serializer.fromJson<String>(json['deckId']),
      front: serializer.fromJson<String>(json['front']),
      back: serializer.fromJson<String>(json['back']),
      easeFactor: serializer.fromJson<double>(json['easeFactor']),
      interval: serializer.fromJson<int>(json['interval']),
      repetitions: serializer.fromJson<int>(json['repetitions']),
      nextReviewAt: serializer.fromJson<DateTime?>(json['nextReviewAt']),
      lastReviewedAt: serializer.fromJson<DateTime?>(json['lastReviewedAt']),
      book: serializer.fromJson<String?>(json['book']),
      chapter: serializer.fromJson<int?>(json['chapter']),
      verse: serializer.fromJson<int?>(json['verse']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'deckId': serializer.toJson<String>(deckId),
      'front': serializer.toJson<String>(front),
      'back': serializer.toJson<String>(back),
      'easeFactor': serializer.toJson<double>(easeFactor),
      'interval': serializer.toJson<int>(interval),
      'repetitions': serializer.toJson<int>(repetitions),
      'nextReviewAt': serializer.toJson<DateTime?>(nextReviewAt),
      'lastReviewedAt': serializer.toJson<DateTime?>(lastReviewedAt),
      'book': serializer.toJson<String?>(book),
      'chapter': serializer.toJson<int?>(chapter),
      'verse': serializer.toJson<int?>(verse),
    };
  }

  Item copyWith({
    String? id,
    String? deckId,
    String? front,
    String? back,
    double? easeFactor,
    int? interval,
    int? repetitions,
    Value<DateTime?> nextReviewAt = const Value.absent(),
    Value<DateTime?> lastReviewedAt = const Value.absent(),
    Value<String?> book = const Value.absent(),
    Value<int?> chapter = const Value.absent(),
    Value<int?> verse = const Value.absent(),
  }) => Item(
    id: id ?? this.id,
    deckId: deckId ?? this.deckId,
    front: front ?? this.front,
    back: back ?? this.back,
    easeFactor: easeFactor ?? this.easeFactor,
    interval: interval ?? this.interval,
    repetitions: repetitions ?? this.repetitions,
    nextReviewAt: nextReviewAt.present ? nextReviewAt.value : this.nextReviewAt,
    lastReviewedAt: lastReviewedAt.present
        ? lastReviewedAt.value
        : this.lastReviewedAt,
    book: book.present ? book.value : this.book,
    chapter: chapter.present ? chapter.value : this.chapter,
    verse: verse.present ? verse.value : this.verse,
  );
  Item copyWithCompanion(ItemsCompanion data) {
    return Item(
      id: data.id.present ? data.id.value : this.id,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      front: data.front.present ? data.front.value : this.front,
      back: data.back.present ? data.back.value : this.back,
      easeFactor: data.easeFactor.present
          ? data.easeFactor.value
          : this.easeFactor,
      interval: data.interval.present ? data.interval.value : this.interval,
      repetitions: data.repetitions.present
          ? data.repetitions.value
          : this.repetitions,
      nextReviewAt: data.nextReviewAt.present
          ? data.nextReviewAt.value
          : this.nextReviewAt,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
      book: data.book.present ? data.book.value : this.book,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      verse: data.verse.present ? data.verse.value : this.verse,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Item(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('front: $front, ')
          ..write('back: $back, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('interval: $interval, ')
          ..write('repetitions: $repetitions, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('book: $book, ')
          ..write('chapter: $chapter, ')
          ..write('verse: $verse')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Item &&
          other.id == this.id &&
          other.deckId == this.deckId &&
          other.front == this.front &&
          other.back == this.back &&
          other.easeFactor == this.easeFactor &&
          other.interval == this.interval &&
          other.repetitions == this.repetitions &&
          other.nextReviewAt == this.nextReviewAt &&
          other.lastReviewedAt == this.lastReviewedAt &&
          other.book == this.book &&
          other.chapter == this.chapter &&
          other.verse == this.verse);
}

class ItemsCompanion extends UpdateCompanion<Item> {
  final Value<String> id;
  final Value<String> deckId;
  final Value<String> front;
  final Value<String> back;
  final Value<double> easeFactor;
  final Value<int> interval;
  final Value<int> repetitions;
  final Value<DateTime?> nextReviewAt;
  final Value<DateTime?> lastReviewedAt;
  final Value<String?> book;
  final Value<int?> chapter;
  final Value<int?> verse;
  final Value<int> rowid;
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.deckId = const Value.absent(),
    this.front = const Value.absent(),
    this.back = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.interval = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.book = const Value.absent(),
    this.chapter = const Value.absent(),
    this.verse = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemsCompanion.insert({
    required String id,
    required String deckId,
    required String front,
    required String back,
    this.easeFactor = const Value.absent(),
    this.interval = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.book = const Value.absent(),
    this.chapter = const Value.absent(),
    this.verse = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       deckId = Value(deckId),
       front = Value(front),
       back = Value(back);
  static Insertable<Item> custom({
    Expression<String>? id,
    Expression<String>? deckId,
    Expression<String>? front,
    Expression<String>? back,
    Expression<double>? easeFactor,
    Expression<int>? interval,
    Expression<int>? repetitions,
    Expression<DateTime>? nextReviewAt,
    Expression<DateTime>? lastReviewedAt,
    Expression<String>? book,
    Expression<int>? chapter,
    Expression<int>? verse,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deckId != null) 'deck_id': deckId,
      if (front != null) 'front': front,
      if (back != null) 'back': back,
      if (easeFactor != null) 'ease_factor': easeFactor,
      if (interval != null) 'interval': interval,
      if (repetitions != null) 'repetitions': repetitions,
      if (nextReviewAt != null) 'next_review_at': nextReviewAt,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
      if (book != null) 'book': book,
      if (chapter != null) 'chapter': chapter,
      if (verse != null) 'verse': verse,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? deckId,
    Value<String>? front,
    Value<String>? back,
    Value<double>? easeFactor,
    Value<int>? interval,
    Value<int>? repetitions,
    Value<DateTime?>? nextReviewAt,
    Value<DateTime?>? lastReviewedAt,
    Value<String?>? book,
    Value<int?>? chapter,
    Value<int?>? verse,
    Value<int>? rowid,
  }) {
    return ItemsCompanion(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
      repetitions: repetitions ?? this.repetitions,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deckId.present) {
      map['deck_id'] = Variable<String>(deckId.value);
    }
    if (front.present) {
      map['front'] = Variable<String>(front.value);
    }
    if (back.present) {
      map['back'] = Variable<String>(back.value);
    }
    if (easeFactor.present) {
      map['ease_factor'] = Variable<double>(easeFactor.value);
    }
    if (interval.present) {
      map['interval'] = Variable<int>(interval.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (nextReviewAt.present) {
      map['next_review_at'] = Variable<DateTime>(nextReviewAt.value);
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt.value);
    }
    if (book.present) {
      map['book'] = Variable<String>(book.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<int>(chapter.value);
    }
    if (verse.present) {
      map['verse'] = Variable<int>(verse.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('front: $front, ')
          ..write('back: $back, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('interval: $interval, ')
          ..write('repetitions: $repetitions, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('book: $book, ')
          ..write('chapter: $chapter, ')
          ..write('verse: $verse, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewLogsTable extends ReviewLogs
    with TableInfo<$ReviewLogsTable, ReviewLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<String> deckId = GeneratedColumn<String>(
    'deck_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES decks (id)',
    ),
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<String> rating = GeneratedColumn<String>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalBeforeMeta = const VerificationMeta(
    'intervalBefore',
  );
  @override
  late final GeneratedColumn<int> intervalBefore = GeneratedColumn<int>(
    'interval_before',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalAfterMeta = const VerificationMeta(
    'intervalAfter',
  );
  @override
  late final GeneratedColumn<int> intervalAfter = GeneratedColumn<int>(
    'interval_after',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    deckId,
    rating,
    intervalBefore,
    intervalAfter,
    reviewedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('deck_id')) {
      context.handle(
        _deckIdMeta,
        deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('interval_before')) {
      context.handle(
        _intervalBeforeMeta,
        intervalBefore.isAcceptableOrUnknown(
          data['interval_before']!,
          _intervalBeforeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intervalBeforeMeta);
    }
    if (data.containsKey('interval_after')) {
      context.handle(
        _intervalAfterMeta,
        intervalAfter.isAcceptableOrUnknown(
          data['interval_after']!,
          _intervalAfterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intervalAfterMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      deckId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deck_id'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rating'],
      )!,
      intervalBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_before'],
      )!,
      intervalAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_after'],
      )!,
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reviewed_at'],
      )!,
    );
  }

  @override
  $ReviewLogsTable createAlias(String alias) {
    return $ReviewLogsTable(attachedDatabase, alias);
  }
}

class ReviewLog extends DataClass implements Insertable<ReviewLog> {
  final int id;
  final String itemId;
  final String deckId;
  final String rating;
  final int intervalBefore;
  final int intervalAfter;
  final DateTime reviewedAt;
  const ReviewLog({
    required this.id,
    required this.itemId,
    required this.deckId,
    required this.rating,
    required this.intervalBefore,
    required this.intervalAfter,
    required this.reviewedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<String>(itemId);
    map['deck_id'] = Variable<String>(deckId);
    map['rating'] = Variable<String>(rating);
    map['interval_before'] = Variable<int>(intervalBefore);
    map['interval_after'] = Variable<int>(intervalAfter);
    map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    return map;
  }

  ReviewLogsCompanion toCompanion(bool nullToAbsent) {
    return ReviewLogsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      deckId: Value(deckId),
      rating: Value(rating),
      intervalBefore: Value(intervalBefore),
      intervalAfter: Value(intervalAfter),
      reviewedAt: Value(reviewedAt),
    );
  }

  factory ReviewLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewLog(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      deckId: serializer.fromJson<String>(json['deckId']),
      rating: serializer.fromJson<String>(json['rating']),
      intervalBefore: serializer.fromJson<int>(json['intervalBefore']),
      intervalAfter: serializer.fromJson<int>(json['intervalAfter']),
      reviewedAt: serializer.fromJson<DateTime>(json['reviewedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<String>(itemId),
      'deckId': serializer.toJson<String>(deckId),
      'rating': serializer.toJson<String>(rating),
      'intervalBefore': serializer.toJson<int>(intervalBefore),
      'intervalAfter': serializer.toJson<int>(intervalAfter),
      'reviewedAt': serializer.toJson<DateTime>(reviewedAt),
    };
  }

  ReviewLog copyWith({
    int? id,
    String? itemId,
    String? deckId,
    String? rating,
    int? intervalBefore,
    int? intervalAfter,
    DateTime? reviewedAt,
  }) => ReviewLog(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    deckId: deckId ?? this.deckId,
    rating: rating ?? this.rating,
    intervalBefore: intervalBefore ?? this.intervalBefore,
    intervalAfter: intervalAfter ?? this.intervalAfter,
    reviewedAt: reviewedAt ?? this.reviewedAt,
  );
  ReviewLog copyWithCompanion(ReviewLogsCompanion data) {
    return ReviewLog(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      rating: data.rating.present ? data.rating.value : this.rating,
      intervalBefore: data.intervalBefore.present
          ? data.intervalBefore.value
          : this.intervalBefore,
      intervalAfter: data.intervalAfter.present
          ? data.intervalAfter.value
          : this.intervalAfter,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLog(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('deckId: $deckId, ')
          ..write('rating: $rating, ')
          ..write('intervalBefore: $intervalBefore, ')
          ..write('intervalAfter: $intervalAfter, ')
          ..write('reviewedAt: $reviewedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    deckId,
    rating,
    intervalBefore,
    intervalAfter,
    reviewedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewLog &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.deckId == this.deckId &&
          other.rating == this.rating &&
          other.intervalBefore == this.intervalBefore &&
          other.intervalAfter == this.intervalAfter &&
          other.reviewedAt == this.reviewedAt);
}

class ReviewLogsCompanion extends UpdateCompanion<ReviewLog> {
  final Value<int> id;
  final Value<String> itemId;
  final Value<String> deckId;
  final Value<String> rating;
  final Value<int> intervalBefore;
  final Value<int> intervalAfter;
  final Value<DateTime> reviewedAt;
  const ReviewLogsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.deckId = const Value.absent(),
    this.rating = const Value.absent(),
    this.intervalBefore = const Value.absent(),
    this.intervalAfter = const Value.absent(),
    this.reviewedAt = const Value.absent(),
  });
  ReviewLogsCompanion.insert({
    this.id = const Value.absent(),
    required String itemId,
    required String deckId,
    required String rating,
    required int intervalBefore,
    required int intervalAfter,
    this.reviewedAt = const Value.absent(),
  }) : itemId = Value(itemId),
       deckId = Value(deckId),
       rating = Value(rating),
       intervalBefore = Value(intervalBefore),
       intervalAfter = Value(intervalAfter);
  static Insertable<ReviewLog> custom({
    Expression<int>? id,
    Expression<String>? itemId,
    Expression<String>? deckId,
    Expression<String>? rating,
    Expression<int>? intervalBefore,
    Expression<int>? intervalAfter,
    Expression<DateTime>? reviewedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (deckId != null) 'deck_id': deckId,
      if (rating != null) 'rating': rating,
      if (intervalBefore != null) 'interval_before': intervalBefore,
      if (intervalAfter != null) 'interval_after': intervalAfter,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
    });
  }

  ReviewLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? itemId,
    Value<String>? deckId,
    Value<String>? rating,
    Value<int>? intervalBefore,
    Value<int>? intervalAfter,
    Value<DateTime>? reviewedAt,
  }) {
    return ReviewLogsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      deckId: deckId ?? this.deckId,
      rating: rating ?? this.rating,
      intervalBefore: intervalBefore ?? this.intervalBefore,
      intervalAfter: intervalAfter ?? this.intervalAfter,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (deckId.present) {
      map['deck_id'] = Variable<String>(deckId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<String>(rating.value);
    }
    if (intervalBefore.present) {
      map['interval_before'] = Variable<int>(intervalBefore.value);
    }
    if (intervalAfter.present) {
      map['interval_after'] = Variable<int>(intervalAfter.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('deckId: $deckId, ')
          ..write('rating: $rating, ')
          ..write('intervalBefore: $intervalBefore, ')
          ..write('intervalAfter: $intervalAfter, ')
          ..write('reviewedAt: $reviewedAt')
          ..write(')'))
        .toString();
  }
}

class $MemorizationPlansTable extends MemorizationPlans
    with TableInfo<$MemorizationPlansTable, MemorizationPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemorizationPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<String> deckId = GeneratedColumn<String>(
    'deck_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES decks (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deckId,
    name,
    difficulty,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memorization_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemorizationPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('deck_id')) {
      context.handle(
        _deckIdMeta,
        deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemorizationPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemorizationPlan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      deckId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deck_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MemorizationPlansTable createAlias(String alias) {
    return $MemorizationPlansTable(attachedDatabase, alias);
  }
}

class MemorizationPlan extends DataClass
    implements Insertable<MemorizationPlan> {
  final String id;
  final String deckId;
  final String name;
  final String difficulty;
  final DateTime createdAt;
  const MemorizationPlan({
    required this.id,
    required this.deckId,
    required this.name,
    required this.difficulty,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['deck_id'] = Variable<String>(deckId);
    map['name'] = Variable<String>(name);
    map['difficulty'] = Variable<String>(difficulty);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MemorizationPlansCompanion toCompanion(bool nullToAbsent) {
    return MemorizationPlansCompanion(
      id: Value(id),
      deckId: Value(deckId),
      name: Value(name),
      difficulty: Value(difficulty),
      createdAt: Value(createdAt),
    );
  }

  factory MemorizationPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemorizationPlan(
      id: serializer.fromJson<String>(json['id']),
      deckId: serializer.fromJson<String>(json['deckId']),
      name: serializer.fromJson<String>(json['name']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'deckId': serializer.toJson<String>(deckId),
      'name': serializer.toJson<String>(name),
      'difficulty': serializer.toJson<String>(difficulty),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MemorizationPlan copyWith({
    String? id,
    String? deckId,
    String? name,
    String? difficulty,
    DateTime? createdAt,
  }) => MemorizationPlan(
    id: id ?? this.id,
    deckId: deckId ?? this.deckId,
    name: name ?? this.name,
    difficulty: difficulty ?? this.difficulty,
    createdAt: createdAt ?? this.createdAt,
  );
  MemorizationPlan copyWithCompanion(MemorizationPlansCompanion data) {
    return MemorizationPlan(
      id: data.id.present ? data.id.value : this.id,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      name: data.name.present ? data.name.value : this.name,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemorizationPlan(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('name: $name, ')
          ..write('difficulty: $difficulty, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, deckId, name, difficulty, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemorizationPlan &&
          other.id == this.id &&
          other.deckId == this.deckId &&
          other.name == this.name &&
          other.difficulty == this.difficulty &&
          other.createdAt == this.createdAt);
}

class MemorizationPlansCompanion extends UpdateCompanion<MemorizationPlan> {
  final Value<String> id;
  final Value<String> deckId;
  final Value<String> name;
  final Value<String> difficulty;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MemorizationPlansCompanion({
    this.id = const Value.absent(),
    this.deckId = const Value.absent(),
    this.name = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemorizationPlansCompanion.insert({
    required String id,
    required String deckId,
    required String name,
    required String difficulty,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       deckId = Value(deckId),
       name = Value(name),
       difficulty = Value(difficulty);
  static Insertable<MemorizationPlan> custom({
    Expression<String>? id,
    Expression<String>? deckId,
    Expression<String>? name,
    Expression<String>? difficulty,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deckId != null) 'deck_id': deckId,
      if (name != null) 'name': name,
      if (difficulty != null) 'difficulty': difficulty,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemorizationPlansCompanion copyWith({
    Value<String>? id,
    Value<String>? deckId,
    Value<String>? name,
    Value<String>? difficulty,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MemorizationPlansCompanion(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      name: name ?? this.name,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deckId.present) {
      map['deck_id'] = Variable<String>(deckId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemorizationPlansCompanion(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('name: $name, ')
          ..write('difficulty: $difficulty, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemorizationPlanItemsTable extends MemorizationPlanItems
    with TableInfo<$MemorizationPlanItemsTable, MemorizationPlanItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemorizationPlanItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES memorization_plans (id)',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, planId, itemId, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memorization_plan_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemorizationPlanItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemorizationPlanItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemorizationPlanItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $MemorizationPlanItemsTable createAlias(String alias) {
    return $MemorizationPlanItemsTable(attachedDatabase, alias);
  }
}

class MemorizationPlanItem extends DataClass
    implements Insertable<MemorizationPlanItem> {
  final int id;
  final String planId;
  final String itemId;
  final int position;
  const MemorizationPlanItem({
    required this.id,
    required this.planId,
    required this.itemId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plan_id'] = Variable<String>(planId);
    map['item_id'] = Variable<String>(itemId);
    map['position'] = Variable<int>(position);
    return map;
  }

  MemorizationPlanItemsCompanion toCompanion(bool nullToAbsent) {
    return MemorizationPlanItemsCompanion(
      id: Value(id),
      planId: Value(planId),
      itemId: Value(itemId),
      position: Value(position),
    );
  }

  factory MemorizationPlanItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemorizationPlanItem(
      id: serializer.fromJson<int>(json['id']),
      planId: serializer.fromJson<String>(json['planId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'planId': serializer.toJson<String>(planId),
      'itemId': serializer.toJson<String>(itemId),
      'position': serializer.toJson<int>(position),
    };
  }

  MemorizationPlanItem copyWith({
    int? id,
    String? planId,
    String? itemId,
    int? position,
  }) => MemorizationPlanItem(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    itemId: itemId ?? this.itemId,
    position: position ?? this.position,
  );
  MemorizationPlanItem copyWithCompanion(MemorizationPlanItemsCompanion data) {
    return MemorizationPlanItem(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemorizationPlanItem(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('itemId: $itemId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, planId, itemId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemorizationPlanItem &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.itemId == this.itemId &&
          other.position == this.position);
}

class MemorizationPlanItemsCompanion
    extends UpdateCompanion<MemorizationPlanItem> {
  final Value<int> id;
  final Value<String> planId;
  final Value<String> itemId;
  final Value<int> position;
  const MemorizationPlanItemsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.position = const Value.absent(),
  });
  MemorizationPlanItemsCompanion.insert({
    this.id = const Value.absent(),
    required String planId,
    required String itemId,
    required int position,
  }) : planId = Value(planId),
       itemId = Value(itemId),
       position = Value(position);
  static Insertable<MemorizationPlanItem> custom({
    Expression<int>? id,
    Expression<String>? planId,
    Expression<String>? itemId,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (itemId != null) 'item_id': itemId,
      if (position != null) 'position': position,
    });
  }

  MemorizationPlanItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? planId,
    Value<String>? itemId,
    Value<int>? position,
  }) {
    return MemorizationPlanItemsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      itemId: itemId ?? this.itemId,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemorizationPlanItemsCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('itemId: $itemId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $ExerciseAttemptsTable extends ExerciseAttempts
    with TableInfo<$ExerciseAttemptsTable, ExerciseAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _stepTypeMeta = const VerificationMeta(
    'stepType',
  );
  @override
  late final GeneratedColumn<String> stepType = GeneratedColumn<String>(
    'step_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mistakesMeta = const VerificationMeta(
    'mistakes',
  );
  @override
  late final GeneratedColumn<int> mistakes = GeneratedColumn<int>(
    'mistakes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    stepType,
    level,
    difficulty,
    score,
    mistakes,
    payloadJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseAttempt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('step_type')) {
      context.handle(
        _stepTypeMeta,
        stepType.isAcceptableOrUnknown(data['step_type']!, _stepTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_stepTypeMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('mistakes')) {
      context.handle(
        _mistakesMeta,
        mistakes.isAcceptableOrUnknown(data['mistakes']!, _mistakesMeta),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseAttempt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      stepType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}step_type'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      ),
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      )!,
      mistakes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mistakes'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ExerciseAttemptsTable createAlias(String alias) {
    return $ExerciseAttemptsTable(attachedDatabase, alias);
  }
}

class ExerciseAttempt extends DataClass implements Insertable<ExerciseAttempt> {
  final int id;
  final String itemId;
  final String stepType;
  final String? level;
  final String difficulty;
  final double score;
  final int mistakes;
  final String? payloadJson;
  final DateTime createdAt;
  const ExerciseAttempt({
    required this.id,
    required this.itemId,
    required this.stepType,
    this.level,
    required this.difficulty,
    required this.score,
    required this.mistakes,
    this.payloadJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<String>(itemId);
    map['step_type'] = Variable<String>(stepType);
    if (!nullToAbsent || level != null) {
      map['level'] = Variable<String>(level);
    }
    map['difficulty'] = Variable<String>(difficulty);
    map['score'] = Variable<double>(score);
    map['mistakes'] = Variable<int>(mistakes);
    if (!nullToAbsent || payloadJson != null) {
      map['payload_json'] = Variable<String>(payloadJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExerciseAttemptsCompanion toCompanion(bool nullToAbsent) {
    return ExerciseAttemptsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      stepType: Value(stepType),
      level: level == null && nullToAbsent
          ? const Value.absent()
          : Value(level),
      difficulty: Value(difficulty),
      score: Value(score),
      mistakes: Value(mistakes),
      payloadJson: payloadJson == null && nullToAbsent
          ? const Value.absent()
          : Value(payloadJson),
      createdAt: Value(createdAt),
    );
  }

  factory ExerciseAttempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseAttempt(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      stepType: serializer.fromJson<String>(json['stepType']),
      level: serializer.fromJson<String?>(json['level']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      score: serializer.fromJson<double>(json['score']),
      mistakes: serializer.fromJson<int>(json['mistakes']),
      payloadJson: serializer.fromJson<String?>(json['payloadJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<String>(itemId),
      'stepType': serializer.toJson<String>(stepType),
      'level': serializer.toJson<String?>(level),
      'difficulty': serializer.toJson<String>(difficulty),
      'score': serializer.toJson<double>(score),
      'mistakes': serializer.toJson<int>(mistakes),
      'payloadJson': serializer.toJson<String?>(payloadJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ExerciseAttempt copyWith({
    int? id,
    String? itemId,
    String? stepType,
    Value<String?> level = const Value.absent(),
    String? difficulty,
    double? score,
    int? mistakes,
    Value<String?> payloadJson = const Value.absent(),
    DateTime? createdAt,
  }) => ExerciseAttempt(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    stepType: stepType ?? this.stepType,
    level: level.present ? level.value : this.level,
    difficulty: difficulty ?? this.difficulty,
    score: score ?? this.score,
    mistakes: mistakes ?? this.mistakes,
    payloadJson: payloadJson.present ? payloadJson.value : this.payloadJson,
    createdAt: createdAt ?? this.createdAt,
  );
  ExerciseAttempt copyWithCompanion(ExerciseAttemptsCompanion data) {
    return ExerciseAttempt(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      stepType: data.stepType.present ? data.stepType.value : this.stepType,
      level: data.level.present ? data.level.value : this.level,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      score: data.score.present ? data.score.value : this.score,
      mistakes: data.mistakes.present ? data.mistakes.value : this.mistakes,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseAttempt(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('stepType: $stepType, ')
          ..write('level: $level, ')
          ..write('difficulty: $difficulty, ')
          ..write('score: $score, ')
          ..write('mistakes: $mistakes, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    stepType,
    level,
    difficulty,
    score,
    mistakes,
    payloadJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseAttempt &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.stepType == this.stepType &&
          other.level == this.level &&
          other.difficulty == this.difficulty &&
          other.score == this.score &&
          other.mistakes == this.mistakes &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt);
}

class ExerciseAttemptsCompanion extends UpdateCompanion<ExerciseAttempt> {
  final Value<int> id;
  final Value<String> itemId;
  final Value<String> stepType;
  final Value<String?> level;
  final Value<String> difficulty;
  final Value<double> score;
  final Value<int> mistakes;
  final Value<String?> payloadJson;
  final Value<DateTime> createdAt;
  const ExerciseAttemptsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.stepType = const Value.absent(),
    this.level = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.score = const Value.absent(),
    this.mistakes = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ExerciseAttemptsCompanion.insert({
    this.id = const Value.absent(),
    required String itemId,
    required String stepType,
    this.level = const Value.absent(),
    required String difficulty,
    required double score,
    this.mistakes = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : itemId = Value(itemId),
       stepType = Value(stepType),
       difficulty = Value(difficulty),
       score = Value(score);
  static Insertable<ExerciseAttempt> custom({
    Expression<int>? id,
    Expression<String>? itemId,
    Expression<String>? stepType,
    Expression<String>? level,
    Expression<String>? difficulty,
    Expression<double>? score,
    Expression<int>? mistakes,
    Expression<String>? payloadJson,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (stepType != null) 'step_type': stepType,
      if (level != null) 'level': level,
      if (difficulty != null) 'difficulty': difficulty,
      if (score != null) 'score': score,
      if (mistakes != null) 'mistakes': mistakes,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ExerciseAttemptsCompanion copyWith({
    Value<int>? id,
    Value<String>? itemId,
    Value<String>? stepType,
    Value<String?>? level,
    Value<String>? difficulty,
    Value<double>? score,
    Value<int>? mistakes,
    Value<String?>? payloadJson,
    Value<DateTime>? createdAt,
  }) {
    return ExerciseAttemptsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      stepType: stepType ?? this.stepType,
      level: level ?? this.level,
      difficulty: difficulty ?? this.difficulty,
      score: score ?? this.score,
      mistakes: mistakes ?? this.mistakes,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (stepType.present) {
      map['step_type'] = Variable<String>(stepType.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (mistakes.present) {
      map['mistakes'] = Variable<int>(mistakes.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('stepType: $stepType, ')
          ..write('level: $level, ')
          ..write('difficulty: $difficulty, ')
          ..write('score: $score, ')
          ..write('mistakes: $mistakes, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AudioClipsTable extends AudioClips
    with TableInfo<$AudioClipsTable, AudioClip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AudioClipsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    localPath,
    durationMs,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audio_clips';
  @override
  VerificationContext validateIntegrity(
    Insertable<AudioClip> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AudioClip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AudioClip(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AudioClipsTable createAlias(String alias) {
    return $AudioClipsTable(attachedDatabase, alias);
  }
}

class AudioClip extends DataClass implements Insertable<AudioClip> {
  final int id;
  final String itemId;
  final String localPath;
  final int durationMs;
  final DateTime createdAt;
  const AudioClip({
    required this.id,
    required this.itemId,
    required this.localPath,
    required this.durationMs,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<String>(itemId);
    map['local_path'] = Variable<String>(localPath);
    map['duration_ms'] = Variable<int>(durationMs);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AudioClipsCompanion toCompanion(bool nullToAbsent) {
    return AudioClipsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      localPath: Value(localPath),
      durationMs: Value(durationMs),
      createdAt: Value(createdAt),
    );
  }

  factory AudioClip.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AudioClip(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      localPath: serializer.fromJson<String>(json['localPath']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<String>(itemId),
      'localPath': serializer.toJson<String>(localPath),
      'durationMs': serializer.toJson<int>(durationMs),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AudioClip copyWith({
    int? id,
    String? itemId,
    String? localPath,
    int? durationMs,
    DateTime? createdAt,
  }) => AudioClip(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    localPath: localPath ?? this.localPath,
    durationMs: durationMs ?? this.durationMs,
    createdAt: createdAt ?? this.createdAt,
  );
  AudioClip copyWithCompanion(AudioClipsCompanion data) {
    return AudioClip(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AudioClip(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('localPath: $localPath, ')
          ..write('durationMs: $durationMs, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, itemId, localPath, durationMs, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioClip &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.localPath == this.localPath &&
          other.durationMs == this.durationMs &&
          other.createdAt == this.createdAt);
}

class AudioClipsCompanion extends UpdateCompanion<AudioClip> {
  final Value<int> id;
  final Value<String> itemId;
  final Value<String> localPath;
  final Value<int> durationMs;
  final Value<DateTime> createdAt;
  const AudioClipsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.localPath = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AudioClipsCompanion.insert({
    this.id = const Value.absent(),
    required String itemId,
    required String localPath,
    this.durationMs = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : itemId = Value(itemId),
       localPath = Value(localPath);
  static Insertable<AudioClip> custom({
    Expression<int>? id,
    Expression<String>? itemId,
    Expression<String>? localPath,
    Expression<int>? durationMs,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (localPath != null) 'local_path': localPath,
      if (durationMs != null) 'duration_ms': durationMs,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AudioClipsCompanion copyWith({
    Value<int>? id,
    Value<String>? itemId,
    Value<String>? localPath,
    Value<int>? durationMs,
    Value<DateTime>? createdAt,
  }) {
    return AudioClipsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      localPath: localPath ?? this.localPath,
      durationMs: durationMs ?? this.durationMs,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AudioClipsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('localPath: $localPath, ')
          ..write('durationMs: $durationMs, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ExerciseConsolidationsTable extends ExerciseConsolidations
    with TableInfo<$ExerciseConsolidationsTable, ExerciseConsolidation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseConsolidationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<String> deckId = GeneratedColumn<String>(
    'deck_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES decks (id)',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _averageScoreMeta = const VerificationMeta(
    'averageScore',
  );
  @override
  late final GeneratedColumn<double> averageScore = GeneratedColumn<double>(
    'average_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMistakesMeta = const VerificationMeta(
    'totalMistakes',
  );
  @override
  late final GeneratedColumn<int> totalMistakes = GeneratedColumn<int>(
    'total_mistakes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _weakestStepTypeMeta = const VerificationMeta(
    'weakestStepType',
  );
  @override
  late final GeneratedColumn<String> weakestStepType = GeneratedColumn<String>(
    'weakest_step_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _strongestStepTypeMeta = const VerificationMeta(
    'strongestStepType',
  );
  @override
  late final GeneratedColumn<String> strongestStepType =
      GeneratedColumn<String>(
        'strongest_step_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deckId,
    itemId,
    difficulty,
    averageScore,
    totalMistakes,
    weakestStepType,
    strongestStepType,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_consolidations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseConsolidation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('deck_id')) {
      context.handle(
        _deckIdMeta,
        deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('average_score')) {
      context.handle(
        _averageScoreMeta,
        averageScore.isAcceptableOrUnknown(
          data['average_score']!,
          _averageScoreMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_averageScoreMeta);
    }
    if (data.containsKey('total_mistakes')) {
      context.handle(
        _totalMistakesMeta,
        totalMistakes.isAcceptableOrUnknown(
          data['total_mistakes']!,
          _totalMistakesMeta,
        ),
      );
    }
    if (data.containsKey('weakest_step_type')) {
      context.handle(
        _weakestStepTypeMeta,
        weakestStepType.isAcceptableOrUnknown(
          data['weakest_step_type']!,
          _weakestStepTypeMeta,
        ),
      );
    }
    if (data.containsKey('strongest_step_type')) {
      context.handle(
        _strongestStepTypeMeta,
        strongestStepType.isAcceptableOrUnknown(
          data['strongest_step_type']!,
          _strongestStepTypeMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseConsolidation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseConsolidation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deckId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deck_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      averageScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_score'],
      )!,
      totalMistakes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_mistakes'],
      )!,
      weakestStepType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weakest_step_type'],
      ),
      strongestStepType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strongest_step_type'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ExerciseConsolidationsTable createAlias(String alias) {
    return $ExerciseConsolidationsTable(attachedDatabase, alias);
  }
}

class ExerciseConsolidation extends DataClass
    implements Insertable<ExerciseConsolidation> {
  final int id;
  final String deckId;
  final String itemId;
  final String difficulty;
  final double averageScore;
  final int totalMistakes;
  final String? weakestStepType;
  final String? strongestStepType;
  final DateTime createdAt;
  const ExerciseConsolidation({
    required this.id,
    required this.deckId,
    required this.itemId,
    required this.difficulty,
    required this.averageScore,
    required this.totalMistakes,
    this.weakestStepType,
    this.strongestStepType,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['deck_id'] = Variable<String>(deckId);
    map['item_id'] = Variable<String>(itemId);
    map['difficulty'] = Variable<String>(difficulty);
    map['average_score'] = Variable<double>(averageScore);
    map['total_mistakes'] = Variable<int>(totalMistakes);
    if (!nullToAbsent || weakestStepType != null) {
      map['weakest_step_type'] = Variable<String>(weakestStepType);
    }
    if (!nullToAbsent || strongestStepType != null) {
      map['strongest_step_type'] = Variable<String>(strongestStepType);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExerciseConsolidationsCompanion toCompanion(bool nullToAbsent) {
    return ExerciseConsolidationsCompanion(
      id: Value(id),
      deckId: Value(deckId),
      itemId: Value(itemId),
      difficulty: Value(difficulty),
      averageScore: Value(averageScore),
      totalMistakes: Value(totalMistakes),
      weakestStepType: weakestStepType == null && nullToAbsent
          ? const Value.absent()
          : Value(weakestStepType),
      strongestStepType: strongestStepType == null && nullToAbsent
          ? const Value.absent()
          : Value(strongestStepType),
      createdAt: Value(createdAt),
    );
  }

  factory ExerciseConsolidation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseConsolidation(
      id: serializer.fromJson<int>(json['id']),
      deckId: serializer.fromJson<String>(json['deckId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      averageScore: serializer.fromJson<double>(json['averageScore']),
      totalMistakes: serializer.fromJson<int>(json['totalMistakes']),
      weakestStepType: serializer.fromJson<String?>(json['weakestStepType']),
      strongestStepType: serializer.fromJson<String?>(
        json['strongestStepType'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deckId': serializer.toJson<String>(deckId),
      'itemId': serializer.toJson<String>(itemId),
      'difficulty': serializer.toJson<String>(difficulty),
      'averageScore': serializer.toJson<double>(averageScore),
      'totalMistakes': serializer.toJson<int>(totalMistakes),
      'weakestStepType': serializer.toJson<String?>(weakestStepType),
      'strongestStepType': serializer.toJson<String?>(strongestStepType),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ExerciseConsolidation copyWith({
    int? id,
    String? deckId,
    String? itemId,
    String? difficulty,
    double? averageScore,
    int? totalMistakes,
    Value<String?> weakestStepType = const Value.absent(),
    Value<String?> strongestStepType = const Value.absent(),
    DateTime? createdAt,
  }) => ExerciseConsolidation(
    id: id ?? this.id,
    deckId: deckId ?? this.deckId,
    itemId: itemId ?? this.itemId,
    difficulty: difficulty ?? this.difficulty,
    averageScore: averageScore ?? this.averageScore,
    totalMistakes: totalMistakes ?? this.totalMistakes,
    weakestStepType: weakestStepType.present
        ? weakestStepType.value
        : this.weakestStepType,
    strongestStepType: strongestStepType.present
        ? strongestStepType.value
        : this.strongestStepType,
    createdAt: createdAt ?? this.createdAt,
  );
  ExerciseConsolidation copyWithCompanion(
    ExerciseConsolidationsCompanion data,
  ) {
    return ExerciseConsolidation(
      id: data.id.present ? data.id.value : this.id,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      averageScore: data.averageScore.present
          ? data.averageScore.value
          : this.averageScore,
      totalMistakes: data.totalMistakes.present
          ? data.totalMistakes.value
          : this.totalMistakes,
      weakestStepType: data.weakestStepType.present
          ? data.weakestStepType.value
          : this.weakestStepType,
      strongestStepType: data.strongestStepType.present
          ? data.strongestStepType.value
          : this.strongestStepType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseConsolidation(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('itemId: $itemId, ')
          ..write('difficulty: $difficulty, ')
          ..write('averageScore: $averageScore, ')
          ..write('totalMistakes: $totalMistakes, ')
          ..write('weakestStepType: $weakestStepType, ')
          ..write('strongestStepType: $strongestStepType, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deckId,
    itemId,
    difficulty,
    averageScore,
    totalMistakes,
    weakestStepType,
    strongestStepType,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseConsolidation &&
          other.id == this.id &&
          other.deckId == this.deckId &&
          other.itemId == this.itemId &&
          other.difficulty == this.difficulty &&
          other.averageScore == this.averageScore &&
          other.totalMistakes == this.totalMistakes &&
          other.weakestStepType == this.weakestStepType &&
          other.strongestStepType == this.strongestStepType &&
          other.createdAt == this.createdAt);
}

class ExerciseConsolidationsCompanion
    extends UpdateCompanion<ExerciseConsolidation> {
  final Value<int> id;
  final Value<String> deckId;
  final Value<String> itemId;
  final Value<String> difficulty;
  final Value<double> averageScore;
  final Value<int> totalMistakes;
  final Value<String?> weakestStepType;
  final Value<String?> strongestStepType;
  final Value<DateTime> createdAt;
  const ExerciseConsolidationsCompanion({
    this.id = const Value.absent(),
    this.deckId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.averageScore = const Value.absent(),
    this.totalMistakes = const Value.absent(),
    this.weakestStepType = const Value.absent(),
    this.strongestStepType = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ExerciseConsolidationsCompanion.insert({
    this.id = const Value.absent(),
    required String deckId,
    required String itemId,
    required String difficulty,
    required double averageScore,
    this.totalMistakes = const Value.absent(),
    this.weakestStepType = const Value.absent(),
    this.strongestStepType = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : deckId = Value(deckId),
       itemId = Value(itemId),
       difficulty = Value(difficulty),
       averageScore = Value(averageScore);
  static Insertable<ExerciseConsolidation> custom({
    Expression<int>? id,
    Expression<String>? deckId,
    Expression<String>? itemId,
    Expression<String>? difficulty,
    Expression<double>? averageScore,
    Expression<int>? totalMistakes,
    Expression<String>? weakestStepType,
    Expression<String>? strongestStepType,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deckId != null) 'deck_id': deckId,
      if (itemId != null) 'item_id': itemId,
      if (difficulty != null) 'difficulty': difficulty,
      if (averageScore != null) 'average_score': averageScore,
      if (totalMistakes != null) 'total_mistakes': totalMistakes,
      if (weakestStepType != null) 'weakest_step_type': weakestStepType,
      if (strongestStepType != null) 'strongest_step_type': strongestStepType,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ExerciseConsolidationsCompanion copyWith({
    Value<int>? id,
    Value<String>? deckId,
    Value<String>? itemId,
    Value<String>? difficulty,
    Value<double>? averageScore,
    Value<int>? totalMistakes,
    Value<String?>? weakestStepType,
    Value<String?>? strongestStepType,
    Value<DateTime>? createdAt,
  }) {
    return ExerciseConsolidationsCompanion(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      itemId: itemId ?? this.itemId,
      difficulty: difficulty ?? this.difficulty,
      averageScore: averageScore ?? this.averageScore,
      totalMistakes: totalMistakes ?? this.totalMistakes,
      weakestStepType: weakestStepType ?? this.weakestStepType,
      strongestStepType: strongestStepType ?? this.strongestStepType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deckId.present) {
      map['deck_id'] = Variable<String>(deckId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (averageScore.present) {
      map['average_score'] = Variable<double>(averageScore.value);
    }
    if (totalMistakes.present) {
      map['total_mistakes'] = Variable<int>(totalMistakes.value);
    }
    if (weakestStepType.present) {
      map['weakest_step_type'] = Variable<String>(weakestStepType.value);
    }
    if (strongestStepType.present) {
      map['strongest_step_type'] = Variable<String>(strongestStepType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseConsolidationsCompanion(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('itemId: $itemId, ')
          ..write('difficulty: $difficulty, ')
          ..write('averageScore: $averageScore, ')
          ..write('totalMistakes: $totalMistakes, ')
          ..write('weakestStepType: $weakestStepType, ')
          ..write('strongestStepType: $strongestStepType, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CardsConsolidationsTable extends CardsConsolidations
    with TableInfo<$CardsConsolidationsTable, CardsConsolidation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardsConsolidationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<String> deckId = GeneratedColumn<String>(
    'deck_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES decks (id)',
    ),
  );
  static const VerificationMeta _averageScoreMeta = const VerificationMeta(
    'averageScore',
  );
  @override
  late final GeneratedColumn<double> averageScore = GeneratedColumn<double>(
    'average_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMistakesMeta = const VerificationMeta(
    'totalMistakes',
  );
  @override
  late final GeneratedColumn<int> totalMistakes = GeneratedColumn<int>(
    'total_mistakes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _weakestExerciseTypeMeta =
      const VerificationMeta('weakestExerciseType');
  @override
  late final GeneratedColumn<String> weakestExerciseType =
      GeneratedColumn<String>(
        'weakest_exercise_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _strongestExerciseTypeMeta =
      const VerificationMeta('strongestExerciseType');
  @override
  late final GeneratedColumn<String> strongestExerciseType =
      GeneratedColumn<String>(
        'strongest_exercise_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deckId,
    averageScore,
    totalMistakes,
    weakestExerciseType,
    strongestExerciseType,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cards_consolidations';
  @override
  VerificationContext validateIntegrity(
    Insertable<CardsConsolidation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('deck_id')) {
      context.handle(
        _deckIdMeta,
        deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('average_score')) {
      context.handle(
        _averageScoreMeta,
        averageScore.isAcceptableOrUnknown(
          data['average_score']!,
          _averageScoreMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_averageScoreMeta);
    }
    if (data.containsKey('total_mistakes')) {
      context.handle(
        _totalMistakesMeta,
        totalMistakes.isAcceptableOrUnknown(
          data['total_mistakes']!,
          _totalMistakesMeta,
        ),
      );
    }
    if (data.containsKey('weakest_exercise_type')) {
      context.handle(
        _weakestExerciseTypeMeta,
        weakestExerciseType.isAcceptableOrUnknown(
          data['weakest_exercise_type']!,
          _weakestExerciseTypeMeta,
        ),
      );
    }
    if (data.containsKey('strongest_exercise_type')) {
      context.handle(
        _strongestExerciseTypeMeta,
        strongestExerciseType.isAcceptableOrUnknown(
          data['strongest_exercise_type']!,
          _strongestExerciseTypeMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardsConsolidation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardsConsolidation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deckId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deck_id'],
      )!,
      averageScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_score'],
      )!,
      totalMistakes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_mistakes'],
      )!,
      weakestExerciseType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weakest_exercise_type'],
      ),
      strongestExerciseType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strongest_exercise_type'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CardsConsolidationsTable createAlias(String alias) {
    return $CardsConsolidationsTable(attachedDatabase, alias);
  }
}

class CardsConsolidation extends DataClass
    implements Insertable<CardsConsolidation> {
  final int id;
  final String deckId;
  final double averageScore;
  final int totalMistakes;
  final String? weakestExerciseType;
  final String? strongestExerciseType;
  final DateTime createdAt;
  const CardsConsolidation({
    required this.id,
    required this.deckId,
    required this.averageScore,
    required this.totalMistakes,
    this.weakestExerciseType,
    this.strongestExerciseType,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['deck_id'] = Variable<String>(deckId);
    map['average_score'] = Variable<double>(averageScore);
    map['total_mistakes'] = Variable<int>(totalMistakes);
    if (!nullToAbsent || weakestExerciseType != null) {
      map['weakest_exercise_type'] = Variable<String>(weakestExerciseType);
    }
    if (!nullToAbsent || strongestExerciseType != null) {
      map['strongest_exercise_type'] = Variable<String>(strongestExerciseType);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CardsConsolidationsCompanion toCompanion(bool nullToAbsent) {
    return CardsConsolidationsCompanion(
      id: Value(id),
      deckId: Value(deckId),
      averageScore: Value(averageScore),
      totalMistakes: Value(totalMistakes),
      weakestExerciseType: weakestExerciseType == null && nullToAbsent
          ? const Value.absent()
          : Value(weakestExerciseType),
      strongestExerciseType: strongestExerciseType == null && nullToAbsent
          ? const Value.absent()
          : Value(strongestExerciseType),
      createdAt: Value(createdAt),
    );
  }

  factory CardsConsolidation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardsConsolidation(
      id: serializer.fromJson<int>(json['id']),
      deckId: serializer.fromJson<String>(json['deckId']),
      averageScore: serializer.fromJson<double>(json['averageScore']),
      totalMistakes: serializer.fromJson<int>(json['totalMistakes']),
      weakestExerciseType: serializer.fromJson<String?>(
        json['weakestExerciseType'],
      ),
      strongestExerciseType: serializer.fromJson<String?>(
        json['strongestExerciseType'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deckId': serializer.toJson<String>(deckId),
      'averageScore': serializer.toJson<double>(averageScore),
      'totalMistakes': serializer.toJson<int>(totalMistakes),
      'weakestExerciseType': serializer.toJson<String?>(weakestExerciseType),
      'strongestExerciseType': serializer.toJson<String?>(
        strongestExerciseType,
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CardsConsolidation copyWith({
    int? id,
    String? deckId,
    double? averageScore,
    int? totalMistakes,
    Value<String?> weakestExerciseType = const Value.absent(),
    Value<String?> strongestExerciseType = const Value.absent(),
    DateTime? createdAt,
  }) => CardsConsolidation(
    id: id ?? this.id,
    deckId: deckId ?? this.deckId,
    averageScore: averageScore ?? this.averageScore,
    totalMistakes: totalMistakes ?? this.totalMistakes,
    weakestExerciseType: weakestExerciseType.present
        ? weakestExerciseType.value
        : this.weakestExerciseType,
    strongestExerciseType: strongestExerciseType.present
        ? strongestExerciseType.value
        : this.strongestExerciseType,
    createdAt: createdAt ?? this.createdAt,
  );
  CardsConsolidation copyWithCompanion(CardsConsolidationsCompanion data) {
    return CardsConsolidation(
      id: data.id.present ? data.id.value : this.id,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      averageScore: data.averageScore.present
          ? data.averageScore.value
          : this.averageScore,
      totalMistakes: data.totalMistakes.present
          ? data.totalMistakes.value
          : this.totalMistakes,
      weakestExerciseType: data.weakestExerciseType.present
          ? data.weakestExerciseType.value
          : this.weakestExerciseType,
      strongestExerciseType: data.strongestExerciseType.present
          ? data.strongestExerciseType.value
          : this.strongestExerciseType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardsConsolidation(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('averageScore: $averageScore, ')
          ..write('totalMistakes: $totalMistakes, ')
          ..write('weakestExerciseType: $weakestExerciseType, ')
          ..write('strongestExerciseType: $strongestExerciseType, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deckId,
    averageScore,
    totalMistakes,
    weakestExerciseType,
    strongestExerciseType,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardsConsolidation &&
          other.id == this.id &&
          other.deckId == this.deckId &&
          other.averageScore == this.averageScore &&
          other.totalMistakes == this.totalMistakes &&
          other.weakestExerciseType == this.weakestExerciseType &&
          other.strongestExerciseType == this.strongestExerciseType &&
          other.createdAt == this.createdAt);
}

class CardsConsolidationsCompanion extends UpdateCompanion<CardsConsolidation> {
  final Value<int> id;
  final Value<String> deckId;
  final Value<double> averageScore;
  final Value<int> totalMistakes;
  final Value<String?> weakestExerciseType;
  final Value<String?> strongestExerciseType;
  final Value<DateTime> createdAt;
  const CardsConsolidationsCompanion({
    this.id = const Value.absent(),
    this.deckId = const Value.absent(),
    this.averageScore = const Value.absent(),
    this.totalMistakes = const Value.absent(),
    this.weakestExerciseType = const Value.absent(),
    this.strongestExerciseType = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CardsConsolidationsCompanion.insert({
    this.id = const Value.absent(),
    required String deckId,
    required double averageScore,
    this.totalMistakes = const Value.absent(),
    this.weakestExerciseType = const Value.absent(),
    this.strongestExerciseType = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : deckId = Value(deckId),
       averageScore = Value(averageScore);
  static Insertable<CardsConsolidation> custom({
    Expression<int>? id,
    Expression<String>? deckId,
    Expression<double>? averageScore,
    Expression<int>? totalMistakes,
    Expression<String>? weakestExerciseType,
    Expression<String>? strongestExerciseType,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deckId != null) 'deck_id': deckId,
      if (averageScore != null) 'average_score': averageScore,
      if (totalMistakes != null) 'total_mistakes': totalMistakes,
      if (weakestExerciseType != null)
        'weakest_exercise_type': weakestExerciseType,
      if (strongestExerciseType != null)
        'strongest_exercise_type': strongestExerciseType,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CardsConsolidationsCompanion copyWith({
    Value<int>? id,
    Value<String>? deckId,
    Value<double>? averageScore,
    Value<int>? totalMistakes,
    Value<String?>? weakestExerciseType,
    Value<String?>? strongestExerciseType,
    Value<DateTime>? createdAt,
  }) {
    return CardsConsolidationsCompanion(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      averageScore: averageScore ?? this.averageScore,
      totalMistakes: totalMistakes ?? this.totalMistakes,
      weakestExerciseType: weakestExerciseType ?? this.weakestExerciseType,
      strongestExerciseType:
          strongestExerciseType ?? this.strongestExerciseType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deckId.present) {
      map['deck_id'] = Variable<String>(deckId.value);
    }
    if (averageScore.present) {
      map['average_score'] = Variable<double>(averageScore.value);
    }
    if (totalMistakes.present) {
      map['total_mistakes'] = Variable<int>(totalMistakes.value);
    }
    if (weakestExerciseType.present) {
      map['weakest_exercise_type'] = Variable<String>(
        weakestExerciseType.value,
      );
    }
    if (strongestExerciseType.present) {
      map['strongest_exercise_type'] = Variable<String>(
        strongestExerciseType.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardsConsolidationsCompanion(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('averageScore: $averageScore, ')
          ..write('totalMistakes: $totalMistakes, ')
          ..write('weakestExerciseType: $weakestExerciseType, ')
          ..write('strongestExerciseType: $strongestExerciseType, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $MemorizationGoalsTable extends MemorizationGoals
    with TableInfo<$MemorizationGoalsTable, MemorizationGoal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemorizationGoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<String> deckId = GeneratedColumn<String>(
    'deck_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES decks (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _objectiveMeta = const VerificationMeta(
    'objective',
  );
  @override
  late final GeneratedColumn<String> objective = GeneratedColumn<String>(
    'objective',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetItemsMeta = const VerificationMeta(
    'targetItems',
  );
  @override
  late final GeneratedColumn<int> targetItems = GeneratedColumn<int>(
    'target_items',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<DateTime> targetDate = GeneratedColumn<DateTime>(
    'target_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deckId,
    title,
    objective,
    targetItems,
    targetDate,
    status,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memorization_goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemorizationGoal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('deck_id')) {
      context.handle(
        _deckIdMeta,
        deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('objective')) {
      context.handle(
        _objectiveMeta,
        objective.isAcceptableOrUnknown(data['objective']!, _objectiveMeta),
      );
    } else if (isInserting) {
      context.missing(_objectiveMeta);
    }
    if (data.containsKey('target_items')) {
      context.handle(
        _targetItemsMeta,
        targetItems.isAcceptableOrUnknown(
          data['target_items']!,
          _targetItemsMeta,
        ),
      );
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemorizationGoal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemorizationGoal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      deckId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deck_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      objective: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}objective'],
      )!,
      targetItems: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_items'],
      )!,
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}target_date'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MemorizationGoalsTable createAlias(String alias) {
    return $MemorizationGoalsTable(attachedDatabase, alias);
  }
}

class MemorizationGoal extends DataClass
    implements Insertable<MemorizationGoal> {
  final String id;
  final String deckId;
  final String title;
  final String objective;
  final int targetItems;
  final DateTime? targetDate;
  final String status;
  final DateTime createdAt;
  const MemorizationGoal({
    required this.id,
    required this.deckId,
    required this.title,
    required this.objective,
    required this.targetItems,
    this.targetDate,
    required this.status,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['deck_id'] = Variable<String>(deckId);
    map['title'] = Variable<String>(title);
    map['objective'] = Variable<String>(objective);
    map['target_items'] = Variable<int>(targetItems);
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<DateTime>(targetDate);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MemorizationGoalsCompanion toCompanion(bool nullToAbsent) {
    return MemorizationGoalsCompanion(
      id: Value(id),
      deckId: Value(deckId),
      title: Value(title),
      objective: Value(objective),
      targetItems: Value(targetItems),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory MemorizationGoal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemorizationGoal(
      id: serializer.fromJson<String>(json['id']),
      deckId: serializer.fromJson<String>(json['deckId']),
      title: serializer.fromJson<String>(json['title']),
      objective: serializer.fromJson<String>(json['objective']),
      targetItems: serializer.fromJson<int>(json['targetItems']),
      targetDate: serializer.fromJson<DateTime?>(json['targetDate']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'deckId': serializer.toJson<String>(deckId),
      'title': serializer.toJson<String>(title),
      'objective': serializer.toJson<String>(objective),
      'targetItems': serializer.toJson<int>(targetItems),
      'targetDate': serializer.toJson<DateTime?>(targetDate),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MemorizationGoal copyWith({
    String? id,
    String? deckId,
    String? title,
    String? objective,
    int? targetItems,
    Value<DateTime?> targetDate = const Value.absent(),
    String? status,
    DateTime? createdAt,
  }) => MemorizationGoal(
    id: id ?? this.id,
    deckId: deckId ?? this.deckId,
    title: title ?? this.title,
    objective: objective ?? this.objective,
    targetItems: targetItems ?? this.targetItems,
    targetDate: targetDate.present ? targetDate.value : this.targetDate,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
  MemorizationGoal copyWithCompanion(MemorizationGoalsCompanion data) {
    return MemorizationGoal(
      id: data.id.present ? data.id.value : this.id,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      title: data.title.present ? data.title.value : this.title,
      objective: data.objective.present ? data.objective.value : this.objective,
      targetItems: data.targetItems.present
          ? data.targetItems.value
          : this.targetItems,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemorizationGoal(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('title: $title, ')
          ..write('objective: $objective, ')
          ..write('targetItems: $targetItems, ')
          ..write('targetDate: $targetDate, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deckId,
    title,
    objective,
    targetItems,
    targetDate,
    status,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemorizationGoal &&
          other.id == this.id &&
          other.deckId == this.deckId &&
          other.title == this.title &&
          other.objective == this.objective &&
          other.targetItems == this.targetItems &&
          other.targetDate == this.targetDate &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class MemorizationGoalsCompanion extends UpdateCompanion<MemorizationGoal> {
  final Value<String> id;
  final Value<String> deckId;
  final Value<String> title;
  final Value<String> objective;
  final Value<int> targetItems;
  final Value<DateTime?> targetDate;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MemorizationGoalsCompanion({
    this.id = const Value.absent(),
    this.deckId = const Value.absent(),
    this.title = const Value.absent(),
    this.objective = const Value.absent(),
    this.targetItems = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemorizationGoalsCompanion.insert({
    required String id,
    required String deckId,
    required String title,
    required String objective,
    this.targetItems = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       deckId = Value(deckId),
       title = Value(title),
       objective = Value(objective);
  static Insertable<MemorizationGoal> custom({
    Expression<String>? id,
    Expression<String>? deckId,
    Expression<String>? title,
    Expression<String>? objective,
    Expression<int>? targetItems,
    Expression<DateTime>? targetDate,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deckId != null) 'deck_id': deckId,
      if (title != null) 'title': title,
      if (objective != null) 'objective': objective,
      if (targetItems != null) 'target_items': targetItems,
      if (targetDate != null) 'target_date': targetDate,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemorizationGoalsCompanion copyWith({
    Value<String>? id,
    Value<String>? deckId,
    Value<String>? title,
    Value<String>? objective,
    Value<int>? targetItems,
    Value<DateTime?>? targetDate,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MemorizationGoalsCompanion(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      title: title ?? this.title,
      objective: objective ?? this.objective,
      targetItems: targetItems ?? this.targetItems,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deckId.present) {
      map['deck_id'] = Variable<String>(deckId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (objective.present) {
      map['objective'] = Variable<String>(objective.value);
    }
    if (targetItems.present) {
      map['target_items'] = Variable<int>(targetItems.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(targetDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemorizationGoalsCompanion(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('title: $title, ')
          ..write('objective: $objective, ')
          ..write('targetItems: $targetItems, ')
          ..write('targetDate: $targetDate, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemorizationJourneysTable extends MemorizationJourneys
    with TableInfo<$MemorizationJourneysTable, MemorizationJourney> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemorizationJourneysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<String> deckId = GeneratedColumn<String>(
    'deck_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES decks (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDaysMeta = const VerificationMeta(
    'targetDays',
  );
  @override
  late final GeneratedColumn<int> targetDays = GeneratedColumn<int>(
    'target_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemsPerDayMeta = const VerificationMeta(
    'itemsPerDay',
  );
  @override
  late final GeneratedColumn<int> itemsPerDay = GeneratedColumn<int>(
    'items_per_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetItemCountMeta = const VerificationMeta(
    'targetItemCount',
  );
  @override
  late final GeneratedColumn<int> targetItemCount = GeneratedColumn<int>(
    'target_item_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _objectiveMeta = const VerificationMeta(
    'objective',
  );
  @override
  late final GeneratedColumn<String> objective = GeneratedColumn<String>(
    'objective',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deckId,
    title,
    targetDays,
    itemsPerDay,
    targetItemCount,
    objective,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memorization_journeys';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemorizationJourney> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('deck_id')) {
      context.handle(
        _deckIdMeta,
        deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('target_days')) {
      context.handle(
        _targetDaysMeta,
        targetDays.isAcceptableOrUnknown(data['target_days']!, _targetDaysMeta),
      );
    } else if (isInserting) {
      context.missing(_targetDaysMeta);
    }
    if (data.containsKey('items_per_day')) {
      context.handle(
        _itemsPerDayMeta,
        itemsPerDay.isAcceptableOrUnknown(
          data['items_per_day']!,
          _itemsPerDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_itemsPerDayMeta);
    }
    if (data.containsKey('target_item_count')) {
      context.handle(
        _targetItemCountMeta,
        targetItemCount.isAcceptableOrUnknown(
          data['target_item_count']!,
          _targetItemCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetItemCountMeta);
    }
    if (data.containsKey('objective')) {
      context.handle(
        _objectiveMeta,
        objective.isAcceptableOrUnknown(data['objective']!, _objectiveMeta),
      );
    } else if (isInserting) {
      context.missing(_objectiveMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemorizationJourney map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemorizationJourney(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      deckId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deck_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      targetDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_days'],
      )!,
      itemsPerDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}items_per_day'],
      )!,
      targetItemCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_item_count'],
      )!,
      objective: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}objective'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MemorizationJourneysTable createAlias(String alias) {
    return $MemorizationJourneysTable(attachedDatabase, alias);
  }
}

class MemorizationJourney extends DataClass
    implements Insertable<MemorizationJourney> {
  final String id;
  final String deckId;
  final String title;
  final int targetDays;
  final int itemsPerDay;
  final int targetItemCount;
  final String objective;
  final DateTime createdAt;
  const MemorizationJourney({
    required this.id,
    required this.deckId,
    required this.title,
    required this.targetDays,
    required this.itemsPerDay,
    required this.targetItemCount,
    required this.objective,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['deck_id'] = Variable<String>(deckId);
    map['title'] = Variable<String>(title);
    map['target_days'] = Variable<int>(targetDays);
    map['items_per_day'] = Variable<int>(itemsPerDay);
    map['target_item_count'] = Variable<int>(targetItemCount);
    map['objective'] = Variable<String>(objective);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MemorizationJourneysCompanion toCompanion(bool nullToAbsent) {
    return MemorizationJourneysCompanion(
      id: Value(id),
      deckId: Value(deckId),
      title: Value(title),
      targetDays: Value(targetDays),
      itemsPerDay: Value(itemsPerDay),
      targetItemCount: Value(targetItemCount),
      objective: Value(objective),
      createdAt: Value(createdAt),
    );
  }

  factory MemorizationJourney.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemorizationJourney(
      id: serializer.fromJson<String>(json['id']),
      deckId: serializer.fromJson<String>(json['deckId']),
      title: serializer.fromJson<String>(json['title']),
      targetDays: serializer.fromJson<int>(json['targetDays']),
      itemsPerDay: serializer.fromJson<int>(json['itemsPerDay']),
      targetItemCount: serializer.fromJson<int>(json['targetItemCount']),
      objective: serializer.fromJson<String>(json['objective']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'deckId': serializer.toJson<String>(deckId),
      'title': serializer.toJson<String>(title),
      'targetDays': serializer.toJson<int>(targetDays),
      'itemsPerDay': serializer.toJson<int>(itemsPerDay),
      'targetItemCount': serializer.toJson<int>(targetItemCount),
      'objective': serializer.toJson<String>(objective),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MemorizationJourney copyWith({
    String? id,
    String? deckId,
    String? title,
    int? targetDays,
    int? itemsPerDay,
    int? targetItemCount,
    String? objective,
    DateTime? createdAt,
  }) => MemorizationJourney(
    id: id ?? this.id,
    deckId: deckId ?? this.deckId,
    title: title ?? this.title,
    targetDays: targetDays ?? this.targetDays,
    itemsPerDay: itemsPerDay ?? this.itemsPerDay,
    targetItemCount: targetItemCount ?? this.targetItemCount,
    objective: objective ?? this.objective,
    createdAt: createdAt ?? this.createdAt,
  );
  MemorizationJourney copyWithCompanion(MemorizationJourneysCompanion data) {
    return MemorizationJourney(
      id: data.id.present ? data.id.value : this.id,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      title: data.title.present ? data.title.value : this.title,
      targetDays: data.targetDays.present
          ? data.targetDays.value
          : this.targetDays,
      itemsPerDay: data.itemsPerDay.present
          ? data.itemsPerDay.value
          : this.itemsPerDay,
      targetItemCount: data.targetItemCount.present
          ? data.targetItemCount.value
          : this.targetItemCount,
      objective: data.objective.present ? data.objective.value : this.objective,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemorizationJourney(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('title: $title, ')
          ..write('targetDays: $targetDays, ')
          ..write('itemsPerDay: $itemsPerDay, ')
          ..write('targetItemCount: $targetItemCount, ')
          ..write('objective: $objective, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deckId,
    title,
    targetDays,
    itemsPerDay,
    targetItemCount,
    objective,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemorizationJourney &&
          other.id == this.id &&
          other.deckId == this.deckId &&
          other.title == this.title &&
          other.targetDays == this.targetDays &&
          other.itemsPerDay == this.itemsPerDay &&
          other.targetItemCount == this.targetItemCount &&
          other.objective == this.objective &&
          other.createdAt == this.createdAt);
}

class MemorizationJourneysCompanion
    extends UpdateCompanion<MemorizationJourney> {
  final Value<String> id;
  final Value<String> deckId;
  final Value<String> title;
  final Value<int> targetDays;
  final Value<int> itemsPerDay;
  final Value<int> targetItemCount;
  final Value<String> objective;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MemorizationJourneysCompanion({
    this.id = const Value.absent(),
    this.deckId = const Value.absent(),
    this.title = const Value.absent(),
    this.targetDays = const Value.absent(),
    this.itemsPerDay = const Value.absent(),
    this.targetItemCount = const Value.absent(),
    this.objective = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemorizationJourneysCompanion.insert({
    required String id,
    required String deckId,
    required String title,
    required int targetDays,
    required int itemsPerDay,
    required int targetItemCount,
    required String objective,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       deckId = Value(deckId),
       title = Value(title),
       targetDays = Value(targetDays),
       itemsPerDay = Value(itemsPerDay),
       targetItemCount = Value(targetItemCount),
       objective = Value(objective);
  static Insertable<MemorizationJourney> custom({
    Expression<String>? id,
    Expression<String>? deckId,
    Expression<String>? title,
    Expression<int>? targetDays,
    Expression<int>? itemsPerDay,
    Expression<int>? targetItemCount,
    Expression<String>? objective,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deckId != null) 'deck_id': deckId,
      if (title != null) 'title': title,
      if (targetDays != null) 'target_days': targetDays,
      if (itemsPerDay != null) 'items_per_day': itemsPerDay,
      if (targetItemCount != null) 'target_item_count': targetItemCount,
      if (objective != null) 'objective': objective,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemorizationJourneysCompanion copyWith({
    Value<String>? id,
    Value<String>? deckId,
    Value<String>? title,
    Value<int>? targetDays,
    Value<int>? itemsPerDay,
    Value<int>? targetItemCount,
    Value<String>? objective,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MemorizationJourneysCompanion(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      title: title ?? this.title,
      targetDays: targetDays ?? this.targetDays,
      itemsPerDay: itemsPerDay ?? this.itemsPerDay,
      targetItemCount: targetItemCount ?? this.targetItemCount,
      objective: objective ?? this.objective,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deckId.present) {
      map['deck_id'] = Variable<String>(deckId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (targetDays.present) {
      map['target_days'] = Variable<int>(targetDays.value);
    }
    if (itemsPerDay.present) {
      map['items_per_day'] = Variable<int>(itemsPerDay.value);
    }
    if (targetItemCount.present) {
      map['target_item_count'] = Variable<int>(targetItemCount.value);
    }
    if (objective.present) {
      map['objective'] = Variable<String>(objective.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemorizationJourneysCompanion(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('title: $title, ')
          ..write('targetDays: $targetDays, ')
          ..write('itemsPerDay: $itemsPerDay, ')
          ..write('targetItemCount: $targetItemCount, ')
          ..write('objective: $objective, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AchievementUnlocksTable extends AchievementUnlocks
    with TableInfo<$AchievementUnlocksTable, AchievementUnlock> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AchievementUnlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unlockedAtMeta = const VerificationMeta(
    'unlockedAt',
  );
  @override
  late final GeneratedColumn<DateTime> unlockedAt = GeneratedColumn<DateTime>(
    'unlocked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    title,
    description,
    unlockedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'achievement_unlocks';
  @override
  VerificationContext validateIntegrity(
    Insertable<AchievementUnlock> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('unlocked_at')) {
      context.handle(
        _unlockedAtMeta,
        unlockedAt.isAcceptableOrUnknown(data['unlocked_at']!, _unlockedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AchievementUnlock map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AchievementUnlock(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      unlockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}unlocked_at'],
      )!,
    );
  }

  @override
  $AchievementUnlocksTable createAlias(String alias) {
    return $AchievementUnlocksTable(attachedDatabase, alias);
  }
}

class AchievementUnlock extends DataClass
    implements Insertable<AchievementUnlock> {
  final String id;
  final String code;
  final String title;
  final String description;
  final DateTime unlockedAt;
  const AchievementUnlock({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.unlockedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['unlocked_at'] = Variable<DateTime>(unlockedAt);
    return map;
  }

  AchievementUnlocksCompanion toCompanion(bool nullToAbsent) {
    return AchievementUnlocksCompanion(
      id: Value(id),
      code: Value(code),
      title: Value(title),
      description: Value(description),
      unlockedAt: Value(unlockedAt),
    );
  }

  factory AchievementUnlock.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AchievementUnlock(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      unlockedAt: serializer.fromJson<DateTime>(json['unlockedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'unlockedAt': serializer.toJson<DateTime>(unlockedAt),
    };
  }

  AchievementUnlock copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    DateTime? unlockedAt,
  }) => AchievementUnlock(
    id: id ?? this.id,
    code: code ?? this.code,
    title: title ?? this.title,
    description: description ?? this.description,
    unlockedAt: unlockedAt ?? this.unlockedAt,
  );
  AchievementUnlock copyWithCompanion(AchievementUnlocksCompanion data) {
    return AchievementUnlock(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      unlockedAt: data.unlockedAt.present
          ? data.unlockedAt.value
          : this.unlockedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AchievementUnlock(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('unlockedAt: $unlockedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, code, title, description, unlockedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AchievementUnlock &&
          other.id == this.id &&
          other.code == this.code &&
          other.title == this.title &&
          other.description == this.description &&
          other.unlockedAt == this.unlockedAt);
}

class AchievementUnlocksCompanion extends UpdateCompanion<AchievementUnlock> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> title;
  final Value<String> description;
  final Value<DateTime> unlockedAt;
  final Value<int> rowid;
  const AchievementUnlocksCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AchievementUnlocksCompanion.insert({
    required String id,
    required String code,
    required String title,
    required String description,
    this.unlockedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       code = Value(code),
       title = Value(title),
       description = Value(description);
  static Insertable<AchievementUnlock> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? unlockedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (unlockedAt != null) 'unlocked_at': unlockedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AchievementUnlocksCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<String>? title,
    Value<String>? description,
    Value<DateTime>? unlockedAt,
    Value<int>? rowid,
  }) {
    return AchievementUnlocksCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (unlockedAt.present) {
      map['unlocked_at'] = Variable<DateTime>(unlockedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AchievementUnlocksCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ErrorBankEntriesTable extends ErrorBankEntries
    with TableInfo<$ErrorBankEntriesTable, ErrorBankEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ErrorBankEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<String> deckId = GeneratedColumn<String>(
    'deck_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES decks (id)',
    ),
  );
  static const VerificationMeta _stepTypeMeta = const VerificationMeta(
    'stepType',
  );
  @override
  late final GeneratedColumn<String> stepType = GeneratedColumn<String>(
    'step_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tokenMeta = const VerificationMeta('token');
  @override
  late final GeneratedColumn<String> token = GeneratedColumn<String>(
    'token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorKindMeta = const VerificationMeta(
    'errorKind',
  );
  @override
  late final GeneratedColumn<String> errorKind = GeneratedColumn<String>(
    'error_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurrencesMeta = const VerificationMeta(
    'occurrences',
  );
  @override
  late final GeneratedColumn<int> occurrences = GeneratedColumn<int>(
    'occurrences',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    deckId,
    stepType,
    token,
    errorKind,
    occurrences,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'error_bank_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ErrorBankEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('deck_id')) {
      context.handle(
        _deckIdMeta,
        deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('step_type')) {
      context.handle(
        _stepTypeMeta,
        stepType.isAcceptableOrUnknown(data['step_type']!, _stepTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_stepTypeMeta);
    }
    if (data.containsKey('token')) {
      context.handle(
        _tokenMeta,
        token.isAcceptableOrUnknown(data['token']!, _tokenMeta),
      );
    }
    if (data.containsKey('error_kind')) {
      context.handle(
        _errorKindMeta,
        errorKind.isAcceptableOrUnknown(data['error_kind']!, _errorKindMeta),
      );
    } else if (isInserting) {
      context.missing(_errorKindMeta);
    }
    if (data.containsKey('occurrences')) {
      context.handle(
        _occurrencesMeta,
        occurrences.isAcceptableOrUnknown(
          data['occurrences']!,
          _occurrencesMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ErrorBankEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ErrorBankEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      deckId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deck_id'],
      )!,
      stepType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}step_type'],
      )!,
      token: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}token'],
      ),
      errorKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_kind'],
      )!,
      occurrences: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurrences'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ErrorBankEntriesTable createAlias(String alias) {
    return $ErrorBankEntriesTable(attachedDatabase, alias);
  }
}

class ErrorBankEntry extends DataClass implements Insertable<ErrorBankEntry> {
  final int id;
  final String itemId;
  final String deckId;
  final String stepType;
  final String? token;
  final String errorKind;
  final int occurrences;
  final DateTime createdAt;
  const ErrorBankEntry({
    required this.id,
    required this.itemId,
    required this.deckId,
    required this.stepType,
    this.token,
    required this.errorKind,
    required this.occurrences,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<String>(itemId);
    map['deck_id'] = Variable<String>(deckId);
    map['step_type'] = Variable<String>(stepType);
    if (!nullToAbsent || token != null) {
      map['token'] = Variable<String>(token);
    }
    map['error_kind'] = Variable<String>(errorKind);
    map['occurrences'] = Variable<int>(occurrences);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ErrorBankEntriesCompanion toCompanion(bool nullToAbsent) {
    return ErrorBankEntriesCompanion(
      id: Value(id),
      itemId: Value(itemId),
      deckId: Value(deckId),
      stepType: Value(stepType),
      token: token == null && nullToAbsent
          ? const Value.absent()
          : Value(token),
      errorKind: Value(errorKind),
      occurrences: Value(occurrences),
      createdAt: Value(createdAt),
    );
  }

  factory ErrorBankEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ErrorBankEntry(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      deckId: serializer.fromJson<String>(json['deckId']),
      stepType: serializer.fromJson<String>(json['stepType']),
      token: serializer.fromJson<String?>(json['token']),
      errorKind: serializer.fromJson<String>(json['errorKind']),
      occurrences: serializer.fromJson<int>(json['occurrences']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<String>(itemId),
      'deckId': serializer.toJson<String>(deckId),
      'stepType': serializer.toJson<String>(stepType),
      'token': serializer.toJson<String?>(token),
      'errorKind': serializer.toJson<String>(errorKind),
      'occurrences': serializer.toJson<int>(occurrences),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ErrorBankEntry copyWith({
    int? id,
    String? itemId,
    String? deckId,
    String? stepType,
    Value<String?> token = const Value.absent(),
    String? errorKind,
    int? occurrences,
    DateTime? createdAt,
  }) => ErrorBankEntry(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    deckId: deckId ?? this.deckId,
    stepType: stepType ?? this.stepType,
    token: token.present ? token.value : this.token,
    errorKind: errorKind ?? this.errorKind,
    occurrences: occurrences ?? this.occurrences,
    createdAt: createdAt ?? this.createdAt,
  );
  ErrorBankEntry copyWithCompanion(ErrorBankEntriesCompanion data) {
    return ErrorBankEntry(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      stepType: data.stepType.present ? data.stepType.value : this.stepType,
      token: data.token.present ? data.token.value : this.token,
      errorKind: data.errorKind.present ? data.errorKind.value : this.errorKind,
      occurrences: data.occurrences.present
          ? data.occurrences.value
          : this.occurrences,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ErrorBankEntry(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('deckId: $deckId, ')
          ..write('stepType: $stepType, ')
          ..write('token: $token, ')
          ..write('errorKind: $errorKind, ')
          ..write('occurrences: $occurrences, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    deckId,
    stepType,
    token,
    errorKind,
    occurrences,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ErrorBankEntry &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.deckId == this.deckId &&
          other.stepType == this.stepType &&
          other.token == this.token &&
          other.errorKind == this.errorKind &&
          other.occurrences == this.occurrences &&
          other.createdAt == this.createdAt);
}

class ErrorBankEntriesCompanion extends UpdateCompanion<ErrorBankEntry> {
  final Value<int> id;
  final Value<String> itemId;
  final Value<String> deckId;
  final Value<String> stepType;
  final Value<String?> token;
  final Value<String> errorKind;
  final Value<int> occurrences;
  final Value<DateTime> createdAt;
  const ErrorBankEntriesCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.deckId = const Value.absent(),
    this.stepType = const Value.absent(),
    this.token = const Value.absent(),
    this.errorKind = const Value.absent(),
    this.occurrences = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ErrorBankEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String itemId,
    required String deckId,
    required String stepType,
    this.token = const Value.absent(),
    required String errorKind,
    this.occurrences = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : itemId = Value(itemId),
       deckId = Value(deckId),
       stepType = Value(stepType),
       errorKind = Value(errorKind);
  static Insertable<ErrorBankEntry> custom({
    Expression<int>? id,
    Expression<String>? itemId,
    Expression<String>? deckId,
    Expression<String>? stepType,
    Expression<String>? token,
    Expression<String>? errorKind,
    Expression<int>? occurrences,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (deckId != null) 'deck_id': deckId,
      if (stepType != null) 'step_type': stepType,
      if (token != null) 'token': token,
      if (errorKind != null) 'error_kind': errorKind,
      if (occurrences != null) 'occurrences': occurrences,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ErrorBankEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? itemId,
    Value<String>? deckId,
    Value<String>? stepType,
    Value<String?>? token,
    Value<String>? errorKind,
    Value<int>? occurrences,
    Value<DateTime>? createdAt,
  }) {
    return ErrorBankEntriesCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      deckId: deckId ?? this.deckId,
      stepType: stepType ?? this.stepType,
      token: token ?? this.token,
      errorKind: errorKind ?? this.errorKind,
      occurrences: occurrences ?? this.occurrences,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (deckId.present) {
      map['deck_id'] = Variable<String>(deckId.value);
    }
    if (stepType.present) {
      map['step_type'] = Variable<String>(stepType.value);
    }
    if (token.present) {
      map['token'] = Variable<String>(token.value);
    }
    if (errorKind.present) {
      map['error_kind'] = Variable<String>(errorKind.value);
    }
    if (occurrences.present) {
      map['occurrences'] = Variable<int>(occurrences.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ErrorBankEntriesCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('deckId: $deckId, ')
          ..write('stepType: $stepType, ')
          ..write('token: $token, ')
          ..write('errorKind: $errorKind, ')
          ..write('occurrences: $occurrences, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DecksTable decks = $DecksTable(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $ReviewLogsTable reviewLogs = $ReviewLogsTable(this);
  late final $MemorizationPlansTable memorizationPlans =
      $MemorizationPlansTable(this);
  late final $MemorizationPlanItemsTable memorizationPlanItems =
      $MemorizationPlanItemsTable(this);
  late final $ExerciseAttemptsTable exerciseAttempts = $ExerciseAttemptsTable(
    this,
  );
  late final $AudioClipsTable audioClips = $AudioClipsTable(this);
  late final $ExerciseConsolidationsTable exerciseConsolidations =
      $ExerciseConsolidationsTable(this);
  late final $CardsConsolidationsTable cardsConsolidations =
      $CardsConsolidationsTable(this);
  late final $MemorizationGoalsTable memorizationGoals =
      $MemorizationGoalsTable(this);
  late final $MemorizationJourneysTable memorizationJourneys =
      $MemorizationJourneysTable(this);
  late final $AchievementUnlocksTable achievementUnlocks =
      $AchievementUnlocksTable(this);
  late final $ErrorBankEntriesTable errorBankEntries = $ErrorBankEntriesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    decks,
    items,
    reviewLogs,
    memorizationPlans,
    memorizationPlanItems,
    exerciseAttempts,
    audioClips,
    exerciseConsolidations,
    cardsConsolidations,
    memorizationGoals,
    memorizationJourneys,
    achievementUnlocks,
    errorBankEntries,
  ];
}

typedef $$DecksTableCreateCompanionBuilder =
    DecksCompanion Function({
      required String id,
      required String name,
      required String description,
      required String type,
      Value<int> accentColorIndex,
      Value<String?> emoji,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$DecksTableUpdateCompanionBuilder =
    DecksCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> description,
      Value<String> type,
      Value<int> accentColorIndex,
      Value<String?> emoji,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$DecksTableReferences
    extends BaseReferences<_$AppDatabase, $DecksTable, Deck> {
  $$DecksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ItemsTable, List<Item>> _itemsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.items,
    aliasName: $_aliasNameGenerator(db.decks.id, db.items.deckId),
  );

  $$ItemsTableProcessedTableManager get itemsRefs {
    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.deckId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReviewLogsTable, List<ReviewLog>>
  _reviewLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reviewLogs,
    aliasName: $_aliasNameGenerator(db.decks.id, db.reviewLogs.deckId),
  );

  $$ReviewLogsTableProcessedTableManager get reviewLogsRefs {
    final manager = $$ReviewLogsTableTableManager(
      $_db,
      $_db.reviewLogs,
    ).filter((f) => f.deckId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_reviewLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MemorizationPlansTable, List<MemorizationPlan>>
  _memorizationPlansRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.memorizationPlans,
        aliasName: $_aliasNameGenerator(
          db.decks.id,
          db.memorizationPlans.deckId,
        ),
      );

  $$MemorizationPlansTableProcessedTableManager get memorizationPlansRefs {
    final manager = $$MemorizationPlansTableTableManager(
      $_db,
      $_db.memorizationPlans,
    ).filter((f) => f.deckId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _memorizationPlansRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ExerciseConsolidationsTable,
    List<ExerciseConsolidation>
  >
  _exerciseConsolidationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.exerciseConsolidations,
        aliasName: $_aliasNameGenerator(
          db.decks.id,
          db.exerciseConsolidations.deckId,
        ),
      );

  $$ExerciseConsolidationsTableProcessedTableManager
  get exerciseConsolidationsRefs {
    final manager = $$ExerciseConsolidationsTableTableManager(
      $_db,
      $_db.exerciseConsolidations,
    ).filter((f) => f.deckId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exerciseConsolidationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $CardsConsolidationsTable,
    List<CardsConsolidation>
  >
  _cardsConsolidationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.cardsConsolidations,
        aliasName: $_aliasNameGenerator(
          db.decks.id,
          db.cardsConsolidations.deckId,
        ),
      );

  $$CardsConsolidationsTableProcessedTableManager get cardsConsolidationsRefs {
    final manager = $$CardsConsolidationsTableTableManager(
      $_db,
      $_db.cardsConsolidations,
    ).filter((f) => f.deckId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _cardsConsolidationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MemorizationGoalsTable, List<MemorizationGoal>>
  _memorizationGoalsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.memorizationGoals,
        aliasName: $_aliasNameGenerator(
          db.decks.id,
          db.memorizationGoals.deckId,
        ),
      );

  $$MemorizationGoalsTableProcessedTableManager get memorizationGoalsRefs {
    final manager = $$MemorizationGoalsTableTableManager(
      $_db,
      $_db.memorizationGoals,
    ).filter((f) => f.deckId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _memorizationGoalsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $MemorizationJourneysTable,
    List<MemorizationJourney>
  >
  _memorizationJourneysRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.memorizationJourneys,
        aliasName: $_aliasNameGenerator(
          db.decks.id,
          db.memorizationJourneys.deckId,
        ),
      );

  $$MemorizationJourneysTableProcessedTableManager
  get memorizationJourneysRefs {
    final manager = $$MemorizationJourneysTableTableManager(
      $_db,
      $_db.memorizationJourneys,
    ).filter((f) => f.deckId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _memorizationJourneysRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ErrorBankEntriesTable, List<ErrorBankEntry>>
  _errorBankEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.errorBankEntries,
    aliasName: $_aliasNameGenerator(db.decks.id, db.errorBankEntries.deckId),
  );

  $$ErrorBankEntriesTableProcessedTableManager get errorBankEntriesRefs {
    final manager = $$ErrorBankEntriesTableTableManager(
      $_db,
      $_db.errorBankEntries,
    ).filter((f) => f.deckId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _errorBankEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DecksTableFilterComposer extends Composer<_$AppDatabase, $DecksTable> {
  $$DecksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accentColorIndex => $composableBuilder(
    column: $table.accentColorIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> itemsRefs(
    Expression<bool> Function($$ItemsTableFilterComposer f) f,
  ) {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> reviewLogsRefs(
    Expression<bool> Function($$ReviewLogsTableFilterComposer f) f,
  ) {
    final $$ReviewLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewLogs,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewLogsTableFilterComposer(
            $db: $db,
            $table: $db.reviewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> memorizationPlansRefs(
    Expression<bool> Function($$MemorizationPlansTableFilterComposer f) f,
  ) {
    final $$MemorizationPlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.memorizationPlans,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemorizationPlansTableFilterComposer(
            $db: $db,
            $table: $db.memorizationPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> exerciseConsolidationsRefs(
    Expression<bool> Function($$ExerciseConsolidationsTableFilterComposer f) f,
  ) {
    final $$ExerciseConsolidationsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.exerciseConsolidations,
          getReferencedColumn: (t) => t.deckId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExerciseConsolidationsTableFilterComposer(
                $db: $db,
                $table: $db.exerciseConsolidations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> cardsConsolidationsRefs(
    Expression<bool> Function($$CardsConsolidationsTableFilterComposer f) f,
  ) {
    final $$CardsConsolidationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cardsConsolidations,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsConsolidationsTableFilterComposer(
            $db: $db,
            $table: $db.cardsConsolidations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> memorizationGoalsRefs(
    Expression<bool> Function($$MemorizationGoalsTableFilterComposer f) f,
  ) {
    final $$MemorizationGoalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.memorizationGoals,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemorizationGoalsTableFilterComposer(
            $db: $db,
            $table: $db.memorizationGoals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> memorizationJourneysRefs(
    Expression<bool> Function($$MemorizationJourneysTableFilterComposer f) f,
  ) {
    final $$MemorizationJourneysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.memorizationJourneys,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemorizationJourneysTableFilterComposer(
            $db: $db,
            $table: $db.memorizationJourneys,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> errorBankEntriesRefs(
    Expression<bool> Function($$ErrorBankEntriesTableFilterComposer f) f,
  ) {
    final $$ErrorBankEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.errorBankEntries,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ErrorBankEntriesTableFilterComposer(
            $db: $db,
            $table: $db.errorBankEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DecksTableOrderingComposer
    extends Composer<_$AppDatabase, $DecksTable> {
  $$DecksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accentColorIndex => $composableBuilder(
    column: $table.accentColorIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DecksTableAnnotationComposer
    extends Composer<_$AppDatabase, $DecksTable> {
  $$DecksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get accentColorIndex => $composableBuilder(
    column: $table.accentColorIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> itemsRefs<T extends Object>(
    Expression<T> Function($$ItemsTableAnnotationComposer a) f,
  ) {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> reviewLogsRefs<T extends Object>(
    Expression<T> Function($$ReviewLogsTableAnnotationComposer a) f,
  ) {
    final $$ReviewLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewLogs,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.reviewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> memorizationPlansRefs<T extends Object>(
    Expression<T> Function($$MemorizationPlansTableAnnotationComposer a) f,
  ) {
    final $$MemorizationPlansTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.memorizationPlans,
          getReferencedColumn: (t) => t.deckId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MemorizationPlansTableAnnotationComposer(
                $db: $db,
                $table: $db.memorizationPlans,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> exerciseConsolidationsRefs<T extends Object>(
    Expression<T> Function($$ExerciseConsolidationsTableAnnotationComposer a) f,
  ) {
    final $$ExerciseConsolidationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.exerciseConsolidations,
          getReferencedColumn: (t) => t.deckId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExerciseConsolidationsTableAnnotationComposer(
                $db: $db,
                $table: $db.exerciseConsolidations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> cardsConsolidationsRefs<T extends Object>(
    Expression<T> Function($$CardsConsolidationsTableAnnotationComposer a) f,
  ) {
    final $$CardsConsolidationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.cardsConsolidations,
          getReferencedColumn: (t) => t.deckId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CardsConsolidationsTableAnnotationComposer(
                $db: $db,
                $table: $db.cardsConsolidations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> memorizationGoalsRefs<T extends Object>(
    Expression<T> Function($$MemorizationGoalsTableAnnotationComposer a) f,
  ) {
    final $$MemorizationGoalsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.memorizationGoals,
          getReferencedColumn: (t) => t.deckId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MemorizationGoalsTableAnnotationComposer(
                $db: $db,
                $table: $db.memorizationGoals,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> memorizationJourneysRefs<T extends Object>(
    Expression<T> Function($$MemorizationJourneysTableAnnotationComposer a) f,
  ) {
    final $$MemorizationJourneysTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.memorizationJourneys,
          getReferencedColumn: (t) => t.deckId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MemorizationJourneysTableAnnotationComposer(
                $db: $db,
                $table: $db.memorizationJourneys,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> errorBankEntriesRefs<T extends Object>(
    Expression<T> Function($$ErrorBankEntriesTableAnnotationComposer a) f,
  ) {
    final $$ErrorBankEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.errorBankEntries,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ErrorBankEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.errorBankEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DecksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DecksTable,
          Deck,
          $$DecksTableFilterComposer,
          $$DecksTableOrderingComposer,
          $$DecksTableAnnotationComposer,
          $$DecksTableCreateCompanionBuilder,
          $$DecksTableUpdateCompanionBuilder,
          (Deck, $$DecksTableReferences),
          Deck,
          PrefetchHooks Function({
            bool itemsRefs,
            bool reviewLogsRefs,
            bool memorizationPlansRefs,
            bool exerciseConsolidationsRefs,
            bool cardsConsolidationsRefs,
            bool memorizationGoalsRefs,
            bool memorizationJourneysRefs,
            bool errorBankEntriesRefs,
          })
        > {
  $$DecksTableTableManager(_$AppDatabase db, $DecksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DecksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DecksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DecksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> accentColorIndex = const Value.absent(),
                Value<String?> emoji = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DecksCompanion(
                id: id,
                name: name,
                description: description,
                type: type,
                accentColorIndex: accentColorIndex,
                emoji: emoji,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String description,
                required String type,
                Value<int> accentColorIndex = const Value.absent(),
                Value<String?> emoji = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DecksCompanion.insert(
                id: id,
                name: name,
                description: description,
                type: type,
                accentColorIndex: accentColorIndex,
                emoji: emoji,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$DecksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                itemsRefs = false,
                reviewLogsRefs = false,
                memorizationPlansRefs = false,
                exerciseConsolidationsRefs = false,
                cardsConsolidationsRefs = false,
                memorizationGoalsRefs = false,
                memorizationJourneysRefs = false,
                errorBankEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (itemsRefs) db.items,
                    if (reviewLogsRefs) db.reviewLogs,
                    if (memorizationPlansRefs) db.memorizationPlans,
                    if (exerciseConsolidationsRefs) db.exerciseConsolidations,
                    if (cardsConsolidationsRefs) db.cardsConsolidations,
                    if (memorizationGoalsRefs) db.memorizationGoals,
                    if (memorizationJourneysRefs) db.memorizationJourneys,
                    if (errorBankEntriesRefs) db.errorBankEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (itemsRefs)
                        await $_getPrefetchedData<Deck, $DecksTable, Item>(
                          currentTable: table,
                          referencedTable: $$DecksTableReferences
                              ._itemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DecksTableReferences(db, table, p0).itemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.deckId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (reviewLogsRefs)
                        await $_getPrefetchedData<Deck, $DecksTable, ReviewLog>(
                          currentTable: table,
                          referencedTable: $$DecksTableReferences
                              ._reviewLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DecksTableReferences(
                                db,
                                table,
                                p0,
                              ).reviewLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.deckId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (memorizationPlansRefs)
                        await $_getPrefetchedData<
                          Deck,
                          $DecksTable,
                          MemorizationPlan
                        >(
                          currentTable: table,
                          referencedTable: $$DecksTableReferences
                              ._memorizationPlansRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DecksTableReferences(
                                db,
                                table,
                                p0,
                              ).memorizationPlansRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.deckId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (exerciseConsolidationsRefs)
                        await $_getPrefetchedData<
                          Deck,
                          $DecksTable,
                          ExerciseConsolidation
                        >(
                          currentTable: table,
                          referencedTable: $$DecksTableReferences
                              ._exerciseConsolidationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DecksTableReferences(
                                db,
                                table,
                                p0,
                              ).exerciseConsolidationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.deckId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cardsConsolidationsRefs)
                        await $_getPrefetchedData<
                          Deck,
                          $DecksTable,
                          CardsConsolidation
                        >(
                          currentTable: table,
                          referencedTable: $$DecksTableReferences
                              ._cardsConsolidationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DecksTableReferences(
                                db,
                                table,
                                p0,
                              ).cardsConsolidationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.deckId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (memorizationGoalsRefs)
                        await $_getPrefetchedData<
                          Deck,
                          $DecksTable,
                          MemorizationGoal
                        >(
                          currentTable: table,
                          referencedTable: $$DecksTableReferences
                              ._memorizationGoalsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DecksTableReferences(
                                db,
                                table,
                                p0,
                              ).memorizationGoalsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.deckId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (memorizationJourneysRefs)
                        await $_getPrefetchedData<
                          Deck,
                          $DecksTable,
                          MemorizationJourney
                        >(
                          currentTable: table,
                          referencedTable: $$DecksTableReferences
                              ._memorizationJourneysRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DecksTableReferences(
                                db,
                                table,
                                p0,
                              ).memorizationJourneysRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.deckId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (errorBankEntriesRefs)
                        await $_getPrefetchedData<
                          Deck,
                          $DecksTable,
                          ErrorBankEntry
                        >(
                          currentTable: table,
                          referencedTable: $$DecksTableReferences
                              ._errorBankEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DecksTableReferences(
                                db,
                                table,
                                p0,
                              ).errorBankEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.deckId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DecksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DecksTable,
      Deck,
      $$DecksTableFilterComposer,
      $$DecksTableOrderingComposer,
      $$DecksTableAnnotationComposer,
      $$DecksTableCreateCompanionBuilder,
      $$DecksTableUpdateCompanionBuilder,
      (Deck, $$DecksTableReferences),
      Deck,
      PrefetchHooks Function({
        bool itemsRefs,
        bool reviewLogsRefs,
        bool memorizationPlansRefs,
        bool exerciseConsolidationsRefs,
        bool cardsConsolidationsRefs,
        bool memorizationGoalsRefs,
        bool memorizationJourneysRefs,
        bool errorBankEntriesRefs,
      })
    >;
typedef $$ItemsTableCreateCompanionBuilder =
    ItemsCompanion Function({
      required String id,
      required String deckId,
      required String front,
      required String back,
      Value<double> easeFactor,
      Value<int> interval,
      Value<int> repetitions,
      Value<DateTime?> nextReviewAt,
      Value<DateTime?> lastReviewedAt,
      Value<String?> book,
      Value<int?> chapter,
      Value<int?> verse,
      Value<int> rowid,
    });
typedef $$ItemsTableUpdateCompanionBuilder =
    ItemsCompanion Function({
      Value<String> id,
      Value<String> deckId,
      Value<String> front,
      Value<String> back,
      Value<double> easeFactor,
      Value<int> interval,
      Value<int> repetitions,
      Value<DateTime?> nextReviewAt,
      Value<DateTime?> lastReviewedAt,
      Value<String?> book,
      Value<int?> chapter,
      Value<int?> verse,
      Value<int> rowid,
    });

final class $$ItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ItemsTable, Item> {
  $$ItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DecksTable _deckIdTable(_$AppDatabase db) =>
      db.decks.createAlias($_aliasNameGenerator(db.items.deckId, db.decks.id));

  $$DecksTableProcessedTableManager get deckId {
    final $_column = $_itemColumn<String>('deck_id')!;

    final manager = $$DecksTableTableManager(
      $_db,
      $_db.decks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deckIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ReviewLogsTable, List<ReviewLog>>
  _reviewLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reviewLogs,
    aliasName: $_aliasNameGenerator(db.items.id, db.reviewLogs.itemId),
  );

  $$ReviewLogsTableProcessedTableManager get reviewLogsRefs {
    final manager = $$ReviewLogsTableTableManager(
      $_db,
      $_db.reviewLogs,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_reviewLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $MemorizationPlanItemsTable,
    List<MemorizationPlanItem>
  >
  _memorizationPlanItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.memorizationPlanItems,
        aliasName: $_aliasNameGenerator(
          db.items.id,
          db.memorizationPlanItems.itemId,
        ),
      );

  $$MemorizationPlanItemsTableProcessedTableManager
  get memorizationPlanItemsRefs {
    final manager = $$MemorizationPlanItemsTableTableManager(
      $_db,
      $_db.memorizationPlanItems,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _memorizationPlanItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExerciseAttemptsTable, List<ExerciseAttempt>>
  _exerciseAttemptsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.exerciseAttempts,
    aliasName: $_aliasNameGenerator(db.items.id, db.exerciseAttempts.itemId),
  );

  $$ExerciseAttemptsTableProcessedTableManager get exerciseAttemptsRefs {
    final manager = $$ExerciseAttemptsTableTableManager(
      $_db,
      $_db.exerciseAttempts,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exerciseAttemptsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AudioClipsTable, List<AudioClip>>
  _audioClipsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.audioClips,
    aliasName: $_aliasNameGenerator(db.items.id, db.audioClips.itemId),
  );

  $$AudioClipsTableProcessedTableManager get audioClipsRefs {
    final manager = $$AudioClipsTableTableManager(
      $_db,
      $_db.audioClips,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_audioClipsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ExerciseConsolidationsTable,
    List<ExerciseConsolidation>
  >
  _exerciseConsolidationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.exerciseConsolidations,
        aliasName: $_aliasNameGenerator(
          db.items.id,
          db.exerciseConsolidations.itemId,
        ),
      );

  $$ExerciseConsolidationsTableProcessedTableManager
  get exerciseConsolidationsRefs {
    final manager = $$ExerciseConsolidationsTableTableManager(
      $_db,
      $_db.exerciseConsolidations,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exerciseConsolidationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ErrorBankEntriesTable, List<ErrorBankEntry>>
  _errorBankEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.errorBankEntries,
    aliasName: $_aliasNameGenerator(db.items.id, db.errorBankEntries.itemId),
  );

  $$ErrorBankEntriesTableProcessedTableManager get errorBankEntriesRefs {
    final manager = $$ErrorBankEntriesTableTableManager(
      $_db,
      $_db.errorBankEntries,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _errorBankEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ItemsTableFilterComposer extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get front => $composableBuilder(
    column: $table.front,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get back => $composableBuilder(
    column: $table.back,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get interval => $composableBuilder(
    column: $table.interval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get book => $composableBuilder(
    column: $table.book,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get verse => $composableBuilder(
    column: $table.verse,
    builder: (column) => ColumnFilters(column),
  );

  $$DecksTableFilterComposer get deckId {
    final $$DecksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableFilterComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> reviewLogsRefs(
    Expression<bool> Function($$ReviewLogsTableFilterComposer f) f,
  ) {
    final $$ReviewLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewLogs,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewLogsTableFilterComposer(
            $db: $db,
            $table: $db.reviewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> memorizationPlanItemsRefs(
    Expression<bool> Function($$MemorizationPlanItemsTableFilterComposer f) f,
  ) {
    final $$MemorizationPlanItemsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.memorizationPlanItems,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MemorizationPlanItemsTableFilterComposer(
                $db: $db,
                $table: $db.memorizationPlanItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> exerciseAttemptsRefs(
    Expression<bool> Function($$ExerciseAttemptsTableFilterComposer f) f,
  ) {
    final $$ExerciseAttemptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseAttempts,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseAttemptsTableFilterComposer(
            $db: $db,
            $table: $db.exerciseAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> audioClipsRefs(
    Expression<bool> Function($$AudioClipsTableFilterComposer f) f,
  ) {
    final $$AudioClipsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.audioClips,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AudioClipsTableFilterComposer(
            $db: $db,
            $table: $db.audioClips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> exerciseConsolidationsRefs(
    Expression<bool> Function($$ExerciseConsolidationsTableFilterComposer f) f,
  ) {
    final $$ExerciseConsolidationsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.exerciseConsolidations,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExerciseConsolidationsTableFilterComposer(
                $db: $db,
                $table: $db.exerciseConsolidations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> errorBankEntriesRefs(
    Expression<bool> Function($$ErrorBankEntriesTableFilterComposer f) f,
  ) {
    final $$ErrorBankEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.errorBankEntries,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ErrorBankEntriesTableFilterComposer(
            $db: $db,
            $table: $db.errorBankEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get front => $composableBuilder(
    column: $table.front,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get back => $composableBuilder(
    column: $table.back,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get interval => $composableBuilder(
    column: $table.interval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get book => $composableBuilder(
    column: $table.book,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get verse => $composableBuilder(
    column: $table.verse,
    builder: (column) => ColumnOrderings(column),
  );

  $$DecksTableOrderingComposer get deckId {
    final $$DecksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableOrderingComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get front =>
      $composableBuilder(column: $table.front, builder: (column) => column);

  GeneratedColumn<String> get back =>
      $composableBuilder(column: $table.back, builder: (column) => column);

  GeneratedColumn<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get interval =>
      $composableBuilder(column: $table.interval, builder: (column) => column);

  GeneratedColumn<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get book =>
      $composableBuilder(column: $table.book, builder: (column) => column);

  GeneratedColumn<int> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<int> get verse =>
      $composableBuilder(column: $table.verse, builder: (column) => column);

  $$DecksTableAnnotationComposer get deckId {
    final $$DecksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableAnnotationComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> reviewLogsRefs<T extends Object>(
    Expression<T> Function($$ReviewLogsTableAnnotationComposer a) f,
  ) {
    final $$ReviewLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewLogs,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.reviewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> memorizationPlanItemsRefs<T extends Object>(
    Expression<T> Function($$MemorizationPlanItemsTableAnnotationComposer a) f,
  ) {
    final $$MemorizationPlanItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.memorizationPlanItems,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MemorizationPlanItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.memorizationPlanItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> exerciseAttemptsRefs<T extends Object>(
    Expression<T> Function($$ExerciseAttemptsTableAnnotationComposer a) f,
  ) {
    final $$ExerciseAttemptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseAttempts,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseAttemptsTableAnnotationComposer(
            $db: $db,
            $table: $db.exerciseAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> audioClipsRefs<T extends Object>(
    Expression<T> Function($$AudioClipsTableAnnotationComposer a) f,
  ) {
    final $$AudioClipsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.audioClips,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AudioClipsTableAnnotationComposer(
            $db: $db,
            $table: $db.audioClips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> exerciseConsolidationsRefs<T extends Object>(
    Expression<T> Function($$ExerciseConsolidationsTableAnnotationComposer a) f,
  ) {
    final $$ExerciseConsolidationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.exerciseConsolidations,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExerciseConsolidationsTableAnnotationComposer(
                $db: $db,
                $table: $db.exerciseConsolidations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> errorBankEntriesRefs<T extends Object>(
    Expression<T> Function($$ErrorBankEntriesTableAnnotationComposer a) f,
  ) {
    final $$ErrorBankEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.errorBankEntries,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ErrorBankEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.errorBankEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemsTable,
          Item,
          $$ItemsTableFilterComposer,
          $$ItemsTableOrderingComposer,
          $$ItemsTableAnnotationComposer,
          $$ItemsTableCreateCompanionBuilder,
          $$ItemsTableUpdateCompanionBuilder,
          (Item, $$ItemsTableReferences),
          Item,
          PrefetchHooks Function({
            bool deckId,
            bool reviewLogsRefs,
            bool memorizationPlanItemsRefs,
            bool exerciseAttemptsRefs,
            bool audioClipsRefs,
            bool exerciseConsolidationsRefs,
            bool errorBankEntriesRefs,
          })
        > {
  $$ItemsTableTableManager(_$AppDatabase db, $ItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> deckId = const Value.absent(),
                Value<String> front = const Value.absent(),
                Value<String> back = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<int> interval = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<DateTime?> nextReviewAt = const Value.absent(),
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<String?> book = const Value.absent(),
                Value<int?> chapter = const Value.absent(),
                Value<int?> verse = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion(
                id: id,
                deckId: deckId,
                front: front,
                back: back,
                easeFactor: easeFactor,
                interval: interval,
                repetitions: repetitions,
                nextReviewAt: nextReviewAt,
                lastReviewedAt: lastReviewedAt,
                book: book,
                chapter: chapter,
                verse: verse,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String deckId,
                required String front,
                required String back,
                Value<double> easeFactor = const Value.absent(),
                Value<int> interval = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<DateTime?> nextReviewAt = const Value.absent(),
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<String?> book = const Value.absent(),
                Value<int?> chapter = const Value.absent(),
                Value<int?> verse = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion.insert(
                id: id,
                deckId: deckId,
                front: front,
                back: back,
                easeFactor: easeFactor,
                interval: interval,
                repetitions: repetitions,
                nextReviewAt: nextReviewAt,
                lastReviewedAt: lastReviewedAt,
                book: book,
                chapter: chapter,
                verse: verse,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ItemsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                deckId = false,
                reviewLogsRefs = false,
                memorizationPlanItemsRefs = false,
                exerciseAttemptsRefs = false,
                audioClipsRefs = false,
                exerciseConsolidationsRefs = false,
                errorBankEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (reviewLogsRefs) db.reviewLogs,
                    if (memorizationPlanItemsRefs) db.memorizationPlanItems,
                    if (exerciseAttemptsRefs) db.exerciseAttempts,
                    if (audioClipsRefs) db.audioClips,
                    if (exerciseConsolidationsRefs) db.exerciseConsolidations,
                    if (errorBankEntriesRefs) db.errorBankEntries,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (deckId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.deckId,
                                    referencedTable: $$ItemsTableReferences
                                        ._deckIdTable(db),
                                    referencedColumn: $$ItemsTableReferences
                                        ._deckIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (reviewLogsRefs)
                        await $_getPrefetchedData<Item, $ItemsTable, ReviewLog>(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._reviewLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).reviewLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (memorizationPlanItemsRefs)
                        await $_getPrefetchedData<
                          Item,
                          $ItemsTable,
                          MemorizationPlanItem
                        >(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._memorizationPlanItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).memorizationPlanItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (exerciseAttemptsRefs)
                        await $_getPrefetchedData<
                          Item,
                          $ItemsTable,
                          ExerciseAttempt
                        >(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._exerciseAttemptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).exerciseAttemptsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (audioClipsRefs)
                        await $_getPrefetchedData<Item, $ItemsTable, AudioClip>(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._audioClipsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).audioClipsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (exerciseConsolidationsRefs)
                        await $_getPrefetchedData<
                          Item,
                          $ItemsTable,
                          ExerciseConsolidation
                        >(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._exerciseConsolidationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).exerciseConsolidationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (errorBankEntriesRefs)
                        await $_getPrefetchedData<
                          Item,
                          $ItemsTable,
                          ErrorBankEntry
                        >(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._errorBankEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).errorBankEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemsTable,
      Item,
      $$ItemsTableFilterComposer,
      $$ItemsTableOrderingComposer,
      $$ItemsTableAnnotationComposer,
      $$ItemsTableCreateCompanionBuilder,
      $$ItemsTableUpdateCompanionBuilder,
      (Item, $$ItemsTableReferences),
      Item,
      PrefetchHooks Function({
        bool deckId,
        bool reviewLogsRefs,
        bool memorizationPlanItemsRefs,
        bool exerciseAttemptsRefs,
        bool audioClipsRefs,
        bool exerciseConsolidationsRefs,
        bool errorBankEntriesRefs,
      })
    >;
typedef $$ReviewLogsTableCreateCompanionBuilder =
    ReviewLogsCompanion Function({
      Value<int> id,
      required String itemId,
      required String deckId,
      required String rating,
      required int intervalBefore,
      required int intervalAfter,
      Value<DateTime> reviewedAt,
    });
typedef $$ReviewLogsTableUpdateCompanionBuilder =
    ReviewLogsCompanion Function({
      Value<int> id,
      Value<String> itemId,
      Value<String> deckId,
      Value<String> rating,
      Value<int> intervalBefore,
      Value<int> intervalAfter,
      Value<DateTime> reviewedAt,
    });

final class $$ReviewLogsTableReferences
    extends BaseReferences<_$AppDatabase, $ReviewLogsTable, ReviewLog> {
  $$ReviewLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemsTable _itemIdTable(_$AppDatabase db) => db.items.createAlias(
    $_aliasNameGenerator(db.reviewLogs.itemId, db.items.id),
  );

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DecksTable _deckIdTable(_$AppDatabase db) => db.decks.createAlias(
    $_aliasNameGenerator(db.reviewLogs.deckId, db.decks.id),
  );

  $$DecksTableProcessedTableManager get deckId {
    final $_column = $_itemColumn<String>('deck_id')!;

    final manager = $$DecksTableTableManager(
      $_db,
      $_db.decks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deckIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReviewLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalBefore => $composableBuilder(
    column: $table.intervalBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalAfter => $composableBuilder(
    column: $table.intervalAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DecksTableFilterComposer get deckId {
    final $$DecksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableFilterComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalBefore => $composableBuilder(
    column: $table.intervalBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalAfter => $composableBuilder(
    column: $table.intervalAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DecksTableOrderingComposer get deckId {
    final $$DecksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableOrderingComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get intervalBefore => $composableBuilder(
    column: $table.intervalBefore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalAfter => $composableBuilder(
    column: $table.intervalAfter,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DecksTableAnnotationComposer get deckId {
    final $$DecksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableAnnotationComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewLogsTable,
          ReviewLog,
          $$ReviewLogsTableFilterComposer,
          $$ReviewLogsTableOrderingComposer,
          $$ReviewLogsTableAnnotationComposer,
          $$ReviewLogsTableCreateCompanionBuilder,
          $$ReviewLogsTableUpdateCompanionBuilder,
          (ReviewLog, $$ReviewLogsTableReferences),
          ReviewLog,
          PrefetchHooks Function({bool itemId, bool deckId})
        > {
  $$ReviewLogsTableTableManager(_$AppDatabase db, $ReviewLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> deckId = const Value.absent(),
                Value<String> rating = const Value.absent(),
                Value<int> intervalBefore = const Value.absent(),
                Value<int> intervalAfter = const Value.absent(),
                Value<DateTime> reviewedAt = const Value.absent(),
              }) => ReviewLogsCompanion(
                id: id,
                itemId: itemId,
                deckId: deckId,
                rating: rating,
                intervalBefore: intervalBefore,
                intervalAfter: intervalAfter,
                reviewedAt: reviewedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String itemId,
                required String deckId,
                required String rating,
                required int intervalBefore,
                required int intervalAfter,
                Value<DateTime> reviewedAt = const Value.absent(),
              }) => ReviewLogsCompanion.insert(
                id: id,
                itemId: itemId,
                deckId: deckId,
                rating: rating,
                intervalBefore: intervalBefore,
                intervalAfter: intervalAfter,
                reviewedAt: reviewedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReviewLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false, deckId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable: $$ReviewLogsTableReferences
                                    ._itemIdTable(db),
                                referencedColumn: $$ReviewLogsTableReferences
                                    ._itemIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (deckId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.deckId,
                                referencedTable: $$ReviewLogsTableReferences
                                    ._deckIdTable(db),
                                referencedColumn: $$ReviewLogsTableReferences
                                    ._deckIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReviewLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewLogsTable,
      ReviewLog,
      $$ReviewLogsTableFilterComposer,
      $$ReviewLogsTableOrderingComposer,
      $$ReviewLogsTableAnnotationComposer,
      $$ReviewLogsTableCreateCompanionBuilder,
      $$ReviewLogsTableUpdateCompanionBuilder,
      (ReviewLog, $$ReviewLogsTableReferences),
      ReviewLog,
      PrefetchHooks Function({bool itemId, bool deckId})
    >;
typedef $$MemorizationPlansTableCreateCompanionBuilder =
    MemorizationPlansCompanion Function({
      required String id,
      required String deckId,
      required String name,
      required String difficulty,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$MemorizationPlansTableUpdateCompanionBuilder =
    MemorizationPlansCompanion Function({
      Value<String> id,
      Value<String> deckId,
      Value<String> name,
      Value<String> difficulty,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$MemorizationPlansTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MemorizationPlansTable,
          MemorizationPlan
        > {
  $$MemorizationPlansTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DecksTable _deckIdTable(_$AppDatabase db) => db.decks.createAlias(
    $_aliasNameGenerator(db.memorizationPlans.deckId, db.decks.id),
  );

  $$DecksTableProcessedTableManager get deckId {
    final $_column = $_itemColumn<String>('deck_id')!;

    final manager = $$DecksTableTableManager(
      $_db,
      $_db.decks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deckIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $MemorizationPlanItemsTable,
    List<MemorizationPlanItem>
  >
  _memorizationPlanItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.memorizationPlanItems,
        aliasName: $_aliasNameGenerator(
          db.memorizationPlans.id,
          db.memorizationPlanItems.planId,
        ),
      );

  $$MemorizationPlanItemsTableProcessedTableManager
  get memorizationPlanItemsRefs {
    final manager = $$MemorizationPlanItemsTableTableManager(
      $_db,
      $_db.memorizationPlanItems,
    ).filter((f) => f.planId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _memorizationPlanItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MemorizationPlansTableFilterComposer
    extends Composer<_$AppDatabase, $MemorizationPlansTable> {
  $$MemorizationPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DecksTableFilterComposer get deckId {
    final $$DecksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableFilterComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> memorizationPlanItemsRefs(
    Expression<bool> Function($$MemorizationPlanItemsTableFilterComposer f) f,
  ) {
    final $$MemorizationPlanItemsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.memorizationPlanItems,
          getReferencedColumn: (t) => t.planId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MemorizationPlanItemsTableFilterComposer(
                $db: $db,
                $table: $db.memorizationPlanItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MemorizationPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $MemorizationPlansTable> {
  $$MemorizationPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DecksTableOrderingComposer get deckId {
    final $$DecksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableOrderingComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MemorizationPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemorizationPlansTable> {
  $$MemorizationPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DecksTableAnnotationComposer get deckId {
    final $$DecksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableAnnotationComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> memorizationPlanItemsRefs<T extends Object>(
    Expression<T> Function($$MemorizationPlanItemsTableAnnotationComposer a) f,
  ) {
    final $$MemorizationPlanItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.memorizationPlanItems,
          getReferencedColumn: (t) => t.planId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MemorizationPlanItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.memorizationPlanItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MemorizationPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MemorizationPlansTable,
          MemorizationPlan,
          $$MemorizationPlansTableFilterComposer,
          $$MemorizationPlansTableOrderingComposer,
          $$MemorizationPlansTableAnnotationComposer,
          $$MemorizationPlansTableCreateCompanionBuilder,
          $$MemorizationPlansTableUpdateCompanionBuilder,
          (MemorizationPlan, $$MemorizationPlansTableReferences),
          MemorizationPlan,
          PrefetchHooks Function({bool deckId, bool memorizationPlanItemsRefs})
        > {
  $$MemorizationPlansTableTableManager(
    _$AppDatabase db,
    $MemorizationPlansTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemorizationPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemorizationPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemorizationPlansTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> deckId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemorizationPlansCompanion(
                id: id,
                deckId: deckId,
                name: name,
                difficulty: difficulty,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String deckId,
                required String name,
                required String difficulty,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemorizationPlansCompanion.insert(
                id: id,
                deckId: deckId,
                name: name,
                difficulty: difficulty,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MemorizationPlansTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({deckId = false, memorizationPlanItemsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (memorizationPlanItemsRefs) db.memorizationPlanItems,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (deckId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.deckId,
                                    referencedTable:
                                        $$MemorizationPlansTableReferences
                                            ._deckIdTable(db),
                                    referencedColumn:
                                        $$MemorizationPlansTableReferences
                                            ._deckIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (memorizationPlanItemsRefs)
                        await $_getPrefetchedData<
                          MemorizationPlan,
                          $MemorizationPlansTable,
                          MemorizationPlanItem
                        >(
                          currentTable: table,
                          referencedTable: $$MemorizationPlansTableReferences
                              ._memorizationPlanItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MemorizationPlansTableReferences(
                                db,
                                table,
                                p0,
                              ).memorizationPlanItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.planId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MemorizationPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MemorizationPlansTable,
      MemorizationPlan,
      $$MemorizationPlansTableFilterComposer,
      $$MemorizationPlansTableOrderingComposer,
      $$MemorizationPlansTableAnnotationComposer,
      $$MemorizationPlansTableCreateCompanionBuilder,
      $$MemorizationPlansTableUpdateCompanionBuilder,
      (MemorizationPlan, $$MemorizationPlansTableReferences),
      MemorizationPlan,
      PrefetchHooks Function({bool deckId, bool memorizationPlanItemsRefs})
    >;
typedef $$MemorizationPlanItemsTableCreateCompanionBuilder =
    MemorizationPlanItemsCompanion Function({
      Value<int> id,
      required String planId,
      required String itemId,
      required int position,
    });
typedef $$MemorizationPlanItemsTableUpdateCompanionBuilder =
    MemorizationPlanItemsCompanion Function({
      Value<int> id,
      Value<String> planId,
      Value<String> itemId,
      Value<int> position,
    });

final class $$MemorizationPlanItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MemorizationPlanItemsTable,
          MemorizationPlanItem
        > {
  $$MemorizationPlanItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MemorizationPlansTable _planIdTable(_$AppDatabase db) =>
      db.memorizationPlans.createAlias(
        $_aliasNameGenerator(
          db.memorizationPlanItems.planId,
          db.memorizationPlans.id,
        ),
      );

  $$MemorizationPlansTableProcessedTableManager get planId {
    final $_column = $_itemColumn<String>('plan_id')!;

    final manager = $$MemorizationPlansTableTableManager(
      $_db,
      $_db.memorizationPlans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ItemsTable _itemIdTable(_$AppDatabase db) => db.items.createAlias(
    $_aliasNameGenerator(db.memorizationPlanItems.itemId, db.items.id),
  );

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MemorizationPlanItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MemorizationPlanItemsTable> {
  $$MemorizationPlanItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$MemorizationPlansTableFilterComposer get planId {
    final $$MemorizationPlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.memorizationPlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemorizationPlansTableFilterComposer(
            $db: $db,
            $table: $db.memorizationPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MemorizationPlanItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MemorizationPlanItemsTable> {
  $$MemorizationPlanItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$MemorizationPlansTableOrderingComposer get planId {
    final $$MemorizationPlansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.memorizationPlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemorizationPlansTableOrderingComposer(
            $db: $db,
            $table: $db.memorizationPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MemorizationPlanItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemorizationPlanItemsTable> {
  $$MemorizationPlanItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$MemorizationPlansTableAnnotationComposer get planId {
    final $$MemorizationPlansTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.planId,
          referencedTable: $db.memorizationPlans,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MemorizationPlansTableAnnotationComposer(
                $db: $db,
                $table: $db.memorizationPlans,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MemorizationPlanItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MemorizationPlanItemsTable,
          MemorizationPlanItem,
          $$MemorizationPlanItemsTableFilterComposer,
          $$MemorizationPlanItemsTableOrderingComposer,
          $$MemorizationPlanItemsTableAnnotationComposer,
          $$MemorizationPlanItemsTableCreateCompanionBuilder,
          $$MemorizationPlanItemsTableUpdateCompanionBuilder,
          (MemorizationPlanItem, $$MemorizationPlanItemsTableReferences),
          MemorizationPlanItem,
          PrefetchHooks Function({bool planId, bool itemId})
        > {
  $$MemorizationPlanItemsTableTableManager(
    _$AppDatabase db,
    $MemorizationPlanItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemorizationPlanItemsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MemorizationPlanItemsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MemorizationPlanItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => MemorizationPlanItemsCompanion(
                id: id,
                planId: planId,
                itemId: itemId,
                position: position,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String planId,
                required String itemId,
                required int position,
              }) => MemorizationPlanItemsCompanion.insert(
                id: id,
                planId: planId,
                itemId: itemId,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MemorizationPlanItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({planId = false, itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (planId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.planId,
                                referencedTable:
                                    $$MemorizationPlanItemsTableReferences
                                        ._planIdTable(db),
                                referencedColumn:
                                    $$MemorizationPlanItemsTableReferences
                                        ._planIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable:
                                    $$MemorizationPlanItemsTableReferences
                                        ._itemIdTable(db),
                                referencedColumn:
                                    $$MemorizationPlanItemsTableReferences
                                        ._itemIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MemorizationPlanItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MemorizationPlanItemsTable,
      MemorizationPlanItem,
      $$MemorizationPlanItemsTableFilterComposer,
      $$MemorizationPlanItemsTableOrderingComposer,
      $$MemorizationPlanItemsTableAnnotationComposer,
      $$MemorizationPlanItemsTableCreateCompanionBuilder,
      $$MemorizationPlanItemsTableUpdateCompanionBuilder,
      (MemorizationPlanItem, $$MemorizationPlanItemsTableReferences),
      MemorizationPlanItem,
      PrefetchHooks Function({bool planId, bool itemId})
    >;
typedef $$ExerciseAttemptsTableCreateCompanionBuilder =
    ExerciseAttemptsCompanion Function({
      Value<int> id,
      required String itemId,
      required String stepType,
      Value<String?> level,
      required String difficulty,
      required double score,
      Value<int> mistakes,
      Value<String?> payloadJson,
      Value<DateTime> createdAt,
    });
typedef $$ExerciseAttemptsTableUpdateCompanionBuilder =
    ExerciseAttemptsCompanion Function({
      Value<int> id,
      Value<String> itemId,
      Value<String> stepType,
      Value<String?> level,
      Value<String> difficulty,
      Value<double> score,
      Value<int> mistakes,
      Value<String?> payloadJson,
      Value<DateTime> createdAt,
    });

final class $$ExerciseAttemptsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ExerciseAttemptsTable, ExerciseAttempt> {
  $$ExerciseAttemptsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ItemsTable _itemIdTable(_$AppDatabase db) => db.items.createAlias(
    $_aliasNameGenerator(db.exerciseAttempts.itemId, db.items.id),
  );

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExerciseAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseAttemptsTable> {
  $$ExerciseAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stepType => $composableBuilder(
    column: $table.stepType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mistakes => $composableBuilder(
    column: $table.mistakes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseAttemptsTable> {
  $$ExerciseAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stepType => $composableBuilder(
    column: $table.stepType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mistakes => $composableBuilder(
    column: $table.mistakes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseAttemptsTable> {
  $$ExerciseAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get stepType =>
      $composableBuilder(column: $table.stepType, builder: (column) => column);

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get mistakes =>
      $composableBuilder(column: $table.mistakes, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseAttemptsTable,
          ExerciseAttempt,
          $$ExerciseAttemptsTableFilterComposer,
          $$ExerciseAttemptsTableOrderingComposer,
          $$ExerciseAttemptsTableAnnotationComposer,
          $$ExerciseAttemptsTableCreateCompanionBuilder,
          $$ExerciseAttemptsTableUpdateCompanionBuilder,
          (ExerciseAttempt, $$ExerciseAttemptsTableReferences),
          ExerciseAttempt,
          PrefetchHooks Function({bool itemId})
        > {
  $$ExerciseAttemptsTableTableManager(
    _$AppDatabase db,
    $ExerciseAttemptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> stepType = const Value.absent(),
                Value<String?> level = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<double> score = const Value.absent(),
                Value<int> mistakes = const Value.absent(),
                Value<String?> payloadJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ExerciseAttemptsCompanion(
                id: id,
                itemId: itemId,
                stepType: stepType,
                level: level,
                difficulty: difficulty,
                score: score,
                mistakes: mistakes,
                payloadJson: payloadJson,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String itemId,
                required String stepType,
                Value<String?> level = const Value.absent(),
                required String difficulty,
                required double score,
                Value<int> mistakes = const Value.absent(),
                Value<String?> payloadJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ExerciseAttemptsCompanion.insert(
                id: id,
                itemId: itemId,
                stepType: stepType,
                level: level,
                difficulty: difficulty,
                score: score,
                mistakes: mistakes,
                payloadJson: payloadJson,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExerciseAttemptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable:
                                    $$ExerciseAttemptsTableReferences
                                        ._itemIdTable(db),
                                referencedColumn:
                                    $$ExerciseAttemptsTableReferences
                                        ._itemIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExerciseAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseAttemptsTable,
      ExerciseAttempt,
      $$ExerciseAttemptsTableFilterComposer,
      $$ExerciseAttemptsTableOrderingComposer,
      $$ExerciseAttemptsTableAnnotationComposer,
      $$ExerciseAttemptsTableCreateCompanionBuilder,
      $$ExerciseAttemptsTableUpdateCompanionBuilder,
      (ExerciseAttempt, $$ExerciseAttemptsTableReferences),
      ExerciseAttempt,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$AudioClipsTableCreateCompanionBuilder =
    AudioClipsCompanion Function({
      Value<int> id,
      required String itemId,
      required String localPath,
      Value<int> durationMs,
      Value<DateTime> createdAt,
    });
typedef $$AudioClipsTableUpdateCompanionBuilder =
    AudioClipsCompanion Function({
      Value<int> id,
      Value<String> itemId,
      Value<String> localPath,
      Value<int> durationMs,
      Value<DateTime> createdAt,
    });

final class $$AudioClipsTableReferences
    extends BaseReferences<_$AppDatabase, $AudioClipsTable, AudioClip> {
  $$AudioClipsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemsTable _itemIdTable(_$AppDatabase db) => db.items.createAlias(
    $_aliasNameGenerator(db.audioClips.itemId, db.items.id),
  );

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AudioClipsTableFilterComposer
    extends Composer<_$AppDatabase, $AudioClipsTable> {
  $$AudioClipsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AudioClipsTableOrderingComposer
    extends Composer<_$AppDatabase, $AudioClipsTable> {
  $$AudioClipsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AudioClipsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AudioClipsTable> {
  $$AudioClipsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AudioClipsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AudioClipsTable,
          AudioClip,
          $$AudioClipsTableFilterComposer,
          $$AudioClipsTableOrderingComposer,
          $$AudioClipsTableAnnotationComposer,
          $$AudioClipsTableCreateCompanionBuilder,
          $$AudioClipsTableUpdateCompanionBuilder,
          (AudioClip, $$AudioClipsTableReferences),
          AudioClip,
          PrefetchHooks Function({bool itemId})
        > {
  $$AudioClipsTableTableManager(_$AppDatabase db, $AudioClipsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AudioClipsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AudioClipsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AudioClipsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AudioClipsCompanion(
                id: id,
                itemId: itemId,
                localPath: localPath,
                durationMs: durationMs,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String itemId,
                required String localPath,
                Value<int> durationMs = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AudioClipsCompanion.insert(
                id: id,
                itemId: itemId,
                localPath: localPath,
                durationMs: durationMs,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AudioClipsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable: $$AudioClipsTableReferences
                                    ._itemIdTable(db),
                                referencedColumn: $$AudioClipsTableReferences
                                    ._itemIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AudioClipsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AudioClipsTable,
      AudioClip,
      $$AudioClipsTableFilterComposer,
      $$AudioClipsTableOrderingComposer,
      $$AudioClipsTableAnnotationComposer,
      $$AudioClipsTableCreateCompanionBuilder,
      $$AudioClipsTableUpdateCompanionBuilder,
      (AudioClip, $$AudioClipsTableReferences),
      AudioClip,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$ExerciseConsolidationsTableCreateCompanionBuilder =
    ExerciseConsolidationsCompanion Function({
      Value<int> id,
      required String deckId,
      required String itemId,
      required String difficulty,
      required double averageScore,
      Value<int> totalMistakes,
      Value<String?> weakestStepType,
      Value<String?> strongestStepType,
      Value<DateTime> createdAt,
    });
typedef $$ExerciseConsolidationsTableUpdateCompanionBuilder =
    ExerciseConsolidationsCompanion Function({
      Value<int> id,
      Value<String> deckId,
      Value<String> itemId,
      Value<String> difficulty,
      Value<double> averageScore,
      Value<int> totalMistakes,
      Value<String?> weakestStepType,
      Value<String?> strongestStepType,
      Value<DateTime> createdAt,
    });

final class $$ExerciseConsolidationsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ExerciseConsolidationsTable,
          ExerciseConsolidation
        > {
  $$ExerciseConsolidationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DecksTable _deckIdTable(_$AppDatabase db) => db.decks.createAlias(
    $_aliasNameGenerator(db.exerciseConsolidations.deckId, db.decks.id),
  );

  $$DecksTableProcessedTableManager get deckId {
    final $_column = $_itemColumn<String>('deck_id')!;

    final manager = $$DecksTableTableManager(
      $_db,
      $_db.decks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deckIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ItemsTable _itemIdTable(_$AppDatabase db) => db.items.createAlias(
    $_aliasNameGenerator(db.exerciseConsolidations.itemId, db.items.id),
  );

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExerciseConsolidationsTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseConsolidationsTable> {
  $$ExerciseConsolidationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averageScore => $composableBuilder(
    column: $table.averageScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalMistakes => $composableBuilder(
    column: $table.totalMistakes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weakestStepType => $composableBuilder(
    column: $table.weakestStepType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strongestStepType => $composableBuilder(
    column: $table.strongestStepType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DecksTableFilterComposer get deckId {
    final $$DecksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableFilterComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseConsolidationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseConsolidationsTable> {
  $$ExerciseConsolidationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averageScore => $composableBuilder(
    column: $table.averageScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalMistakes => $composableBuilder(
    column: $table.totalMistakes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weakestStepType => $composableBuilder(
    column: $table.weakestStepType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strongestStepType => $composableBuilder(
    column: $table.strongestStepType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DecksTableOrderingComposer get deckId {
    final $$DecksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableOrderingComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseConsolidationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseConsolidationsTable> {
  $$ExerciseConsolidationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<double> get averageScore => $composableBuilder(
    column: $table.averageScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalMistakes => $composableBuilder(
    column: $table.totalMistakes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get weakestStepType => $composableBuilder(
    column: $table.weakestStepType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get strongestStepType => $composableBuilder(
    column: $table.strongestStepType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DecksTableAnnotationComposer get deckId {
    final $$DecksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableAnnotationComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseConsolidationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseConsolidationsTable,
          ExerciseConsolidation,
          $$ExerciseConsolidationsTableFilterComposer,
          $$ExerciseConsolidationsTableOrderingComposer,
          $$ExerciseConsolidationsTableAnnotationComposer,
          $$ExerciseConsolidationsTableCreateCompanionBuilder,
          $$ExerciseConsolidationsTableUpdateCompanionBuilder,
          (ExerciseConsolidation, $$ExerciseConsolidationsTableReferences),
          ExerciseConsolidation,
          PrefetchHooks Function({bool deckId, bool itemId})
        > {
  $$ExerciseConsolidationsTableTableManager(
    _$AppDatabase db,
    $ExerciseConsolidationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseConsolidationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ExerciseConsolidationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ExerciseConsolidationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> deckId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<double> averageScore = const Value.absent(),
                Value<int> totalMistakes = const Value.absent(),
                Value<String?> weakestStepType = const Value.absent(),
                Value<String?> strongestStepType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ExerciseConsolidationsCompanion(
                id: id,
                deckId: deckId,
                itemId: itemId,
                difficulty: difficulty,
                averageScore: averageScore,
                totalMistakes: totalMistakes,
                weakestStepType: weakestStepType,
                strongestStepType: strongestStepType,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String deckId,
                required String itemId,
                required String difficulty,
                required double averageScore,
                Value<int> totalMistakes = const Value.absent(),
                Value<String?> weakestStepType = const Value.absent(),
                Value<String?> strongestStepType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ExerciseConsolidationsCompanion.insert(
                id: id,
                deckId: deckId,
                itemId: itemId,
                difficulty: difficulty,
                averageScore: averageScore,
                totalMistakes: totalMistakes,
                weakestStepType: weakestStepType,
                strongestStepType: strongestStepType,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExerciseConsolidationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({deckId = false, itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (deckId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.deckId,
                                referencedTable:
                                    $$ExerciseConsolidationsTableReferences
                                        ._deckIdTable(db),
                                referencedColumn:
                                    $$ExerciseConsolidationsTableReferences
                                        ._deckIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable:
                                    $$ExerciseConsolidationsTableReferences
                                        ._itemIdTable(db),
                                referencedColumn:
                                    $$ExerciseConsolidationsTableReferences
                                        ._itemIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExerciseConsolidationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseConsolidationsTable,
      ExerciseConsolidation,
      $$ExerciseConsolidationsTableFilterComposer,
      $$ExerciseConsolidationsTableOrderingComposer,
      $$ExerciseConsolidationsTableAnnotationComposer,
      $$ExerciseConsolidationsTableCreateCompanionBuilder,
      $$ExerciseConsolidationsTableUpdateCompanionBuilder,
      (ExerciseConsolidation, $$ExerciseConsolidationsTableReferences),
      ExerciseConsolidation,
      PrefetchHooks Function({bool deckId, bool itemId})
    >;
typedef $$CardsConsolidationsTableCreateCompanionBuilder =
    CardsConsolidationsCompanion Function({
      Value<int> id,
      required String deckId,
      required double averageScore,
      Value<int> totalMistakes,
      Value<String?> weakestExerciseType,
      Value<String?> strongestExerciseType,
      Value<DateTime> createdAt,
    });
typedef $$CardsConsolidationsTableUpdateCompanionBuilder =
    CardsConsolidationsCompanion Function({
      Value<int> id,
      Value<String> deckId,
      Value<double> averageScore,
      Value<int> totalMistakes,
      Value<String?> weakestExerciseType,
      Value<String?> strongestExerciseType,
      Value<DateTime> createdAt,
    });

final class $$CardsConsolidationsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CardsConsolidationsTable,
          CardsConsolidation
        > {
  $$CardsConsolidationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DecksTable _deckIdTable(_$AppDatabase db) => db.decks.createAlias(
    $_aliasNameGenerator(db.cardsConsolidations.deckId, db.decks.id),
  );

  $$DecksTableProcessedTableManager get deckId {
    final $_column = $_itemColumn<String>('deck_id')!;

    final manager = $$DecksTableTableManager(
      $_db,
      $_db.decks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deckIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CardsConsolidationsTableFilterComposer
    extends Composer<_$AppDatabase, $CardsConsolidationsTable> {
  $$CardsConsolidationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averageScore => $composableBuilder(
    column: $table.averageScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalMistakes => $composableBuilder(
    column: $table.totalMistakes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weakestExerciseType => $composableBuilder(
    column: $table.weakestExerciseType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strongestExerciseType => $composableBuilder(
    column: $table.strongestExerciseType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DecksTableFilterComposer get deckId {
    final $$DecksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableFilterComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CardsConsolidationsTableOrderingComposer
    extends Composer<_$AppDatabase, $CardsConsolidationsTable> {
  $$CardsConsolidationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averageScore => $composableBuilder(
    column: $table.averageScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalMistakes => $composableBuilder(
    column: $table.totalMistakes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weakestExerciseType => $composableBuilder(
    column: $table.weakestExerciseType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strongestExerciseType => $composableBuilder(
    column: $table.strongestExerciseType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DecksTableOrderingComposer get deckId {
    final $$DecksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableOrderingComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CardsConsolidationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardsConsolidationsTable> {
  $$CardsConsolidationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get averageScore => $composableBuilder(
    column: $table.averageScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalMistakes => $composableBuilder(
    column: $table.totalMistakes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get weakestExerciseType => $composableBuilder(
    column: $table.weakestExerciseType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get strongestExerciseType => $composableBuilder(
    column: $table.strongestExerciseType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DecksTableAnnotationComposer get deckId {
    final $$DecksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableAnnotationComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CardsConsolidationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CardsConsolidationsTable,
          CardsConsolidation,
          $$CardsConsolidationsTableFilterComposer,
          $$CardsConsolidationsTableOrderingComposer,
          $$CardsConsolidationsTableAnnotationComposer,
          $$CardsConsolidationsTableCreateCompanionBuilder,
          $$CardsConsolidationsTableUpdateCompanionBuilder,
          (CardsConsolidation, $$CardsConsolidationsTableReferences),
          CardsConsolidation,
          PrefetchHooks Function({bool deckId})
        > {
  $$CardsConsolidationsTableTableManager(
    _$AppDatabase db,
    $CardsConsolidationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardsConsolidationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardsConsolidationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CardsConsolidationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> deckId = const Value.absent(),
                Value<double> averageScore = const Value.absent(),
                Value<int> totalMistakes = const Value.absent(),
                Value<String?> weakestExerciseType = const Value.absent(),
                Value<String?> strongestExerciseType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CardsConsolidationsCompanion(
                id: id,
                deckId: deckId,
                averageScore: averageScore,
                totalMistakes: totalMistakes,
                weakestExerciseType: weakestExerciseType,
                strongestExerciseType: strongestExerciseType,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String deckId,
                required double averageScore,
                Value<int> totalMistakes = const Value.absent(),
                Value<String?> weakestExerciseType = const Value.absent(),
                Value<String?> strongestExerciseType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CardsConsolidationsCompanion.insert(
                id: id,
                deckId: deckId,
                averageScore: averageScore,
                totalMistakes: totalMistakes,
                weakestExerciseType: weakestExerciseType,
                strongestExerciseType: strongestExerciseType,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CardsConsolidationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({deckId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (deckId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.deckId,
                                referencedTable:
                                    $$CardsConsolidationsTableReferences
                                        ._deckIdTable(db),
                                referencedColumn:
                                    $$CardsConsolidationsTableReferences
                                        ._deckIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CardsConsolidationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CardsConsolidationsTable,
      CardsConsolidation,
      $$CardsConsolidationsTableFilterComposer,
      $$CardsConsolidationsTableOrderingComposer,
      $$CardsConsolidationsTableAnnotationComposer,
      $$CardsConsolidationsTableCreateCompanionBuilder,
      $$CardsConsolidationsTableUpdateCompanionBuilder,
      (CardsConsolidation, $$CardsConsolidationsTableReferences),
      CardsConsolidation,
      PrefetchHooks Function({bool deckId})
    >;
typedef $$MemorizationGoalsTableCreateCompanionBuilder =
    MemorizationGoalsCompanion Function({
      required String id,
      required String deckId,
      required String title,
      required String objective,
      Value<int> targetItems,
      Value<DateTime?> targetDate,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$MemorizationGoalsTableUpdateCompanionBuilder =
    MemorizationGoalsCompanion Function({
      Value<String> id,
      Value<String> deckId,
      Value<String> title,
      Value<String> objective,
      Value<int> targetItems,
      Value<DateTime?> targetDate,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$MemorizationGoalsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MemorizationGoalsTable,
          MemorizationGoal
        > {
  $$MemorizationGoalsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DecksTable _deckIdTable(_$AppDatabase db) => db.decks.createAlias(
    $_aliasNameGenerator(db.memorizationGoals.deckId, db.decks.id),
  );

  $$DecksTableProcessedTableManager get deckId {
    final $_column = $_itemColumn<String>('deck_id')!;

    final manager = $$DecksTableTableManager(
      $_db,
      $_db.decks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deckIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MemorizationGoalsTableFilterComposer
    extends Composer<_$AppDatabase, $MemorizationGoalsTable> {
  $$MemorizationGoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get objective => $composableBuilder(
    column: $table.objective,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetItems => $composableBuilder(
    column: $table.targetItems,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DecksTableFilterComposer get deckId {
    final $$DecksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableFilterComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MemorizationGoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $MemorizationGoalsTable> {
  $$MemorizationGoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get objective => $composableBuilder(
    column: $table.objective,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetItems => $composableBuilder(
    column: $table.targetItems,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DecksTableOrderingComposer get deckId {
    final $$DecksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableOrderingComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MemorizationGoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemorizationGoalsTable> {
  $$MemorizationGoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get objective =>
      $composableBuilder(column: $table.objective, builder: (column) => column);

  GeneratedColumn<int> get targetItems => $composableBuilder(
    column: $table.targetItems,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DecksTableAnnotationComposer get deckId {
    final $$DecksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableAnnotationComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MemorizationGoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MemorizationGoalsTable,
          MemorizationGoal,
          $$MemorizationGoalsTableFilterComposer,
          $$MemorizationGoalsTableOrderingComposer,
          $$MemorizationGoalsTableAnnotationComposer,
          $$MemorizationGoalsTableCreateCompanionBuilder,
          $$MemorizationGoalsTableUpdateCompanionBuilder,
          (MemorizationGoal, $$MemorizationGoalsTableReferences),
          MemorizationGoal,
          PrefetchHooks Function({bool deckId})
        > {
  $$MemorizationGoalsTableTableManager(
    _$AppDatabase db,
    $MemorizationGoalsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemorizationGoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemorizationGoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemorizationGoalsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> deckId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> objective = const Value.absent(),
                Value<int> targetItems = const Value.absent(),
                Value<DateTime?> targetDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemorizationGoalsCompanion(
                id: id,
                deckId: deckId,
                title: title,
                objective: objective,
                targetItems: targetItems,
                targetDate: targetDate,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String deckId,
                required String title,
                required String objective,
                Value<int> targetItems = const Value.absent(),
                Value<DateTime?> targetDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemorizationGoalsCompanion.insert(
                id: id,
                deckId: deckId,
                title: title,
                objective: objective,
                targetItems: targetItems,
                targetDate: targetDate,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MemorizationGoalsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({deckId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (deckId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.deckId,
                                referencedTable:
                                    $$MemorizationGoalsTableReferences
                                        ._deckIdTable(db),
                                referencedColumn:
                                    $$MemorizationGoalsTableReferences
                                        ._deckIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MemorizationGoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MemorizationGoalsTable,
      MemorizationGoal,
      $$MemorizationGoalsTableFilterComposer,
      $$MemorizationGoalsTableOrderingComposer,
      $$MemorizationGoalsTableAnnotationComposer,
      $$MemorizationGoalsTableCreateCompanionBuilder,
      $$MemorizationGoalsTableUpdateCompanionBuilder,
      (MemorizationGoal, $$MemorizationGoalsTableReferences),
      MemorizationGoal,
      PrefetchHooks Function({bool deckId})
    >;
typedef $$MemorizationJourneysTableCreateCompanionBuilder =
    MemorizationJourneysCompanion Function({
      required String id,
      required String deckId,
      required String title,
      required int targetDays,
      required int itemsPerDay,
      required int targetItemCount,
      required String objective,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$MemorizationJourneysTableUpdateCompanionBuilder =
    MemorizationJourneysCompanion Function({
      Value<String> id,
      Value<String> deckId,
      Value<String> title,
      Value<int> targetDays,
      Value<int> itemsPerDay,
      Value<int> targetItemCount,
      Value<String> objective,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$MemorizationJourneysTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MemorizationJourneysTable,
          MemorizationJourney
        > {
  $$MemorizationJourneysTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DecksTable _deckIdTable(_$AppDatabase db) => db.decks.createAlias(
    $_aliasNameGenerator(db.memorizationJourneys.deckId, db.decks.id),
  );

  $$DecksTableProcessedTableManager get deckId {
    final $_column = $_itemColumn<String>('deck_id')!;

    final manager = $$DecksTableTableManager(
      $_db,
      $_db.decks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deckIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MemorizationJourneysTableFilterComposer
    extends Composer<_$AppDatabase, $MemorizationJourneysTable> {
  $$MemorizationJourneysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetDays => $composableBuilder(
    column: $table.targetDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemsPerDay => $composableBuilder(
    column: $table.itemsPerDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetItemCount => $composableBuilder(
    column: $table.targetItemCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get objective => $composableBuilder(
    column: $table.objective,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DecksTableFilterComposer get deckId {
    final $$DecksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableFilterComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MemorizationJourneysTableOrderingComposer
    extends Composer<_$AppDatabase, $MemorizationJourneysTable> {
  $$MemorizationJourneysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetDays => $composableBuilder(
    column: $table.targetDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemsPerDay => $composableBuilder(
    column: $table.itemsPerDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetItemCount => $composableBuilder(
    column: $table.targetItemCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get objective => $composableBuilder(
    column: $table.objective,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DecksTableOrderingComposer get deckId {
    final $$DecksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableOrderingComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MemorizationJourneysTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemorizationJourneysTable> {
  $$MemorizationJourneysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get targetDays => $composableBuilder(
    column: $table.targetDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get itemsPerDay => $composableBuilder(
    column: $table.itemsPerDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetItemCount => $composableBuilder(
    column: $table.targetItemCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get objective =>
      $composableBuilder(column: $table.objective, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DecksTableAnnotationComposer get deckId {
    final $$DecksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableAnnotationComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MemorizationJourneysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MemorizationJourneysTable,
          MemorizationJourney,
          $$MemorizationJourneysTableFilterComposer,
          $$MemorizationJourneysTableOrderingComposer,
          $$MemorizationJourneysTableAnnotationComposer,
          $$MemorizationJourneysTableCreateCompanionBuilder,
          $$MemorizationJourneysTableUpdateCompanionBuilder,
          (MemorizationJourney, $$MemorizationJourneysTableReferences),
          MemorizationJourney,
          PrefetchHooks Function({bool deckId})
        > {
  $$MemorizationJourneysTableTableManager(
    _$AppDatabase db,
    $MemorizationJourneysTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemorizationJourneysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemorizationJourneysTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MemorizationJourneysTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> deckId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> targetDays = const Value.absent(),
                Value<int> itemsPerDay = const Value.absent(),
                Value<int> targetItemCount = const Value.absent(),
                Value<String> objective = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemorizationJourneysCompanion(
                id: id,
                deckId: deckId,
                title: title,
                targetDays: targetDays,
                itemsPerDay: itemsPerDay,
                targetItemCount: targetItemCount,
                objective: objective,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String deckId,
                required String title,
                required int targetDays,
                required int itemsPerDay,
                required int targetItemCount,
                required String objective,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemorizationJourneysCompanion.insert(
                id: id,
                deckId: deckId,
                title: title,
                targetDays: targetDays,
                itemsPerDay: itemsPerDay,
                targetItemCount: targetItemCount,
                objective: objective,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MemorizationJourneysTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({deckId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (deckId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.deckId,
                                referencedTable:
                                    $$MemorizationJourneysTableReferences
                                        ._deckIdTable(db),
                                referencedColumn:
                                    $$MemorizationJourneysTableReferences
                                        ._deckIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MemorizationJourneysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MemorizationJourneysTable,
      MemorizationJourney,
      $$MemorizationJourneysTableFilterComposer,
      $$MemorizationJourneysTableOrderingComposer,
      $$MemorizationJourneysTableAnnotationComposer,
      $$MemorizationJourneysTableCreateCompanionBuilder,
      $$MemorizationJourneysTableUpdateCompanionBuilder,
      (MemorizationJourney, $$MemorizationJourneysTableReferences),
      MemorizationJourney,
      PrefetchHooks Function({bool deckId})
    >;
typedef $$AchievementUnlocksTableCreateCompanionBuilder =
    AchievementUnlocksCompanion Function({
      required String id,
      required String code,
      required String title,
      required String description,
      Value<DateTime> unlockedAt,
      Value<int> rowid,
    });
typedef $$AchievementUnlocksTableUpdateCompanionBuilder =
    AchievementUnlocksCompanion Function({
      Value<String> id,
      Value<String> code,
      Value<String> title,
      Value<String> description,
      Value<DateTime> unlockedAt,
      Value<int> rowid,
    });

class $$AchievementUnlocksTableFilterComposer
    extends Composer<_$AppDatabase, $AchievementUnlocksTable> {
  $$AchievementUnlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AchievementUnlocksTableOrderingComposer
    extends Composer<_$AppDatabase, $AchievementUnlocksTable> {
  $$AchievementUnlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AchievementUnlocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $AchievementUnlocksTable> {
  $$AchievementUnlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => column,
  );
}

class $$AchievementUnlocksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AchievementUnlocksTable,
          AchievementUnlock,
          $$AchievementUnlocksTableFilterComposer,
          $$AchievementUnlocksTableOrderingComposer,
          $$AchievementUnlocksTableAnnotationComposer,
          $$AchievementUnlocksTableCreateCompanionBuilder,
          $$AchievementUnlocksTableUpdateCompanionBuilder,
          (
            AchievementUnlock,
            BaseReferences<
              _$AppDatabase,
              $AchievementUnlocksTable,
              AchievementUnlock
            >,
          ),
          AchievementUnlock,
          PrefetchHooks Function()
        > {
  $$AchievementUnlocksTableTableManager(
    _$AppDatabase db,
    $AchievementUnlocksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AchievementUnlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AchievementUnlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AchievementUnlocksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<DateTime> unlockedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AchievementUnlocksCompanion(
                id: id,
                code: code,
                title: title,
                description: description,
                unlockedAt: unlockedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String code,
                required String title,
                required String description,
                Value<DateTime> unlockedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AchievementUnlocksCompanion.insert(
                id: id,
                code: code,
                title: title,
                description: description,
                unlockedAt: unlockedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AchievementUnlocksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AchievementUnlocksTable,
      AchievementUnlock,
      $$AchievementUnlocksTableFilterComposer,
      $$AchievementUnlocksTableOrderingComposer,
      $$AchievementUnlocksTableAnnotationComposer,
      $$AchievementUnlocksTableCreateCompanionBuilder,
      $$AchievementUnlocksTableUpdateCompanionBuilder,
      (
        AchievementUnlock,
        BaseReferences<
          _$AppDatabase,
          $AchievementUnlocksTable,
          AchievementUnlock
        >,
      ),
      AchievementUnlock,
      PrefetchHooks Function()
    >;
typedef $$ErrorBankEntriesTableCreateCompanionBuilder =
    ErrorBankEntriesCompanion Function({
      Value<int> id,
      required String itemId,
      required String deckId,
      required String stepType,
      Value<String?> token,
      required String errorKind,
      Value<int> occurrences,
      Value<DateTime> createdAt,
    });
typedef $$ErrorBankEntriesTableUpdateCompanionBuilder =
    ErrorBankEntriesCompanion Function({
      Value<int> id,
      Value<String> itemId,
      Value<String> deckId,
      Value<String> stepType,
      Value<String?> token,
      Value<String> errorKind,
      Value<int> occurrences,
      Value<DateTime> createdAt,
    });

final class $$ErrorBankEntriesTableReferences
    extends
        BaseReferences<_$AppDatabase, $ErrorBankEntriesTable, ErrorBankEntry> {
  $$ErrorBankEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ItemsTable _itemIdTable(_$AppDatabase db) => db.items.createAlias(
    $_aliasNameGenerator(db.errorBankEntries.itemId, db.items.id),
  );

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DecksTable _deckIdTable(_$AppDatabase db) => db.decks.createAlias(
    $_aliasNameGenerator(db.errorBankEntries.deckId, db.decks.id),
  );

  $$DecksTableProcessedTableManager get deckId {
    final $_column = $_itemColumn<String>('deck_id')!;

    final manager = $$DecksTableTableManager(
      $_db,
      $_db.decks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deckIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ErrorBankEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $ErrorBankEntriesTable> {
  $$ErrorBankEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stepType => $composableBuilder(
    column: $table.stepType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get token => $composableBuilder(
    column: $table.token,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorKind => $composableBuilder(
    column: $table.errorKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurrences => $composableBuilder(
    column: $table.occurrences,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DecksTableFilterComposer get deckId {
    final $$DecksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableFilterComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ErrorBankEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ErrorBankEntriesTable> {
  $$ErrorBankEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stepType => $composableBuilder(
    column: $table.stepType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get token => $composableBuilder(
    column: $table.token,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorKind => $composableBuilder(
    column: $table.errorKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurrences => $composableBuilder(
    column: $table.occurrences,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DecksTableOrderingComposer get deckId {
    final $$DecksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableOrderingComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ErrorBankEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ErrorBankEntriesTable> {
  $$ErrorBankEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get stepType =>
      $composableBuilder(column: $table.stepType, builder: (column) => column);

  GeneratedColumn<String> get token =>
      $composableBuilder(column: $table.token, builder: (column) => column);

  GeneratedColumn<String> get errorKind =>
      $composableBuilder(column: $table.errorKind, builder: (column) => column);

  GeneratedColumn<int> get occurrences => $composableBuilder(
    column: $table.occurrences,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DecksTableAnnotationComposer get deckId {
    final $$DecksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableAnnotationComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ErrorBankEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ErrorBankEntriesTable,
          ErrorBankEntry,
          $$ErrorBankEntriesTableFilterComposer,
          $$ErrorBankEntriesTableOrderingComposer,
          $$ErrorBankEntriesTableAnnotationComposer,
          $$ErrorBankEntriesTableCreateCompanionBuilder,
          $$ErrorBankEntriesTableUpdateCompanionBuilder,
          (ErrorBankEntry, $$ErrorBankEntriesTableReferences),
          ErrorBankEntry,
          PrefetchHooks Function({bool itemId, bool deckId})
        > {
  $$ErrorBankEntriesTableTableManager(
    _$AppDatabase db,
    $ErrorBankEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ErrorBankEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ErrorBankEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ErrorBankEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> deckId = const Value.absent(),
                Value<String> stepType = const Value.absent(),
                Value<String?> token = const Value.absent(),
                Value<String> errorKind = const Value.absent(),
                Value<int> occurrences = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ErrorBankEntriesCompanion(
                id: id,
                itemId: itemId,
                deckId: deckId,
                stepType: stepType,
                token: token,
                errorKind: errorKind,
                occurrences: occurrences,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String itemId,
                required String deckId,
                required String stepType,
                Value<String?> token = const Value.absent(),
                required String errorKind,
                Value<int> occurrences = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ErrorBankEntriesCompanion.insert(
                id: id,
                itemId: itemId,
                deckId: deckId,
                stepType: stepType,
                token: token,
                errorKind: errorKind,
                occurrences: occurrences,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ErrorBankEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false, deckId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable:
                                    $$ErrorBankEntriesTableReferences
                                        ._itemIdTable(db),
                                referencedColumn:
                                    $$ErrorBankEntriesTableReferences
                                        ._itemIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (deckId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.deckId,
                                referencedTable:
                                    $$ErrorBankEntriesTableReferences
                                        ._deckIdTable(db),
                                referencedColumn:
                                    $$ErrorBankEntriesTableReferences
                                        ._deckIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ErrorBankEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ErrorBankEntriesTable,
      ErrorBankEntry,
      $$ErrorBankEntriesTableFilterComposer,
      $$ErrorBankEntriesTableOrderingComposer,
      $$ErrorBankEntriesTableAnnotationComposer,
      $$ErrorBankEntriesTableCreateCompanionBuilder,
      $$ErrorBankEntriesTableUpdateCompanionBuilder,
      (ErrorBankEntry, $$ErrorBankEntriesTableReferences),
      ErrorBankEntry,
      PrefetchHooks Function({bool itemId, bool deckId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DecksTableTableManager get decks =>
      $$DecksTableTableManager(_db, _db.decks);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$ReviewLogsTableTableManager get reviewLogs =>
      $$ReviewLogsTableTableManager(_db, _db.reviewLogs);
  $$MemorizationPlansTableTableManager get memorizationPlans =>
      $$MemorizationPlansTableTableManager(_db, _db.memorizationPlans);
  $$MemorizationPlanItemsTableTableManager get memorizationPlanItems =>
      $$MemorizationPlanItemsTableTableManager(_db, _db.memorizationPlanItems);
  $$ExerciseAttemptsTableTableManager get exerciseAttempts =>
      $$ExerciseAttemptsTableTableManager(_db, _db.exerciseAttempts);
  $$AudioClipsTableTableManager get audioClips =>
      $$AudioClipsTableTableManager(_db, _db.audioClips);
  $$ExerciseConsolidationsTableTableManager get exerciseConsolidations =>
      $$ExerciseConsolidationsTableTableManager(
        _db,
        _db.exerciseConsolidations,
      );
  $$CardsConsolidationsTableTableManager get cardsConsolidations =>
      $$CardsConsolidationsTableTableManager(_db, _db.cardsConsolidations);
  $$MemorizationGoalsTableTableManager get memorizationGoals =>
      $$MemorizationGoalsTableTableManager(_db, _db.memorizationGoals);
  $$MemorizationJourneysTableTableManager get memorizationJourneys =>
      $$MemorizationJourneysTableTableManager(_db, _db.memorizationJourneys);
  $$AchievementUnlocksTableTableManager get achievementUnlocks =>
      $$AchievementUnlocksTableTableManager(_db, _db.achievementUnlocks);
  $$ErrorBankEntriesTableTableManager get errorBankEntries =>
      $$ErrorBankEntriesTableTableManager(_db, _db.errorBankEntries);
}
