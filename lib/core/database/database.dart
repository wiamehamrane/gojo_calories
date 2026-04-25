import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class FoodLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get mealName => text()();
  TextColumn get nameEn => text().nullable()();
  TextColumn get nameFr => text().nullable()();
  TextColumn get nameAr => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get ingredients => text().nullable()();
  IntColumn get calories => integer()();
  IntColumn get protein => integer()();
  IntColumn get carbs => integer()();
  IntColumn get fat => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class DailyStats extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime().unique()();
  IntColumn get calorieBudget => integer()();
  IntColumn get caloriesConsumed => integer()();
  IntColumn get proteinTarget => integer()();
  IntColumn get proteinConsumed => integer()();
  IntColumn get carbsTarget => integer()();
  IntColumn get carbsConsumed => integer()();
  IntColumn get fatTarget => integer()();
  IntColumn get fatConsumed => integer()();
}

@DriftDatabase(tables: [FoodLogs, DailyStats])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(foodLogs, foodLogs.nameEn);
            await m.addColumn(foodLogs, foodLogs.nameFr);
            await m.addColumn(foodLogs, foodLogs.nameAr);
          }
          if (from < 3) {
            await m.addColumn(foodLogs, foodLogs.imageUrl);
          }
          if (from < 4) {
            await m.addColumn(foodLogs, foodLogs.ingredients);
          }
        },
      );



  Future<List<FoodLog>> getAllFoodLogs() => select(foodLogs).get();
  Future<int> insertFoodLog(FoodLogsCompanion log) =>
      into(foodLogs).insert(log);

  Future<DailyStat?> getStatsForDate(DateTime dt) {
    final start = DateTime(dt.year, dt.month, dt.day);
    return (select(
      dailyStats,
    )..where((tbl) => tbl.date.equals(start))).getSingleOrNull();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
