// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $IncomesTable extends Incomes with TableInfo<$IncomesTable, Income> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IncomesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
      'month', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
      'year', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _incomeTypeMeta =
      const VerificationMeta('incomeType');
  @override
  late final GeneratedColumn<String> incomeType = GeneratedColumn<String>(
      'income_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _isNetMeta = const VerificationMeta('isNet');
  @override
  late final GeneratedColumn<bool> isNet = GeneratedColumn<bool>(
      'is_net', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_net" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _inssDeductedMeta =
      const VerificationMeta('inssDeducted');
  @override
  late final GeneratedColumn<double> inssDeducted = GeneratedColumn<double>(
      'inss_deducted', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _irrfDeductedMeta =
      const VerificationMeta('irrfDeducted');
  @override
  late final GeneratedColumn<double> irrfDeducted = GeneratedColumn<double>(
      'irrf_deducted', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        month,
        year,
        incomeType,
        amount,
        isNet,
        inssDeducted,
        irrfDeducted,
        notes,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'incomes';
  @override
  VerificationContext validateIntegrity(Insertable<Income> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('month')) {
      context.handle(
          _monthMeta, month.isAcceptableOrUnknown(data['month']!, _monthMeta));
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
          _yearMeta, year.isAcceptableOrUnknown(data['year']!, _yearMeta));
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('income_type')) {
      context.handle(
          _incomeTypeMeta,
          incomeType.isAcceptableOrUnknown(
              data['income_type']!, _incomeTypeMeta));
    } else if (isInserting) {
      context.missing(_incomeTypeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('is_net')) {
      context.handle(
          _isNetMeta, isNet.isAcceptableOrUnknown(data['is_net']!, _isNetMeta));
    }
    if (data.containsKey('inss_deducted')) {
      context.handle(
          _inssDeductedMeta,
          inssDeducted.isAcceptableOrUnknown(
              data['inss_deducted']!, _inssDeductedMeta));
    }
    if (data.containsKey('irrf_deducted')) {
      context.handle(
          _irrfDeductedMeta,
          irrfDeducted.isAcceptableOrUnknown(
              data['irrf_deducted']!, _irrfDeductedMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Income map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Income(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      month: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}month'])!,
      year: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}year'])!,
      incomeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}income_type'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      isNet: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_net'])!,
      inssDeducted: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}inss_deducted']),
      irrfDeducted: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}irrf_deducted']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $IncomesTable createAlias(String alias) {
    return $IncomesTable(attachedDatabase, alias);
  }
}

