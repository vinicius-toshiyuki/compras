import '../product/product.dart';
import '../database.dart';
import 'dart:collection';

const String ShoppingListDatabase = 'ShoppingListDatabase';

class ShoppingList extends MapBase<String,Product> {
	Map<String,Product> _products = Map();

	Iterable<String> get keys {
		List<String> pkeys = _products.keys
			.toList()
			..sort((key1, key2) {
				if(
					_products[key1].order == null ||
					_products[key2].order == null
				)
					return -1;
				return _products[key1].order.compareTo(_products[key2].order);
			});
		for(final key in pkeys) {
			if(_products[key].order != null)
			pkeys.insert(_products[key].order, pkeys.removeAt(pkeys.indexOf(key)));
		}
		return pkeys;
	}
	Product operator [](Object key) => _products[key];
	int get length => _products.length;
	Product remove(Object key) { _update(); return _products.remove(key); }
	void clear() { _update(); _products.clear(); }
	void operator []=(String key, Product val) { _update(); _products[key] = val; }

	set products(Map<String,Product> val) { _update(); products = val; }
	Map<String,Product> get product => Map.from(_products);

	void _update() { dateModified = DateTime.now(); }

	final DateTime dateCreated;
	DateTime dateModified;
	String _title;
	String get title => _title ?? 'Nova lista';
	set title(String val) { _update(); _title = val; }
	int order;
	int _id;

	ShoppingList({
		int id,
		DateTime date,
		this.dateModified,
		String title,
		this.order,
		Map<String,Product> productList,
	}): this.dateCreated = date ?? DateTime.now(),
		this._id = id {
		_title = title;
		this.dateModified ??= this.dateCreated;
		this._products = productList ?? Map();
	}

	void fromEntries(Iterable<MapEntry<String,Product>> entries) {
		_products = Map.fromEntries(entries);
	}

	set id(int val) => this._id ??= val;
	get id => this._id;

	Map<String,dynamic> toDBMap() {
		return {
			DatabaseManager.id: id,
			DatabaseManager.date: dateCreated.toIso8601String(),
			DatabaseManager.dateModified: dateModified.toIso8601String(),
			DatabaseManager.title: title,
			DatabaseManager.order: order,
			DatabaseManager.itemCount: length,
		};
	}

	@override
	String toString() => '$title ($id)';
}
