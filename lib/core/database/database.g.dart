// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $FoodLogsTable extends FoodLogs with TableInfo<$FoodLogsTable, FoodLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _mealNameMeta = const VerificationMeta(
    'mealName',
  );
  @override
  late final GeneratedColumn<String> mealName = GeneratedColumn<String>(
    'meal_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameFrMeta = const VerificationMeta('nameFr');
  @override
  late final GeneratedColumn<String> nameFr = GeneratedColumn<String>(
    'name_fr',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
    'name_ar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ingredientsMeta = const VerificationMeta(
    'ingredients',
  );
  @override
  late final GeneratedColumn<String> ingredients = GeneratedColumn<String>(
    'ingredients',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<int> calories = GeneratedColumn<int>(
    'calories',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinMeta = const VerificationMeta(
    'protein',
  );
  @override
  late final GeneratedColumn<int> protein = GeneratedColumn<int>(
    'protein',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsMeta = const VerificationMeta('carbs');
  @override
  late final GeneratedColumn<int> carbs = GeneratedColumn<int>(
    'carbs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatMeta = const VerificationMeta('fat');
  @override
  late final GeneratedColumn<int> fat = GeneratedColumn<int>(
    'fat',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    mealName,
    nameEn,
    nameFr,
    nameAr,
    imageUrl,
    ingredients,
    calories,
    protein,
    carbs,
    fat,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('meal_name')) {
      context.handle(
        _mealNameMeta,
        mealName.isAcceptableOrUnknown(data['meal_name']!, _mealNameMeta),
      );
    } else if (isInserting) {
      context.missing(_mealNameMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    }
    if (data.containsKey('name_fr')) {
      context.handle(
        _nameFrMeta,
        nameFr.isAcceptableOrUnknown(data['name_fr']!, _nameFrMeta),
      );
    }
    if (data.containsKey('name_ar')) {
      context.handle(
        _nameArMeta,
        nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('ingredients')) {
      context.handle(
        _ingredientsMeta,
        ingredients.isAcceptableOrUnknown(
          data['ingredients']!,
          _ingredientsMeta,
        ),
      );
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    } else if (isInserting) {
      context.missing(_caloriesMeta);
    }
    if (data.containsKey('protein')) {
      context.handle(
        _proteinMeta,
        protein.isAcceptableOrUnknown(data['protein']!, _proteinMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinMeta);
    }
    if (data.containsKey('carbs')) {
      context.handle(
        _carbsMeta,
        carbs.isAcceptableOrUnknown(data['carbs']!, _carbsMeta),
      );
    } else if (isInserting) {
      context.missing(_carbsMeta);
    }
    if (data.containsKey('fat')) {
      context.handle(
        _fatMeta,
        fat.isAcceptableOrUnknown(data['fat']!, _fatMeta),
      );
    } else if (isInserting) {
      context.missing(_fatMeta);
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
  FoodLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      mealName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_name'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      ),
      nameFr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_fr'],
      ),
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      ingredients: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ingredients'],
      ),
      calories: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calories'],
      )!,
      protein: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}protein'],
      )!,
      carbs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}carbs'],
      )!,
      fat: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fat'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FoodLogsTable createAlias(String alias) {
    return $FoodLogsTable(attachedDatabase, alias);
  }
}