class Income extends DataClass implements Insertable<Income> {
  final int id;
  final int month;
  final int year;
  final String incomeType;
  final double amount;
  final bool isNet;
  final double? inssDeducted;
  final double? irrfDeducted;
  final String? notes;
  final DateTime createdAt;
  const Income(
      {required this.id,
      required this.month,
      required this.year,
      required this.incomeType,
      required this.amount,
      required this.isNet,
      this.inssDeducted,
      this.irrfDeducted,
      this.notes,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['month'] = Variable<int>(month);
    map['year'] = Variable<int>(year);
    map['income_type'] = Variable<String>(incomeType);
    map['amount'] = Variable<double>(amount);
    map['is_net'] = Variable<bool>(isNet);
    if (!nullToAbsent || inssDeducted != null) {
      map['inss_deducted'] = Variable<double>(inssDeducted);
    }
    if (!nullToAbsent || irrfDeducted != null) {
      map['irrf_deducted'] = Variable<double>(irrfDeducted);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  IncomesCompanion toCompanion(bool nullToAbsent) {
    return IncomesCompanion(
      id: Value(id),
      month: Value(month),
      year: Value(year),
      incomeType: Value(incomeType),
      amount: Value(amount),
      isNet: Value(isNet),
      inssDeducted: inssDeducted == null && nullToAbsent
          ? const Value.absent()
          : Value(inssDeducted),
      irrfDeducted: irrfDeducted == null && nullToAbsent
          ? const Value.absent()
          : Value(irrfDeducted),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory Income.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Income(
      id: serializer.fromJson<int>(json['id']),
      month: serializer.fromJson<int>(json['month']),
      year: serializer.fromJson<int>(json['year']),
      incomeType: serializer.fromJson<String>(json['incomeType']),
      amount: serializer.fromJson<double>(json['amount']),
      isNet: serializer.fromJson<bool>(json['isNet']),
      inssDeducted: serializer.fromJson<double?>(json['inssDeducted']),
      irrfDeducted: serializer.fromJson<double?>(json['irrfDeducted']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'month': serializer.toJson<int>(month),
      'year': serializer.toJson<int>(year),
      'incomeType': serializer.toJson<String>(incomeType),
      'amount': serializer.toJson<double>(amount),
      'isNet': serializer.toJson<bool>(isNet),
      'inssDeducted': serializer.toJson<double?>(inssDeducted),
      'irrfDeducted': serializer.toJson<double?>(irrfDeducted),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Income copyWith(
          {int? id,
          int? month,
          int? year,
          String? incomeType,
          double? amount,
          bool? isNet,
          Value<double?> inssDeducted = const Value.absent(),
          Value<double?> irrfDeducted = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt}) =>
      Income(
        id: id ?? this.id,
        month: month ?? this.month,
        year: year ?? this.year,
        incomeType: incomeType ?? this.incomeType,
        amount: amount ?? this.amount,
        isNet: isNet ?? this.isNet,
        inssDeducted:
            inssDeducted.present ? inssDeducted.value : this.inssDeducted,
        irrfDeducted:
            irrfDeducted.present ? irrfDeducted.value : this.irrfDeducted,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('Income(')
          ..write('id: $id, ')
          ..write('month: $month, ')
          ..write('year: $year, ')
          ..write('incomeType: $incomeType, ')
          ..write('amount: $amount, ')
          ..write('isNet: $isNet, ')
          ..write('inssDeducted: $inssDeducted, ')
          ..write('irrfDeducted: $irrfDeducted, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, month, year, incomeType, amount, isNet,
      inssDeducted, irrfDeducted, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Income &&
          other.id == this.id &&
          other.month == this.month &&
          other.year == this.year &&
          other.incomeType == this.incomeType &&
          other.amount == this.amount &&
          other.isNet == this.isNet &&
          other.inssDeducted == this.inssDeducted &&
          other.irrfDeducted == this.irrfDeducted &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class IncomesCompanion extends UpdateCompanion<Income> {
  final Value<int> id;
  final Value<int> month;
  final Value<int> year;
  final Value<String> incomeType;
  final Value<double> amount;
  final Value<bool> isNet;
  final Value<double?> inssDeducted;
  final Value<double?> irrfDeducted;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const IncomesCompanion({
    this.id = const Value.absent(),
    this.month = const Value.absent(),
    this.year = const Value.absent(),
    this.incomeType = const Value.absent(),
    this.amount = const Value.absent(),
    this.isNet = const Value.absent(),
    this.inssDeducted = const Value.absent(),
    this.irrfDeducted = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  IncomesCompanion.insert({
    this.id = const Value.absent(),
    required int month,
    required int year,
    required String incomeType,
    required double amount,
    this.isNet = const Value.absent(),
    this.inssDeducted = const Value.absent(),
    this.irrfDeducted = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : month = Value(month),
        year = Value(year),
        incomeType = Value(incomeType),
        amount = Value(amount);
  static Insertable<Income> custom({
    Expression<int>? id,
    Expression<int>? month,
    Expression<int>? year,
    Expression<String>? incomeType,
    Expression<double>? amount,
    Expression<bool>? isNet,
    Expression<double>? inssDeducted,
    Expression<double>? irrfDeducted,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (month != null) 'month': month,
      if (year != null) 'year': year,
      if (incomeType != null) 'income_type': incomeType,
      if (amount != null) 'amount': amount,
      if (isNet != null) 'is_net': isNet,
      if (inssDeducted != null) 'inss_deducted': inssDeducted,
      if (irrfDeducted != null) 'irrf_deducted': irrfDeducted,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  IncomesCompanion copyWith(
      {Value<int>? id,
      Value<int>? month,
      Value<int>? year,
      Value<String>? incomeType,
      Value<double>? amount,
      Value<bool>? isNet,
      Value<double?>? inssDeducted,
      Value<double?>? irrfDeducted,
      Value<String?>? notes,
      Value<DateTime>? createdAt}) {
    return IncomesCompanion(
      id: id ?? this.id,
      month: month ?? this.month,
      year: year ?? this.year,
      incomeType: incomeType ?? this.incomeType,
      amount: amount ?? this.amount,
      isNet: isNet ?? this.isNet,
      inssDeducted: inssDeducted ?? this.inssDeducted,
      irrfDeducted: irrfDeducted ?? this.irrfDeducted,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (incomeType.present) {
      map['income_type'] = Variable<String>(incomeType.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (isNet.present) {
      map['is_net'] = Variable<bool>(isNet.value);
    }
    if (inssDeducted.present) {
      map['inss_deducted'] = Variable<double>(inssDeducted.value);
    }
    if (irrfDeducted.present) {
      map['irrf_deducted'] = Variable<double>(irrfDeducted.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IncomesCompanion(')
          ..write('id: $id, ')
          ..write('month: $month, ')
          ..write('year: $year, ')
          ..write('incomeType: $incomeType, ')
          ..write('amount: $amount, ')
          ..write('isNet: $isNet, ')
          ..write('inssDeducted: $inssDeducted, ')
          ..write('irrfDeducted: $irrfDeducted, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses with TableInfo<$ExpensesTable, Expense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
      'month', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
      'year', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _payTypeMeta =
      const VerificationMeta('payType');
  @override
  late final GeneratedColumn<String> payType = GeneratedColumn<String>(
      'pay_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subcategoryMeta =
      const VerificationMeta('subcategory');
  @override
  late final GeneratedColumn<String> subcategory = GeneratedColumn<String>(
      'subcategory', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _paymentMethodMeta =
      const VerificationMeta('paymentMethod');
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
      'payment_method', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _installmentsMeta =
      const VerificationMeta('installments');
  @override
  late final GeneratedColumn<int> installments = GeneratedColumn<int>(
      'installments', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _isFixedMeta =
      const VerificationMeta('isFixed');
  @override
  late final GeneratedColumn<bool> isFixed = GeneratedColumn<bool>(
      'is_fixed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_fixed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _storeDescriptionMeta =
      const VerificationMeta('storeDescription');
  @override
  late final GeneratedColumn<String> storeDescription = GeneratedColumn<String>(
      'store_description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        month,
        year,
        payType,
        category,
        subcategory,
        amount,
        paymentMethod,
        installments,
        isFixed,
        storeDescription,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(Insertable<Expense> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('month')) {
      context.handle(
          _monthMeta, month.isAcceptableOrUnknown(data['month']!, _monthMeta));
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
          _yearMeta, year.isAcceptableOrUnknown(data['year']!, _yearMeta));
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('pay_type')) {
      context.handle(_payTypeMeta,
          payType.isAcceptableOrUnknown(data['pay_type']!, _payTypeMeta));
    } else if (isInserting) {
      context.missing(_payTypeMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('subcategory')) {
      context.handle(
          _subcategoryMeta,
          subcategory.isAcceptableOrUnknown(
              data['subcategory']!, _subcategoryMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
          _paymentMethodMeta,
          paymentMethod.isAcceptableOrUnknown(
              data['payment_method']!, _paymentMethodMeta));
    } else if (isInserting) {
      context.missing(_paymentMethodMeta);
    }
    if (data.containsKey('installments')) {
      context.handle(
          _installmentsMeta,
          installments.isAcceptableOrUnknown(
              data['installments']!, _installmentsMeta));
    }
    if (data.containsKey('is_fixed')) {
      context.handle(_isFixedMeta,
          isFixed.isAcceptableOrUnknown(data['is_fixed']!, _isFixedMeta));
    }
    if (data.containsKey('store_description')) {
      context.handle(
          _storeDescriptionMeta,
          storeDescription.isAcceptableOrUnknown(
              data['store_description']!, _storeDescriptionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Expense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Expense(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      month: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}month'])!,
      year: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}year'])!,
      payType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pay_type'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      subcategory: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subcategory']),
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      paymentMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_method'])!,
      installments: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}installments'])!,
      isFixed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_fixed'])!,
      storeDescription: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}store_description']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class Expense extends DataClass implements Insertable<Expense> {
  final int id;
  final int month;
  final int year;
  final String payType;
  final String category;
  final String? subcategory;
  final double amount;
  final String paymentMethod;
  final int installments;
  final bool isFixed;
  final String? storeDescription;
  final DateTime createdAt;
  const Expense(
      {required this.id,
      required this.month,
      required this.year,
      required this.payType,
      required this.category,
      this.subcategory,
      required this.amount,
      required this.paymentMethod,
      required this.installments,
      required this.isFixed,
      this.storeDescription,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['month'] = Variable<int>(month);
    map['year'] = Variable<int>(year);
    map['pay_type'] = Variable<String>(payType);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || subcategory != null) {
      map['subcategory'] = Variable<String>(subcategory);
    }
    map['amount'] = Variable<double>(amount);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['installments'] = Variable<int>(installments);
    map['is_fixed'] = Variable<bool>(isFixed);
    if (!nullToAbsent || storeDescription != null) {
      map['store_description'] = Variable<String>(storeDescription);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      month: Value(month),
      year: Value(year),
      payType: Value(payType),
      category: Value(category),
      subcategory: subcategory == null && nullToAbsent
          ? const Value.absent()
          : Value(subcategory),
      amount: Value(amount),
      paymentMethod: Value(paymentMethod),
      installments: Value(installments),
      isFixed: Value(isFixed),
      storeDescription: storeDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(storeDescription),
      createdAt: Value(createdAt),
    );
  }

  factory Expense.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Expense(
      id: serializer.fromJson<int>(json['id']),
      month: serializer.fromJson<int>(json['month']),
      year: serializer.fromJson<int>(json['year']),
      payType: serializer.fromJson<String>(json['payType']),
      category: serializer.fromJson<String>(json['category']),
      subcategory: serializer.fromJson<String?>(json['subcategory']),
      amount: serializer.fromJson<double>(json['amount']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      installments: serializer.fromJson<int>(json['installments']),
      isFixed: serializer.fromJson<bool>(json['isFixed']),
      storeDescription: serializer.fromJson<String?>(json['storeDescription']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'month': serializer.toJson<int>(month),
      'year': serializer.toJson<int>(year),
      'payType': serializer.toJson<String>(payType),
      'category': serializer.toJson<String>(category),
      'subcategory': serializer.toJson<String?>(subcategory),
      'amount': serializer.toJson<double>(amount),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'installments': serializer.toJson<int>(installments),
      'isFixed': serializer.toJson<bool>(isFixed),
      'storeDescription': serializer.toJson<String?>(storeDescription),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Expense copyWith(
          {int? id,
          int? month,
          int? year,
          String? payType,
          String? category,
          Value<String?> subcategory = const Value.absent(),
          double? amount,
          String? paymentMethod,
          int? installments,
          bool? isFixed,
          Value<String?> storeDescription = const Value.absent(),
          DateTime? createdAt}) =>
      Expense(
        id: id ?? this.id,
        month: month ?? this.month,
        year: year ?? this.year,
        payType: payType ?? this.payType,
        category: category ?? this.category,
        subcategory: subcategory.present ? subcategory.value : this.subcategory,
        amount: amount ?? this.amount,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        installments: installments ?? this.installments,
        isFixed: isFixed ?? this.isFixed,
        storeDescription: storeDescription.present
            ? storeDescription.value
            : this.storeDescription,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('Expense(')
          ..write('id: $id, ')
          ..write('month: $month, ')
          ..write('year: $year, ')
          ..write('payType: $payType, ')
          ..write('category: $category, ')
          ..write('subcategory: $subcategory, ')
          ..write('amount: $amount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('installments: $installments, ')
          ..write('isFixed: $isFixed, ')
          ..write('storeDescription: $storeDescription, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      month,
      year,
      payType,
      category,
      subcategory,
      amount,
      paymentMethod,
      installments,
      isFixed,
      storeDescription,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Expense &&
          other.id == this.id &&
          other.month == this.month &&
          other.year == this.year &&
          other.payType == this.payType &&
          other.category == this.category &&
          other.subcategory == this.subcategory &&
          other.amount == this.amount &&
          other.paymentMethod == this.paymentMethod &&
          other.installments == this.installments &&
          other.isFixed == this.isFixed &&
          other.storeDescription == this.storeDescription &&
          other.createdAt == this.createdAt);
}

class ExpensesCompanion extends UpdateCompanion<Expense> {
  final Value<int> id;
  final Value<int> month;
  final Value<int> year;
  final Value<String> payType;
  final Value<String> category;
  final Value<String?> subcategory;
  final Value<double> amount;
  final Value<String> paymentMethod;
  final Value<int> installments;
  final Value<bool> isFixed;
  final Value<String?> storeDescription;
  final Value<DateTime> createdAt;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.month = const Value.absent(),
    this.year = const Value.absent(),
    this.payType = const Value.absent(),
    this.category = const Value.absent(),
    this.subcategory = const Value.absent(),
    this.amount = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.installments = const Value.absent(),
    this.isFixed = const Value.absent(),
    this.storeDescription = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ExpensesCompanion.insert({
    this.id = const Value.absent(),
    required int month,
    required int year,
    required String payType,
    required String category,
    this.subcategory = const Value.absent(),
    required double amount,
    required String paymentMethod,
    this.installments = const Value.absent(),
    this.isFixed = const Value.absent(),
    this.storeDescription = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : month = Value(month),
        year = Value(year),
        payType = Value(payType),
        category = Value(category),
        amount = Value(amount),
        paymentMethod = Value(paymentMethod);
  static Insertable<Expense> custom({
    Expression<int>? id,
    Expression<int>? month,
    Expression<int>? year,
    Expression<String>? payType,
    Expression<String>? category,
    Expression<String>? subcategory,
    Expression<double>? amount,
    Expression<String>? paymentMethod,
    Expression<int>? installments,
    Expression<bool>? isFixed,
    Expression<String>? storeDescription,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (month != null) 'month': month,
      if (year != null) 'year': year,
      if (payType != null) 'pay_type': payType,
      if (category != null) 'category': category,
      if (subcategory != null) 'subcategory': subcategory,
      if (amount != null) 'amount': amount,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (installments != null) 'installments': installments,
      if (isFixed != null) 'is_fixed': isFixed,
      if (storeDescription != null) 'store_description': storeDescription,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ExpensesCompanion copyWith(
      {Value<int>? id,
      Value<int>? month,
      Value<int>? year,
      Value<String>? payType,
      Value<String>? category,
      Value<String?>? subcategory,
      Value<double>? amount,
      Value<String>? paymentMethod,
      Value<int>? installments,
      Value<bool>? isFixed,
      Value<String?>? storeDescription,
      Value<DateTime>? createdAt}) {
    return ExpensesCompanion(
      id: id ?? this.id,
      month: month ?? this.month,
      year: year ?? this.year,
      payType: payType ?? this.payType,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      installments: installments ?? this.installments,
      isFixed: isFixed ?? this.isFixed,
      storeDescription: storeDescription ?? this.storeDescription,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (payType.present) {
      map['pay_type'] = Variable<String>(payType.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (subcategory.present) {
      map['subcategory'] = Variable<String>(subcategory.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (installments.present) {
      map['installments'] = Variable<int>(installments.value);
    }
    if (isFixed.present) {
      map['is_fixed'] = Variable<bool>(isFixed.value);
    }
    if (storeDescription.present) {
      map['store_description'] = Variable<String>(storeDescription.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('month: $month, ')
          ..write('year: $year, ')
          ..write('payType: $payType, ')
          ..write('category: $category, ')
          ..write('subcategory: $subcategory, ')
          ..write('amount: $amount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('installments: $installments, ')
          ..write('isFixed: $isFixed, ')
          ..write('storeDescription: $storeDescription, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CardInstallmentsTable extends CardInstallments
    with TableInfo<$CardInstallmentsTable, CardInstallment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardInstallmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _purchaseDateMeta =
      const VerificationMeta('purchaseDate');
  @override
  late final GeneratedColumn<DateTime> purchaseDate = GeneratedColumn<DateTime>(
      'purchase_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _totalValueMeta =
      const VerificationMeta('totalValue');
  @override
  late final GeneratedColumn<double> totalValue = GeneratedColumn<double>(
      'total_value', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _numInstallmentsMeta =
      const VerificationMeta('numInstallments');
  @override
  late final GeneratedColumn<int> numInstallments = GeneratedColumn<int>(
      'num_installments', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _currentInstallmentMeta =
      const VerificationMeta('currentInstallment');
  @override
  late final GeneratedColumn<int> currentInstallment = GeneratedColumn<int>(
      'current_installment', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _monthlyAmountMeta =
      const VerificationMeta('monthlyAmount');
  @override
  late final GeneratedColumn<double> monthlyAmount = GeneratedColumn<double>(
      'monthly_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Active'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        description,
        purchaseDate,
        totalValue,
        numInstallments,
        currentInstallment,
        monthlyAmount,
        status,
        notes,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'card_installments';
  @override
  VerificationContext validateIntegrity(Insertable<CardInstallment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
          _purchaseDateMeta,
          purchaseDate.isAcceptableOrUnknown(
              data['purchase_date']!, _purchaseDateMeta));
    } else if (isInserting) {
      context.missing(_purchaseDateMeta);
    }
    if (data.containsKey('total_value')) {
      context.handle(
          _totalValueMeta,
          totalValue.isAcceptableOrUnknown(
              data['total_value']!, _totalValueMeta));
    } else if (isInserting) {
      context.missing(_totalValueMeta);
    }
    if (data.containsKey('num_installments')) {
      context.handle(
          _numInstallmentsMeta,
          numInstallments.isAcceptableOrUnknown(
              data['num_installments']!, _numInstallmentsMeta));
    } else if (isInserting) {
      context.missing(_numInstallmentsMeta);
    }
    if (data.containsKey('current_installment')) {
      context.handle(
          _currentInstallmentMeta,
          currentInstallment.isAcceptableOrUnknown(
              data['current_installment']!, _currentInstallmentMeta));
    } else if (isInserting) {
      context.missing(_currentInstallmentMeta);
    }
    if (data.containsKey('monthly_amount')) {
      context.handle(
          _monthlyAmountMeta,
          monthlyAmount.isAcceptableOrUnknown(
              data['monthly_amount']!, _monthlyAmountMeta));
    } else if (isInserting) {
      context.missing(_monthlyAmountMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardInstallment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardInstallment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      purchaseDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}purchase_date'])!,
      totalValue: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_value'])!,
      numInstallments: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}num_installments'])!,
      currentInstallment: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}current_installment'])!,
      monthlyAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}monthly_amount'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $CardInstallmentsTable createAlias(String alias) {
    return $CardInstallmentsTable(attachedDatabase, alias);
  }
}

class CardInstallment extends DataClass implements Insertable<CardInstallment> {
  final int id;
  final String description;
  final DateTime purchaseDate;
  final double totalValue;
  final int numInstallments;
  final int currentInstallment;
  final double monthlyAmount;
  final String status;
  final String? notes;
  final DateTime createdAt;
  const CardInstallment(
      {required this.id,
      required this.description,
      required this.purchaseDate,
      required this.totalValue,
      required this.numInstallments,
      required this.currentInstallment,
      required this.monthlyAmount,
      required this.status,
      this.notes,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['description'] = Variable<String>(description);
    map['purchase_date'] = Variable<DateTime>(purchaseDate);
    map['total_value'] = Variable<double>(totalValue);
    map['num_installments'] = Variable<int>(numInstallments);
    map['current_installment'] = Variable<int>(currentInstallment);
    map['monthly_amount'] = Variable<double>(monthlyAmount);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CardInstallmentsCompanion toCompanion(bool nullToAbsent) {
    return CardInstallmentsCompanion(
      id: Value(id),
      description: Value(description),
      purchaseDate: Value(purchaseDate),
      totalValue: Value(totalValue),
      numInstallments: Value(numInstallments),
      currentInstallment: Value(currentInstallment),
      monthlyAmount: Value(monthlyAmount),
      status: Value(status),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory CardInstallment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardInstallment(
      id: serializer.fromJson<int>(json['id']),
      description: serializer.fromJson<String>(json['description']),
      purchaseDate: serializer.fromJson<DateTime>(json['purchaseDate']),
      totalValue: serializer.fromJson<double>(json['totalValue']),
      numInstallments: serializer.fromJson<int>(json['numInstallments']),
      currentInstallment: serializer.fromJson<int>(json['currentInstallment']),
      monthlyAmount: serializer.fromJson<double>(json['monthlyAmount']),
      status: serializer.fromJson<String>(json['status']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'description': serializer.toJson<String>(description),
      'purchaseDate': serializer.toJson<DateTime>(purchaseDate),
      'totalValue': serializer.toJson<double>(totalValue),
      'numInstallments': serializer.toJson<int>(numInstallments),
      'currentInstallment': serializer.toJson<int>(currentInstallment),
      'monthlyAmount': serializer.toJson<double>(monthlyAmount),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CardInstallment copyWith(
          {int? id,
          String? description,
          DateTime? purchaseDate,
          double? totalValue,
          int? numInstallments,
          int? currentInstallment,
          double? monthlyAmount,
          String? status,
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt}) =>
      CardInstallment(
        id: id ?? this.id,
        description: description ?? this.description,
        purchaseDate: purchaseDate ?? this.purchaseDate,
        totalValue: totalValue ?? this.totalValue,
        numInstallments: numInstallments ?? this.numInstallments,
        currentInstallment: currentInstallment ?? this.currentInstallment,
        monthlyAmount: monthlyAmount ?? this.monthlyAmount,
        status: status ?? this.status,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('CardInstallment(')
          ..write('id: $id, ')
          ..write('description: $description, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('totalValue: $totalValue, ')
          ..write('numInstallments: $numInstallments, ')
          ..write('currentInstallment: $currentInstallment, ')
          ..write('monthlyAmount: $monthlyAmount, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      description,
      purchaseDate,
      totalValue,
      numInstallments,
      currentInstallment,
      monthlyAmount,
      status,
      notes,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardInstallment &&
          other.id == this.id &&
          other.description == this.description &&
          other.purchaseDate == this.purchaseDate &&
          other.totalValue == this.totalValue &&
          other.numInstallments == this.numInstallments &&
          other.currentInstallment == this.currentInstallment &&
          other.monthlyAmount == this.monthlyAmount &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class CardInstallmentsCompanion extends UpdateCompanion<CardInstallment> {
  final Value<int> id;
  final Value<String> description;
  final Value<DateTime> purchaseDate;
  final Value<double> totalValue;
  final Value<int> numInstallments;
  final Value<int> currentInstallment;
  final Value<double> monthlyAmount;
  final Value<String> status;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const CardInstallmentsCompanion({
    this.id = const Value.absent(),
    this.description = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.totalValue = const Value.absent(),
    this.numInstallments = const Value.absent(),
    this.currentInstallment = const Value.absent(),
    this.monthlyAmount = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CardInstallmentsCompanion.insert({
    this.id = const Value.absent(),
    required String description,
    required DateTime purchaseDate,
    required double totalValue,
    required int numInstallments,
    required int currentInstallment,
    required double monthlyAmount,
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : description = Value(description),
        purchaseDate = Value(purchaseDate),
        totalValue = Value(totalValue),
        numInstallments = Value(numInstallments),
        currentInstallment = Value(currentInstallment),
        monthlyAmount = Value(monthlyAmount);
  static Insertable<CardInstallment> custom({
    Expression<int>? id,
    Expression<String>? description,
    Expression<DateTime>? purchaseDate,
    Expression<double>? totalValue,
    Expression<int>? numInstallments,
    Expression<int>? currentInstallment,
    Expression<double>? monthlyAmount,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (description != null) 'description': description,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (totalValue != null) 'total_value': totalValue,
      if (numInstallments != null) 'num_installments': numInstallments,
      if (currentInstallment != null) 'current_installment': currentInstallment,
      if (monthlyAmount != null) 'monthly_amount': monthlyAmount,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CardInstallmentsCompanion copyWith(
      {Value<int>? id,
      Value<String>? description,
      Value<DateTime>? purchaseDate,
      Value<double>? totalValue,
      Value<int>? numInstallments,
      Value<int>? currentInstallment,
      Value<double>? monthlyAmount,
      Value<String>? status,
      Value<String?>? notes,
      Value<DateTime>? createdAt}) {
    return CardInstallmentsCompanion(
      id: id ?? this.id,
      description: description ?? this.description,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      totalValue: totalValue ?? this.totalValue,
      numInstallments: numInstallments ?? this.numInstallments,
      currentInstallment: currentInstallment ?? this.currentInstallment,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<DateTime>(purchaseDate.value);
    }
    if (totalValue.present) {
      map['total_value'] = Variable<double>(totalValue.value);
    }
    if (numInstallments.present) {
      map['num_installments'] = Variable<int>(numInstallments.value);
    }
    if (currentInstallment.present) {
      map['current_installment'] = Variable<int>(currentInstallment.value);
    }
    if (monthlyAmount.present) {
      map['monthly_amount'] = Variable<double>(monthlyAmount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardInstallmentsCompanion(')
          ..write('id: $id, ')
          ..write('description: $description, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('totalValue: $totalValue, ')
          ..write('numInstallments: $numInstallments, ')
          ..write('currentInstallment: $currentInstallment, ')
          ..write('monthlyAmount: $monthlyAmount, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $InvestmentsTable extends Investments
    with TableInfo<$InvestmentsTable, Investment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvestmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productNameMeta =
      const VerificationMeta('productName');
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
      'product_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _institutionMeta =
      const VerificationMeta('institution');
  @override
  late final GeneratedColumn<String> institution = GeneratedColumn<String>(
      'institution', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateAddedMeta =
      const VerificationMeta('dateAdded');
  @override
  late final GeneratedColumn<DateTime> dateAdded = GeneratedColumn<DateTime>(
      'date_added', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _totalInvestedMeta =
      const VerificationMeta('totalInvested');
  @override
  late final GeneratedColumn<double> totalInvested = GeneratedColumn<double>(
      'total_invested', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currentBalanceMeta =
      const VerificationMeta('currentBalance');
  @override
  late final GeneratedColumn<double> currentBalance = GeneratedColumn<double>(
      'current_balance', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _returnAmountMeta =
      const VerificationMeta('returnAmount');
  @override
  late final GeneratedColumn<double> returnAmount = GeneratedColumn<double>(
      'return_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _liquidityMeta =
      const VerificationMeta('liquidity');
  @override
  late final GeneratedColumn<String> liquidity = GeneratedColumn<String>(
      'liquidity', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        type,
        productName,
        institution,
        dateAdded,
        totalInvested,
        currentBalance,
        returnAmount,
        liquidity,
        notes,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'investments';
  @override
  VerificationContext validateIntegrity(Insertable<Investment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
          _productNameMeta,
          productName.isAcceptableOrUnknown(
              data['product_name']!, _productNameMeta));
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('institution')) {
      context.handle(
          _institutionMeta,
          institution.isAcceptableOrUnknown(
              data['institution']!, _institutionMeta));
    } else if (isInserting) {
      context.missing(_institutionMeta);
    }
    if (data.containsKey('date_added')) {
      context.handle(_dateAddedMeta,
          dateAdded.isAcceptableOrUnknown(data['date_added']!, _dateAddedMeta));
    } else if (isInserting) {
      context.missing(_dateAddedMeta);
    }
    if (data.containsKey('total_invested')) {
      context.handle(
          _totalInvestedMeta,
          totalInvested.isAcceptableOrUnknown(
              data['total_invested']!, _totalInvestedMeta));
    } else if (isInserting) {
      context.missing(_totalInvestedMeta);
    }
    if (data.containsKey('current_balance')) {
      context.handle(
          _currentBalanceMeta,
          currentBalance.isAcceptableOrUnknown(
              data['current_balance']!, _currentBalanceMeta));
    } else if (isInserting) {
      context.missing(_currentBalanceMeta);
    }
    if (data.containsKey('return_amount')) {
      context.handle(
          _returnAmountMeta,
          returnAmount.isAcceptableOrUnknown(
              data['return_amount']!, _returnAmountMeta));
    }
    if (data.containsKey('liquidity')) {
      context.handle(_liquidityMeta,
          liquidity.isAcceptableOrUnknown(data['liquidity']!, _liquidityMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Investment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Investment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      productName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_name'])!,
      institution: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}institution'])!,
      dateAdded: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date_added'])!,
      totalInvested: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_invested'])!,
      currentBalance: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}current_balance'])!,
      returnAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}return_amount'])!,
      liquidity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}liquidity']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $InvestmentsTable createAlias(String alias) {
    return $InvestmentsTable(attachedDatabase, alias);
  }
}

class Investment extends DataClass implements Insertable<Investment> {
  final int id;
  final String type;
  final String productName;
  final String institution;
  final DateTime dateAdded;
  final double totalInvested;
  final double currentBalance;
  final double returnAmount;
  final String? liquidity;
  final String? notes;
  final DateTime createdAt;
  const Investment(
      {required this.id,
      required this.type,
      required this.productName,
      required this.institution,
      required this.dateAdded,
      required this.totalInvested,
      required this.currentBalance,
      required this.returnAmount,
      this.liquidity,
      this.notes,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['product_name'] = Variable<String>(productName);
    map['institution'] = Variable<String>(institution);
    map['date_added'] = Variable<DateTime>(dateAdded);
    map['total_invested'] = Variable<double>(totalInvested);
    map['current_balance'] = Variable<double>(currentBalance);
    map['return_amount'] = Variable<double>(returnAmount);
    if (!nullToAbsent || liquidity != null) {
      map['liquidity'] = Variable<String>(liquidity);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  InvestmentsCompanion toCompanion(bool nullToAbsent) {
    return InvestmentsCompanion(
      id: Value(id),
      type: Value(type),
      productName: Value(productName),
      institution: Value(institution),
      dateAdded: Value(dateAdded),
      totalInvested: Value(totalInvested),
      currentBalance: Value(currentBalance),
      returnAmount: Value(returnAmount),
      liquidity: liquidity == null && nullToAbsent
          ? const Value.absent()
          : Value(liquidity),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory Investment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Investment(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      productName: serializer.fromJson<String>(json['productName']),
      institution: serializer.fromJson<String>(json['institution']),
      dateAdded: serializer.fromJson<DateTime>(json['dateAdded']),
      totalInvested: serializer.fromJson<double>(json['totalInvested']),
      currentBalance: serializer.fromJson<double>(json['currentBalance']),
      returnAmount: serializer.fromJson<double>(json['returnAmount']),
      liquidity: serializer.fromJson<String?>(json['liquidity']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'productName': serializer.toJson<String>(productName),
      'institution': serializer.toJson<String>(institution),
      'dateAdded': serializer.toJson<DateTime>(dateAdded),
      'totalInvested': serializer.toJson<double>(totalInvested),
      'currentBalance': serializer.toJson<double>(currentBalance),
      'returnAmount': serializer.toJson<double>(returnAmount),
      'liquidity': serializer.toJson<String?>(liquidity),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Investment copyWith(
          {int? id,
          String? type,
          String? productName,
          String? institution,
          DateTime? dateAdded,
          double? totalInvested,
          double? currentBalance,
          double? returnAmount,
          Value<String?> liquidity = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt}) =>
      Investment(
        id: id ?? this.id,
        type: type ?? this.type,
        productName: productName ?? this.productName,
        institution: institution ?? this.institution,
        dateAdded: dateAdded ?? this.dateAdded,
        totalInvested: totalInvested ?? this.totalInvested,
        currentBalance: currentBalance ?? this.currentBalance,
        returnAmount: returnAmount ?? this.returnAmount,
        liquidity: liquidity.present ? liquidity.value : this.liquidity,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('Investment(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('productName: $productName, ')
          ..write('institution: $institution, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('totalInvested: $totalInvested, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('returnAmount: $returnAmount, ')
          ..write('liquidity: $liquidity, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, type, productName, institution, dateAdded,
      totalInvested, currentBalance, returnAmount, liquidity, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Investment &&
          other.id == this.id &&
          other.type == this.type &&
          other.productName == this.productName &&
          other.institution == this.institution &&
          other.dateAdded == this.dateAdded &&
          other.totalInvested == this.totalInvested &&
          other.currentBalance == this.currentBalance &&
          other.returnAmount == this.returnAmount &&
          other.liquidity == this.liquidity &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class InvestmentsCompanion extends UpdateCompanion<Investment> {
  final Value<int> id;
  final Value<String> type;
  final Value<String> productName;
  final Value<String> institution;
  final Value<DateTime> dateAdded;
  final Value<double> totalInvested;
  final Value<double> currentBalance;
  final Value<double> returnAmount;
  final Value<String?> liquidity;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const InvestmentsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.productName = const Value.absent(),
    this.institution = const Value.absent(),
    this.dateAdded = const Value.absent(),
    this.totalInvested = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.returnAmount = const Value.absent(),
    this.liquidity = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  InvestmentsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required String productName,
    required String institution,
    required DateTime dateAdded,
    required double totalInvested,
    required double currentBalance,
    this.returnAmount = const Value.absent(),
    this.liquidity = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : type = Value(type),
        productName = Value(productName),
        institution = Value(institution),
        dateAdded = Value(dateAdded),
        totalInvested = Value(totalInvested),
        currentBalance = Value(currentBalance);
  static Insertable<Investment> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? productName,
    Expression<String>? institution,
    Expression<DateTime>? dateAdded,
    Expression<double>? totalInvested,
    Expression<double>? currentBalance,
    Expression<double>? returnAmount,
    Expression<String>? liquidity,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (productName != null) 'product_name': productName,
      if (institution != null) 'institution': institution,
      if (dateAdded != null) 'date_added': dateAdded,
      if (totalInvested != null) 'total_invested': totalInvested,
      if (currentBalance != null) 'current_balance': currentBalance,
      if (returnAmount != null) 'return_amount': returnAmount,
      if (liquidity != null) 'liquidity': liquidity,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  InvestmentsCompanion copyWith(
      {Value<int>? id,
      Value<String>? type,
      Value<String>? productName,
      Value<String>? institution,
      Value<DateTime>? dateAdded,
      Value<double>? totalInvested,
      Value<double>? currentBalance,
      Value<double>? returnAmount,
      Value<String?>? liquidity,
      Value<String?>? notes,
      Value<DateTime>? createdAt}) {
    return InvestmentsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      productName: productName ?? this.productName,
      institution: institution ?? this.institution,
      dateAdded: dateAdded ?? this.dateAdded,
      totalInvested: totalInvested ?? this.totalInvested,
      currentBalance: currentBalance ?? this.currentBalance,
      returnAmount: returnAmount ?? this.returnAmount,
      liquidity: liquidity ?? this.liquidity,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (institution.present) {
      map['institution'] = Variable<String>(institution.value);
    }
    if (dateAdded.present) {
      map['date_added'] = Variable<DateTime>(dateAdded.value);
    }
    if (totalInvested.present) {
      map['total_invested'] = Variable<double>(totalInvested.value);
    }
    if (currentBalance.present) {
      map['current_balance'] = Variable<double>(currentBalance.value);
    }
    if (returnAmount.present) {
      map['return_amount'] = Variable<double>(returnAmount.value);
    }
    if (liquidity.present) {
      map['liquidity'] = Variable<String>(liquidity.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvestmentsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('productName: $productName, ')
          ..write('institution: $institution, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('totalInvested: $totalInvested, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('returnAmount: $returnAmount, ')
          ..write('liquidity: $liquidity, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $NetWorthSnapshotsTable extends NetWorthSnapshots
    with TableInfo<$NetWorthSnapshotsTable, NetWorthSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NetWorthSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
      'month', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
      'year', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _fgtsBalanceMeta =
      const VerificationMeta('fgtsBalance');
  @override
  late final GeneratedColumn<double> fgtsBalance = GeneratedColumn<double>(
      'fgts_balance', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _investmentsTotalMeta =
      const VerificationMeta('investmentsTotal');
  @override
  late final GeneratedColumn<double> investmentsTotal = GeneratedColumn<double>(
      'investments_total', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _emergencyFundMeta =
      const VerificationMeta('emergencyFund');
  @override
  late final GeneratedColumn<double> emergencyFund = GeneratedColumn<double>(
      'emergency_fund', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _pendingInstallmentsMeta =
      const VerificationMeta('pendingInstallments');
  @override
  late final GeneratedColumn<double> pendingInstallments =
      GeneratedColumn<double>('pending_installments', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0.0));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        month,
        year,
        fgtsBalance,
        investmentsTotal,
        emergencyFund,
        pendingInstallments,
        notes,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'net_worth_snapshots';
  @override
  VerificationContext validateIntegrity(Insertable<NetWorthSnapshot> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('month')) {
      context.handle(
          _monthMeta, month.isAcceptableOrUnknown(data['month']!, _monthMeta));
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
          _yearMeta, year.isAcceptableOrUnknown(data['year']!, _yearMeta));
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('fgts_balance')) {
      context.handle(
          _fgtsBalanceMeta,
          fgtsBalance.isAcceptableOrUnknown(
              data['fgts_balance']!, _fgtsBalanceMeta));
    }
    if (data.containsKey('investments_total')) {
      context.handle(
          _investmentsTotalMeta,
          investmentsTotal.isAcceptableOrUnknown(
              data['investments_total']!, _investmentsTotalMeta));
    }
    if (data.containsKey('emergency_fund')) {
      context.handle(
          _emergencyFundMeta,
          emergencyFund.isAcceptableOrUnknown(
              data['emergency_fund']!, _emergencyFundMeta));
    }
    if (data.containsKey('pending_installments')) {
      context.handle(
          _pendingInstallmentsMeta,
          pendingInstallments.isAcceptableOrUnknown(
              data['pending_installments']!, _pendingInstallmentsMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NetWorthSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NetWorthSnapshot(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      month: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}month'])!,
      year: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}year'])!,
      fgtsBalance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fgts_balance'])!,
      investmentsTotal: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}investments_total'])!,
      emergencyFund: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}emergency_fund'])!,
      pendingInstallments: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}pending_installments'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $NetWorthSnapshotsTable createAlias(String alias) {
    return $NetWorthSnapshotsTable(attachedDatabase, alias);
  }
}

class NetWorthSnapshot extends DataClass
    implements Insertable<NetWorthSnapshot> {
  final int id;
  final int month;
  final int year;
  final double fgtsBalance;
  final double investmentsTotal;
  final double emergencyFund;
  final double pendingInstallments;
  final String? notes;
  final DateTime createdAt;
  const NetWorthSnapshot(
      {required this.id,
      required this.month,
      required this.year,
      required this.fgtsBalance,
      required this.investmentsTotal,
      required this.emergencyFund,
      required this.pendingInstallments,
      this.notes,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['month'] = Variable<int>(month);
    map['year'] = Variable<int>(year);
    map['fgts_balance'] = Variable<double>(fgtsBalance);
    map['investments_total'] = Variable<double>(investmentsTotal);
    map['emergency_fund'] = Variable<double>(emergencyFund);
    map['pending_installments'] = Variable<double>(pendingInstallments);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  NetWorthSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return NetWorthSnapshotsCompanion(
      id: Value(id),
      month: Value(month),
      year: Value(year),
      fgtsBalance: Value(fgtsBalance),
      investmentsTotal: Value(investmentsTotal),
      emergencyFund: Value(emergencyFund),
      pendingInstallments: Value(pendingInstallments),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory NetWorthSnapshot.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NetWorthSnapshot(
      id: serializer.fromJson<int>(json['id']),
      month: serializer.fromJson<int>(json['month']),
      year: serializer.fromJson<int>(json['year']),
      fgtsBalance: serializer.fromJson<double>(json['fgtsBalance']),
      investmentsTotal: serializer.fromJson<double>(json['investmentsTotal']),
      emergencyFund: serializer.fromJson<double>(json['emergencyFund']),
      pendingInstallments:
          serializer.fromJson<double>(json['pendingInstallments']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'month': serializer.toJson<int>(month),
      'year': serializer.toJson<int>(year),
      'fgtsBalance': serializer.toJson<double>(fgtsBalance),
      'investmentsTotal': serializer.toJson<double>(investmentsTotal),
      'emergencyFund': serializer.toJson<double>(emergencyFund),
      'pendingInstallments': serializer.toJson<double>(pendingInstallments),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  NetWorthSnapshot copyWith(
          {int? id,
          int? month,
          int? year,
          double? fgtsBalance,
          double? investmentsTotal,
          double? emergencyFund,
          double? pendingInstallments,
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt}) =>
      NetWorthSnapshot(
        id: id ?? this.id,
        month: month ?? this.month,
        year: year ?? this.year,
        fgtsBalance: fgtsBalance ?? this.fgtsBalance,
        investmentsTotal: investmentsTotal ?? this.investmentsTotal,
        emergencyFund: emergencyFund ?? this.emergencyFund,
        pendingInstallments: pendingInstallments ?? this.pendingInstallments,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('NetWorthSnapshot(')
          ..write('id: $id, ')
          ..write('month: $month, ')
          ..write('year: $year, ')
          ..write('fgtsBalance: $fgtsBalance, ')
          ..write('investmentsTotal: $investmentsTotal, ')
          ..write('emergencyFund: $emergencyFund, ')
          ..write('pendingInstallments: $pendingInstallments, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, month, year, fgtsBalance,
      investmentsTotal, emergencyFund, pendingInstallments, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NetWorthSnapshot &&
          other.id == this.id &&
          other.month == this.month &&
          other.year == this.year &&
          other.fgtsBalance == this.fgtsBalance &&
          other.investmentsTotal == this.investmentsTotal &&
          other.emergencyFund == this.emergencyFund &&
          other.pendingInstallments == this.pendingInstallments &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class NetWorthSnapshotsCompanion extends UpdateCompanion<NetWorthSnapshot> {
  final Value<int> id;
  final Value<int> month;
  final Value<int> year;
  final Value<double> fgtsBalance;
  final Value<double> investmentsTotal;
  final Value<double> emergencyFund;
  final Value<double> pendingInstallments;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const NetWorthSnapshotsCompanion({
    this.id = const Value.absent(),
    this.month = const Value.absent(),
    this.year = const Value.absent(),
    this.fgtsBalance = const Value.absent(),
    this.investmentsTotal = const Value.absent(),
    this.emergencyFund = const Value.absent(),
    this.pendingInstallments = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  NetWorthSnapshotsCompanion.insert({
    this.id = const Value.absent(),
    required int month,
    required int year,
    this.fgtsBalance = const Value.absent(),
    this.investmentsTotal = const Value.absent(),
    this.emergencyFund = const Value.absent(),
    this.pendingInstallments = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : month = Value(month),
        year = Value(year);
  static Insertable<NetWorthSnapshot> custom({
    Expression<int>? id,
    Expression<int>? month,
    Expression<int>? year,
    Expression<double>? fgtsBalance,
    Expression<double>? investmentsTotal,
    Expression<double>? emergencyFund,
    Expression<double>? pendingInstallments,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (month != null) 'month': month,
      if (year != null) 'year': year,
      if (fgtsBalance != null) 'fgts_balance': fgtsBalance,
      if (investmentsTotal != null) 'investments_total': investmentsTotal,
      if (emergencyFund != null) 'emergency_fund': emergencyFund,
      if (pendingInstallments != null)
        'pending_installments': pendingInstallments,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  NetWorthSnapshotsCompanion copyWith(
      {Value<int>? id,
      Value<int>? month,
      Value<int>? year,
      Value<double>? fgtsBalance,
      Value<double>? investmentsTotal,
      Value<double>? emergencyFund,
      Value<double>? pendingInstallments,
      Value<String?>? notes,
      Value<DateTime>? createdAt}) {
    return NetWorthSnapshotsCompanion(
      id: id ?? this.id,
      month: month ?? this.month,
      year: year ?? this.year,
      fgtsBalance: fgtsBalance ?? this.fgtsBalance,
      investmentsTotal: investmentsTotal ?? this.investmentsTotal,
      emergencyFund: emergencyFund ?? this.emergencyFund,
      pendingInstallments: pendingInstallments ?? this.pendingInstallments,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (fgtsBalance.present) {
      map['fgts_balance'] = Variable<double>(fgtsBalance.value);
    }
    if (investmentsTotal.present) {
      map['investments_total'] = Variable<double>(investmentsTotal.value);
    }
    if (emergencyFund.present) {
      map['emergency_fund'] = Variable<double>(emergencyFund.value);
    }
    if (pendingInstallments.present) {
      map['pending_installments'] = Variable<double>(pendingInstallments.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NetWorthSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('month: $month, ')
          ..write('year: $year, ')
          ..write('fgtsBalance: $fgtsBalance, ')
          ..write('investmentsTotal: $investmentsTotal, ')
          ..write('emergencyFund: $emergencyFund, ')
          ..write('pendingInstallments: $pendingInstallments, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BudgetGoalsTable extends BudgetGoals
    with TableInfo<$BudgetGoalsTable, BudgetGoal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetGoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetPercentageMeta =
      const VerificationMeta('targetPercentage');
  @override
  late final GeneratedColumn<double> targetPercentage = GeneratedColumn<double>(
      'target_percentage', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _targetAmountMeta =
      const VerificationMeta('targetAmount');
  @override
  late final GeneratedColumn<double> targetAmount = GeneratedColumn<double>(
      'target_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, category, targetPercentage, targetAmount, type, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_goals';
  @override
  VerificationContext validateIntegrity(Insertable<BudgetGoal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('target_percentage')) {
      context.handle(
          _targetPercentageMeta,
          targetPercentage.isAcceptableOrUnknown(
              data['target_percentage']!, _targetPercentageMeta));
    } else if (isInserting) {
      context.missing(_targetPercentageMeta);
    }
    if (data.containsKey('target_amount')) {
      context.handle(
          _targetAmountMeta,
          targetAmount.isAcceptableOrUnknown(
              data['target_amount']!, _targetAmountMeta));
    } else if (isInserting) {
      context.missing(_targetAmountMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetGoal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetGoal(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      targetPercentage: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}target_percentage'])!,
      targetAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}target_amount'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $BudgetGoalsTable createAlias(String alias) {
    return $BudgetGoalsTable(attachedDatabase, alias);
  }
}

class BudgetGoal extends DataClass implements Insertable<BudgetGoal> {
  final int id;
  final String category;
  final double targetPercentage;
  final double targetAmount;
  final String type;
  final DateTime createdAt;
  const BudgetGoal(
      {required this.id,
      required this.category,
      required this.targetPercentage,
      required this.targetAmount,
      required this.type,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category'] = Variable<String>(category);
    map['target_percentage'] = Variable<double>(targetPercentage);
    map['target_amount'] = Variable<double>(targetAmount);
    map['type'] = Variable<String>(type);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BudgetGoalsCompanion toCompanion(bool nullToAbsent) {
    return BudgetGoalsCompanion(
      id: Value(id),
      category: Value(category),
      targetPercentage: Value(targetPercentage),
      targetAmount: Value(targetAmount),
      type: Value(type),
      createdAt: Value(createdAt),
    );
  }

  factory BudgetGoal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetGoal(
      id: serializer.fromJson<int>(json['id']),
      category: serializer.fromJson<String>(json['category']),
      targetPercentage: serializer.fromJson<double>(json['targetPercentage']),
      targetAmount: serializer.fromJson<double>(json['targetAmount']),
      type: serializer.fromJson<String>(json['type']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'category': serializer.toJson<String>(category),
      'targetPercentage': serializer.toJson<double>(targetPercentage),
      'targetAmount': serializer.toJson<double>(targetAmount),
      'type': serializer.toJson<String>(type),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BudgetGoal copyWith(
          {int? id,
          String? category,
          double? targetPercentage,
          double? targetAmount,
          String? type,
          DateTime? createdAt}) =>
      BudgetGoal(
        id: id ?? this.id,
        category: category ?? this.category,
        targetPercentage: targetPercentage ?? this.targetPercentage,
        targetAmount: targetAmount ?? this.targetAmount,
        type: type ?? this.type,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('BudgetGoal(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('targetPercentage: $targetPercentage, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, category, targetPercentage, targetAmount, type, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetGoal &&
          other.id == this.id &&
          other.category == this.category &&
          other.targetPercentage == this.targetPercentage &&
          other.targetAmount == this.targetAmount &&
          other.type == this.type &&
          other.createdAt == this.createdAt);
}

class BudgetGoalsCompanion extends UpdateCompanion<BudgetGoal> {
  final Value<int> id;
  final Value<String> category;
  final Value<double> targetPercentage;
  final Value<double> targetAmount;
  final Value<String> type;
  final Value<DateTime> createdAt;
  const BudgetGoalsCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.targetPercentage = const Value.absent(),
    this.targetAmount = const Value.absent(),
    this.type = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BudgetGoalsCompanion.insert({
    this.id = const Value.absent(),
    required String category,
    required double targetPercentage,
    required double targetAmount,
    required String type,
    this.createdAt = const Value.absent(),
  })  : category = Value(category),
        targetPercentage = Value(targetPercentage),
        targetAmount = Value(targetAmount),
        type = Value(type);
  static Insertable<BudgetGoal> custom({
    Expression<int>? id,
    Expression<String>? category,
    Expression<double>? targetPercentage,
    Expression<double>? targetAmount,
    Expression<String>? type,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (targetPercentage != null) 'target_percentage': targetPercentage,
      if (targetAmount != null) 'target_amount': targetAmount,
      if (type != null) 'type': type,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BudgetGoalsCompanion copyWith(
      {Value<int>? id,
      Value<String>? category,
      Value<double>? targetPercentage,
      Value<double>? targetAmount,
      Value<String>? type,
      Value<DateTime>? createdAt}) {
    return BudgetGoalsCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      targetPercentage: targetPercentage ?? this.targetPercentage,
      targetAmount: targetAmount ?? this.targetAmount,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (targetPercentage.present) {
      map['target_percentage'] = Variable<double>(targetPercentage.value);
    }
    if (targetAmount.present) {
      map['target_amount'] = Variable<double>(targetAmount.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetGoalsCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('targetPercentage: $targetPercentage, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $UserSettingsTable extends UserSettings
    with TableInfo<$UserSettingsTable, UserSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_settings';
  @override
  VerificationContext validateIntegrity(Insertable<UserSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSetting(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $UserSettingsTable createAlias(String alias) {
    return $UserSettingsTable(attachedDatabase, alias);
  }
}

class UserSetting extends DataClass implements Insertable<UserSetting> {
  final int id;
  final String key;
  final String value;
  const UserSetting({required this.id, required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  UserSettingsCompanion toCompanion(bool nullToAbsent) {
    return UserSettingsCompanion(
      id: Value(id),
      key: Value(key),
      value: Value(value),
    );
  }

  factory UserSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSetting(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  UserSetting copyWith({int? id, String? key, String? value}) => UserSetting(
        id: id ?? this.id,
        key: key ?? this.key,
        value: value ?? this.value,
      );
  @override
  String toString() {
    return (StringBuffer('UserSetting(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSetting &&
          other.id == this.id &&
          other.key == this.key &&
          other.value == this.value);
}

class UserSettingsCompanion extends UpdateCompanion<UserSetting> {
  final Value<int> id;
  final Value<String> key;
  final Value<String> value;
  const UserSettingsCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
  });
  UserSettingsCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    required String value,
  })  : key = Value(key),
        value = Value(value);
  static Insertable<UserSetting> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? value,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
    });
  }

  UserSettingsCompanion copyWith(
      {Value<int>? id, Value<String>? key, Value<String>? value}) {
    return UserSettingsCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $IncomesTable incomes = $IncomesTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $CardInstallmentsTable cardInstallments =
      $CardInstallmentsTable(this);
  late final $InvestmentsTable investments = $InvestmentsTable(this);
  late final $NetWorthSnapshotsTable netWorthSnapshots =
      $NetWorthSnapshotsTable(this);
  late final $BudgetGoalsTable budgetGoals = $BudgetGoalsTable(this);
  late final $UserSettingsTable userSettings = $UserSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        incomes,
        expenses,
        cardInstallments,
        investments,
        netWorthSnapshots,
        budgetGoals,
        userSettings
      ];
}
