import 'package:drift/drift.dart';

class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get targetAmount => real()();
  RealColumn get savedAmount => real().withDefault(const Constant(0.0))();
  IntColumn get color => integer()();
  IntColumn get icon => integer().withDefault(const Constant(0xEE51))();
  // Optional product image from an online search (URL).
  TextColumn get imageUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deadline => dateTime().nullable()();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId => integer().nullable()();
  RealColumn get amount => real()();
  // 'deposit' or 'withdrawal'
  TextColumn get type => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get category => text().withDefault(const Constant('General'))();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
}

class Streaks extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastDepositDate => dateTime().nullable()();
}

class Achievements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get badgeType => text()();
  DateTimeColumn get unlockedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get goalId => integer().nullable()();
}

class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  BoolColumn get reduceMotion => boolean().withDefault(const Constant(false))();
  TextColumn get language => text().withDefault(const Constant('en'))();
  TextColumn get themeId => text().withDefault(const Constant('indigo'))();
  TextColumn get displayName => text().nullable()();
  BoolColumn get hasOnboarded => boolean().withDefault(const Constant(false))();
}
