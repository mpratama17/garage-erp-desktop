// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
  @override
  late final GeneratedColumnWithTypeConverter<ProductType, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<ProductType>($ProductsTable.$convertertype);
  static const VerificationMeta _sellPriceMeta = const VerificationMeta(
    'sellPrice',
  );
  @override
  late final GeneratedColumn<int> sellPrice = GeneratedColumn<int>(
    'sell_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minStockMeta = const VerificationMeta(
    'minStock',
  );
  @override
  late final GeneratedColumn<int> minStock = GeneratedColumn<int>(
    'min_stock',
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sku,
    name,
    type,
    sellPrice,
    minStock,
    active,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sell_price')) {
      context.handle(
        _sellPriceMeta,
        sellPrice.isAcceptableOrUnknown(data['sell_price']!, _sellPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_sellPriceMeta);
    }
    if (data.containsKey('min_stock')) {
      context.handle(
        _minStockMeta,
        minStock.isAcceptableOrUnknown(data['min_stock']!, _minStockMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $ProductsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      sellPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sell_price'],
      )!,
      minStock: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_stock'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ProductType, int, int> $convertertype =
      const EnumIndexConverter<ProductType>(ProductType.values);
}

class Product extends DataClass implements Insertable<Product> {
  final int id;
  final String sku;
  final String name;
  final ProductType type;
  final int sellPrice;
  final int minStock;
  final bool active;
  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.type,
    required this.sellPrice,
    required this.minStock,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sku'] = Variable<String>(sku);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<int>($ProductsTable.$convertertype.toSql(type));
    }
    map['sell_price'] = Variable<int>(sellPrice);
    map['min_stock'] = Variable<int>(minStock);
    map['active'] = Variable<bool>(active);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      sku: Value(sku),
      name: Value(name),
      type: Value(type),
      sellPrice: Value(sellPrice),
      minStock: Value(minStock),
      active: Value(active),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<int>(json['id']),
      sku: serializer.fromJson<String>(json['sku']),
      name: serializer.fromJson<String>(json['name']),
      type: $ProductsTable.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
      sellPrice: serializer.fromJson<int>(json['sellPrice']),
      minStock: serializer.fromJson<int>(json['minStock']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sku': serializer.toJson<String>(sku),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<int>(
        $ProductsTable.$convertertype.toJson(type),
      ),
      'sellPrice': serializer.toJson<int>(sellPrice),
      'minStock': serializer.toJson<int>(minStock),
      'active': serializer.toJson<bool>(active),
    };
  }

  Product copyWith({
    int? id,
    String? sku,
    String? name,
    ProductType? type,
    int? sellPrice,
    int? minStock,
    bool? active,
  }) => Product(
    id: id ?? this.id,
    sku: sku ?? this.sku,
    name: name ?? this.name,
    type: type ?? this.type,
    sellPrice: sellPrice ?? this.sellPrice,
    minStock: minStock ?? this.minStock,
    active: active ?? this.active,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      sku: data.sku.present ? data.sku.value : this.sku,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      sellPrice: data.sellPrice.present ? data.sellPrice.value : this.sellPrice,
      minStock: data.minStock.present ? data.minStock.value : this.minStock,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('sku: $sku, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('sellPrice: $sellPrice, ')
          ..write('minStock: $minStock, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sku, name, type, sellPrice, minStock, active);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.sku == this.sku &&
          other.name == this.name &&
          other.type == this.type &&
          other.sellPrice == this.sellPrice &&
          other.minStock == this.minStock &&
          other.active == this.active);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<int> id;
  final Value<String> sku;
  final Value<String> name;
  final Value<ProductType> type;
  final Value<int> sellPrice;
  final Value<int> minStock;
  final Value<bool> active;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.sku = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.sellPrice = const Value.absent(),
    this.minStock = const Value.absent(),
    this.active = const Value.absent(),
  });
  ProductsCompanion.insert({
    this.id = const Value.absent(),
    this.sku = const Value.absent(),
    required String name,
    required ProductType type,
    required int sellPrice,
    this.minStock = const Value.absent(),
    this.active = const Value.absent(),
  }) : name = Value(name),
       type = Value(type),
       sellPrice = Value(sellPrice);
  static Insertable<Product> custom({
    Expression<int>? id,
    Expression<String>? sku,
    Expression<String>? name,
    Expression<int>? type,
    Expression<int>? sellPrice,
    Expression<int>? minStock,
    Expression<bool>? active,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sku != null) 'sku': sku,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (sellPrice != null) 'sell_price': sellPrice,
      if (minStock != null) 'min_stock': minStock,
      if (active != null) 'active': active,
    });
  }

  ProductsCompanion copyWith({
    Value<int>? id,
    Value<String>? sku,
    Value<String>? name,
    Value<ProductType>? type,
    Value<int>? sellPrice,
    Value<int>? minStock,
    Value<bool>? active,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      type: type ?? this.type,
      sellPrice: sellPrice ?? this.sellPrice,
      minStock: minStock ?? this.minStock,
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
    if (type.present) {
      map['type'] = Variable<int>(
        $ProductsTable.$convertertype.toSql(type.value),
      );
    }
    if (sellPrice.present) {
      map['sell_price'] = Variable<int>(sellPrice.value);
    }
    if (minStock.present) {
      map['min_stock'] = Variable<int>(minStock.value);
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
          ..write('type: $type, ')
          ..write('sellPrice: $sellPrice, ')
          ..write('minStock: $minStock, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }
}

class $BundleItemsTable extends BundleItems
    with TableInfo<$BundleItemsTable, BundleItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BundleItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bundleIdMeta = const VerificationMeta(
    'bundleId',
  );
  @override
  late final GeneratedColumn<int> bundleId = GeneratedColumn<int>(
    'bundle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
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
  @override
  List<GeneratedColumn> get $columns => [bundleId, productId, qty];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bundle_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<BundleItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('bundle_id')) {
      context.handle(
        _bundleIdMeta,
        bundleId.isAcceptableOrUnknown(data['bundle_id']!, _bundleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bundleIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bundleId, productId};
  @override
  BundleItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BundleItem(
      bundleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bundle_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      )!,
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty'],
      )!,
    );
  }

  @override
  $BundleItemsTable createAlias(String alias) {
    return $BundleItemsTable(attachedDatabase, alias);
  }
}

class BundleItem extends DataClass implements Insertable<BundleItem> {
  final int bundleId;
  final int productId;
  final int qty;
  const BundleItem({
    required this.bundleId,
    required this.productId,
    required this.qty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['bundle_id'] = Variable<int>(bundleId);
    map['product_id'] = Variable<int>(productId);
    map['qty'] = Variable<int>(qty);
    return map;
  }

  BundleItemsCompanion toCompanion(bool nullToAbsent) {
    return BundleItemsCompanion(
      bundleId: Value(bundleId),
      productId: Value(productId),
      qty: Value(qty),
    );
  }

  factory BundleItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BundleItem(
      bundleId: serializer.fromJson<int>(json['bundleId']),
      productId: serializer.fromJson<int>(json['productId']),
      qty: serializer.fromJson<int>(json['qty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bundleId': serializer.toJson<int>(bundleId),
      'productId': serializer.toJson<int>(productId),
      'qty': serializer.toJson<int>(qty),
    };
  }

  BundleItem copyWith({int? bundleId, int? productId, int? qty}) => BundleItem(
    bundleId: bundleId ?? this.bundleId,
    productId: productId ?? this.productId,
    qty: qty ?? this.qty,
  );
  BundleItem copyWithCompanion(BundleItemsCompanion data) {
    return BundleItem(
      bundleId: data.bundleId.present ? data.bundleId.value : this.bundleId,
      productId: data.productId.present ? data.productId.value : this.productId,
      qty: data.qty.present ? data.qty.value : this.qty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BundleItem(')
          ..write('bundleId: $bundleId, ')
          ..write('productId: $productId, ')
          ..write('qty: $qty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(bundleId, productId, qty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BundleItem &&
          other.bundleId == this.bundleId &&
          other.productId == this.productId &&
          other.qty == this.qty);
}

class BundleItemsCompanion extends UpdateCompanion<BundleItem> {
  final Value<int> bundleId;
  final Value<int> productId;
  final Value<int> qty;
  final Value<int> rowid;
  const BundleItemsCompanion({
    this.bundleId = const Value.absent(),
    this.productId = const Value.absent(),
    this.qty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BundleItemsCompanion.insert({
    required int bundleId,
    required int productId,
    required int qty,
    this.rowid = const Value.absent(),
  }) : bundleId = Value(bundleId),
       productId = Value(productId),
       qty = Value(qty);
  static Insertable<BundleItem> custom({
    Expression<int>? bundleId,
    Expression<int>? productId,
    Expression<int>? qty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bundleId != null) 'bundle_id': bundleId,
      if (productId != null) 'product_id': productId,
      if (qty != null) 'qty': qty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BundleItemsCompanion copyWith({
    Value<int>? bundleId,
    Value<int>? productId,
    Value<int>? qty,
    Value<int>? rowid,
  }) {
    return BundleItemsCompanion(
      bundleId: bundleId ?? this.bundleId,
      productId: productId ?? this.productId,
      qty: qty ?? this.qty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bundleId.present) {
      map['bundle_id'] = Variable<int>(bundleId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (qty.present) {
      map['qty'] = Variable<int>(qty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BundleItemsCompanion(')
          ..write('bundleId: $bundleId, ')
          ..write('productId: $productId, ')
          ..write('qty: $qty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockMovesTable extends StockMoves
    with TableInfo<$StockMovesTable, StockMove> {
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
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
  static const VerificationMeta _unitCostMeta = const VerificationMeta(
    'unitCost',
  );
  @override
  late final GeneratedColumn<int> unitCost = GeneratedColumn<int>(
    'unit_cost',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _refTypeMeta = const VerificationMeta(
    'refType',
  );
  @override
  late final GeneratedColumn<String> refType = GeneratedColumn<String>(
    'ref_type',
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
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    qty,
    unitCost,
    refType,
    refId,
    note,
    at,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_moves';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockMove> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMeta);
    }
    if (data.containsKey('unit_cost')) {
      context.handle(
        _unitCostMeta,
        unitCost.isAcceptableOrUnknown(data['unit_cost']!, _unitCostMeta),
      );
    }
    if (data.containsKey('ref_type')) {
      context.handle(
        _refTypeMeta,
        refType.isAcceptableOrUnknown(data['ref_type']!, _refTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_refTypeMeta);
    }
    if (data.containsKey('ref_id')) {
      context.handle(
        _refIdMeta,
        refId.isAcceptableOrUnknown(data['ref_id']!, _refIdMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockMove map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockMove(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      )!,
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty'],
      )!,
      unitCost: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_cost'],
      )!,
      refType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref_type'],
      )!,
      refId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ref_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $StockMovesTable createAlias(String alias) {
    return $StockMovesTable(attachedDatabase, alias);
  }
}

class StockMove extends DataClass implements Insertable<StockMove> {
  final int id;
  final int productId;
  final int qty;
  final int unitCost;
  final String refType;
  final int? refId;
  final String note;
  final DateTime at;
  const StockMove({
    required this.id,
    required this.productId,
    required this.qty,
    required this.unitCost,
    required this.refType,
    this.refId,
    required this.note,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['product_id'] = Variable<int>(productId);
    map['qty'] = Variable<int>(qty);
    map['unit_cost'] = Variable<int>(unitCost);
    map['ref_type'] = Variable<String>(refType);
    if (!nullToAbsent || refId != null) {
      map['ref_id'] = Variable<int>(refId);
    }
    map['note'] = Variable<String>(note);
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  StockMovesCompanion toCompanion(bool nullToAbsent) {
    return StockMovesCompanion(
      id: Value(id),
      productId: Value(productId),
      qty: Value(qty),
      unitCost: Value(unitCost),
      refType: Value(refType),
      refId: refId == null && nullToAbsent
          ? const Value.absent()
          : Value(refId),
      note: Value(note),
      at: Value(at),
    );
  }

  factory StockMove.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockMove(
      id: serializer.fromJson<int>(json['id']),
      productId: serializer.fromJson<int>(json['productId']),
      qty: serializer.fromJson<int>(json['qty']),
      unitCost: serializer.fromJson<int>(json['unitCost']),
      refType: serializer.fromJson<String>(json['refType']),
      refId: serializer.fromJson<int?>(json['refId']),
      note: serializer.fromJson<String>(json['note']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productId': serializer.toJson<int>(productId),
      'qty': serializer.toJson<int>(qty),
      'unitCost': serializer.toJson<int>(unitCost),
      'refType': serializer.toJson<String>(refType),
      'refId': serializer.toJson<int?>(refId),
      'note': serializer.toJson<String>(note),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  StockMove copyWith({
    int? id,
    int? productId,
    int? qty,
    int? unitCost,
    String? refType,
    Value<int?> refId = const Value.absent(),
    String? note,
    DateTime? at,
  }) => StockMove(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    qty: qty ?? this.qty,
    unitCost: unitCost ?? this.unitCost,
    refType: refType ?? this.refType,
    refId: refId.present ? refId.value : this.refId,
    note: note ?? this.note,
    at: at ?? this.at,
  );
  StockMove copyWithCompanion(StockMovesCompanion data) {
    return StockMove(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      qty: data.qty.present ? data.qty.value : this.qty,
      unitCost: data.unitCost.present ? data.unitCost.value : this.unitCost,
      refType: data.refType.present ? data.refType.value : this.refType,
      refId: data.refId.present ? data.refId.value : this.refId,
      note: data.note.present ? data.note.value : this.note,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockMove(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('qty: $qty, ')
          ..write('unitCost: $unitCost, ')
          ..write('refType: $refType, ')
          ..write('refId: $refId, ')
          ..write('note: $note, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, productId, qty, unitCost, refType, refId, note, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockMove &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.qty == this.qty &&
          other.unitCost == this.unitCost &&
          other.refType == this.refType &&
          other.refId == this.refId &&
          other.note == this.note &&
          other.at == this.at);
}

class StockMovesCompanion extends UpdateCompanion<StockMove> {
  final Value<int> id;
  final Value<int> productId;
  final Value<int> qty;
  final Value<int> unitCost;
  final Value<String> refType;
  final Value<int?> refId;
  final Value<String> note;
  final Value<DateTime> at;
  const StockMovesCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.qty = const Value.absent(),
    this.unitCost = const Value.absent(),
    this.refType = const Value.absent(),
    this.refId = const Value.absent(),
    this.note = const Value.absent(),
    this.at = const Value.absent(),
  });
  StockMovesCompanion.insert({
    this.id = const Value.absent(),
    required int productId,
    required int qty,
    this.unitCost = const Value.absent(),
    required String refType,
    this.refId = const Value.absent(),
    this.note = const Value.absent(),
    this.at = const Value.absent(),
  }) : productId = Value(productId),
       qty = Value(qty),
       refType = Value(refType);
  static Insertable<StockMove> custom({
    Expression<int>? id,
    Expression<int>? productId,
    Expression<int>? qty,
    Expression<int>? unitCost,
    Expression<String>? refType,
    Expression<int>? refId,
    Expression<String>? note,
    Expression<DateTime>? at,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (qty != null) 'qty': qty,
      if (unitCost != null) 'unit_cost': unitCost,
      if (refType != null) 'ref_type': refType,
      if (refId != null) 'ref_id': refId,
      if (note != null) 'note': note,
      if (at != null) 'at': at,
    });
  }

  StockMovesCompanion copyWith({
    Value<int>? id,
    Value<int>? productId,
    Value<int>? qty,
    Value<int>? unitCost,
    Value<String>? refType,
    Value<int?>? refId,
    Value<String>? note,
    Value<DateTime>? at,
  }) {
    return StockMovesCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      qty: qty ?? this.qty,
      unitCost: unitCost ?? this.unitCost,
      refType: refType ?? this.refType,
      refId: refId ?? this.refId,
      note: note ?? this.note,
      at: at ?? this.at,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (qty.present) {
      map['qty'] = Variable<int>(qty.value);
    }
    if (unitCost.present) {
      map['unit_cost'] = Variable<int>(unitCost.value);
    }
    if (refType.present) {
      map['ref_type'] = Variable<String>(refType.value);
    }
    if (refId.present) {
      map['ref_id'] = Variable<int>(refId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockMovesCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('qty: $qty, ')
          ..write('unitCost: $unitCost, ')
          ..write('refType: $refType, ')
          ..write('refId: $refId, ')
          ..write('note: $note, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }
}

class $PurchasesTable extends Purchases
    with TableInfo<$PurchasesTable, Purchase> {
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _supplierMeta = const VerificationMeta(
    'supplier',
  );
  @override
  late final GeneratedColumn<String> supplier = GeneratedColumn<String>(
    'supplier',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, supplier, at];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchases';
  @override
  VerificationContext validateIntegrity(
    Insertable<Purchase> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('supplier')) {
      context.handle(
        _supplierMeta,
        supplier.isAcceptableOrUnknown(data['supplier']!, _supplierMeta),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Purchase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Purchase(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      supplier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $PurchasesTable createAlias(String alias) {
    return $PurchasesTable(attachedDatabase, alias);
  }
}

class Purchase extends DataClass implements Insertable<Purchase> {
  final int id;
  final String supplier;
  final DateTime at;
  const Purchase({required this.id, required this.supplier, required this.at});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['supplier'] = Variable<String>(supplier);
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  PurchasesCompanion toCompanion(bool nullToAbsent) {
    return PurchasesCompanion(
      id: Value(id),
      supplier: Value(supplier),
      at: Value(at),
    );
  }

  factory Purchase.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Purchase(
      id: serializer.fromJson<int>(json['id']),
      supplier: serializer.fromJson<String>(json['supplier']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'supplier': serializer.toJson<String>(supplier),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  Purchase copyWith({int? id, String? supplier, DateTime? at}) => Purchase(
    id: id ?? this.id,
    supplier: supplier ?? this.supplier,
    at: at ?? this.at,
  );
  Purchase copyWithCompanion(PurchasesCompanion data) {
    return Purchase(
      id: data.id.present ? data.id.value : this.id,
      supplier: data.supplier.present ? data.supplier.value : this.supplier,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Purchase(')
          ..write('id: $id, ')
          ..write('supplier: $supplier, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, supplier, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Purchase &&
          other.id == this.id &&
          other.supplier == this.supplier &&
          other.at == this.at);
}

class PurchasesCompanion extends UpdateCompanion<Purchase> {
  final Value<int> id;
  final Value<String> supplier;
  final Value<DateTime> at;
  const PurchasesCompanion({
    this.id = const Value.absent(),
    this.supplier = const Value.absent(),
    this.at = const Value.absent(),
  });
  PurchasesCompanion.insert({
    this.id = const Value.absent(),
    this.supplier = const Value.absent(),
    this.at = const Value.absent(),
  });
  static Insertable<Purchase> custom({
    Expression<int>? id,
    Expression<String>? supplier,
    Expression<DateTime>? at,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (supplier != null) 'supplier': supplier,
      if (at != null) 'at': at,
    });
  }

  PurchasesCompanion copyWith({
    Value<int>? id,
    Value<String>? supplier,
    Value<DateTime>? at,
  }) {
    return PurchasesCompanion(
      id: id ?? this.id,
      supplier: supplier ?? this.supplier,
      at: at ?? this.at,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (supplier.present) {
      map['supplier'] = Variable<String>(supplier.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchasesCompanion(')
          ..write('id: $id, ')
          ..write('supplier: $supplier, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }
}

class $CustomersTable extends Customers
    with TableInfo<$CustomersTable, Customer> {
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
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
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, phone];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Customer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Customer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Customer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
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
  final String phone;
  const Customer({required this.id, required this.name, required this.phone});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      name: Value(name),
      phone: Value(phone),
    );
  }

  factory Customer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Customer(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String>(phone),
    };
  }

  Customer copyWith({int? id, String? name, String? phone}) => Customer(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
  );
  Customer copyWithCompanion(CustomersCompanion data) {
    return Customer(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Customer(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, phone);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Customer &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone);
}

class CustomersCompanion extends UpdateCompanion<Customer> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> phone;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
  });
  CustomersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String phone,
  }) : name = Value(name),
       phone = Value(phone);
  static Insertable<Customer> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? phone,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
    });
  }

  CustomersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? phone,
  }) {
    return CustomersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone')
          ..write(')'))
        .toString();
  }
}

class $InvoicesTable extends Invoices with TableInfo<$InvoicesTable, Invoice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoicesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _noMeta = const VerificationMeta('no');
  @override
  late final GeneratedColumn<String> no = GeneratedColumn<String>(
    'no',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<int> customerId = GeneratedColumn<int>(
    'customer_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES customers (id)',
    ),
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
  static const VerificationMeta _ppnMeta = const VerificationMeta('ppn');
  @override
  late final GeneratedColumn<bool> ppn = GeneratedColumn<bool>(
    'ppn',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ppn" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _payMethodMeta = const VerificationMeta(
    'payMethod',
  );
  @override
  late final GeneratedColumn<String> payMethod = GeneratedColumn<String>(
    'pay_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<int> subtotal = GeneratedColumn<int>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _isVoidMeta = const VerificationMeta('isVoid');
  @override
  late final GeneratedColumn<bool> isVoid = GeneratedColumn<bool>(
    'is_void',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_void" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _voidReasonMeta = const VerificationMeta(
    'voidReason',
  );
  @override
  late final GeneratedColumn<String> voidReason = GeneratedColumn<String>(
    'void_reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    no,
    at,
    customerId,
    car,
    plate,
    ppn,
    payMethod,
    subtotal,
    total,
    isVoid,
    voidReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoices';
  @override
  VerificationContext validateIntegrity(
    Insertable<Invoice> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('no')) {
      context.handle(_noMeta, no.isAcceptableOrUnknown(data['no']!, _noMeta));
    } else if (isInserting) {
      context.missing(_noMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    }
    if (data.containsKey('car')) {
      context.handle(
        _carMeta,
        car.isAcceptableOrUnknown(data['car']!, _carMeta),
      );
    }
    if (data.containsKey('plate')) {
      context.handle(
        _plateMeta,
        plate.isAcceptableOrUnknown(data['plate']!, _plateMeta),
      );
    }
    if (data.containsKey('ppn')) {
      context.handle(
        _ppnMeta,
        ppn.isAcceptableOrUnknown(data['ppn']!, _ppnMeta),
      );
    }
    if (data.containsKey('pay_method')) {
      context.handle(
        _payMethodMeta,
        payMethod.isAcceptableOrUnknown(data['pay_method']!, _payMethodMeta),
      );
    } else if (isInserting) {
      context.missing(_payMethodMeta);
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('is_void')) {
      context.handle(
        _isVoidMeta,
        isVoid.isAcceptableOrUnknown(data['is_void']!, _isVoidMeta),
      );
    }
    if (data.containsKey('void_reason')) {
      context.handle(
        _voidReasonMeta,
        voidReason.isAcceptableOrUnknown(data['void_reason']!, _voidReasonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Invoice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Invoice(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      no: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}no'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}customer_id'],
      ),
      car: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}car'],
      )!,
      plate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plate'],
      )!,
      ppn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ppn'],
      )!,
      payMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pay_method'],
      )!,
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subtotal'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total'],
      )!,
      isVoid: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_void'],
      )!,
      voidReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}void_reason'],
      )!,
    );
  }

  @override
  $InvoicesTable createAlias(String alias) {
    return $InvoicesTable(attachedDatabase, alias);
  }
}

class Invoice extends DataClass implements Insertable<Invoice> {
  final int id;
  final String no;
  final DateTime at;
  final int? customerId;
  final String car;
  final String plate;
  final bool ppn;
  final String payMethod;
  final int subtotal;
  final int total;
  final bool isVoid;
  final String voidReason;
  const Invoice({
    required this.id,
    required this.no,
    required this.at,
    this.customerId,
    required this.car,
    required this.plate,
    required this.ppn,
    required this.payMethod,
    required this.subtotal,
    required this.total,
    required this.isVoid,
    required this.voidReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['no'] = Variable<String>(no);
    map['at'] = Variable<DateTime>(at);
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<int>(customerId);
    }
    map['car'] = Variable<String>(car);
    map['plate'] = Variable<String>(plate);
    map['ppn'] = Variable<bool>(ppn);
    map['pay_method'] = Variable<String>(payMethod);
    map['subtotal'] = Variable<int>(subtotal);
    map['total'] = Variable<int>(total);
    map['is_void'] = Variable<bool>(isVoid);
    map['void_reason'] = Variable<String>(voidReason);
    return map;
  }

  InvoicesCompanion toCompanion(bool nullToAbsent) {
    return InvoicesCompanion(
      id: Value(id),
      no: Value(no),
      at: Value(at),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      car: Value(car),
      plate: Value(plate),
      ppn: Value(ppn),
      payMethod: Value(payMethod),
      subtotal: Value(subtotal),
      total: Value(total),
      isVoid: Value(isVoid),
      voidReason: Value(voidReason),
    );
  }

  factory Invoice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Invoice(
      id: serializer.fromJson<int>(json['id']),
      no: serializer.fromJson<String>(json['no']),
      at: serializer.fromJson<DateTime>(json['at']),
      customerId: serializer.fromJson<int?>(json['customerId']),
      car: serializer.fromJson<String>(json['car']),
      plate: serializer.fromJson<String>(json['plate']),
      ppn: serializer.fromJson<bool>(json['ppn']),
      payMethod: serializer.fromJson<String>(json['payMethod']),
      subtotal: serializer.fromJson<int>(json['subtotal']),
      total: serializer.fromJson<int>(json['total']),
      isVoid: serializer.fromJson<bool>(json['isVoid']),
      voidReason: serializer.fromJson<String>(json['voidReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'no': serializer.toJson<String>(no),
      'at': serializer.toJson<DateTime>(at),
      'customerId': serializer.toJson<int?>(customerId),
      'car': serializer.toJson<String>(car),
      'plate': serializer.toJson<String>(plate),
      'ppn': serializer.toJson<bool>(ppn),
      'payMethod': serializer.toJson<String>(payMethod),
      'subtotal': serializer.toJson<int>(subtotal),
      'total': serializer.toJson<int>(total),
      'isVoid': serializer.toJson<bool>(isVoid),
      'voidReason': serializer.toJson<String>(voidReason),
    };
  }

  Invoice copyWith({
    int? id,
    String? no,
    DateTime? at,
    Value<int?> customerId = const Value.absent(),
    String? car,
    String? plate,
    bool? ppn,
    String? payMethod,
    int? subtotal,
    int? total,
    bool? isVoid,
    String? voidReason,
  }) => Invoice(
    id: id ?? this.id,
    no: no ?? this.no,
    at: at ?? this.at,
    customerId: customerId.present ? customerId.value : this.customerId,
    car: car ?? this.car,
    plate: plate ?? this.plate,
    ppn: ppn ?? this.ppn,
    payMethod: payMethod ?? this.payMethod,
    subtotal: subtotal ?? this.subtotal,
    total: total ?? this.total,
    isVoid: isVoid ?? this.isVoid,
    voidReason: voidReason ?? this.voidReason,
  );
  Invoice copyWithCompanion(InvoicesCompanion data) {
    return Invoice(
      id: data.id.present ? data.id.value : this.id,
      no: data.no.present ? data.no.value : this.no,
      at: data.at.present ? data.at.value : this.at,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      car: data.car.present ? data.car.value : this.car,
      plate: data.plate.present ? data.plate.value : this.plate,
      ppn: data.ppn.present ? data.ppn.value : this.ppn,
      payMethod: data.payMethod.present ? data.payMethod.value : this.payMethod,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      total: data.total.present ? data.total.value : this.total,
      isVoid: data.isVoid.present ? data.isVoid.value : this.isVoid,
      voidReason: data.voidReason.present
          ? data.voidReason.value
          : this.voidReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Invoice(')
          ..write('id: $id, ')
          ..write('no: $no, ')
          ..write('at: $at, ')
          ..write('customerId: $customerId, ')
          ..write('car: $car, ')
          ..write('plate: $plate, ')
          ..write('ppn: $ppn, ')
          ..write('payMethod: $payMethod, ')
          ..write('subtotal: $subtotal, ')
          ..write('total: $total, ')
          ..write('isVoid: $isVoid, ')
          ..write('voidReason: $voidReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    no,
    at,
    customerId,
    car,
    plate,
    ppn,
    payMethod,
    subtotal,
    total,
    isVoid,
    voidReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Invoice &&
          other.id == this.id &&
          other.no == this.no &&
          other.at == this.at &&
          other.customerId == this.customerId &&
          other.car == this.car &&
          other.plate == this.plate &&
          other.ppn == this.ppn &&
          other.payMethod == this.payMethod &&
          other.subtotal == this.subtotal &&
          other.total == this.total &&
          other.isVoid == this.isVoid &&
          other.voidReason == this.voidReason);
}

class InvoicesCompanion extends UpdateCompanion<Invoice> {
  final Value<int> id;
  final Value<String> no;
  final Value<DateTime> at;
  final Value<int?> customerId;
  final Value<String> car;
  final Value<String> plate;
  final Value<bool> ppn;
  final Value<String> payMethod;
  final Value<int> subtotal;
  final Value<int> total;
  final Value<bool> isVoid;
  final Value<String> voidReason;
  const InvoicesCompanion({
    this.id = const Value.absent(),
    this.no = const Value.absent(),
    this.at = const Value.absent(),
    this.customerId = const Value.absent(),
    this.car = const Value.absent(),
    this.plate = const Value.absent(),
    this.ppn = const Value.absent(),
    this.payMethod = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.total = const Value.absent(),
    this.isVoid = const Value.absent(),
    this.voidReason = const Value.absent(),
  });
  InvoicesCompanion.insert({
    this.id = const Value.absent(),
    required String no,
    this.at = const Value.absent(),
    this.customerId = const Value.absent(),
    this.car = const Value.absent(),
    this.plate = const Value.absent(),
    this.ppn = const Value.absent(),
    required String payMethod,
    required int subtotal,
    required int total,
    this.isVoid = const Value.absent(),
    this.voidReason = const Value.absent(),
  }) : no = Value(no),
       payMethod = Value(payMethod),
       subtotal = Value(subtotal),
       total = Value(total);
  static Insertable<Invoice> custom({
    Expression<int>? id,
    Expression<String>? no,
    Expression<DateTime>? at,
    Expression<int>? customerId,
    Expression<String>? car,
    Expression<String>? plate,
    Expression<bool>? ppn,
    Expression<String>? payMethod,
    Expression<int>? subtotal,
    Expression<int>? total,
    Expression<bool>? isVoid,
    Expression<String>? voidReason,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (no != null) 'no': no,
      if (at != null) 'at': at,
      if (customerId != null) 'customer_id': customerId,
      if (car != null) 'car': car,
      if (plate != null) 'plate': plate,
      if (ppn != null) 'ppn': ppn,
      if (payMethod != null) 'pay_method': payMethod,
      if (subtotal != null) 'subtotal': subtotal,
      if (total != null) 'total': total,
      if (isVoid != null) 'is_void': isVoid,
      if (voidReason != null) 'void_reason': voidReason,
    });
  }

  InvoicesCompanion copyWith({
    Value<int>? id,
    Value<String>? no,
    Value<DateTime>? at,
    Value<int?>? customerId,
    Value<String>? car,
    Value<String>? plate,
    Value<bool>? ppn,
    Value<String>? payMethod,
    Value<int>? subtotal,
    Value<int>? total,
    Value<bool>? isVoid,
    Value<String>? voidReason,
  }) {
    return InvoicesCompanion(
      id: id ?? this.id,
      no: no ?? this.no,
      at: at ?? this.at,
      customerId: customerId ?? this.customerId,
      car: car ?? this.car,
      plate: plate ?? this.plate,
      ppn: ppn ?? this.ppn,
      payMethod: payMethod ?? this.payMethod,
      subtotal: subtotal ?? this.subtotal,
      total: total ?? this.total,
      isVoid: isVoid ?? this.isVoid,
      voidReason: voidReason ?? this.voidReason,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (no.present) {
      map['no'] = Variable<String>(no.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<int>(customerId.value);
    }
    if (car.present) {
      map['car'] = Variable<String>(car.value);
    }
    if (plate.present) {
      map['plate'] = Variable<String>(plate.value);
    }
    if (ppn.present) {
      map['ppn'] = Variable<bool>(ppn.value);
    }
    if (payMethod.present) {
      map['pay_method'] = Variable<String>(payMethod.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<int>(subtotal.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (isVoid.present) {
      map['is_void'] = Variable<bool>(isVoid.value);
    }
    if (voidReason.present) {
      map['void_reason'] = Variable<String>(voidReason.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoicesCompanion(')
          ..write('id: $id, ')
          ..write('no: $no, ')
          ..write('at: $at, ')
          ..write('customerId: $customerId, ')
          ..write('car: $car, ')
          ..write('plate: $plate, ')
          ..write('ppn: $ppn, ')
          ..write('payMethod: $payMethod, ')
          ..write('subtotal: $subtotal, ')
          ..write('total: $total, ')
          ..write('isVoid: $isVoid, ')
          ..write('voidReason: $voidReason')
          ..write(')'))
        .toString();
  }
}

class $InvoiceLinesTable extends InvoiceLines
    with TableInfo<$InvoiceLinesTable, InvoiceLine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoiceLinesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _invoiceIdMeta = const VerificationMeta(
    'invoiceId',
  );
  @override
  late final GeneratedColumn<int> invoiceId = GeneratedColumn<int>(
    'invoice_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES invoices (id)',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<int> price = GeneratedColumn<int>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountPctMeta = const VerificationMeta(
    'discountPct',
  );
  @override
  late final GeneratedColumn<int> discountPct = GeneratedColumn<int>(
    'discount_pct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _costMeta = const VerificationMeta('cost');
  @override
  late final GeneratedColumn<int> cost = GeneratedColumn<int>(
    'cost',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    invoiceId,
    productId,
    name,
    description,
    qty,
    price,
    discountPct,
    total,
    cost,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoice_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<InvoiceLine> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('invoice_id')) {
      context.handle(
        _invoiceIdMeta,
        invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_invoiceIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
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
    }
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('discount_pct')) {
      context.handle(
        _discountPctMeta,
        discountPct.isAcceptableOrUnknown(
          data['discount_pct']!,
          _discountPctMeta,
        ),
      );
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('cost')) {
      context.handle(
        _costMeta,
        cost.isAcceptableOrUnknown(data['cost']!, _costMeta),
      );
    } else if (isInserting) {
      context.missing(_costMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InvoiceLine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvoiceLine(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      invoiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}invoice_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price'],
      )!,
      discountPct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_pct'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total'],
      )!,
      cost: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost'],
      )!,
    );
  }

  @override
  $InvoiceLinesTable createAlias(String alias) {
    return $InvoiceLinesTable(attachedDatabase, alias);
  }
}

class InvoiceLine extends DataClass implements Insertable<InvoiceLine> {
  final int id;
  final int invoiceId;
  final int productId;
  final String name;
  final String description;
  final int qty;
  final int price;
  final int discountPct;
  final int total;
  final int cost;
  const InvoiceLine({
    required this.id,
    required this.invoiceId,
    required this.productId,
    required this.name,
    required this.description,
    required this.qty,
    required this.price,
    required this.discountPct,
    required this.total,
    required this.cost,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['invoice_id'] = Variable<int>(invoiceId);
    map['product_id'] = Variable<int>(productId);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['qty'] = Variable<int>(qty);
    map['price'] = Variable<int>(price);
    map['discount_pct'] = Variable<int>(discountPct);
    map['total'] = Variable<int>(total);
    map['cost'] = Variable<int>(cost);
    return map;
  }

  InvoiceLinesCompanion toCompanion(bool nullToAbsent) {
    return InvoiceLinesCompanion(
      id: Value(id),
      invoiceId: Value(invoiceId),
      productId: Value(productId),
      name: Value(name),
      description: Value(description),
      qty: Value(qty),
      price: Value(price),
      discountPct: Value(discountPct),
      total: Value(total),
      cost: Value(cost),
    );
  }

  factory InvoiceLine.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvoiceLine(
      id: serializer.fromJson<int>(json['id']),
      invoiceId: serializer.fromJson<int>(json['invoiceId']),
      productId: serializer.fromJson<int>(json['productId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      qty: serializer.fromJson<int>(json['qty']),
      price: serializer.fromJson<int>(json['price']),
      discountPct: serializer.fromJson<int>(json['discountPct']),
      total: serializer.fromJson<int>(json['total']),
      cost: serializer.fromJson<int>(json['cost']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'invoiceId': serializer.toJson<int>(invoiceId),
      'productId': serializer.toJson<int>(productId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'qty': serializer.toJson<int>(qty),
      'price': serializer.toJson<int>(price),
      'discountPct': serializer.toJson<int>(discountPct),
      'total': serializer.toJson<int>(total),
      'cost': serializer.toJson<int>(cost),
    };
  }

  InvoiceLine copyWith({
    int? id,
    int? invoiceId,
    int? productId,
    String? name,
    String? description,
    int? qty,
    int? price,
    int? discountPct,
    int? total,
    int? cost,
  }) => InvoiceLine(
    id: id ?? this.id,
    invoiceId: invoiceId ?? this.invoiceId,
    productId: productId ?? this.productId,
    name: name ?? this.name,
    description: description ?? this.description,
    qty: qty ?? this.qty,
    price: price ?? this.price,
    discountPct: discountPct ?? this.discountPct,
    total: total ?? this.total,
    cost: cost ?? this.cost,
  );
  InvoiceLine copyWithCompanion(InvoiceLinesCompanion data) {
    return InvoiceLine(
      id: data.id.present ? data.id.value : this.id,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      productId: data.productId.present ? data.productId.value : this.productId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      qty: data.qty.present ? data.qty.value : this.qty,
      price: data.price.present ? data.price.value : this.price,
      discountPct: data.discountPct.present
          ? data.discountPct.value
          : this.discountPct,
      total: data.total.present ? data.total.value : this.total,
      cost: data.cost.present ? data.cost.value : this.cost,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceLine(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('productId: $productId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('qty: $qty, ')
          ..write('price: $price, ')
          ..write('discountPct: $discountPct, ')
          ..write('total: $total, ')
          ..write('cost: $cost')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    invoiceId,
    productId,
    name,
    description,
    qty,
    price,
    discountPct,
    total,
    cost,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvoiceLine &&
          other.id == this.id &&
          other.invoiceId == this.invoiceId &&
          other.productId == this.productId &&
          other.name == this.name &&
          other.description == this.description &&
          other.qty == this.qty &&
          other.price == this.price &&
          other.discountPct == this.discountPct &&
          other.total == this.total &&
          other.cost == this.cost);
}

class InvoiceLinesCompanion extends UpdateCompanion<InvoiceLine> {
  final Value<int> id;
  final Value<int> invoiceId;
  final Value<int> productId;
  final Value<String> name;
  final Value<String> description;
  final Value<int> qty;
  final Value<int> price;
  final Value<int> discountPct;
  final Value<int> total;
  final Value<int> cost;
  const InvoiceLinesCompanion({
    this.id = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.productId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.qty = const Value.absent(),
    this.price = const Value.absent(),
    this.discountPct = const Value.absent(),
    this.total = const Value.absent(),
    this.cost = const Value.absent(),
  });
  InvoiceLinesCompanion.insert({
    this.id = const Value.absent(),
    required int invoiceId,
    required int productId,
    required String name,
    this.description = const Value.absent(),
    required int qty,
    required int price,
    this.discountPct = const Value.absent(),
    required int total,
    required int cost,
  }) : invoiceId = Value(invoiceId),
       productId = Value(productId),
       name = Value(name),
       qty = Value(qty),
       price = Value(price),
       total = Value(total),
       cost = Value(cost);
  static Insertable<InvoiceLine> custom({
    Expression<int>? id,
    Expression<int>? invoiceId,
    Expression<int>? productId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? qty,
    Expression<int>? price,
    Expression<int>? discountPct,
    Expression<int>? total,
    Expression<int>? cost,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (productId != null) 'product_id': productId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (qty != null) 'qty': qty,
      if (price != null) 'price': price,
      if (discountPct != null) 'discount_pct': discountPct,
      if (total != null) 'total': total,
      if (cost != null) 'cost': cost,
    });
  }

  InvoiceLinesCompanion copyWith({
    Value<int>? id,
    Value<int>? invoiceId,
    Value<int>? productId,
    Value<String>? name,
    Value<String>? description,
    Value<int>? qty,
    Value<int>? price,
    Value<int>? discountPct,
    Value<int>? total,
    Value<int>? cost,
  }) {
    return InvoiceLinesCompanion(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      description: description ?? this.description,
      qty: qty ?? this.qty,
      price: price ?? this.price,
      discountPct: discountPct ?? this.discountPct,
      total: total ?? this.total,
      cost: cost ?? this.cost,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<int>(invoiceId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (qty.present) {
      map['qty'] = Variable<int>(qty.value);
    }
    if (price.present) {
      map['price'] = Variable<int>(price.value);
    }
    if (discountPct.present) {
      map['discount_pct'] = Variable<int>(discountPct.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (cost.present) {
      map['cost'] = Variable<int>(cost.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceLinesCompanion(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('productId: $productId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('qty: $qty, ')
          ..write('price: $price, ')
          ..write('discountPct: $discountPct, ')
          ..write('total: $total, ')
          ..write('cost: $cost')
          ..write(')'))
        .toString();
  }
}

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
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
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
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
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

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
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
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
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
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
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

abstract class _$AppDb extends GeneratedDatabase {
  _$AppDb(QueryExecutor e) : super(e);
  $AppDbManager get managers => $AppDbManager(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $BundleItemsTable bundleItems = $BundleItemsTable(this);
  late final $StockMovesTable stockMoves = $StockMovesTable(this);
  late final $PurchasesTable purchases = $PurchasesTable(this);
  late final $CustomersTable customers = $CustomersTable(this);
  late final $InvoicesTable invoices = $InvoicesTable(this);
  late final $InvoiceLinesTable invoiceLines = $InvoiceLinesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    products,
    bundleItems,
    stockMoves,
    purchases,
    customers,
    invoices,
    invoiceLines,
    settings,
  ];
}

typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  Value<int> id,
  Value<String> sku,
  required String name,
  required ProductType type,
  required int sellPrice,
  Value<int> minStock,
  Value<bool> active,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<int> id,
  Value<String> sku,
  Value<String> name,
  Value<ProductType> type,
  Value<int> sellPrice,
  Value<int> minStock,
  Value<bool> active,
});

final class $$ProductsTableReferences
    extends BaseReferences<_$AppDb, $ProductsTable, Product> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$StockMovesTable, List<StockMove>>
  _stockMovesRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
    db.stockMoves,
    aliasName: 'products__id__stock_moves__product_id',
  );

  $$StockMovesTableProcessedTableManager get stockMovesRefs {
    final manager = $$StockMovesTableTableManager(
      $_db,
      $_db.stockMoves,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_stockMovesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$InvoiceLinesTable, List<InvoiceLine>>
  _invoiceLinesRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
    db.invoiceLines,
    aliasName: 'products__id__invoice_lines__product_id',
  );

  $$InvoiceLinesTableProcessedTableManager get invoiceLinesRefs {
    final manager = $$InvoiceLinesTableTableManager(
      $_db,
      $_db.invoiceLines,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_invoiceLinesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
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
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ProductType, ProductType, int> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get sellPrice => $composableBuilder(
    column: $table.sellPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minStock => $composableBuilder(
    column: $table.minStock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> stockMovesRefs(
    Expression<bool> Function($$StockMovesTableFilterComposer f) f,
  ) {
    final $$StockMovesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stockMoves,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StockMovesTableFilterComposer(
            $db: $db,
            $table: $db.stockMoves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> invoiceLinesRefs(
    Expression<bool> Function($$InvoiceLinesTableFilterComposer f) f,
  ) {
    final $$InvoiceLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoiceLines,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoiceLinesTableFilterComposer(
            $db: $db,
            $table: $db.invoiceLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDb, $ProductsTable> {
  $$ProductsTableOrderingComposer({
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

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sellPrice => $composableBuilder(
    column: $table.sellPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minStock => $composableBuilder(
    column: $table.minStock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDb, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ProductType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get sellPrice =>
      $composableBuilder(column: $table.sellPrice, builder: (column) => column);

  GeneratedColumn<int> get minStock =>
      $composableBuilder(column: $table.minStock, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  Expression<T> stockMovesRefs<T extends Object>(
    Expression<T> Function($$StockMovesTableAnnotationComposer a) f,
  ) {
    final $$StockMovesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stockMoves,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StockMovesTableAnnotationComposer(
            $db: $db,
            $table: $db.stockMoves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> invoiceLinesRefs<T extends Object>(
    Expression<T> Function($$InvoiceLinesTableAnnotationComposer a) f,
  ) {
    final $$InvoiceLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoiceLines,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoiceLinesTableAnnotationComposer(
            $db: $db,
            $table: $db.invoiceLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
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
          PrefetchHooks Function({bool stockMovesRefs, bool invoiceLinesRefs})
        > {
  $$ProductsTableTableManager(_$AppDb db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sku = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<ProductType> type = const Value.absent(),
                Value<int> sellPrice = const Value.absent(),
                Value<int> minStock = const Value.absent(),
                Value<bool> active = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                sku: sku,
                name: name,
                type: type,
                sellPrice: sellPrice,
                minStock: minStock,
                active: active,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sku = const Value.absent(),
                required String name,
                required ProductType type,
                required int sellPrice,
                Value<int> minStock = const Value.absent(),
                Value<bool> active = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                sku: sku,
                name: name,
                type: type,
                sellPrice: sellPrice,
                minStock: minStock,
                active: active,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProductsTable, Product>(table),
                  $$ProductsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({stockMovesRefs = false, invoiceLinesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (stockMovesRefs) db.stockMoves,
                    if (invoiceLinesRefs) db.invoiceLines,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (stockMovesRefs)
                        await $_getPrefetchedData<
                          Product,
                          $ProductsTable,
                          StockMove
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._stockMovesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).stockMovesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (invoiceLinesRefs)
                        await $_getPrefetchedData<
                          Product,
                          $ProductsTable,
                          InvoiceLine
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._invoiceLinesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).invoiceLinesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
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
      PrefetchHooks Function({bool stockMovesRefs, bool invoiceLinesRefs})
    >;
typedef $$BundleItemsTableCreateCompanionBuilder =
    BundleItemsCompanion Function({
      required int bundleId,
      required int productId,
      required int qty,
      Value<int> rowid,
    });
typedef $$BundleItemsTableUpdateCompanionBuilder =
    BundleItemsCompanion Function({
      Value<int> bundleId,
      Value<int> productId,
      Value<int> qty,
      Value<int> rowid,
    });

final class $$BundleItemsTableReferences
    extends BaseReferences<_$AppDb, $BundleItemsTable, BundleItem> {
  $$BundleItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProductsTable _bundleIdTable(_$AppDb db) =>
      db.products.createAlias('bundle_items__bundle_id__products__id');

  $$ProductsTableProcessedTableManager get bundleId {
    final $_column = $_itemColumn<int>('bundle_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bundleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProductsTable _productIdTable(_$AppDb db) =>
      db.products.createAlias('bundle_items__product_id__products__id');

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BundleItemsTableFilterComposer
    extends Composer<_$AppDb, $BundleItemsTable> {
  $$BundleItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableFilterComposer get bundleId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bundleId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BundleItemsTableOrderingComposer
    extends Composer<_$AppDb, $BundleItemsTable> {
  $$BundleItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableOrderingComposer get bundleId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bundleId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BundleItemsTableAnnotationComposer
    extends Composer<_$AppDb, $BundleItemsTable> {
  $$BundleItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  $$ProductsTableAnnotationComposer get bundleId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bundleId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BundleItemsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $BundleItemsTable,
          BundleItem,
          $$BundleItemsTableFilterComposer,
          $$BundleItemsTableOrderingComposer,
          $$BundleItemsTableAnnotationComposer,
          $$BundleItemsTableCreateCompanionBuilder,
          $$BundleItemsTableUpdateCompanionBuilder,
          (BundleItem, $$BundleItemsTableReferences),
          BundleItem,
          PrefetchHooks Function({bool bundleId, bool productId})
        > {
  $$BundleItemsTableTableManager(_$AppDb db, $BundleItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BundleItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BundleItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BundleItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> bundleId = const Value.absent(),
                Value<int> productId = const Value.absent(),
                Value<int> qty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BundleItemsCompanion(
                bundleId: bundleId,
                productId: productId,
                qty: qty,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int bundleId,
                required int productId,
                required int qty,
                Value<int> rowid = const Value.absent(),
              }) => BundleItemsCompanion.insert(
                bundleId: bundleId,
                productId: productId,
                qty: qty,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BundleItemsTable, BundleItem>(table),
                  $$BundleItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bundleId = false, productId = false}) {
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
                    if (bundleId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.bundleId,
                        referencedTable: $$BundleItemsTableReferences
                            ._bundleIdTable(db),
                        referencedColumn: $$BundleItemsTableReferences
                            ._bundleIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (productId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.productId,
                        referencedTable: $$BundleItemsTableReferences
                            ._productIdTable(db),
                        referencedColumn: $$BundleItemsTableReferences
                            ._productIdTable(db)
                            .id,
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

typedef $$BundleItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $BundleItemsTable,
      BundleItem,
      $$BundleItemsTableFilterComposer,
      $$BundleItemsTableOrderingComposer,
      $$BundleItemsTableAnnotationComposer,
      $$BundleItemsTableCreateCompanionBuilder,
      $$BundleItemsTableUpdateCompanionBuilder,
      (BundleItem, $$BundleItemsTableReferences),
      BundleItem,
      PrefetchHooks Function({bool bundleId, bool productId})
    >;
typedef $$StockMovesTableCreateCompanionBuilder = StockMovesCompanion Function({
  Value<int> id,
  required int productId,
  required int qty,
  Value<int> unitCost,
  required String refType,
  Value<int?> refId,
  Value<String> note,
  Value<DateTime> at,
});
typedef $$StockMovesTableUpdateCompanionBuilder = StockMovesCompanion Function({
  Value<int> id,
  Value<int> productId,
  Value<int> qty,
  Value<int> unitCost,
  Value<String> refType,
  Value<int?> refId,
  Value<String> note,
  Value<DateTime> at,
});

final class $$StockMovesTableReferences
    extends BaseReferences<_$AppDb, $StockMovesTable, StockMove> {
  $$StockMovesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProductsTable _productIdTable(_$AppDb db) =>
      db.products.createAlias('stock_moves__product_id__products__id');

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StockMovesTableFilterComposer
    extends Composer<_$AppDb, $StockMovesTable> {
  $$StockMovesTableFilterComposer({
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

  ColumnFilters<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitCost => $composableBuilder(
    column: $table.unitCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refType => $composableBuilder(
    column: $table.refType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockMovesTableOrderingComposer
    extends Composer<_$AppDb, $StockMovesTable> {
  $$StockMovesTableOrderingComposer({
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

  ColumnOrderings<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitCost => $composableBuilder(
    column: $table.unitCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refType => $composableBuilder(
    column: $table.refType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockMovesTableAnnotationComposer
    extends Composer<_$AppDb, $StockMovesTable> {
  $$StockMovesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<int> get unitCost =>
      $composableBuilder(column: $table.unitCost, builder: (column) => column);

  GeneratedColumn<String> get refType =>
      $composableBuilder(column: $table.refType, builder: (column) => column);

  GeneratedColumn<int> get refId =>
      $composableBuilder(column: $table.refId, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
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
          createFilteringComposer: () =>
              $$StockMovesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockMovesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockMovesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> productId = const Value.absent(),
                Value<int> qty = const Value.absent(),
                Value<int> unitCost = const Value.absent(),
                Value<String> refType = const Value.absent(),
                Value<int?> refId = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
              }) => StockMovesCompanion(
                id: id,
                productId: productId,
                qty: qty,
                unitCost: unitCost,
                refType: refType,
                refId: refId,
                note: note,
                at: at,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int productId,
                required int qty,
                Value<int> unitCost = const Value.absent(),
                required String refType,
                Value<int?> refId = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
              }) => StockMovesCompanion.insert(
                id: id,
                productId: productId,
                qty: qty,
                unitCost: unitCost,
                refType: refType,
                refId: refId,
                note: note,
                at: at,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StockMovesTable, StockMove>(table),
                  $$StockMovesTableReferences(db, table, e),
                ),
              )
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
                        referencedTable: $$StockMovesTableReferences
                            ._productIdTable(db),
                        referencedColumn: $$StockMovesTableReferences
                            ._productIdTable(db)
                            .id,
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
  Value<String> supplier,
  Value<DateTime> at,
});
typedef $$PurchasesTableUpdateCompanionBuilder = PurchasesCompanion Function({
  Value<int> id,
  Value<String> supplier,
  Value<DateTime> at,
});

class $$PurchasesTableFilterComposer
    extends Composer<_$AppDb, $PurchasesTable> {
  $$PurchasesTableFilterComposer({
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

  ColumnFilters<String> get supplier => $composableBuilder(
    column: $table.supplier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PurchasesTableOrderingComposer
    extends Composer<_$AppDb, $PurchasesTable> {
  $$PurchasesTableOrderingComposer({
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

  ColumnOrderings<String> get supplier => $composableBuilder(
    column: $table.supplier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PurchasesTableAnnotationComposer
    extends Composer<_$AppDb, $PurchasesTable> {
  $$PurchasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get supplier =>
      $composableBuilder(column: $table.supplier, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);
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
          (Purchase, BaseReferences<_$AppDb, $PurchasesTable, Purchase>),
          Purchase,
          PrefetchHooks Function()
        > {
  $$PurchasesTableTableManager(_$AppDb db, $PurchasesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PurchasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PurchasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PurchasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> supplier = const Value.absent(),
            Value<DateTime> at = const Value.absent(),
          }) => PurchasesCompanion(id: id, supplier: supplier, at: at),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> supplier = const Value.absent(),
            Value<DateTime> at = const Value.absent(),
          }) => PurchasesCompanion.insert(id: id, supplier: supplier, at: at),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PurchasesTable, Purchase>(table),
                  BaseReferences<_$AppDb, $PurchasesTable, Purchase>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
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
      (Purchase, BaseReferences<_$AppDb, $PurchasesTable, Purchase>),
      Purchase,
      PrefetchHooks Function()
    >;
typedef $$CustomersTableCreateCompanionBuilder = CustomersCompanion Function({
  Value<int> id,
  required String name,
  required String phone,
});
typedef $$CustomersTableUpdateCompanionBuilder = CustomersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> phone,
});

final class $$CustomersTableReferences
    extends BaseReferences<_$AppDb, $CustomersTable, Customer> {
  $$CustomersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$InvoicesTable, List<Invoice>> _invoicesRefsTable(
    _$AppDb db,
  ) => MultiTypedResultKey.fromTable(
    db.invoices,
    aliasName: 'customers__id__invoices__customer_id',
  );

  $$InvoicesTableProcessedTableManager get invoicesRefs {
    final manager = $$InvoicesTableTableManager(
      $_db,
      $_db.invoices,
    ).filter((f) => f.customerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_invoicesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CustomersTableFilterComposer
    extends Composer<_$AppDb, $CustomersTable> {
  $$CustomersTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> invoicesRefs(
    Expression<bool> Function($$InvoicesTableFilterComposer f) f,
  ) {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableFilterComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomersTableOrderingComposer
    extends Composer<_$AppDb, $CustomersTable> {
  $$CustomersTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomersTableAnnotationComposer
    extends Composer<_$AppDb, $CustomersTable> {
  $$CustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  Expression<T> invoicesRefs<T extends Object>(
    Expression<T> Function($$InvoicesTableAnnotationComposer a) f,
  ) {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableAnnotationComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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
          (Customer, $$CustomersTableReferences),
          Customer,
          PrefetchHooks Function({bool invoicesRefs})
        > {
  $$CustomersTableTableManager(_$AppDb db, $CustomersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> phone = const Value.absent(),
          }) => CustomersCompanion(id: id, name: name, phone: phone),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String phone,
          }) => CustomersCompanion.insert(id: id, name: name, phone: phone),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CustomersTable, Customer>(table),
                  $$CustomersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({invoicesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (invoicesRefs) db.invoices],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (invoicesRefs)
                    await $_getPrefetchedData<
                      Customer,
                      $CustomersTable,
                      Invoice
                    >(
                      currentTable: table,
                      referencedTable: $$CustomersTableReferences
                          ._invoicesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CustomersTableReferences(
                            db,
                            table,
                            p0,
                          ).invoicesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.customerId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
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
      (Customer, $$CustomersTableReferences),
      Customer,
      PrefetchHooks Function({bool invoicesRefs})
    >;
typedef $$InvoicesTableCreateCompanionBuilder = InvoicesCompanion Function({
  Value<int> id,
  required String no,
  Value<DateTime> at,
  Value<int?> customerId,
  Value<String> car,
  Value<String> plate,
  Value<bool> ppn,
  required String payMethod,
  required int subtotal,
  required int total,
  Value<bool> isVoid,
  Value<String> voidReason,
});
typedef $$InvoicesTableUpdateCompanionBuilder = InvoicesCompanion Function({
  Value<int> id,
  Value<String> no,
  Value<DateTime> at,
  Value<int?> customerId,
  Value<String> car,
  Value<String> plate,
  Value<bool> ppn,
  Value<String> payMethod,
  Value<int> subtotal,
  Value<int> total,
  Value<bool> isVoid,
  Value<String> voidReason,
});

final class $$InvoicesTableReferences
    extends BaseReferences<_$AppDb, $InvoicesTable, Invoice> {
  $$InvoicesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CustomersTable _customerIdTable(_$AppDb db) =>
      db.customers.createAlias('invoices__customer_id__customers__id');

  $$CustomersTableProcessedTableManager? get customerId {
    final $_column = $_itemColumn<int>('customer_id');
    if ($_column == null) return null;
    final manager = $$CustomersTableTableManager(
      $_db,
      $_db.customers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$InvoiceLinesTable, List<InvoiceLine>>
  _invoiceLinesRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
    db.invoiceLines,
    aliasName: 'invoices__id__invoice_lines__invoice_id',
  );

  $$InvoiceLinesTableProcessedTableManager get invoiceLinesRefs {
    final manager = $$InvoiceLinesTableTableManager(
      $_db,
      $_db.invoiceLines,
    ).filter((f) => f.invoiceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_invoiceLinesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$InvoicesTableFilterComposer extends Composer<_$AppDb, $InvoicesTable> {
  $$InvoicesTableFilterComposer({
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

  ColumnFilters<String> get no => $composableBuilder(
    column: $table.no,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get car => $composableBuilder(
    column: $table.car,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plate => $composableBuilder(
    column: $table.plate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get ppn => $composableBuilder(
    column: $table.ppn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payMethod => $composableBuilder(
    column: $table.payMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isVoid => $composableBuilder(
    column: $table.isVoid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => ColumnFilters(column),
  );

  $$CustomersTableFilterComposer get customerId {
    final $$CustomersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableFilterComposer(
            $db: $db,
            $table: $db.customers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> invoiceLinesRefs(
    Expression<bool> Function($$InvoiceLinesTableFilterComposer f) f,
  ) {
    final $$InvoiceLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoiceLines,
      getReferencedColumn: (t) => t.invoiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoiceLinesTableFilterComposer(
            $db: $db,
            $table: $db.invoiceLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InvoicesTableOrderingComposer
    extends Composer<_$AppDb, $InvoicesTable> {
  $$InvoicesTableOrderingComposer({
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

  ColumnOrderings<String> get no => $composableBuilder(
    column: $table.no,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get car => $composableBuilder(
    column: $table.car,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plate => $composableBuilder(
    column: $table.plate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get ppn => $composableBuilder(
    column: $table.ppn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payMethod => $composableBuilder(
    column: $table.payMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isVoid => $composableBuilder(
    column: $table.isVoid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => ColumnOrderings(column),
  );

  $$CustomersTableOrderingComposer get customerId {
    final $$CustomersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableOrderingComposer(
            $db: $db,
            $table: $db.customers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoicesTableAnnotationComposer
    extends Composer<_$AppDb, $InvoicesTable> {
  $$InvoicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get no =>
      $composableBuilder(column: $table.no, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get car =>
      $composableBuilder(column: $table.car, builder: (column) => column);

  GeneratedColumn<String> get plate =>
      $composableBuilder(column: $table.plate, builder: (column) => column);

  GeneratedColumn<bool> get ppn =>
      $composableBuilder(column: $table.ppn, builder: (column) => column);

  GeneratedColumn<String> get payMethod =>
      $composableBuilder(column: $table.payMethod, builder: (column) => column);

  GeneratedColumn<int> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<bool> get isVoid =>
      $composableBuilder(column: $table.isVoid, builder: (column) => column);

  GeneratedColumn<String> get voidReason => $composableBuilder(
    column: $table.voidReason,
    builder: (column) => column,
  );

  $$CustomersTableAnnotationComposer get customerId {
    final $$CustomersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableAnnotationComposer(
            $db: $db,
            $table: $db.customers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> invoiceLinesRefs<T extends Object>(
    Expression<T> Function($$InvoiceLinesTableAnnotationComposer a) f,
  ) {
    final $$InvoiceLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invoiceLines,
      getReferencedColumn: (t) => t.invoiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoiceLinesTableAnnotationComposer(
            $db: $db,
            $table: $db.invoiceLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InvoicesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $InvoicesTable,
          Invoice,
          $$InvoicesTableFilterComposer,
          $$InvoicesTableOrderingComposer,
          $$InvoicesTableAnnotationComposer,
          $$InvoicesTableCreateCompanionBuilder,
          $$InvoicesTableUpdateCompanionBuilder,
          (Invoice, $$InvoicesTableReferences),
          Invoice,
          PrefetchHooks Function({bool customerId, bool invoiceLinesRefs})
        > {
  $$InvoicesTableTableManager(_$AppDb db, $InvoicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> no = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<int?> customerId = const Value.absent(),
                Value<String> car = const Value.absent(),
                Value<String> plate = const Value.absent(),
                Value<bool> ppn = const Value.absent(),
                Value<String> payMethod = const Value.absent(),
                Value<int> subtotal = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<bool> isVoid = const Value.absent(),
                Value<String> voidReason = const Value.absent(),
              }) => InvoicesCompanion(
                id: id,
                no: no,
                at: at,
                customerId: customerId,
                car: car,
                plate: plate,
                ppn: ppn,
                payMethod: payMethod,
                subtotal: subtotal,
                total: total,
                isVoid: isVoid,
                voidReason: voidReason,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String no,
                Value<DateTime> at = const Value.absent(),
                Value<int?> customerId = const Value.absent(),
                Value<String> car = const Value.absent(),
                Value<String> plate = const Value.absent(),
                Value<bool> ppn = const Value.absent(),
                required String payMethod,
                required int subtotal,
                required int total,
                Value<bool> isVoid = const Value.absent(),
                Value<String> voidReason = const Value.absent(),
              }) => InvoicesCompanion.insert(
                id: id,
                no: no,
                at: at,
                customerId: customerId,
                car: car,
                plate: plate,
                ppn: ppn,
                payMethod: payMethod,
                subtotal: subtotal,
                total: total,
                isVoid: isVoid,
                voidReason: voidReason,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InvoicesTable, Invoice>(table),
                  $$InvoicesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({customerId = false, invoiceLinesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (invoiceLinesRefs) db.invoiceLines,
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
                        if (customerId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.customerId,
                            referencedTable: $$InvoicesTableReferences
                                ._customerIdTable(db),
                            referencedColumn: $$InvoicesTableReferences
                                ._customerIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (invoiceLinesRefs)
                        await $_getPrefetchedData<
                          Invoice,
                          $InvoicesTable,
                          InvoiceLine
                        >(
                          currentTable: table,
                          referencedTable: $$InvoicesTableReferences
                              ._invoiceLinesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$InvoicesTableReferences(
                                db,
                                table,
                                p0,
                              ).invoiceLinesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.invoiceId == item.id,
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

typedef $$InvoicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $InvoicesTable,
      Invoice,
      $$InvoicesTableFilterComposer,
      $$InvoicesTableOrderingComposer,
      $$InvoicesTableAnnotationComposer,
      $$InvoicesTableCreateCompanionBuilder,
      $$InvoicesTableUpdateCompanionBuilder,
      (Invoice, $$InvoicesTableReferences),
      Invoice,
      PrefetchHooks Function({bool customerId, bool invoiceLinesRefs})
    >;
typedef $$InvoiceLinesTableCreateCompanionBuilder =
    InvoiceLinesCompanion Function({
      Value<int> id,
      required int invoiceId,
      required int productId,
      required String name,
      Value<String> description,
      required int qty,
      required int price,
      Value<int> discountPct,
      required int total,
      required int cost,
    });
typedef $$InvoiceLinesTableUpdateCompanionBuilder =
    InvoiceLinesCompanion Function({
      Value<int> id,
      Value<int> invoiceId,
      Value<int> productId,
      Value<String> name,
      Value<String> description,
      Value<int> qty,
      Value<int> price,
      Value<int> discountPct,
      Value<int> total,
      Value<int> cost,
    });

final class $$InvoiceLinesTableReferences
    extends BaseReferences<_$AppDb, $InvoiceLinesTable, InvoiceLine> {
  $$InvoiceLinesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $InvoicesTable _invoiceIdTable(_$AppDb db) =>
      db.invoices.createAlias('invoice_lines__invoice_id__invoices__id');

  $$InvoicesTableProcessedTableManager get invoiceId {
    final $_column = $_itemColumn<int>('invoice_id')!;

    final manager = $$InvoicesTableTableManager(
      $_db,
      $_db.invoices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_invoiceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProductsTable _productIdTable(_$AppDb db) =>
      db.products.createAlias('invoice_lines__product_id__products__id');

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InvoiceLinesTableFilterComposer
    extends Composer<_$AppDb, $InvoiceLinesTable> {
  $$InvoiceLinesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountPct => $composableBuilder(
    column: $table.discountPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnFilters(column),
  );

  $$InvoicesTableFilterComposer get invoiceId {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableFilterComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoiceLinesTableOrderingComposer
    extends Composer<_$AppDb, $InvoiceLinesTable> {
  $$InvoiceLinesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountPct => $composableBuilder(
    column: $table.discountPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnOrderings(column),
  );

  $$InvoicesTableOrderingComposer get invoiceId {
    final $$InvoicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableOrderingComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoiceLinesTableAnnotationComposer
    extends Composer<_$AppDb, $InvoiceLinesTable> {
  $$InvoiceLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<int> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<int> get discountPct => $composableBuilder(
    column: $table.discountPct,
    builder: (column) => column,
  );

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<int> get cost =>
      $composableBuilder(column: $table.cost, builder: (column) => column);

  $$InvoicesTableAnnotationComposer get invoiceId {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.invoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvoicesTableAnnotationComposer(
            $db: $db,
            $table: $db.invoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvoiceLinesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $InvoiceLinesTable,
          InvoiceLine,
          $$InvoiceLinesTableFilterComposer,
          $$InvoiceLinesTableOrderingComposer,
          $$InvoiceLinesTableAnnotationComposer,
          $$InvoiceLinesTableCreateCompanionBuilder,
          $$InvoiceLinesTableUpdateCompanionBuilder,
          (InvoiceLine, $$InvoiceLinesTableReferences),
          InvoiceLine,
          PrefetchHooks Function({bool invoiceId, bool productId})
        > {
  $$InvoiceLinesTableTableManager(_$AppDb db, $InvoiceLinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoiceLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoiceLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoiceLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> invoiceId = const Value.absent(),
                Value<int> productId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> qty = const Value.absent(),
                Value<int> price = const Value.absent(),
                Value<int> discountPct = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<int> cost = const Value.absent(),
              }) => InvoiceLinesCompanion(
                id: id,
                invoiceId: invoiceId,
                productId: productId,
                name: name,
                description: description,
                qty: qty,
                price: price,
                discountPct: discountPct,
                total: total,
                cost: cost,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int invoiceId,
                required int productId,
                required String name,
                Value<String> description = const Value.absent(),
                required int qty,
                required int price,
                Value<int> discountPct = const Value.absent(),
                required int total,
                required int cost,
              }) => InvoiceLinesCompanion.insert(
                id: id,
                invoiceId: invoiceId,
                productId: productId,
                name: name,
                description: description,
                qty: qty,
                price: price,
                discountPct: discountPct,
                total: total,
                cost: cost,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InvoiceLinesTable, InvoiceLine>(table),
                  $$InvoiceLinesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({invoiceId = false, productId = false}) {
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
                    if (invoiceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.invoiceId,
                        referencedTable: $$InvoiceLinesTableReferences
                            ._invoiceIdTable(db),
                        referencedColumn: $$InvoiceLinesTableReferences
                            ._invoiceIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (productId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.productId,
                        referencedTable: $$InvoiceLinesTableReferences
                            ._productIdTable(db),
                        referencedColumn: $$InvoiceLinesTableReferences
                            ._productIdTable(db)
                            .id,
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

typedef $$InvoiceLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $InvoiceLinesTable,
      InvoiceLine,
      $$InvoiceLinesTableFilterComposer,
      $$InvoiceLinesTableOrderingComposer,
      $$InvoiceLinesTableAnnotationComposer,
      $$InvoiceLinesTableCreateCompanionBuilder,
      $$InvoiceLinesTableUpdateCompanionBuilder,
      (InvoiceLine, $$InvoiceLinesTableReferences),
      InvoiceLine,
      PrefetchHooks Function({bool invoiceId, bool productId})
    >;
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
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDb, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDb, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
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
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
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
                  BaseReferences<_$AppDb, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
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

class $AppDbManager {
  final _$AppDb _db;
  $AppDbManager(this._db);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$BundleItemsTableTableManager get bundleItems =>
      $$BundleItemsTableTableManager(_db, _db.bundleItems);
  $$StockMovesTableTableManager get stockMoves =>
      $$StockMovesTableTableManager(_db, _db.stockMoves);
  $$PurchasesTableTableManager get purchases =>
      $$PurchasesTableTableManager(_db, _db.purchases);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
  $$InvoicesTableTableManager get invoices =>
      $$InvoicesTableTableManager(_db, _db.invoices);
  $$InvoiceLinesTableTableManager get invoiceLines =>
      $$InvoiceLinesTableTableManager(_db, _db.invoiceLines);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
