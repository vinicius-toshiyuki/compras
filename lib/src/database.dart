import 'dart:async';
import 'dart:io' show Platform;

import 'package:compras/compras.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseManager {
  static const String id = '_id';
  static const String date = '_date';
  static const String dateModified = '_date_modified';
  static const String title = '_title';
  static const String order = '_order';
  static const String itemCount = '_count';
  static const String productName = '_name';
  static const String productDataType = '_type';
  static const String productDataPrice = '_price';
  static const String productDataQuantity = '_quantity';
  static const String shoppinglistTable = 'shopping_lists';
  static const String productTable = 'products';
  static const String productDataTable = 'products_data';

  static const String _createShoppingListTable = """
    CREATE TABLE $shoppinglistTable (
      $id INTEGER PRIMARY KEY AUTOINCREMENT,
      $date DATE NOT NULL,
      $dateModified DATE,
      $title TEXT,
      $order INTEGER,
      $itemCount INTEGER NOT NULL,
      UNIQUE ($order)
    )
    """;
  static const String _createProductTable = """
              create table $productTable (
                $id INTEGER NOT NULL,
                $productName TEXT NOT NULL,
                $order INTEGER,
                FOREIGN Key ($id) REFERENCES $shoppinglistTable ($id)
                ON DELETE CASCADE,
                PRIMARY KEY ($id, $productName),
                UNIQUE ($order, $id)
              )
              """;
  static const String _createProductDataTable = """
              CREATE TABLE $productDataTable (
                $id INTEGER NOT NULL,
                $productName TEXT NOT NULL,
                $productDataType TEXT NOT NULL,
                $productDataPrice REAL,
                $productDataQuantity REAL,
                FOREIGN KEY ($id, $productName) REFERENCES $productTable ($id, $productName)
                ON DELETE CASCADE,
                PRIMARY KEY ($id, $productName, $productDataType)
              )
              """;

  static const int _version = 1;
  final Future<Database> Function(String) _open;
  final String dbName;

  factory DatabaseManager(String name) {
    if (Platform.isIOS || Platform.isAndroid) {
      return DatabaseManager._internal(name, (name) async {
        WidgetsFlutterBinding.ensureInitialized();
        return openDatabase(
          join(await getDatabasesPath(), name),
          onConfigure: _onConfigure,
          onCreate: _onCreate,
          version: _version,
        );
      });
    } else {
      return DatabaseManager._internal(name, (name) async {
        sqfliteFfiInit();
        return databaseFactoryFfi.openDatabase(
          join(await databaseFactoryFfi.getDatabasesPath(), name),
          options: OpenDatabaseOptions(
            onConfigure: _onConfigure,
            onCreate: _onCreate,
            version: _version,
          ),
        );
      });
    }
  }
  DatabaseManager._internal(this.dbName, this._open);

  Future<Database> get database => _open(dbName);

  Future<void> delete() => deleteDatabase(dbName);

  Future<void> deleteProduct(
    int shoppinglistId,
    String productName,
  ) async {
    final db = await database;

    await db.delete(
      productTable,
      where: "$id = ? AND ${DatabaseManager.productName} = ?",
      whereArgs: [shoppinglistId, productName],
    );
  }

  Future<void> deleteProductData(
    int shoppinglistId,
    String productName,
    String productDataType,
  ) async {
    final db = await database;

    await db.delete(
      productTable,
      where:
          "$id = ? AND ${DatabaseManager.productName} = ? AND ${DatabaseManager.productDataType} = ?",
      whereArgs: [shoppinglistId, productName, productDataType],
    );
  }

  Future<void> deleteShoppingList(
    int shoppinglistId,
  ) async {
    final db = await database;

    await db.delete(
      shoppinglistTable,
      where: "$id = ?",
      whereArgs: [shoppinglistId],
    );
  }

  Future<List<ShoppingList>> getShoppingLists() async {
    final Database db = await database;

    List<ShoppingList> lists = [];

    return db.transaction((tnx) async {
      final List<Map<String, dynamic>> maps =
          await tnx.query(shoppinglistTable);
      for (final listMaps in maps) {
        final List<Map<String, dynamic>> productMaps = await tnx.query(
          productTable,
          where: '$id = ?',
          whereArgs: [listMaps[id]],
        );

        List<Product> prdts = List.generate(
          productMaps.length,
          (i) => Product(
            name: productMaps[i][productName],
            order: productMaps[i][order],
          ),
        );

        for (final prdt in prdts) {
          final List<Map<String, dynamic>> pdMaps = await tnx.query(
            productDataTable,
            where: '$id = ? and $productName = ?',
            whereArgs: [listMaps[id], prdt.name],
          );

          List<ProductData> pds = List.generate(
            pdMaps.length,
            (i) => ProductData(
              type: pdMaps[i][productDataType],
              price: pdMaps[i][productDataPrice],
              quantity: pdMaps[i][productDataQuantity],
            ),
          );

          prdt.data = Map.fromIterable(
            pds,
            key: (pd) => pd.type,
            value: (pd) => pd,
          );
        }

        lists.add(ShoppingList(
          id: listMaps[id],
          date: DateTime.parse(listMaps[date]),
          dateModified: DateTime.parse(listMaps[dateModified]),
          title: listMaps[title],
          order: listMaps[order],
          productList: Map.fromIterable(
            prdts,
            key: (prdt) => prdt.name,
            value: (prdt) => prdt,
          ),
        ));
      }
      return lists;
    });
  }

  Future<void> insertShoppingList(ShoppingList shoppinglist) async {
    final Database db = await database;

    db.transaction((tnx) async {
      await tnx.insert(
        shoppinglistTable,
        shoppinglist.toDBMap()
          ..removeWhere((key, val) => key == id && val == null),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      shoppinglist.id ??= (await tnx.query(shoppinglistTable,
          where: "$id = (SELECT max($id) FROM $shoppinglistTable)",
          columns: [id]))[0][id];

      await tnx
          .delete(productTable, where: '$id = ?', whereArgs: [shoppinglist.id]);

      for (final prdt in shoppinglist.values) {
        await tnx.insert(
          productTable,
          prdt.toDBMap()..putIfAbsent(id, () => shoppinglist.id),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        for (final pd in prdt.values)
          await tnx.insert(
            productDataTable,
            pd.toDBMap()
              ..putIfAbsent(id, () => shoppinglist.id)
              ..putIfAbsent(productName, () => prdt.name),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
      }
    });
  }

  Future<void> updateProduct(
    Product product,
    int shoppinglistId,
  ) async {
    final db = await database;

    await db.update(
      productTable,
      product.toDBMap(),
      where: "$id = ? AND $productName = ?",
      whereArgs: [shoppinglistId, product.name],
    );
  }

  Future<void> updateProductData(
    ProductData pd,
    int shoppinglistId,
    String productName,
  ) async {
    final db = await database;

    await db.update(
      productDataTable,
      pd.toDBMap(),
      where:
          "$id = ? AND ${DatabaseManager.productName} = ? AND $productDataType = ?",
      whereArgs: [shoppinglistId, productName, pd.type],
    );
  }

  Future<void> updateShoppingList(ShoppingList shoppinglist) async {
    final db = await database;

    await db.update(
      shoppinglistTable,
      shoppinglist.toDBMap(),
      where: "$id = ?",
      whereArgs: [shoppinglist.id],
    );
  }

  static FutureOr<void> _onConfigure(Database db) async {
    await db.execute("PRAGMA FOREIGN_KEYS = ON");
  }

  static FutureOr<void> _onCreate(Database db, int version) async {
        await db.execute(_createShoppingListTable);
        await db.execute(_createProductTable);
        await db.execute(_createProductDataTable);
  }
}
