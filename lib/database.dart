
import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'shoppingList.dart';
import 'product.dart';

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
	static const String shoppingListTable = 'shopping_lists';
	static const String productTable = 'products';
	static const String productDataTable = 'products_data';

	final String dbName;
	Future<Database> get database => _open(dbName);

	DatabaseManager(this.dbName);

	Future<void> delete() => deleteDatabase(dbName);

	Future<Database> _open(String name) async {
		WidgetsFlutterBinding.ensureInitialized();
		return openDatabase(
			join(await getDatabasesPath(), name),
			onConfigure: (db) async => await db.execute("pragma foreign_keys = on"),
			onCreate: (db, version) async {
				await db.execute(
					"""
					CREATE TABLE $shoppingListTable (
						$id INTEGER PRIMARY KEY AUTOINCREMENT,
						$date DATE NOT NULL,
						$dateModified DATE,
						$title TEXT,
						$order INTEGER,
						$itemCount INTEGER NOT NULL,
						UNIQUE ($order)
					)
					""");
				await db.execute(
					"""
					create table $productTable (
						$id INTEGER NOT NULL,
						$productName TEXT NOT NULL,
						$order INTEGER,
						FOREIGN Key ($id) REFERENCES $shoppingListTable ($id)
						ON DELETE CASCADE,
						PRIMARY KEY ($id, $productName),
						UNIQUE ($order, $id)
					)
					""");
				await db.execute(
					"""
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
					""");
			},
			version: 1,
		);
	}

	Future<void> insertShoppingList(ShoppingList shoppingList) async {
		final Database db = await database;
		await db.insert(
			shoppingListTable,
			shoppingList.toDBMap()
				..removeWhere(
					(key, val) => key == id && val == null
				),
			conflictAlgorithm: ConflictAlgorithm.replace,
		);

		shoppingList.id ??= (await db.query(
			shoppingListTable,
			where: "$id = (select max($id) from $shoppingListTable)",
			columns: [id]
		))[0][id];

		await db.delete(
			productTable,
			where: '$id = ?',
			whereArgs: [shoppingList.id]
		);

		Batch batch = db.batch(); /* Só funciona se as operações forem em ordem */
		for(final prdt in shoppingList.values) {
			batch.insert(
				productTable,
				prdt.toDBMap()
					..putIfAbsent(id, () => shoppingList.id),
				conflictAlgorithm: ConflictAlgorithm.replace,
			);
			for(final pd in prdt.values)
			batch.insert(
				productDataTable,
				pd.toDBMap()
					..putIfAbsent(id, () => shoppingList.id)
					..putIfAbsent(productName, () => prdt.name),
				conflictAlgorithm: ConflictAlgorithm.replace,
			);
		}
		await batch.commit(noResult: true);
	}

	Future<void> _insertProduct(
		Product product,
		int shoppingListId
	) async {
		final Database db = await database;

		await db.insert(
			productTable,
			product.toDBMap()
				..putIfAbsent(id, () => shoppingListId),
			conflictAlgorithm: ConflictAlgorithm.replace,
		);
	}

	Future<void> _insertProductData(
		ProductData pd,
		int shoppingListId,
		String productName
	) async {
		final Database db = await database;

		await db.insert(
			productDataTable,
			pd.toDBMap()
				..putIfAbsent(id, () => shoppingListId)
				..putIfAbsent(DatabaseManager.productName, () => productName),
			conflictAlgorithm: ConflictAlgorithm.replace,
		);
	}

	Future<List<ShoppingList>> getShoppingLists() async {
		final Database db = await database;
		final List<Map<String, dynamic>> maps = await db.query(shoppingListTable);

		List<ShoppingList> lists = [];
		for(final map in maps)
		lists.add(ShoppingList(
			id: map[id],
			date: DateTime.parse(map[date]),
			dateModified: DateTime.parse(map[dateModified]),
			title: map[title],
			order: map[order],
			productList: Map.fromIterable(
				await _getProducts(map[id]),
				key: (prdt) => prdt.name,
				value: (prdt) => prdt,
			),
		));

		return lists;
	}

	Future<List<Product>> _getProducts(int shoppingListId) async {
		final Database db = await database;
		final List<Map<String, dynamic>> maps =
			await db.query(
				productTable,
				where: '$id = ?',
				whereArgs: [shoppingListId],
			);

		List<Product> prdts = List.generate(
			maps.length,
			(i) => Product(
				name: maps[i][productName],
				order: maps[i][order],
			),
		);

		for(final prdt in prdts) {
			List<ProductData> pds = await _getProductsData(
				shoppingListId,
				prdt.name,
			);
			prdt.data = Map.fromIterable(
				pds,
				key: (pd) => pd.type,
				value: (pd) => pd,
			);
		}

		return prdts;
	}

	Future<List<ProductData>> _getProductsData(
		int shoppingListId,
		String name,
	) async {
		final Database db = await database;
		final List<Map<String, dynamic>> maps =
			await db.query(
				productDataTable,
				where: '$id = ? and $productName = ?',
				whereArgs: [shoppingListId, name],
			);

		return List.generate(
			maps.length,
			(i) => ProductData(
				type: maps[i][productDataType],
				price: maps[i][productDataPrice],
				quantity: maps[i][productDataQuantity],
			),
		);
	}

	Future<void> updateShoppingList(
		ShoppingList shoppingList
	) async {
		final db = await database;

		await db.update(
			shoppingListTable,
			shoppingList.toDBMap(),
			where: "$id = ?",
			whereArgs: [shoppingList.id],
		);
	}

	Future<void> updateProduct(
		Product product,
		int shoppingListId,
	) async {
		final db = await database;

		await db.update(
			productTable,
			product.toDBMap(),
			where: "$id = ? and $productName = ?",
			whereArgs: [shoppingListId, product.name],
		);
	}

	Future<void> updateProductData(
		ProductData pd,
		int shoppingListId,
		String productName,
	) async {
		final db = await database;

		await db.update(
			productDataTable,
			pd.toDBMap(),
			where: "$id = ? and ${DatabaseManager.productName} = ? and $productDataType = ?",
			whereArgs: [shoppingListId, productName, pd.type],
		);
	}

	Future<void> deleteShoppingList(
		int shoppingListId,
	) async {
		final db = await database;

		await db.delete(
			shoppingListTable,
			where: "$id = ?",
			whereArgs: [shoppingListId],
		);
	}

	Future<void> deleteProduct(
		int shoppingListId,
		String productName,
	) async {
		final db = await database;

		await db.delete(
			productTable,
			where: "$id = ? and ${DatabaseManager.productName} = ?",
			whereArgs: [shoppingListId, productName],
		);
	}

	Future<void> deleteProductData(
		int shoppingListId,
		String productName,
		String productDataType,
	) async {
		final db = await database;

		await db.delete(
			productTable,
			where: "$id = ? and ${DatabaseManager.productName} = ? and ${DatabaseManager.productDataType} = ?",
			whereArgs: [shoppingListId, productName, productDataType],
		);
	}
}
