// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<Setting> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(_keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(key: serializer.fromJson<String>(json['key']), value: serializer.fromJson<String>(json['value']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'key': serializer.toJson<String>(key), 'value': serializer.toJson<String>(value)};
  }

  Setting copyWith({String? key, String? value}) => Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({required String key, required String value, this.rowid = const Value.absent()})
    : key = Value(key),
      value = Value(value);
  static Insertable<Setting> custom({Expression<String>? key, Expression<String>? value, Expression<int>? rowid}) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingsCompanion(key: key ?? this.key, value: value ?? this.value, rowid: rowid ?? this.rowid);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _openingBalanceMeta = const VerificationMeta('openingBalance');
  @override
  late final GeneratedColumn<int> openingBalance = GeneratedColumn<int>(
    'opening_balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, openingBalance, note, active];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(Insertable<Account> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('opening_balance')) {
      context.handle(
        _openingBalanceMeta,
        openingBalance.isAcceptableOrUnknown(data['opening_balance']!, _openingBalanceMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta, active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      openingBalance: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}opening_balance'])!,
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      active: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final int id;
  final String name;
  final int openingBalance;
  final String note;
  final bool active;
  const Account({
    required this.id,
    required this.name,
    required this.openingBalance,
    required this.note,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['opening_balance'] = Variable<int>(openingBalance);
    map['note'] = Variable<String>(note);
    map['active'] = Variable<bool>(active);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      openingBalance: Value(openingBalance),
      note: Value(note),
      active: Value(active),
    );
  }

  factory Account.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      openingBalance: serializer.fromJson<int>(json['openingBalance']),
      note: serializer.fromJson<String>(json['note']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'openingBalance': serializer.toJson<int>(openingBalance),
      'note': serializer.toJson<String>(note),
      'active': serializer.toJson<bool>(active),
    };
  }

  Account copyWith({int? id, String? name, int? openingBalance, String? note, bool? active}) => Account(
    id: id ?? this.id,
    name: name ?? this.name,
    openingBalance: openingBalance ?? this.openingBalance,
    note: note ?? this.note,
    active: active ?? this.active,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      openingBalance: data.openingBalance.present ? data.openingBalance.value : this.openingBalance,
      note: data.note.present ? data.note.value : this.note,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('note: $note, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, openingBalance, note, active);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.name == this.name &&
          other.openingBalance == this.openingBalance &&
          other.note == this.note &&
          other.active == this.active);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> openingBalance;
  final Value<String> note;
  final Value<bool> active;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.note = const Value.absent(),
    this.active = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.openingBalance = const Value.absent(),
    this.note = const Value.absent(),
    this.active = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Account> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? openingBalance,
    Expression<String>? note,
    Expression<bool>? active,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (openingBalance != null) 'opening_balance': openingBalance,
      if (note != null) 'note': note,
      if (active != null) 'active': active,
    });
  }

  AccountsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? openingBalance,
    Value<String>? note,
    Value<bool>? active,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      openingBalance: openingBalance ?? this.openingBalance,
      note: note ?? this.note,
      active: active ?? this.active,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (openingBalance.present) {
      map['opening_balance'] = Variable<int>(openingBalance.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('note: $note, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }
}

class $CashEntriesTable extends CashEntries with TableInfo<$CashEntriesTable, CashEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refIdMeta = const VerificationMeta('refId');
  @override
  late final GeneratedColumn<int> refId = GeneratedColumn<int>(
    'ref_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _proofPathMeta = const VerificationMeta('proofPath');
  @override
  late final GeneratedColumn<String> proofPath = GeneratedColumn<String>(
    'proof_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [id, at, accountId, amount, kind, refId, description, note, proofPath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cash_entries';
  @override
  VerificationContext validateIntegrity(Insertable<CashEntry> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta, accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta, amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(_kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('ref_id')) {
      context.handle(_refIdMeta, refId.isAcceptableOrUnknown(data['ref_id']!, _refIdMeta));
    }
    if (data.containsKey('description')) {
      context.handle(_descriptionMeta, description.isAcceptableOrUnknown(data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('proof_path')) {
      context.handle(_proofPathMeta, proofPath.isAcceptableOrUnknown(data['proof_path']!, _proofPathMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CashEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CashEntry(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      at: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}at'])!,
      accountId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}account_id'])!,
      amount: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      kind: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      refId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}ref_id']),
      description: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      proofPath: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}proof_path'])!,
    );
  }

  @override
  $CashEntriesTable createAlias(String alias) {
    return $CashEntriesTable(attachedDatabase, alias);
  }
}

class CashEntry extends DataClass implements Insertable<CashEntry> {
  final int id;
  final DateTime at;
  final int accountId;
  final int amount;
  final String kind;
  final int? refId;
  final String description;
  final String note;
  final String proofPath;
  const CashEntry({
    required this.id,
    required this.at,
    required this.accountId,
    required this.amount,
    required this.kind,
    this.refId,
    required this.description,
    required this.note,
    required this.proofPath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at'] = Variable<DateTime>(at);
    map['account_id'] = Variable<int>(accountId);
    map['amount'] = Variable<int>(amount);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || refId != null) {
      map['ref_id'] = Variable<int>(refId);
    }
    map['description'] = Variable<String>(description);
    map['note'] = Variable<String>(note);
    map['proof_path'] = Variable<String>(proofPath);
    return map;
  }

  CashEntriesCompanion toCompanion(bool nullToAbsent) {
    return CashEntriesCompanion(
      id: Value(id),
      at: Value(at),
      accountId: Value(accountId),
      amount: Value(amount),
      kind: Value(kind),
      refId: refId == null && nullToAbsent ? const Value.absent() : Value(refId),
      description: Value(description),
      note: Value(note),
      proofPath: Value(proofPath),
    );
  }

  factory CashEntry.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CashEntry(
      id: serializer.fromJson<int>(json['id']),
      at: serializer.fromJson<DateTime>(json['at']),
      accountId: serializer.fromJson<int>(json['accountId']),
      amount: serializer.fromJson<int>(json['amount']),
      kind: serializer.fromJson<String>(json['kind']),
      refId: serializer.fromJson<int?>(json['refId']),
      description: serializer.fromJson<String>(json['description']),
      note: serializer.fromJson<String>(json['note']),
      proofPath: serializer.fromJson<String>(json['proofPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'at': serializer.toJson<DateTime>(at),
      'accountId': serializer.toJson<int>(accountId),
      'amount': serializer.toJson<int>(amount),
      'kind': serializer.toJson<String>(kind),
      'refId': serializer.toJson<int?>(refId),
      'description': serializer.toJson<String>(description),
      'note': serializer.toJson<String>(note),
      'proofPath': serializer.toJson<String>(proofPath),
    };
  }

  CashEntry copyWith({
    int? id,
    DateTime? at,
    int? accountId,
    int? amount,
    String? kind,
    Value<int?> refId = const Value.absent(),
    String? description,
    String? note,
    String? proofPath,
  }) => CashEntry(
    id: id ?? this.id,
    at: at ?? this.at,
    accountId: accountId ?? this.accountId,
    amount: amount ?? this.amount,
    kind: kind ?? this.kind,
    refId: refId.present ? refId.value : this.refId,
    description: description ?? this.description,
    note: note ?? this.note,
    proofPath: proofPath ?? this.proofPath,
  );
  CashEntry copyWithCompanion(CashEntriesCompanion data) {
    return CashEntry(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      amount: data.amount.present ? data.amount.value : this.amount,
      kind: data.kind.present ? data.kind.value : this.kind,
      refId: data.refId.present ? data.refId.value : this.refId,
      description: data.description.present ? data.description.value : this.description,
      note: data.note.present ? data.note.value : this.note,
      proofPath: data.proofPath.present ? data.proofPath.value : this.proofPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CashEntry(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('accountId: $accountId, ')
          ..write('amount: $amount, ')
          ..write('kind: $kind, ')
          ..write('refId: $refId, ')
          ..write('description: $description, ')
          ..write('note: $note, ')
          ..write('proofPath: $proofPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, at, accountId, amount, kind, refId, description, note, proofPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashEntry &&
          other.id == this.id &&
          other.at == this.at &&
          other.accountId == this.accountId &&
          other.amount == this.amount &&
          other.kind == this.kind &&
          other.refId == this.refId &&
          other.description == this.description &&
          other.note == this.note &&
          other.proofPath == this.proofPath);
}

class CashEntriesCompanion extends UpdateCompanion<CashEntry> {
  final Value<int> id;
  final Value<DateTime> at;
  final Value<int> accountId;
  final Value<int> amount;
  final Value<String> kind;
  final Value<int?> refId;
  final Value<String> description;
  final Value<String> note;
  final Value<String> proofPath;
  const CashEntriesCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.accountId = const Value.absent(),
    this.amount = const Value.absent(),
    this.kind = const Value.absent(),
    this.refId = const Value.absent(),
    this.description = const Value.absent(),
    this.note = const Value.absent(),
    this.proofPath = const Value.absent(),
  });
  CashEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime at,
    required int accountId,
    required int amount,
    required String kind,
    this.refId = const Value.absent(),
    required String description,
    this.note = const Value.absent(),
    this.proofPath = const Value.absent(),
  }) : at = Value(at),
       accountId = Value(accountId),
       amount = Value(amount),
       kind = Value(kind),
       description = Value(description);
  static Insertable<CashEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? at,
    Expression<int>? accountId,
    Expression<int>? amount,
    Expression<String>? kind,
    Expression<int>? refId,
    Expression<String>? description,
    Expression<String>? note,
    Expression<String>? proofPath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (accountId != null) 'account_id': accountId,
      if (amount != null) 'amount': amount,
      if (kind != null) 'kind': kind,
      if (refId != null) 'ref_id': refId,
      if (description != null) 'description': description,
      if (note != null) 'note': note,
      if (proofPath != null) 'proof_path': proofPath,
    });
  }

  CashEntriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? at,
    Value<int>? accountId,
    Value<int>? amount,
    Value<String>? kind,
    Value<int?>? refId,
    Value<String>? description,
    Value<String>? note,
    Value<String>? proofPath,
  }) {
    return CashEntriesCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      kind: kind ?? this.kind,
      refId: refId ?? this.refId,
      description: description ?? this.description,
      note: note ?? this.note,
      proofPath: proofPath ?? this.proofPath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (refId.present) {
      map['ref_id'] = Variable<int>(refId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (proofPath.present) {
      map['proof_path'] = Variable<String>(proofPath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashEntriesCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('accountId: $accountId, ')
          ..write('amount: $amount, ')
          ..write('kind: $kind, ')
          ..write('refId: $refId, ')
          ..write('description: $description, ')
          ..write('note: $note, ')
          ..write('proofPath: $proofPath')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  static const VerificationMeta _categoryMeta = const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PCS'),
  );
  static const VerificationMeta _isServiceMeta = const VerificationMeta('isService');
  @override
  late final GeneratedColumn<bool> isService = GeneratedColumn<bool>(
    'is_service',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_service" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _buyPriceMeta = const VerificationMeta('buyPrice');
  @override
  late final GeneratedColumn<int> buyPrice = GeneratedColumn<int>(
    'buy_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sellPriceMeta = const VerificationMeta('sellPrice');
  @override
  late final GeneratedColumn<int> sellPrice = GeneratedColumn<int>(
    'sell_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _minStockMeta = const VerificationMeta('minStock');
  @override
  late final GeneratedColumn<int> minStock = GeneratedColumn<int>(
    'min_stock',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _incentiveMeta = const VerificationMeta('incentive');
  @override
  late final GeneratedColumn<int> incentive = GeneratedColumn<int>(
    'incentive',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sku,
    name,
    category,
    unit,
    isService,
    buyPrice,
    sellPrice,
    minStock,
    incentive,
    active,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(Insertable<Product> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sku')) {
      context.handle(_skuMeta, sku.isAcceptableOrUnknown(data['sku']!, _skuMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta, category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(_unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('is_service')) {
      context.handle(_isServiceMeta, isService.isAcceptableOrUnknown(data['is_service']!, _isServiceMeta));
    }
    if (data.containsKey('buy_price')) {
      context.handle(_buyPriceMeta, buyPrice.isAcceptableOrUnknown(data['buy_price']!, _buyPriceMeta));
    }
    if (data.containsKey('sell_price')) {
      context.handle(_sellPriceMeta, sellPrice.isAcceptableOrUnknown(data['sell_price']!, _sellPriceMeta));
    }
    if (data.containsKey('min_stock')) {
      context.handle(_minStockMeta, minStock.isAcceptableOrUnknown(data['min_stock']!, _minStockMeta));
    }
    if (data.containsKey('incentive')) {
      context.handle(_incentiveMeta, incentive.isAcceptableOrUnknown(data['incentive']!, _incentiveMeta));
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta, active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sku: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}sku']),
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      category: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      unit: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      isService: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_service'])!,
      buyPrice: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}buy_price'])!,
      sellPrice: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sell_price'])!,
      minStock: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}min_stock'])!,
      incentive: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}incentive'])!,
      active: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final int id;
  final String? sku;
  final String name;
  final String category;
  final String unit;
  final bool isService;
  final int buyPrice;
  final int sellPrice;
  final int minStock;
  final int incentive;
  final bool active;
  const Product({
    required this.id,
    this.sku,
    required this.name,
    required this.category,
    required this.unit,
    required this.isService,
    required this.buyPrice,
    required this.sellPrice,
    required this.minStock,
    required this.incentive,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['unit'] = Variable<String>(unit);
    map['is_service'] = Variable<bool>(isService);
    map['buy_price'] = Variable<int>(buyPrice);
    map['sell_price'] = Variable<int>(sellPrice);
    map['min_stock'] = Variable<int>(minStock);
    map['incentive'] = Variable<int>(incentive);
    map['active'] = Variable<bool>(active);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      name: Value(name),
      category: Value(category),
      unit: Value(unit),
      isService: Value(isService),
      buyPrice: Value(buyPrice),
      sellPrice: Value(sellPrice),
      minStock: Value(minStock),
      incentive: Value(incentive),
      active: Value(active),
    );
  }

  factory Product.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<int>(json['id']),
      sku: serializer.fromJson<String?>(json['sku']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      unit: serializer.fromJson<String>(json['unit']),
      isService: serializer.fromJson<bool>(json['isService']),
      buyPrice: serializer.fromJson<int>(json['buyPrice']),
      sellPrice: serializer.fromJson<int>(json['sellPrice']),
      minStock: serializer.fromJson<int>(json['minStock']),
      incentive: serializer.fromJson<int>(json['incentive']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sku': serializer.toJson<String?>(sku),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'unit': serializer.toJson<String>(unit),
      'isService': serializer.toJson<bool>(isService),
      'buyPrice': serializer.toJson<int>(buyPrice),
      'sellPrice': serializer.toJson<int>(sellPrice),
      'minStock': serializer.toJson<int>(minStock),
      'incentive': serializer.toJson<int>(incentive),
      'active': serializer.toJson<bool>(active),
    };
  }

  Product copyWith({
    int? id,
    Value<String?> sku = const Value.absent(),
    String? name,
    String? category,
    String? unit,
    bool? isService,
    int? buyPrice,
    int? sellPrice,
    int? minStock,
    int? incentive,
    bool? active,
  }) => Product(
    id: id ?? this.id,
    sku: sku.present ? sku.value : this.sku,
    name: name ?? this.name,
    category: category ?? this.category,
    unit: unit ?? this.unit,
    isService: isService ?? this.isService,
    buyPrice: buyPrice ?? this.buyPrice,
    sellPrice: sellPrice ?? this.sellPrice,
    minStock: minStock ?? this.minStock,
    incentive: incentive ?? this.incentive,
    active: active ?? this.active,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      sku: data.sku.present ? data.sku.value : this.sku,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      unit: data.unit.present ? data.unit.value : this.unit,
      isService: data.isService.present ? data.isService.value : this.isService,
      buyPrice: data.buyPrice.present ? data.buyPrice.value : this.buyPrice,
      sellPrice: data.sellPrice.present ? data.sellPrice.value : this.sellPrice,
      minStock: data.minStock.present ? data.minStock.value : this.minStock,
      incentive: data.incentive.present ? data.incentive.value : this.incentive,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('sku: $sku, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('unit: $unit, ')
          ..write('isService: $isService, ')
          ..write('buyPrice: $buyPrice, ')
          ..write('sellPrice: $sellPrice, ')
          ..write('minStock: $minStock, ')
          ..write('incentive: $incentive, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sku, name, category, unit, isService, buyPrice, sellPrice, minStock, incentive, active);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.sku == this.sku &&
          other.name == this.name &&
          other.category == this.category &&
          other.unit == this.unit &&
          other.isService == this.isService &&
          other.buyPrice == this.buyPrice &&
          other.sellPrice == this.sellPrice &&
          other.minStock == this.minStock &&
          other.incentive == this.incentive &&
          other.active == this.active);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<int> id;
  final Value<String?> sku;
  final Value<String> name;
  final Value<String> category;
  final Value<String> unit;
  final Value<bool> isService;
  final Value<int> buyPrice;
  final Value<int> sellPrice;
  final Value<int> minStock;
  final Value<int> incentive;
  final Value<bool> active;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.sku = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.unit = const Value.absent(),
    this.isService = const Value.absent(),
    this.buyPrice = const Value.absent(),
    this.sellPrice = const Value.absent(),
    this.minStock = const Value.absent(),
    this.incentive = const Value.absent(),
    this.active = const Value.absent(),
  });
  ProductsCompanion.insert({
    this.id = const Value.absent(),
    this.sku = const Value.absent(),
    required String name,
    this.category = const Value.absent(),
    this.unit = const Value.absent(),
    this.isService = const Value.absent(),
    this.buyPrice = const Value.absent(),
    this.sellPrice = const Value.absent(),
    this.minStock = const Value.absent(),
    this.incentive = const Value.absent(),
    this.active = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Product> custom({
    Expression<int>? id,
    Expression<String>? sku,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? unit,
    Expression<bool>? isService,
    Expression<int>? buyPrice,
    Expression<int>? sellPrice,
    Expression<int>? minStock,
    Expression<int>? incentive,
    Expression<bool>? active,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sku != null) 'sku': sku,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (unit != null) 'unit': unit,
      if (isService != null) 'is_service': isService,
      if (buyPrice != null) 'buy_price': buyPrice,
      if (sellPrice != null) 'sell_price': sellPrice,
      if (minStock != null) 'min_stock': minStock,
      if (incentive != null) 'incentive': incentive,
      if (active != null) 'active': active,
    });
  }

  ProductsCompanion copyWith({
    Value<int>? id,
    Value<String?>? sku,
    Value<String>? name,
    Value<String>? category,
    Value<String>? unit,
    Value<bool>? isService,
    Value<int>? buyPrice,
    Value<int>? sellPrice,
    Value<int>? minStock,
    Value<int>? incentive,
    Value<bool>? active,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      isService: isService ?? this.isService,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      minStock: minStock ?? this.minStock,
      incentive: incentive ?? this.incentive,
      active: active ?? this.active,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (isService.present) {
      map['is_service'] = Variable<bool>(isService.value);
    }
    if (buyPrice.present) {
      map['buy_price'] = Variable<int>(buyPrice.value);
    }
    if (sellPrice.present) {
      map['sell_price'] = Variable<int>(sellPrice.value);
    }
    if (minStock.present) {
      map['min_stock'] = Variable<int>(minStock.value);
    }
    if (incentive.present) {
      map['incentive'] = Variable<int>(incentive.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('sku: $sku, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('unit: $unit, ')
          ..write('isService: $isService, ')
          ..write('buyPrice: $buyPrice, ')
          ..write('sellPrice: $sellPrice, ')
          ..write('minStock: $minStock, ')
          ..write('incentive: $incentive, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }
}

class $StockMovesTable extends StockMoves with TableInfo<$StockMovesTable, StockMove> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockMovesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta('productId');
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES products (id)'),
  );
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<int> qty = GeneratedColumn<int>(
    'qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refIdMeta = const VerificationMeta('refId');
  @override
  late final GeneratedColumn<int> refId = GeneratedColumn<int>(
    'ref_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitCostMeta = const VerificationMeta('unitCost');
  @override
  late final GeneratedColumn<int> unitCost = GeneratedColumn<int>(
    'unit_cost',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [id, at, productId, qty, kind, refId, unitCost, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_moves';
  @override
  VerificationContext validateIntegrity(Insertable<StockMove> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta, productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(_qtyMeta, qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta));
    } else if (isInserting) {
      context.missing(_qtyMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(_kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('ref_id')) {
      context.handle(_refIdMeta, refId.isAcceptableOrUnknown(data['ref_id']!, _refIdMeta));
    }
    if (data.containsKey('unit_cost')) {
      context.handle(_unitCostMeta, unitCost.isAcceptableOrUnknown(data['unit_cost']!, _unitCostMeta));
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockMove map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockMove(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      at: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}at'])!,
      productId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}product_id'])!,
      qty: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}qty'])!,
      kind: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      refId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}ref_id']),
      unitCost: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}unit_cost']),
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note'])!,
    );
  }

  @override
  $StockMovesTable createAlias(String alias) {
    return $StockMovesTable(attachedDatabase, alias);
  }
}

class StockMove extends DataClass implements Insertable<StockMove> {
  final int id;
  final DateTime at;
  final int productId;
  final int qty;
  final String kind;
  final int? refId;
  final int? unitCost;
  final String note;
  const StockMove({
    required this.id,
    required this.at,
    required this.productId,
    required this.qty,
    required this.kind,
    this.refId,
    this.unitCost,
    required this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at'] = Variable<DateTime>(at);
    map['product_id'] = Variable<int>(productId);
    map['qty'] = Variable<int>(qty);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || refId != null) {
      map['ref_id'] = Variable<int>(refId);
    }
    if (!nullToAbsent || unitCost != null) {
      map['unit_cost'] = Variable<int>(unitCost);
    }
    map['note'] = Variable<String>(note);
    return map;
  }

  StockMovesCompanion toCompanion(bool nullToAbsent) {
    return StockMovesCompanion(
      id: Value(id),
      at: Value(at),
      productId: Value(productId),
      qty: Value(qty),
      kind: Value(kind),
      refId: refId == null && nullToAbsent ? const Value.absent() : Value(refId),
      unitCost: unitCost == null && nullToAbsent ? const Value.absent() : Value(unitCost),
      note: Value(note),
    );
  }

  factory StockMove.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockMove(
      id: serializer.fromJson<int>(json['id']),
      at: serializer.fromJson<DateTime>(json['at']),
      productId: serializer.fromJson<int>(json['productId']),
      qty: serializer.fromJson<int>(json['qty']),
      kind: serializer.fromJson<String>(json['kind']),
      refId: serializer.fromJson<int?>(json['refId']),
      unitCost: serializer.fromJson<int?>(json['unitCost']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'at': serializer.toJson<DateTime>(at),
      'productId': serializer.toJson<int>(productId),
      'qty': serializer.toJson<int>(qty),
      'kind': serializer.toJson<String>(kind),
      'refId': serializer.toJson<int?>(refId),
      'unitCost': serializer.toJson<int?>(unitCost),
      'note': serializer.toJson<String>(note),
    };
  }

  StockMove copyWith({
    int? id,
    DateTime? at,
    int? productId,
    int? qty,
    String? kind,
    Value<int?> refId = const Value.absent(),
    Value<int?> unitCost = const Value.absent(),
    String? note,
  }) => StockMove(
    id: id ?? this.id,
    at: at ?? this.at,
    productId: productId ?? this.productId,
    qty: qty ?? this.qty,
    kind: kind ?? this.kind,
    refId: refId.present ? refId.value : this.refId,
    unitCost: unitCost.present ? unitCost.value : this.unitCost,
    note: note ?? this.note,
  );
  StockMove copyWithCompanion(StockMovesCompanion data) {
    return StockMove(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      productId: data.productId.present ? data.productId.value : this.productId,
      qty: data.qty.present ? data.qty.value : this.qty,
      kind: data.kind.present ? data.kind.value : this.kind,
      refId: data.refId.present ? data.refId.value : this.refId,
      unitCost: data.unitCost.present ? data.unitCost.value : this.unitCost,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockMove(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('productId: $productId, ')
          ..write('qty: $qty, ')
          ..write('kind: $kind, ')
          ..write('refId: $refId, ')
          ..write('unitCost: $unitCost, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, at, productId, qty, kind, refId, unitCost, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockMove &&
          other.id == this.id &&
          other.at == this.at &&
          other.productId == this.productId &&
          other.qty == this.qty &&
          other.kind == this.kind &&
          other.refId == this.refId &&
          other.unitCost == this.unitCost &&
          other.note == this.note);
}

class StockMovesCompanion extends UpdateCompanion<StockMove> {
  final Value<int> id;
  final Value<DateTime> at;
  final Value<int> productId;
  final Value<int> qty;
  final Value<String> kind;
  final Value<int?> refId;
  final Value<int?> unitCost;
  final Value<String> note;
  const StockMovesCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.productId = const Value.absent(),
    this.qty = const Value.absent(),
    this.kind = const Value.absent(),
    this.refId = const Value.absent(),
    this.unitCost = const Value.absent(),
    this.note = const Value.absent(),
  });
  StockMovesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime at,
    required int productId,
    required int qty,
    required String kind,
    this.refId = const Value.absent(),
    this.unitCost = const Value.absent(),
    this.note = const Value.absent(),
  }) : at = Value(at),
       productId = Value(productId),
       qty = Value(qty),
       kind = Value(kind);
  static Insertable<StockMove> custom({
    Expression<int>? id,
    Expression<DateTime>? at,
    Expression<int>? productId,
    Expression<int>? qty,
    Expression<String>? kind,
    Expression<int>? refId,
    Expression<int>? unitCost,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (productId != null) 'product_id': productId,
      if (qty != null) 'qty': qty,
      if (kind != null) 'kind': kind,
      if (refId != null) 'ref_id': refId,
      if (unitCost != null) 'unit_cost': unitCost,
      if (note != null) 'note': note,
    });
  }

  StockMovesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? at,
    Value<int>? productId,
    Value<int>? qty,
    Value<String>? kind,
    Value<int?>? refId,
    Value<int?>? unitCost,
    Value<String>? note,
  }) {
    return StockMovesCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      productId: productId ?? this.productId,
      qty: qty ?? this.qty,
      kind: kind ?? this.kind,
      refId: refId ?? this.refId,
      unitCost: unitCost ?? this.unitCost,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (qty.present) {
      map['qty'] = Variable<int>(qty.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (refId.present) {
      map['ref_id'] = Variable<int>(refId.value);
    }
    if (unitCost.present) {
      map['unit_cost'] = Variable<int>(unitCost.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockMovesCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('productId: $productId, ')
          ..write('qty: $qty, ')
          ..write('kind: $kind, ')
          ..write('refId: $refId, ')
          ..write('unitCost: $unitCost, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $PurchasesTable extends Purchases with TableInfo<$PurchasesTable, Purchase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PurchasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _supplierMeta = const VerificationMeta('supplier');
  @override
  late final GeneratedColumn<String> supplier = GeneratedColumn<String>(
    'supplier',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'),
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [id, at, supplier, accountId, total, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchases';
  @override
  VerificationContext validateIntegrity(Insertable<Purchase> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('supplier')) {
      context.handle(_supplierMeta, supplier.isAcceptableOrUnknown(data['supplier']!, _supplierMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta, accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('total')) {
      context.handle(_totalMeta, total.isAcceptableOrUnknown(data['total']!, _totalMeta));
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Purchase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Purchase(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      at: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}at'])!,
      supplier: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}supplier'])!,
      accountId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}account_id'])!,
      total: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}total'])!,
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note'])!,
    );
  }

  @override
  $PurchasesTable createAlias(String alias) {
    return $PurchasesTable(attachedDatabase, alias);
  }
}

class Purchase extends DataClass implements Insertable<Purchase> {
  final int id;
  final DateTime at;
  final String supplier;
  final int accountId;
  final int total;
  final String note;
  const Purchase({
    required this.id,
    required this.at,
    required this.supplier,
    required this.accountId,
    required this.total,
    required this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at'] = Variable<DateTime>(at);
    map['supplier'] = Variable<String>(supplier);
    map['account_id'] = Variable<int>(accountId);
    map['total'] = Variable<int>(total);
    map['note'] = Variable<String>(note);
    return map;
  }

  PurchasesCompanion toCompanion(bool nullToAbsent) {
    return PurchasesCompanion(
      id: Value(id),
      at: Value(at),
      supplier: Value(supplier),
      accountId: Value(accountId),
      total: Value(total),
      note: Value(note),
    );
  }

  factory Purchase.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Purchase(
      id: serializer.fromJson<int>(json['id']),
      at: serializer.fromJson<DateTime>(json['at']),
      supplier: serializer.fromJson<String>(json['supplier']),
      accountId: serializer.fromJson<int>(json['accountId']),
      total: serializer.fromJson<int>(json['total']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'at': serializer.toJson<DateTime>(at),
      'supplier': serializer.toJson<String>(supplier),
      'accountId': serializer.toJson<int>(accountId),
      'total': serializer.toJson<int>(total),
      'note': serializer.toJson<String>(note),
    };
  }

  Purchase copyWith({int? id, DateTime? at, String? supplier, int? accountId, int? total, String? note}) => Purchase(
    id: id ?? this.id,
    at: at ?? this.at,
    supplier: supplier ?? this.supplier,
    accountId: accountId ?? this.accountId,
    total: total ?? this.total,
    note: note ?? this.note,
  );
  Purchase copyWithCompanion(PurchasesCompanion data) {
    return Purchase(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      supplier: data.supplier.present ? data.supplier.value : this.supplier,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      total: data.total.present ? data.total.value : this.total,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Purchase(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('supplier: $supplier, ')
          ..write('accountId: $accountId, ')
          ..write('total: $total, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, at, supplier, accountId, total, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Purchase &&
          other.id == this.id &&
          other.at == this.at &&
          other.supplier == this.supplier &&
          other.accountId == this.accountId &&
          other.total == this.total &&
          other.note == this.note);
}

class PurchasesCompanion extends UpdateCompanion<Purchase> {
  final Value<int> id;
  final Value<DateTime> at;
  final Value<String> supplier;
  final Value<int> accountId;
  final Value<int> total;
  final Value<String> note;
  const PurchasesCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.supplier = const Value.absent(),
    this.accountId = const Value.absent(),
    this.total = const Value.absent(),
    this.note = const Value.absent(),
  });
  PurchasesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime at,
    this.supplier = const Value.absent(),
    required int accountId,
    required int total,
    this.note = const Value.absent(),
  }) : at = Value(at),
       accountId = Value(accountId),
       total = Value(total);
  static Insertable<Purchase> custom({
    Expression<int>? id,
    Expression<DateTime>? at,
    Expression<String>? supplier,
    Expression<int>? accountId,
    Expression<int>? total,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (supplier != null) 'supplier': supplier,
      if (accountId != null) 'account_id': accountId,
      if (total != null) 'total': total,
      if (note != null) 'note': note,
    });
  }

  PurchasesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? at,
    Value<String>? supplier,
    Value<int>? accountId,
    Value<int>? total,
    Value<String>? note,
  }) {
    return PurchasesCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      supplier: supplier ?? this.supplier,
      accountId: accountId ?? this.accountId,
      total: total ?? this.total,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (supplier.present) {
      map['supplier'] = Variable<String>(supplier.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchasesCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('supplier: $supplier, ')
          ..write('accountId: $accountId, ')
          ..write('total: $total, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $CustomersTable extends Customers with TableInfo<$CustomersTable, Customer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
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
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _carMeta = const VerificationMeta('car');
  @override
  late final GeneratedColumn<String> car = GeneratedColumn<String>(
    'car',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _plateMeta = const VerificationMeta('plate');
  @override
  late final GeneratedColumn<String> plate = GeneratedColumn<String>(
    'plate',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, phone, car, plate, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(Insertable<Customer> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(_phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('car')) {
      context.handle(_carMeta, car.isAcceptableOrUnknown(data['car']!, _carMeta));
    }
    if (data.containsKey('plate')) {
      context.handle(_plateMeta, plate.isAcceptableOrUnknown(data['plate']!, _plateMeta));
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Customer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Customer(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      phone: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}phone']),
      car: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}car'])!,
      plate: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}plate'])!,
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note'])!,
    );
  }

  @override
  $CustomersTable createAlias(String alias) {
    return $CustomersTable(attachedDatabase, alias);
  }
}

class Customer extends DataClass implements Insertable<Customer> {
  final int id;
  final String name;
  final String? phone;
  final String car;
  final String plate;
  final String note;
  const Customer({
    required this.id,
    required this.name,
    this.phone,
    required this.car,
    required this.plate,
    required this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    map['car'] = Variable<String>(car);
    map['plate'] = Variable<String>(plate);
    map['note'] = Variable<String>(note);
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      name: Value(name),
      phone: phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      car: Value(car),
      plate: Value(plate),
      note: Value(note),
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Customer(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      car: serializer.fromJson<String>(json['car']),
      plate: serializer.fromJson<String>(json['plate']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'car': serializer.toJson<String>(car),
      'plate': serializer.toJson<String>(plate),
      'note': serializer.toJson<String>(note),
    };
  }

  Customer copyWith({
    int? id,
    String? name,
    Value<String?> phone = const Value.absent(),
    String? car,
    String? plate,
    String? note,
  }) => Customer(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone.present ? phone.value : this.phone,
    car: car ?? this.car,
    plate: plate ?? this.plate,
    note: note ?? this.note,
  );
  Customer copyWithCompanion(CustomersCompanion data) {
    return Customer(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      car: data.car.present ? data.car.value : this.car,
      plate: data.plate.present ? data.plate.value : this.plate,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Customer(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('car: $car, ')
          ..write('plate: $plate, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, phone, car, plate, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Customer &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.car == this.car &&
          other.plate == this.plate &&
          other.note == this.note);
}

class CustomersCompanion extends UpdateCompanion<Customer> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> phone;
  final Value<String> car;
  final Value<String> plate;
  final Value<String> note;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.car = const Value.absent(),
    this.plate = const Value.absent(),
    this.note = const Value.absent(),
  });
  CustomersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.phone = const Value.absent(),
    this.car = const Value.absent(),
    this.plate = const Value.absent(),
    this.note = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Customer> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? car,
    Expression<String>? plate,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (car != null) 'car': car,
      if (plate != null) 'plate': plate,
      if (note != null) 'note': note,
    });
  }

  CustomersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? phone,
    Value<String>? car,
    Value<String>? plate,
    Value<String>? note,
  }) {
    return CustomersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      car: car ?? this.car,
      plate: plate ?? this.plate,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (car.present) {
      map['car'] = Variable<String>(car.value);
    }
    if (plate.present) {
      map['plate'] = Variable<String>(plate.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('car: $car, ')
          ..write('plate: $plate, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDb extends GeneratedDatabase {
  _$AppDb(QueryExecutor e) : super(e);
  $AppDbManager get managers => $AppDbManager(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CashEntriesTable cashEntries = $CashEntriesTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $StockMovesTable stockMoves = $StockMovesTable(this);
  late final $PurchasesTable purchases = $PurchasesTable(this);
  late final $CustomersTable customers = $CustomersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    settings,
    accounts,
    cashEntries,
    products,
    stockMoves,
    purchases,
    customers,
  ];
}

typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer extends Composer<_$AppDb, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer extends Composer<_$AppDb, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer extends Composer<_$AppDb, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key => $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value => $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDb, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDb db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDb, $SettingsTable, Setting>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDb, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  Value<int> id,
  required String name,
  Value<int> openingBalance,
  Value<String> note,
  Value<bool> active,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> openingBalance,
  Value<String> note,
  Value<bool> active,
});

final class $$AccountsTableReferences extends BaseReferences<_$AppDb, $AccountsTable, Account> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CashEntriesTable, List<CashEntry>> _cashEntriesRefsTable(_$AppDb db) =>
      MultiTypedResultKey.fromTable(db.cashEntries, aliasName: 'accounts__id__cash_entries__account_id');

  $$CashEntriesTableProcessedTableManager get cashEntriesRefs {
    final manager = $$CashEntriesTableTableManager(
      $_db,
      $_db.cashEntries,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_cashEntriesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PurchasesTable, List<Purchase>> _purchasesRefsTable(_$AppDb db) =>
      MultiTypedResultKey.fromTable(db.purchases, aliasName: 'accounts__id__purchases__account_id');

  $$PurchasesTableProcessedTableManager get purchasesRefs {
    final manager = $$PurchasesTableTableManager(
      $_db,
      $_db.purchases,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_purchasesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AccountsTableFilterComposer extends Composer<_$AppDb, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get openingBalance =>
      $composableBuilder(column: $table.openingBalance, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => ColumnFilters(column));

  Expression<bool> cashEntriesRefs(Expression<bool> Function($$CashEntriesTableFilterComposer f) f) {
    final $$CashEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cashEntries,
      getReferencedColumn: (t) => t.accountId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CashEntriesTableFilterComposer(
            $db: $db,
            $table: $db.cashEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> purchasesRefs(Expression<bool> Function($$PurchasesTableFilterComposer f) f) {
    final $$PurchasesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.purchases,
      getReferencedColumn: (t) => t.accountId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PurchasesTableFilterComposer(
            $db: $db,
            $table: $db.purchases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer extends Composer<_$AppDb, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get openingBalance =>
      $composableBuilder(column: $table.openingBalance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => ColumnOrderings(column));
}

class $$AccountsTableAnnotationComposer extends Composer<_$AppDb, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get openingBalance =>
      $composableBuilder(column: $table.openingBalance, builder: (column) => column);

  GeneratedColumn<String> get note => $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get active => $composableBuilder(column: $table.active, builder: (column) => column);

  Expression<T> cashEntriesRefs<T extends Object>(Expression<T> Function($$CashEntriesTableAnnotationComposer a) f) {
    final $$CashEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cashEntries,
      getReferencedColumn: (t) => t.accountId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CashEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.cashEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> purchasesRefs<T extends Object>(Expression<T> Function($$PurchasesTableAnnotationComposer a) f) {
    final $$PurchasesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.purchases,
      getReferencedColumn: (t) => t.accountId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PurchasesTableAnnotationComposer(
            $db: $db,
            $table: $db.purchases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, $$AccountsTableReferences),
          Account,
          PrefetchHooks Function({bool cashEntriesRefs, bool purchasesRefs})
        > {
  $$AccountsTableTableManager(_$AppDb db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> openingBalance = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<bool> active = const Value.absent(),
          }) => AccountsCompanion(id: id, name: name, openingBalance: openingBalance, note: note, active: active),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int> openingBalance = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<bool> active = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                name: name,
                openingBalance: openingBalance,
                note: note,
                active: active,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$AccountsTable, Account>(table), $$AccountsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({cashEntriesRefs = false, purchasesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (cashEntriesRefs) db.cashEntries, if (purchasesRefs) db.purchases],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cashEntriesRefs)
                    await $_getPrefetchedData<Account, $AccountsTable, CashEntry>(
                      currentTable: table,
                      referencedTable: $$AccountsTableReferences._cashEntriesRefsTable(db),
                      managerFromTypedResult: (p0) => $$AccountsTableReferences(db, table, p0).cashEntriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.accountId == item.id),
                      typedResults: items,
                    ),
                  if (purchasesRefs)
                    await $_getPrefetchedData<Account, $AccountsTable, Purchase>(
                      currentTable: table,
                      referencedTable: $$AccountsTableReferences._purchasesRefsTable(db),
                      managerFromTypedResult: (p0) => $$AccountsTableReferences(db, table, p0).purchasesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.accountId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, $$AccountsTableReferences),
      Account,
      PrefetchHooks Function({bool cashEntriesRefs, bool purchasesRefs})
    >;
typedef $$CashEntriesTableCreateCompanionBuilder = CashEntriesCompanion Function({
  Value<int> id,
  required DateTime at,
  required int accountId,
  required int amount,
  required String kind,
  Value<int?> refId,
  required String description,
  Value<String> note,
  Value<String> proofPath,
});
typedef $$CashEntriesTableUpdateCompanionBuilder = CashEntriesCompanion Function({
  Value<int> id,
  Value<DateTime> at,
  Value<int> accountId,
  Value<int> amount,
  Value<String> kind,
  Value<int?> refId,
  Value<String> description,
  Value<String> note,
  Value<String> proofPath,
});

final class $$CashEntriesTableReferences extends BaseReferences<_$AppDb, $CashEntriesTable, CashEntry> {
  $$CashEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$AppDb db) =>
      db.accounts.createAlias('cash_entries__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<int>('account_id')!;

    final manager = $$AccountsTableTableManager($_db, $_db.accounts).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CashEntriesTableFilterComposer extends Composer<_$AppDb, $CashEntriesTable> {
  $$CashEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get refId => $composableBuilder(column: $table.refId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description =>
      $composableBuilder(column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get proofPath =>
      $composableBuilder(column: $table.proofPath, builder: (column) => ColumnFilters(column));

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CashEntriesTableOrderingComposer extends Composer<_$AppDb, $CashEntriesTable> {
  $$CashEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get refId =>
      $composableBuilder(column: $table.refId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description =>
      $composableBuilder(column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get proofPath =>
      $composableBuilder(column: $table.proofPath, builder: (column) => ColumnOrderings(column));

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CashEntriesTableAnnotationComposer extends Composer<_$AppDb, $CashEntriesTable> {
  $$CashEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<int> get amount => $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get refId => $composableBuilder(column: $table.refId, builder: (column) => column);

  GeneratedColumn<String> get description =>
      $composableBuilder(column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get note => $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get proofPath => $composableBuilder(column: $table.proofPath, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CashEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $CashEntriesTable,
          CashEntry,
          $$CashEntriesTableFilterComposer,
          $$CashEntriesTableOrderingComposer,
          $$CashEntriesTableAnnotationComposer,
          $$CashEntriesTableCreateCompanionBuilder,
          $$CashEntriesTableUpdateCompanionBuilder,
          (CashEntry, $$CashEntriesTableReferences),
          CashEntry,
          PrefetchHooks Function({bool accountId})
        > {
  $$CashEntriesTableTableManager(_$AppDb db, $CashEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$CashEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$CashEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$CashEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<int> accountId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int?> refId = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> proofPath = const Value.absent(),
              }) => CashEntriesCompanion(
                id: id,
                at: at,
                accountId: accountId,
                amount: amount,
                kind: kind,
                refId: refId,
                description: description,
                note: note,
                proofPath: proofPath,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime at,
                required int accountId,
                required int amount,
                required String kind,
                Value<int?> refId = const Value.absent(),
                required String description,
                Value<String> note = const Value.absent(),
                Value<String> proofPath = const Value.absent(),
              }) => CashEntriesCompanion.insert(
                id: id,
                at: at,
                accountId: accountId,
                amount: amount,
                kind: kind,
                refId: refId,
                description: description,
                note: note,
                proofPath: proofPath,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable<$CashEntriesTable, CashEntry>(table), $$CashEntriesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
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
                    if (accountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.accountId,
                        referencedTable: $$CashEntriesTableReferences._accountIdTable(db),
                        referencedColumn: $$CashEntriesTableReferences._accountIdTable(db).id,
                      ) as T;
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

typedef $$CashEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $CashEntriesTable,
      CashEntry,
      $$CashEntriesTableFilterComposer,
      $$CashEntriesTableOrderingComposer,
      $$CashEntriesTableAnnotationComposer,
      $$CashEntriesTableCreateCompanionBuilder,
      $$CashEntriesTableUpdateCompanionBuilder,
      (CashEntry, $$CashEntriesTableReferences),
      CashEntry,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  Value<int> id,
  Value<String?> sku,
  required String name,
  Value<String> category,
  Value<String> unit,
  Value<bool> isService,
  Value<int> buyPrice,
  Value<int> sellPrice,
  Value<int> minStock,
  Value<int> incentive,
  Value<bool> active,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<int> id,
  Value<String?> sku,
  Value<String> name,
  Value<String> category,
  Value<String> unit,
  Value<bool> isService,
  Value<int> buyPrice,
  Value<int> sellPrice,
  Value<int> minStock,
  Value<int> incentive,
  Value<bool> active,
});

final class $$ProductsTableReferences extends BaseReferences<_$AppDb, $ProductsTable, Product> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$StockMovesTable, List<StockMove>> _stockMovesRefsTable(_$AppDb db) =>
      MultiTypedResultKey.fromTable(db.stockMoves, aliasName: 'products__id__stock_moves__product_id');

  $$StockMovesTableProcessedTableManager get stockMovesRefs {
    final manager = $$StockMovesTableTableManager(
      $_db,
      $_db.stockMoves,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_stockMovesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProductsTableFilterComposer extends Composer<_$AppDb, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sku => $composableBuilder(column: $table.sku, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isService =>
      $composableBuilder(column: $table.isService, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get buyPrice =>
      $composableBuilder(column: $table.buyPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sellPrice =>
      $composableBuilder(column: $table.sellPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minStock =>
      $composableBuilder(column: $table.minStock, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get incentive =>
      $composableBuilder(column: $table.incentive, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => ColumnFilters(column));

  Expression<bool> stockMovesRefs(Expression<bool> Function($$StockMovesTableFilterComposer f) f) {
    final $$StockMovesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stockMoves,
      getReferencedColumn: (t) => t.productId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$StockMovesTableFilterComposer(
            $db: $db,
            $table: $db.stockMoves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer extends Composer<_$AppDb, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isService =>
      $composableBuilder(column: $table.isService, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get buyPrice =>
      $composableBuilder(column: $table.buyPrice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sellPrice =>
      $composableBuilder(column: $table.sellPrice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minStock =>
      $composableBuilder(column: $table.minStock, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get incentive =>
      $composableBuilder(column: $table.incentive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => ColumnOrderings(column));
}

class $$ProductsTableAnnotationComposer extends Composer<_$AppDb, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sku => $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category => $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get unit => $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get isService => $composableBuilder(column: $table.isService, builder: (column) => column);

  GeneratedColumn<int> get buyPrice => $composableBuilder(column: $table.buyPrice, builder: (column) => column);

  GeneratedColumn<int> get sellPrice => $composableBuilder(column: $table.sellPrice, builder: (column) => column);

  GeneratedColumn<int> get minStock => $composableBuilder(column: $table.minStock, builder: (column) => column);

  GeneratedColumn<int> get incentive => $composableBuilder(column: $table.incentive, builder: (column) => column);

  GeneratedColumn<bool> get active => $composableBuilder(column: $table.active, builder: (column) => column);

  Expression<T> stockMovesRefs<T extends Object>(Expression<T> Function($$StockMovesTableAnnotationComposer a) f) {
    final $$StockMovesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stockMoves,
      getReferencedColumn: (t) => t.productId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$StockMovesTableAnnotationComposer(
            $db: $db,
            $table: $db.stockMoves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $ProductsTable,
          Product,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (Product, $$ProductsTableReferences),
          Product,
          PrefetchHooks Function({bool stockMovesRefs})
        > {
  $$ProductsTableTableManager(_$AppDb db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<bool> isService = const Value.absent(),
                Value<int> buyPrice = const Value.absent(),
                Value<int> sellPrice = const Value.absent(),
                Value<int> minStock = const Value.absent(),
                Value<int> incentive = const Value.absent(),
                Value<bool> active = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                sku: sku,
                name: name,
                category: category,
                unit: unit,
                isService: isService,
                buyPrice: buyPrice,
                sellPrice: sellPrice,
                minStock: minStock,
                incentive: incentive,
                active: active,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                required String name,
                Value<String> category = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<bool> isService = const Value.absent(),
                Value<int> buyPrice = const Value.absent(),
                Value<int> sellPrice = const Value.absent(),
                Value<int> minStock = const Value.absent(),
                Value<int> incentive = const Value.absent(),
                Value<bool> active = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                sku: sku,
                name: name,
                category: category,
                unit: unit,
                isService: isService,
                buyPrice: buyPrice,
                sellPrice: sellPrice,
                minStock: minStock,
                incentive: incentive,
                active: active,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$ProductsTable, Product>(table), $$ProductsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({stockMovesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (stockMovesRefs) db.stockMoves],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (stockMovesRefs)
                    await $_getPrefetchedData<Product, $ProductsTable, StockMove>(
                      currentTable: table,
                      referencedTable: $$ProductsTableReferences._stockMovesRefsTable(db),
                      managerFromTypedResult: (p0) => $$ProductsTableReferences(db, table, p0).stockMovesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.productId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $ProductsTable,
      Product,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (Product, $$ProductsTableReferences),
      Product,
      PrefetchHooks Function({bool stockMovesRefs})
    >;
typedef $$StockMovesTableCreateCompanionBuilder = StockMovesCompanion Function({
  Value<int> id,
  required DateTime at,
  required int productId,
  required int qty,
  required String kind,
  Value<int?> refId,
  Value<int?> unitCost,
  Value<String> note,
});
typedef $$StockMovesTableUpdateCompanionBuilder = StockMovesCompanion Function({
  Value<int> id,
  Value<DateTime> at,
  Value<int> productId,
  Value<int> qty,
  Value<String> kind,
  Value<int?> refId,
  Value<int?> unitCost,
  Value<String> note,
});

final class $$StockMovesTableReferences extends BaseReferences<_$AppDb, $StockMovesTable, StockMove> {
  $$StockMovesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProductsTable _productIdTable(_$AppDb db) => db.products.createAlias('stock_moves__product_id__products__id');

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableManager($_db, $_db.products).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$StockMovesTableFilterComposer extends Composer<_$AppDb, $StockMovesTable> {
  $$StockMovesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get qty => $composableBuilder(column: $table.qty, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get refId => $composableBuilder(column: $table.refId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get unitCost =>
      $composableBuilder(column: $table.unitCost, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockMovesTableOrderingComposer extends Composer<_$AppDb, $StockMovesTable> {
  $$StockMovesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get qty => $composableBuilder(column: $table.qty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get refId =>
      $composableBuilder(column: $table.refId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get unitCost =>
      $composableBuilder(column: $table.unitCost, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockMovesTableAnnotationComposer extends Composer<_$AppDb, $StockMovesTable> {
  $$StockMovesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<int> get qty => $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get refId => $composableBuilder(column: $table.refId, builder: (column) => column);

  GeneratedColumn<int> get unitCost => $composableBuilder(column: $table.unitCost, builder: (column) => column);

  GeneratedColumn<String> get note => $composableBuilder(column: $table.note, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockMovesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $StockMovesTable,
          StockMove,
          $$StockMovesTableFilterComposer,
          $$StockMovesTableOrderingComposer,
          $$StockMovesTableAnnotationComposer,
          $$StockMovesTableCreateCompanionBuilder,
          $$StockMovesTableUpdateCompanionBuilder,
          (StockMove, $$StockMovesTableReferences),
          StockMove,
          PrefetchHooks Function({bool productId})
        > {
  $$StockMovesTableTableManager(_$AppDb db, $StockMovesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$StockMovesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$StockMovesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$StockMovesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<int> productId = const Value.absent(),
                Value<int> qty = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int?> refId = const Value.absent(),
                Value<int?> unitCost = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => StockMovesCompanion(
                id: id,
                at: at,
                productId: productId,
                qty: qty,
                kind: kind,
                refId: refId,
                unitCost: unitCost,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime at,
                required int productId,
                required int qty,
                required String kind,
                Value<int?> refId = const Value.absent(),
                Value<int?> unitCost = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => StockMovesCompanion.insert(
                id: id,
                at: at,
                productId: productId,
                qty: qty,
                kind: kind,
                refId: refId,
                unitCost: unitCost,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$StockMovesTable, StockMove>(table), $$StockMovesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({productId = false}) {
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
                    if (productId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.productId,
                        referencedTable: $$StockMovesTableReferences._productIdTable(db),
                        referencedColumn: $$StockMovesTableReferences._productIdTable(db).id,
                      ) as T;
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

typedef $$StockMovesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $StockMovesTable,
      StockMove,
      $$StockMovesTableFilterComposer,
      $$StockMovesTableOrderingComposer,
      $$StockMovesTableAnnotationComposer,
      $$StockMovesTableCreateCompanionBuilder,
      $$StockMovesTableUpdateCompanionBuilder,
      (StockMove, $$StockMovesTableReferences),
      StockMove,
      PrefetchHooks Function({bool productId})
    >;
typedef $$PurchasesTableCreateCompanionBuilder = PurchasesCompanion Function({
  Value<int> id,
  required DateTime at,
  Value<String> supplier,
  required int accountId,
  required int total,
  Value<String> note,
});
typedef $$PurchasesTableUpdateCompanionBuilder = PurchasesCompanion Function({
  Value<int> id,
  Value<DateTime> at,
  Value<String> supplier,
  Value<int> accountId,
  Value<int> total,
  Value<String> note,
});

final class $$PurchasesTableReferences extends BaseReferences<_$AppDb, $PurchasesTable, Purchase> {
  $$PurchasesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$AppDb db) => db.accounts.createAlias('purchases__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<int>('account_id')!;

    final manager = $$AccountsTableTableManager($_db, $_db.accounts).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PurchasesTableFilterComposer extends Composer<_$AppDb, $PurchasesTable> {
  $$PurchasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supplier =>
      $composableBuilder(column: $table.supplier, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get total => $composableBuilder(column: $table.total, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PurchasesTableOrderingComposer extends Composer<_$AppDb, $PurchasesTable> {
  $$PurchasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supplier =>
      $composableBuilder(column: $table.supplier, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PurchasesTableAnnotationComposer extends Composer<_$AppDb, $PurchasesTable> {
  $$PurchasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get supplier => $composableBuilder(column: $table.supplier, builder: (column) => column);

  GeneratedColumn<int> get total => $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<String> get note => $composableBuilder(column: $table.note, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PurchasesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $PurchasesTable,
          Purchase,
          $$PurchasesTableFilterComposer,
          $$PurchasesTableOrderingComposer,
          $$PurchasesTableAnnotationComposer,
          $$PurchasesTableCreateCompanionBuilder,
          $$PurchasesTableUpdateCompanionBuilder,
          (Purchase, $$PurchasesTableReferences),
          Purchase,
          PrefetchHooks Function({bool accountId})
        > {
  $$PurchasesTableTableManager(_$AppDb db, $PurchasesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$PurchasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$PurchasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$PurchasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> at = const Value.absent(),
            Value<String> supplier = const Value.absent(),
            Value<int> accountId = const Value.absent(),
            Value<int> total = const Value.absent(),
            Value<String> note = const Value.absent(),
          }) => PurchasesCompanion(id: id, at: at, supplier: supplier, accountId: accountId, total: total, note: note),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime at,
                Value<String> supplier = const Value.absent(),
                required int accountId,
                required int total,
                Value<String> note = const Value.absent(),
              }) => PurchasesCompanion.insert(
                id: id,
                at: at,
                supplier: supplier,
                accountId: accountId,
                total: total,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$PurchasesTable, Purchase>(table), $$PurchasesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
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
                    if (accountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.accountId,
                        referencedTable: $$PurchasesTableReferences._accountIdTable(db),
                        referencedColumn: $$PurchasesTableReferences._accountIdTable(db).id,
                      ) as T;
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

typedef $$PurchasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $PurchasesTable,
      Purchase,
      $$PurchasesTableFilterComposer,
      $$PurchasesTableOrderingComposer,
      $$PurchasesTableAnnotationComposer,
      $$PurchasesTableCreateCompanionBuilder,
      $$PurchasesTableUpdateCompanionBuilder,
      (Purchase, $$PurchasesTableReferences),
      Purchase,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$CustomersTableCreateCompanionBuilder = CustomersCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> phone,
  Value<String> car,
  Value<String> plate,
  Value<String> note,
});
typedef $$CustomersTableUpdateCompanionBuilder = CustomersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> phone,
  Value<String> car,
  Value<String> plate,
  Value<String> note,
});

class $$CustomersTableFilterComposer extends Composer<_$AppDb, $CustomersTable> {
  $$CustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get car => $composableBuilder(column: $table.car, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get plate =>
      $composableBuilder(column: $table.plate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));
}

class $$CustomersTableOrderingComposer extends Composer<_$AppDb, $CustomersTable> {
  $$CustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get car =>
      $composableBuilder(column: $table.car, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get plate =>
      $composableBuilder(column: $table.plate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));
}

class $$CustomersTableAnnotationComposer extends Composer<_$AppDb, $CustomersTable> {
  $$CustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone => $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get car => $composableBuilder(column: $table.car, builder: (column) => column);

  GeneratedColumn<String> get plate => $composableBuilder(column: $table.plate, builder: (column) => column);

  GeneratedColumn<String> get note => $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$CustomersTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $CustomersTable,
          Customer,
          $$CustomersTableFilterComposer,
          $$CustomersTableOrderingComposer,
          $$CustomersTableAnnotationComposer,
          $$CustomersTableCreateCompanionBuilder,
          $$CustomersTableUpdateCompanionBuilder,
          (Customer, BaseReferences<_$AppDb, $CustomersTable, Customer>),
          Customer,
          PrefetchHooks Function()
        > {
  $$CustomersTableTableManager(_$AppDb db, $CustomersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$CustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$CustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$CustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String> car = const Value.absent(),
            Value<String> plate = const Value.absent(),
            Value<String> note = const Value.absent(),
          }) => CustomersCompanion(id: id, name: name, phone: phone, car: car, plate: plate, note: note),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> phone = const Value.absent(),
            Value<String> car = const Value.absent(),
            Value<String> plate = const Value.absent(),
            Value<String> note = const Value.absent(),
          }) => CustomersCompanion.insert(id: id, name: name, phone: phone, car: car, plate: plate, note: note),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CustomersTable, Customer>(table),
                  BaseReferences<_$AppDb, $CustomersTable, Customer>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $CustomersTable,
      Customer,
      $$CustomersTableFilterComposer,
      $$CustomersTableOrderingComposer,
      $$CustomersTableAnnotationComposer,
      $$CustomersTableCreateCompanionBuilder,
      $$CustomersTableUpdateCompanionBuilder,
      (Customer, BaseReferences<_$AppDb, $CustomersTable, Customer>),
      Customer,
      PrefetchHooks Function()
    >;

class $AppDbManager {
  final _$AppDb _db;
  $AppDbManager(this._db);
  $$SettingsTableTableManager get settings => $$SettingsTableTableManager(_db, _db.settings);
  $$AccountsTableTableManager get accounts => $$AccountsTableTableManager(_db, _db.accounts);
  $$CashEntriesTableTableManager get cashEntries => $$CashEntriesTableTableManager(_db, _db.cashEntries);
  $$ProductsTableTableManager get products => $$ProductsTableTableManager(_db, _db.products);
  $$StockMovesTableTableManager get stockMoves => $$StockMovesTableTableManager(_db, _db.stockMoves);
  $$PurchasesTableTableManager get purchases => $$PurchasesTableTableManager(_db, _db.purchases);
  $$CustomersTableTableManager get customers => $$CustomersTableTableManager(_db, _db.customers);
}