class FoodLog extends DataClass implements Insertable<FoodLog> {
  final int id;
  final String mealName;
  final String? nameEn;
  final String? nameFr;
  final String? nameAr;
  final String? imageUrl;
  final String? ingredients;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final DateTime createdAt;
  const FoodLog({
    required this.id,
    required this.mealName,
    this.nameEn,
    this.nameFr,
    this.nameAr,
    this.imageUrl,
    this.ingredients,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['meal_name'] = Variable<String>(mealName);
    if (!nullToAbsent || nameEn != null) {
      map['name_en'] = Variable<String>(nameEn);
    }
    if (!nullToAbsent || nameFr != null) {
      map['name_fr'] = Variable<String>(nameFr);
    }
    if (!nullToAbsent || nameAr != null) {
      map['name_ar'] = Variable<String>(nameAr);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || ingredients != null) {
      map['ingredients'] = Variable<String>(ingredients);
    }
    map['calories'] = Variable<int>(calories);
    map['protein'] = Variable<int>(protein);
    map['carbs'] = Variable<int>(carbs);
    map['fat'] = Variable<int>(fat);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FoodLogsCompanion toCompanion(bool nullToAbsent) {
    return FoodLogsCompanion(
      id: Value(id),
      mealName: Value(mealName),
      nameEn: nameEn == null && nullToAbsent
          ? const Value.absent()
          : Value(nameEn),
      nameFr: nameFr == null && nullToAbsent
          ? const Value.absent()
          : Value(nameFr),
      nameAr: nameAr == null && nullToAbsent
          ? const Value.absent()
          : Value(nameAr),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      ingredients: ingredients == null && nullToAbsent
          ? const Value.absent()
          : Value(ingredients),
      calories: Value(calories),
      protein: Value(protein),
      carbs: Value(carbs),
      fat: Value(fat),
      createdAt: Value(createdAt),
    );
  }

  factory FoodLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodLog(
      id: serializer.fromJson<int>(json['id']),
      mealName: serializer.fromJson<String>(json['mealName']),
      nameEn: serializer.fromJson<String?>(json['nameEn']),
      nameFr: serializer.fromJson<String?>(json['nameFr']),
      nameAr: serializer.fromJson<String?>(json['nameAr']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      ingredients: serializer.fromJson<String?>(json['ingredients']),
      calories: serializer.fromJson<int>(json['calories']),
      protein: serializer.fromJson<int>(json['protein']),
      carbs: serializer.fromJson<int>(json['carbs']),
      fat: serializer.fromJson<int>(json['fat']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mealName': serializer.toJson<String>(mealName),
      'nameEn': serializer.toJson<String?>(nameEn),
      'nameFr': serializer.toJson<String?>(nameFr),
      'nameAr': serializer.toJson<String?>(nameAr),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'ingredients': serializer.toJson<String?>(ingredients),
      'calories': serializer.toJson<int>(calories),
      'protein': serializer.toJson<int>(protein),
      'carbs': serializer.toJson<int>(carbs),
      'fat': serializer.toJson<int>(fat),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FoodLog copyWith({
    int? id,
    String? mealName,
    Value<String?> nameEn = const Value.absent(),
    Value<String?> nameFr = const Value.absent(),
    Value<String?> nameAr = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> ingredients = const Value.absent(),
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    DateTime? createdAt,
  }) => FoodLog(
    id: id ?? this.id,
    mealName: mealName ?? this.mealName,
    nameEn: nameEn.present ? nameEn.value : this.nameEn,
    nameFr: nameFr.present ? nameFr.value : this.nameFr,
    nameAr: nameAr.present ? nameAr.value : this.nameAr,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    ingredients: ingredients.present ? ingredients.value : this.ingredients,
    calories: calories ?? this.calories,
    protein: protein ?? this.protein,
    carbs: carbs ?? this.carbs,
    fat: fat ?? this.fat,
    createdAt: createdAt ?? this.createdAt,
  );
  FoodLog copyWithCompanion(FoodLogsCompanion data) {
    return FoodLog(
      id: data.id.present ? data.id.value : this.id,
      mealName: data.mealName.present ? data.mealName.value : this.mealName,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      nameFr: data.nameFr.present ? data.nameFr.value : this.nameFr,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      ingredients: data.ingredients.present
          ? data.ingredients.value
          : this.ingredients,
      calories: data.calories.present ? data.calories.value : this.calories,
      protein: data.protein.present ? data.protein.value : this.protein,
      carbs: data.carbs.present ? data.carbs.value : this.carbs,
      fat: data.fat.present ? data.fat.value : this.fat,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodLog(')
          ..write('id: $id, ')
          ..write('mealName: $mealName, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameFr: $nameFr, ')
          ..write('nameAr: $nameAr, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('ingredients: $ingredients, ')
          ..write('calories: $calories, ')
          ..write('protein: $protein, ')
          ..write('carbs: $carbs, ')
          ..write('fat: $fat, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mealName,
    nameEn,
    nameFr,
    nameAr,
    imageUrl,
    ingredients,
    calories,
    protein,
    carbs,
    fat,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodLog &&
          other.id == this.id &&
          other.mealName == this.mealName &&
          other.nameEn == this.nameEn &&
          other.nameFr == this.nameFr &&
          other.nameAr == this.nameAr &&
          other.imageUrl == this.imageUrl &&
          other.ingredients == this.ingredients &&
          other.calories == this.calories &&
          other.protein == this.protein &&
          other.carbs == this.carbs &&
          other.fat == this.fat &&
          other.createdAt == this.createdAt);
}

class FoodLogsCompanion extends UpdateCompanion<FoodLog> {
  final Value<int> id;
  final Value<String> mealName;
  final Value<String?> nameEn;
  final Value<String?> nameFr;
  final Value<String?> nameAr;
  final Value<String?> imageUrl;
  final Value<String?> ingredients;
  final Value<int> calories;
  final Value<int> protein;
  final Value<int> carbs;
  final Value<int> fat;
  final Value<DateTime> createdAt;
  const FoodLogsCompanion({
    this.id = const Value.absent(),
    this.mealName = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.nameFr = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.ingredients = const Value.absent(),
    this.calories = const Value.absent(),
    this.protein = const Value.absent(),
    this.carbs = const Value.absent(),
    this.fat = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FoodLogsCompanion.insert({
    this.id = const Value.absent(),
    required String mealName,
    this.nameEn = const Value.absent(),
    this.nameFr = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.ingredients = const Value.absent(),
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    this.createdAt = const Value.absent(),
  }) : mealName = Value(mealName),
       calories = Value(calories),
       protein = Value(protein),
       carbs = Value(carbs),
       fat = Value(fat);
  static Insertable<FoodLog> custom({
    Expression<int>? id,
    Expression<String>? mealName,
    Expression<String>? nameEn,
    Expression<String>? nameFr,
    Expression<String>? nameAr,
    Expression<String>? imageUrl,
    Expression<String>? ingredients,
    Expression<int>? calories,
    Expression<int>? protein,
    Expression<int>? carbs,
    Expression<int>? fat,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mealName != null) 'meal_name': mealName,
      if (nameEn != null) 'name_en': nameEn,
      if (nameFr != null) 'name_fr': nameFr,
      if (nameAr != null) 'name_ar': nameAr,
      if (imageUrl != null) 'image_url': imageUrl,
      if (ingredients != null) 'ingredients': ingredients,
      if (calories != null) 'calories': calories,
      if (protein != null) 'protein': protein,
      if (carbs != null) 'carbs': carbs,
      if (fat != null) 'fat': fat,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FoodLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? mealName,
    Value<String?>? nameEn,
    Value<String?>? nameFr,
    Value<String?>? nameAr,
    Value<String?>? imageUrl,
    Value<String?>? ingredients,
    Value<int>? calories,
    Value<int>? protein,
    Value<int>? carbs,
    Value<int>? fat,
    Value<DateTime>? createdAt,
  }) {
    return FoodLogsCompanion(
      id: id ?? this.id,
      mealName: mealName ?? this.mealName,
      nameEn: nameEn ?? this.nameEn,
      nameFr: nameFr ?? this.nameFr,
      nameAr: nameAr ?? this.nameAr,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredients: ingredients ?? this.ingredients,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mealName.present) {
      map['meal_name'] = Variable<String>(mealName.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (nameFr.present) {
      map['name_fr'] = Variable<String>(nameFr.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (ingredients.present) {
      map['ingredients'] = Variable<String>(ingredients.value);
    }
    if (calories.present) {
      map['calories'] = Variable<int>(calories.value);
    }
    if (protein.present) {
      map['protein'] = Variable<int>(protein.value);
    }
    if (carbs.present) {
      map['carbs'] = Variable<int>(carbs.value);
    }
    if (fat.present) {
      map['fat'] = Variable<int>(fat.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodLogsCompanion(')
          ..write('id: $id, ')
          ..write('mealName: $mealName, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameFr: $nameFr, ')
          ..write('nameAr: $nameAr, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('ingredients: $ingredients, ')
          ..write('calories: $calories, ')
          ..write('protein: $protein, ')
          ..write('carbs: $carbs, ')
          ..write('fat: $fat, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DailyStatsTable extends DailyStats
    with TableInfo<$DailyStatsTable, DailyStat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyStatsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _calorieBudgetMeta = const VerificationMeta(
    'calorieBudget',
  );
  @override
  late final GeneratedColumn<int> calorieBudget = GeneratedColumn<int>(
    'calorie_budget',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caloriesConsumedMeta = const VerificationMeta(
    'caloriesConsumed',
  );
  @override
  late final GeneratedColumn<int> caloriesConsumed = GeneratedColumn<int>(
    'calories_consumed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinTargetMeta = const VerificationMeta(
    'proteinTarget',
  );
  @override
  late final GeneratedColumn<int> proteinTarget = GeneratedColumn<int>(
    'protein_target',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinConsumedMeta = const VerificationMeta(
    'proteinConsumed',
  );
  @override
  late final GeneratedColumn<int> proteinConsumed = GeneratedColumn<int>(
    'protein_consumed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsTargetMeta = const VerificationMeta(
    'carbsTarget',
  );
  @override
  late final GeneratedColumn<int> carbsTarget = GeneratedColumn<int>(
    'carbs_target',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsConsumedMeta = const VerificationMeta(
    'carbsConsumed',
  );
  @override
  late final GeneratedColumn<int> carbsConsumed = GeneratedColumn<int>(
    'carbs_consumed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatTargetMeta = const VerificationMeta(
    'fatTarget',
  );
  @override
  late final GeneratedColumn<int> fatTarget = GeneratedColumn<int>(
    'fat_target',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatConsumedMeta = const VerificationMeta(
    'fatConsumed',
  );
  @override
  late final GeneratedColumn<int> fatConsumed = GeneratedColumn<int>(
    'fat_consumed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    calorieBudget,
    caloriesConsumed,
    proteinTarget,
    proteinConsumed,
    carbsTarget,
    carbsConsumed,
    fatTarget,
    fatConsumed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyStat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('calorie_budget')) {
      context.handle(
        _calorieBudgetMeta,
        calorieBudget.isAcceptableOrUnknown(
          data['calorie_budget']!,
          _calorieBudgetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_calorieBudgetMeta);
    }
    if (data.containsKey('calories_consumed')) {
      context.handle(
        _caloriesConsumedMeta,
        caloriesConsumed.isAcceptableOrUnknown(
          data['calories_consumed']!,
          _caloriesConsumedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caloriesConsumedMeta);
    }
    if (data.containsKey('protein_target')) {
      context.handle(
        _proteinTargetMeta,
        proteinTarget.isAcceptableOrUnknown(
          data['protein_target']!,
          _proteinTargetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_proteinTargetMeta);
    }
    if (data.containsKey('protein_consumed')) {
      context.handle(
        _proteinConsumedMeta,
        proteinConsumed.isAcceptableOrUnknown(
          data['protein_consumed']!,
          _proteinConsumedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_proteinConsumedMeta);
    }
    if (data.containsKey('carbs_target')) {
      context.handle(
        _carbsTargetMeta,
        carbsTarget.isAcceptableOrUnknown(
          data['carbs_target']!,
          _carbsTargetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_carbsTargetMeta);
    }
    if (data.containsKey('carbs_consumed')) {
      context.handle(
        _carbsConsumedMeta,
        carbsConsumed.isAcceptableOrUnknown(
          data['carbs_consumed']!,
          _carbsConsumedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_carbsConsumedMeta);
    }
    if (data.containsKey('fat_target')) {
      context.handle(
        _fatTargetMeta,
        fatTarget.isAcceptableOrUnknown(data['fat_target']!, _fatTargetMeta),
      );
    } else if (isInserting) {
      context.missing(_fatTargetMeta);
    }
    if (data.containsKey('fat_consumed')) {
      context.handle(
        _fatConsumedMeta,
        fatConsumed.isAcceptableOrUnknown(
          data['fat_consumed']!,
          _fatConsumedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fatConsumedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyStat(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      calorieBudget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calorie_budget'],
      )!,
      caloriesConsumed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calories_consumed'],
      )!,
      proteinTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}protein_target'],
      )!,
      proteinConsumed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}protein_consumed'],
      )!,
      carbsTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}carbs_target'],
      )!,
      carbsConsumed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}carbs_consumed'],
      )!,
      fatTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fat_target'],
      )!,
      fatConsumed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fat_consumed'],
      )!,
    );
  }

  @override
  $DailyStatsTable createAlias(String alias) {
    return $DailyStatsTable(attachedDatabase, alias);
  }
}

class DailyStat extends DataClass implements Insertable<DailyStat> {
  final int id;
  final DateTime date;
  final int calorieBudget;
  final int caloriesConsumed;
  final int proteinTarget;
  final int proteinConsumed;
  final int carbsTarget;
  final int carbsConsumed;
  final int fatTarget;
  final int fatConsumed;
  const DailyStat({
    required this.id,
    required this.date,
    required this.calorieBudget,
    required this.caloriesConsumed,
    required this.proteinTarget,
    required this.proteinConsumed,
    required this.carbsTarget,
    required this.carbsConsumed,
    required this.fatTarget,
    required this.fatConsumed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['calorie_budget'] = Variable<int>(calorieBudget);
    map['calories_consumed'] = Variable<int>(caloriesConsumed);
    map['protein_target'] = Variable<int>(proteinTarget);
    map['protein_consumed'] = Variable<int>(proteinConsumed);
    map['carbs_target'] = Variable<int>(carbsTarget);
    map['carbs_consumed'] = Variable<int>(carbsConsumed);
    map['fat_target'] = Variable<int>(fatTarget);
    map['fat_consumed'] = Variable<int>(fatConsumed);
    return map;
  }

  DailyStatsCompanion toCompanion(bool nullToAbsent) {
    return DailyStatsCompanion(
      id: Value(id),
      date: Value(date),
      calorieBudget: Value(calorieBudget),
      caloriesConsumed: Value(caloriesConsumed),
      proteinTarget: Value(proteinTarget),
      proteinConsumed: Value(proteinConsumed),
      carbsTarget: Value(carbsTarget),
      carbsConsumed: Value(carbsConsumed),
      fatTarget: Value(fatTarget),
      fatConsumed: Value(fatConsumed),
    );
  }

  factory DailyStat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyStat(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      calorieBudget: serializer.fromJson<int>(json['calorieBudget']),
      caloriesConsumed: serializer.fromJson<int>(json['caloriesConsumed']),
      proteinTarget: serializer.fromJson<int>(json['proteinTarget']),
      proteinConsumed: serializer.fromJson<int>(json['proteinConsumed']),
      carbsTarget: serializer.fromJson<int>(json['carbsTarget']),
      carbsConsumed: serializer.fromJson<int>(json['carbsConsumed']),
      fatTarget: serializer.fromJson<int>(json['fatTarget']),
      fatConsumed: serializer.fromJson<int>(json['fatConsumed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'calorieBudget': serializer.toJson<int>(calorieBudget),
      'caloriesConsumed': serializer.toJson<int>(caloriesConsumed),
      'proteinTarget': serializer.toJson<int>(proteinTarget),
      'proteinConsumed': serializer.toJson<int>(proteinConsumed),
      'carbsTarget': serializer.toJson<int>(carbsTarget),
      'carbsConsumed': serializer.toJson<int>(carbsConsumed),
      'fatTarget': serializer.toJson<int>(fatTarget),
      'fatConsumed': serializer.toJson<int>(fatConsumed),
    };
  }

  DailyStat copyWith({
    int? id,
    DateTime? date,
    int? calorieBudget,
    int? caloriesConsumed,
    int? proteinTarget,
    int? proteinConsumed,
    int? carbsTarget,
    int? carbsConsumed,
    int? fatTarget,
    int? fatConsumed,
  }) => DailyStat(
    id: id ?? this.id,
    date: date ?? this.date,
    calorieBudget: calorieBudget ?? this.calorieBudget,
    caloriesConsumed: caloriesConsumed ?? this.caloriesConsumed,
    proteinTarget: proteinTarget ?? this.proteinTarget,
    proteinConsumed: proteinConsumed ?? this.proteinConsumed,
    carbsTarget: carbsTarget ?? this.carbsTarget,
    carbsConsumed: carbsConsumed ?? this.carbsConsumed,
    fatTarget: fatTarget ?? this.fatTarget,
    fatConsumed: fatConsumed ?? this.fatConsumed,
  );
  DailyStat copyWithCompanion(DailyStatsCompanion data) {
    return DailyStat(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      calorieBudget: data.calorieBudget.present
          ? data.calorieBudget.value
          : this.calorieBudget,
      caloriesConsumed: data.caloriesConsumed.present
          ? data.caloriesConsumed.value
          : this.caloriesConsumed,
      proteinTarget: data.proteinTarget.present
          ? data.proteinTarget.value
          : this.proteinTarget,
      proteinConsumed: data.proteinConsumed.present
          ? data.proteinConsumed.value
          : this.proteinConsumed,
      carbsTarget: data.carbsTarget.present
          ? data.carbsTarget.value
          : this.carbsTarget,
      carbsConsumed: data.carbsConsumed.present
          ? data.carbsConsumed.value
          : this.carbsConsumed,
      fatTarget: data.fatTarget.present ? data.fatTarget.value : this.fatTarget,
      fatConsumed: data.fatConsumed.present
          ? data.fatConsumed.value
          : this.fatConsumed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyStat(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('calorieBudget: $calorieBudget, ')
          ..write('caloriesConsumed: $caloriesConsumed, ')
          ..write('proteinTarget: $proteinTarget, ')
          ..write('proteinConsumed: $proteinConsumed, ')
          ..write('carbsTarget: $carbsTarget, ')
          ..write('carbsConsumed: $carbsConsumed, ')
          ..write('fatTarget: $fatTarget, ')
          ..write('fatConsumed: $fatConsumed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    calorieBudget,
    caloriesConsumed,
    proteinTarget,
    proteinConsumed,
    carbsTarget,
    carbsConsumed,
    fatTarget,
    fatConsumed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyStat &&
          other.id == this.id &&
          other.date == this.date &&
          other.calorieBudget == this.calorieBudget &&
          other.caloriesConsumed == this.caloriesConsumed &&
          other.proteinTarget == this.proteinTarget &&
          other.proteinConsumed == this.proteinConsumed &&
          other.carbsTarget == this.carbsTarget &&
          other.carbsConsumed == this.carbsConsumed &&
          other.fatTarget == this.fatTarget &&
          other.fatConsumed == this.fatConsumed);
}

class DailyStatsCompanion extends UpdateCompanion<DailyStat> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<int> calorieBudget;
  final Value<int> caloriesConsumed;
  final Value<int> proteinTarget;
  final Value<int> proteinConsumed;
  final Value<int> carbsTarget;
  final Value<int> carbsConsumed;
  final Value<int> fatTarget;
  final Value<int> fatConsumed;
  const DailyStatsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.calorieBudget = const Value.absent(),
    this.caloriesConsumed = const Value.absent(),
    this.proteinTarget = const Value.absent(),
    this.proteinConsumed = const Value.absent(),
    this.carbsTarget = const Value.absent(),
    this.carbsConsumed = const Value.absent(),
    this.fatTarget = const Value.absent(),
    this.fatConsumed = const Value.absent(),
  });
  DailyStatsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required int calorieBudget,
    required int caloriesConsumed,
    required int proteinTarget,
    required int proteinConsumed,
    required int carbsTarget,
    required int carbsConsumed,
    required int fatTarget,
    required int fatConsumed,
  }) : date = Value(date),
       calorieBudget = Value(calorieBudget),
       caloriesConsumed = Value(caloriesConsumed),
       proteinTarget = Value(proteinTarget),
       proteinConsumed = Value(proteinConsumed),
       carbsTarget = Value(carbsTarget),
       carbsConsumed = Value(carbsConsumed),
       fatTarget = Value(fatTarget),
       fatConsumed = Value(fatConsumed);
  static Insertable<DailyStat> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<int>? calorieBudget,
    Expression<int>? caloriesConsumed,
    Expression<int>? proteinTarget,
    Expression<int>? proteinConsumed,
    Expression<int>? carbsTarget,
    Expression<int>? carbsConsumed,
    Expression<int>? fatTarget,
    Expression<int>? fatConsumed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (calorieBudget != null) 'calorie_budget': calorieBudget,
      if (caloriesConsumed != null) 'calories_consumed': caloriesConsumed,
      if (proteinTarget != null) 'protein_target': proteinTarget,
      if (proteinConsumed != null) 'protein_consumed': proteinConsumed,
      if (carbsTarget != null) 'carbs_target': carbsTarget,
      if (carbsConsumed != null) 'carbs_consumed': carbsConsumed,
      if (fatTarget != null) 'fat_target': fatTarget,
      if (fatConsumed != null) 'fat_consumed': fatConsumed,
    });
  }

  DailyStatsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<int>? calorieBudget,
    Value<int>? caloriesConsumed,
    Value<int>? proteinTarget,
    Value<int>? proteinConsumed,
    Value<int>? carbsTarget,
    Value<int>? carbsConsumed,
    Value<int>? fatTarget,
    Value<int>? fatConsumed,
  }) {
    return DailyStatsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      calorieBudget: calorieBudget ?? this.calorieBudget,
      caloriesConsumed: caloriesConsumed ?? this.caloriesConsumed,
      proteinTarget: proteinTarget ?? this.proteinTarget,
      proteinConsumed: proteinConsumed ?? this.proteinConsumed,
      carbsTarget: carbsTarget ?? this.carbsTarget,
      carbsConsumed: carbsConsumed ?? this.carbsConsumed,
      fatTarget: fatTarget ?? this.fatTarget,
      fatConsumed: fatConsumed ?? this.fatConsumed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (calorieBudget.present) {
      map['calorie_budget'] = Variable<int>(calorieBudget.value);
    }
    if (caloriesConsumed.present) {
      map['calories_consumed'] = Variable<int>(caloriesConsumed.value);
    }
    if (proteinTarget.present) {
      map['protein_target'] = Variable<int>(proteinTarget.value);
    }
    if (proteinConsumed.present) {
      map['protein_consumed'] = Variable<int>(proteinConsumed.value);
    }
    if (carbsTarget.present) {
      map['carbs_target'] = Variable<int>(carbsTarget.value);
    }
    if (carbsConsumed.present) {
      map['carbs_consumed'] = Variable<int>(carbsConsumed.value);
    }
    if (fatTarget.present) {
      map['fat_target'] = Variable<int>(fatTarget.value);
    }
    if (fatConsumed.present) {
      map['fat_consumed'] = Variable<int>(fatConsumed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyStatsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('calorieBudget: $calorieBudget, ')
          ..write('caloriesConsumed: $caloriesConsumed, ')
          ..write('proteinTarget: $proteinTarget, ')
          ..write('proteinConsumed: $proteinConsumed, ')
          ..write('carbsTarget: $carbsTarget, ')
          ..write('carbsConsumed: $carbsConsumed, ')
          ..write('fatTarget: $fatTarget, ')
          ..write('fatConsumed: $fatConsumed')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FoodLogsTable foodLogs = $FoodLogsTable(this);
  late final $DailyStatsTable dailyStats = $DailyStatsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [foodLogs, dailyStats];
}

typedef $$FoodLogsTableCreateCompanionBuilder =
    FoodLogsCompanion Function({
      Value<int> id,
      required String mealName,
      Value<String?> nameEn,
      Value<String?> nameFr,
      Value<String?> nameAr,
      Value<String?> imageUrl,
      Value<String?> ingredients,
      required int calories,
      required int protein,
      required int carbs,
      required int fat,
      Value<DateTime> createdAt,
    });
typedef $$FoodLogsTableUpdateCompanionBuilder =
    FoodLogsCompanion Function({
      Value<int> id,
      Value<String> mealName,
      Value<String?> nameEn,
      Value<String?> nameFr,
      Value<String?> nameAr,
      Value<String?> imageUrl,
      Value<String?> ingredients,
      Value<int> calories,
      Value<int> protein,
      Value<int> carbs,
      Value<int> fat,
      Value<DateTime> createdAt,
    });

class $$FoodLogsTableFilterComposer
    extends Composer<_$AppDatabase, $FoodLogsTable> {
  $$FoodLogsTableFilterComposer({
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

  ColumnFilters<String> get mealName => $composableBuilder(
    column: $table.mealName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameFr => $composableBuilder(
    column: $table.nameFr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ingredients => $composableBuilder(
    column: $table.ingredients,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodLogsTable> {
  $$FoodLogsTableOrderingComposer({
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

  ColumnOrderings<String> get mealName => $composableBuilder(
    column: $table.mealName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameFr => $composableBuilder(
    column: $table.nameFr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ingredients => $composableBuilder(
    column: $table.ingredients,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodLogsTable> {
  $$FoodLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mealName =>
      $composableBuilder(column: $table.mealName, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get nameFr =>
      $composableBuilder(column: $table.nameFr, builder: (column) => column);

  GeneratedColumn<String> get nameAr =>
      $composableBuilder(column: $table.nameAr, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get ingredients => $composableBuilder(
    column: $table.ingredients,
    builder: (column) => column,
  );

  GeneratedColumn<int> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<int> get protein =>
      $composableBuilder(column: $table.protein, builder: (column) => column);

  GeneratedColumn<int> get carbs =>
      $composableBuilder(column: $table.carbs, builder: (column) => column);

  GeneratedColumn<int> get fat =>
      $composableBuilder(column: $table.fat, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FoodLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodLogsTable,
          FoodLog,
          $$FoodLogsTableFilterComposer,
          $$FoodLogsTableOrderingComposer,
          $$FoodLogsTableAnnotationComposer,
          $$FoodLogsTableCreateCompanionBuilder,
          $$FoodLogsTableUpdateCompanionBuilder,
          (FoodLog, BaseReferences<_$AppDatabase, $FoodLogsTable, FoodLog>),
          FoodLog,
          PrefetchHooks Function()
        > {
  $$FoodLogsTableTableManager(_$AppDatabase db, $FoodLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> mealName = const Value.absent(),
                Value<String?> nameEn = const Value.absent(),
                Value<String?> nameFr = const Value.absent(),
                Value<String?> nameAr = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> ingredients = const Value.absent(),
                Value<int> calories = const Value.absent(),
                Value<int> protein = const Value.absent(),
                Value<int> carbs = const Value.absent(),
                Value<int> fat = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FoodLogsCompanion(
                id: id,
                mealName: mealName,
                nameEn: nameEn,
                nameFr: nameFr,
                nameAr: nameAr,
                imageUrl: imageUrl,
                ingredients: ingredients,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String mealName,
                Value<String?> nameEn = const Value.absent(),
                Value<String?> nameFr = const Value.absent(),
                Value<String?> nameAr = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> ingredients = const Value.absent(),
                required int calories,
                required int protein,
                required int carbs,
                required int fat,
                Value<DateTime> createdAt = const Value.absent(),
              }) => FoodLogsCompanion.insert(
                id: id,
                mealName: mealName,
                nameEn: nameEn,
                nameFr: nameFr,
                nameAr: nameAr,
                imageUrl: imageUrl,
                ingredients: ingredients,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoodLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodLogsTable,
      FoodLog,
      $$FoodLogsTableFilterComposer,
      $$FoodLogsTableOrderingComposer,
      $$FoodLogsTableAnnotationComposer,
      $$FoodLogsTableCreateCompanionBuilder,
      $$FoodLogsTableUpdateCompanionBuilder,
      (FoodLog, BaseReferences<_$AppDatabase, $FoodLogsTable, FoodLog>),
      FoodLog,
      PrefetchHooks Function()
    >;
typedef $$DailyStatsTableCreateCompanionBuilder =
    DailyStatsCompanion Function({
      Value<int> id,
      required DateTime date,
      required int calorieBudget,
      required int caloriesConsumed,
      required int proteinTarget,
      required int proteinConsumed,
      required int carbsTarget,
      required int carbsConsumed,
      required int fatTarget,
      required int fatConsumed,
    });
typedef $$DailyStatsTableUpdateCompanionBuilder =
    DailyStatsCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<int> calorieBudget,
      Value<int> caloriesConsumed,
      Value<int> proteinTarget,
      Value<int> proteinConsumed,
      Value<int> carbsTarget,
      Value<int> carbsConsumed,
      Value<int> fatTarget,
      Value<int> fatConsumed,
    });

class $$DailyStatsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyStatsTable> {
  $$DailyStatsTableFilterComposer({
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

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calorieBudget => $composableBuilder(
    column: $table.calorieBudget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get caloriesConsumed => $composableBuilder(
    column: $table.caloriesConsumed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get proteinTarget => $composableBuilder(
    column: $table.proteinTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get proteinConsumed => $composableBuilder(
    column: $table.proteinConsumed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get carbsTarget => $composableBuilder(
    column: $table.carbsTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get carbsConsumed => $composableBuilder(
    column: $table.carbsConsumed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fatTarget => $composableBuilder(
    column: $table.fatTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fatConsumed => $composableBuilder(
    column: $table.fatConsumed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyStatsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyStatsTable> {
  $$DailyStatsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calorieBudget => $composableBuilder(
    column: $table.calorieBudget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get caloriesConsumed => $composableBuilder(
    column: $table.caloriesConsumed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get proteinTarget => $composableBuilder(
    column: $table.proteinTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get proteinConsumed => $composableBuilder(
    column: $table.proteinConsumed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get carbsTarget => $composableBuilder(
    column: $table.carbsTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get carbsConsumed => $composableBuilder(
    column: $table.carbsConsumed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fatTarget => $composableBuilder(
    column: $table.fatTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fatConsumed => $composableBuilder(
    column: $table.fatConsumed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyStatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyStatsTable> {
  $$DailyStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get calorieBudget => $composableBuilder(
    column: $table.calorieBudget,
    builder: (column) => column,
  );

  GeneratedColumn<int> get caloriesConsumed => $composableBuilder(
    column: $table.caloriesConsumed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get proteinTarget => $composableBuilder(
    column: $table.proteinTarget,
    builder: (column) => column,
  );

  GeneratedColumn<int> get proteinConsumed => $composableBuilder(
    column: $table.proteinConsumed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get carbsTarget => $composableBuilder(
    column: $table.carbsTarget,
    builder: (column) => column,
  );

  GeneratedColumn<int> get carbsConsumed => $composableBuilder(
    column: $table.carbsConsumed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fatTarget =>
      $composableBuilder(column: $table.fatTarget, builder: (column) => column);

  GeneratedColumn<int> get fatConsumed => $composableBuilder(
    column: $table.fatConsumed,
    builder: (column) => column,
  );
}

class $$DailyStatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyStatsTable,
          DailyStat,
          $$DailyStatsTableFilterComposer,
          $$DailyStatsTableOrderingComposer,
          $$DailyStatsTableAnnotationComposer,
          $$DailyStatsTableCreateCompanionBuilder,
          $$DailyStatsTableUpdateCompanionBuilder,
          (
            DailyStat,
            BaseReferences<_$AppDatabase, $DailyStatsTable, DailyStat>,
          ),
          DailyStat,
          PrefetchHooks Function()
        > {
  $$DailyStatsTableTableManager(_$AppDatabase db, $DailyStatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> calorieBudget = const Value.absent(),
                Value<int> caloriesConsumed = const Value.absent(),
                Value<int> proteinTarget = const Value.absent(),
                Value<int> proteinConsumed = const Value.absent(),
                Value<int> carbsTarget = const Value.absent(),
                Value<int> carbsConsumed = const Value.absent(),
                Value<int> fatTarget = const Value.absent(),
                Value<int> fatConsumed = const Value.absent(),
              }) => DailyStatsCompanion(
                id: id,
                date: date,
                calorieBudget: calorieBudget,
                caloriesConsumed: caloriesConsumed,
                proteinTarget: proteinTarget,
                proteinConsumed: proteinConsumed,
                carbsTarget: carbsTarget,
                carbsConsumed: carbsConsumed,
                fatTarget: fatTarget,
                fatConsumed: fatConsumed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required int calorieBudget,
                required int caloriesConsumed,
                required int proteinTarget,
                required int proteinConsumed,
                required int carbsTarget,
                required int carbsConsumed,
                required int fatTarget,
                required int fatConsumed,
              }) => DailyStatsCompanion.insert(
                id: id,
                date: date,
                calorieBudget: calorieBudget,
                caloriesConsumed: caloriesConsumed,
                proteinTarget: proteinTarget,
                proteinConsumed: proteinConsumed,
                carbsTarget: carbsTarget,
                carbsConsumed: carbsConsumed,
                fatTarget: fatTarget,
                fatConsumed: fatConsumed,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyStatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyStatsTable,
      DailyStat,
      $$DailyStatsTableFilterComposer,
      $$DailyStatsTableOrderingComposer,
      $$DailyStatsTableAnnotationComposer,
      $$DailyStatsTableCreateCompanionBuilder,
      $$DailyStatsTableUpdateCompanionBuilder,
      (DailyStat, BaseReferences<_$AppDatabase, $DailyStatsTable, DailyStat>),
      DailyStat,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FoodLogsTableTableManager get foodLogs =>
      $$FoodLogsTableTableManager(_db, _db.foodLogs);
  $$DailyStatsTableTableManager get dailyStats =>
      $$DailyStatsTableTableManager(_db, _db.dailyStats);
}
