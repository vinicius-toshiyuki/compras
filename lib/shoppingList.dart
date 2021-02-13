import 'package:flutter/material.dart';
import 'product.dart';
import 'productBottomSheet.dart';
import 'dart:collection';
import 'database.dart';
import 'package:intl/intl.dart';

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
	String toString() => '$title ($length)';
}

class ShoppingListWidget extends StatelessWidget {
	final ShoppingList list;

	ShoppingListWidget({
		@required this.list,
	}): assert(list != null);

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: EdgeInsets.fromLTRB(15, 10, 15, 0),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				mainAxisSize: MainAxisSize.min,
				children: [
					Row(
						children: [
							Expanded(
								child: Text(
									list.title,
									style: Theme.of(context)
										.textTheme
										.headline6
										.copyWith(fontWeight: FontWeight.bold)
								),
							),
						],
					),
					Container(
						height: 5,
					),
					Text(
						'Modificada em ${DateFormat("dd/MM/yyyy HH:mm").format(list.dateModified)}',
						style: Theme.of(context).textTheme.caption,
					),
					Text(
						'Criada em ${DateFormat("dd/MM/yyyy HH:mm").format(list.dateCreated)}',
						style: Theme.of(context).textTheme.caption,
					),
				],
			),
		);
	}
}

class ShoppingListPage extends StatefulWidget {
	static const routeName = '/shoppingList';

	ShoppingListPage({
		Key key,
		this.loadedList,
	}): super(key: key);

	final ShoppingList loadedList;

	@override
	_ShoppingListPageState createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> with WidgetsBindingObserver {
	@override
	void didChangeAppLifecycleState(AppLifecycleState state) {
		if(state == AppLifecycleState.paused) _save();
	}
	
	DatabaseManager _dbManager = DatabaseManager(ShoppingListDatabase);
	ShoppingList spList;

	@override
	void initState() {
		spList = widget.loadedList ?? ShoppingList();
		spList.title ??= 'Nova lista';
		WidgetsBinding.instance.addObserver(this);
		super.initState();
	}

	@override
	void dispose() {
		WidgetsBinding.instance.removeObserver(this);
		super.dispose();
	}

	double get total {
		return spList.length > 0 ? 
			spList.values
				.map((e) => e.total)
				.reduce((val, el) => val + el) : 0;
	}

	void _save() {
		if(spList.length > 0)
		_dbManager.insertShoppingList(spList);
	}

	@override
	Widget build(BuildContext context) {
		List<MapEntry<String,Product>> spListEntries = List.from(spList.entries);
		return WillPopScope(
			onWillPop: () async {
				_save();
				return true;
			},
			child: Scaffold(
				appBar: AppBar(
					title: TextButton(
						child: Text(spList.title,
							style: Theme.of(context).primaryTextTheme.headline6,
							overflow: TextOverflow.ellipsis,
						),
						onPressed: () {
							void _updateTitle(String newTitle) {
								if(newTitle.isNotEmpty) {
									setState(() => spList.title = newTitle);
									Navigator.of(context).pop();
								}
							}
							TextEditingController controller = TextEditingController();
							controller.text = spList.title;
							showDialog(
								context: context,
								builder: (context) => AlertDialog(
									title: Text('Renomear lista'),
									content: TextField(
										controller: controller,
										decoration: InputDecoration(
											border: OutlineInputBorder(),
											isDense: true,
											labelText: 'Novo nome',
										),
										textCapitalization: TextCapitalization.words,
										textInputAction: TextInputAction.done,
										onSubmitted: (value) => _updateTitle(controller.text),
									),
									actions: [
										TextButton(
											child: Text('Cancelar'),
											onPressed: Navigator.of(context).pop,
										),
										TextButton(
											child: Text('OK'),
											onPressed: () => _updateTitle(controller.text),
										),
									],
								),
							);
						},
					),
				),
				body: ListView.separated(
					separatorBuilder: (BuildContext context, int i) =>
						Divider(height: 0, indent: 15, endIndent: 15),
					itemCount: spList.length + 1,
					itemBuilder: (BuildContext context, int i) {
						if(i == spList.length) return Container(height: 60);
						MapEntry<String,Product> removed;

						ProductWidget product = ProductWidget(spListEntries[i].value);
						return Dismissible(
							key: Key('$i${spList.length}'),
							child: product,
							onDismissed: (direction) => setState(() {
								removed = spListEntries.removeAt(i);
								spList.remove(removed.key);

								Scaffold.of(context).showSnackBar(SnackBar(
									content: Text('Item removido'),
									action: SnackBarAction(
										label: 'Desfazer',
										onPressed: () => setState(() =>
											spList.fromEntries(spListEntries..insert(i, removed))
										),
									),
								));
							}),
							background: Container(
								padding: EdgeInsets.symmetric(horizontal: 15),
								alignment: Alignment.centerLeft,
								color: Theme.of(context).colorScheme.error,
								child: Icon(Icons.remove,
									color: Theme.of(context).colorScheme.onError,
								),
							),
							secondaryBackground: Container(
								padding: EdgeInsets.symmetric(horizontal: 15),
								alignment: Alignment.centerRight,
								color: Theme.of(context).colorScheme.error,
								child: Icon(Icons.remove,
									color: Theme.of(context).colorScheme.onError,
								),
							),
						);
					},
				),
				floatingActionButton: Builder(
					builder: (BuildContext context) {
						return FloatingActionButton.extended(
							onPressed: () => showProductBottomSheet(
								context,
								setState,
								_submit,
								'Novo produto',
							),
							tooltip: 'Adicionar',
							icon: Icon(Icons.add),
							label: Text('R\$${total.toStringAsFixed(2)}'),
						);
					},
				),
			)
		);
	}

	bool _submit(
		String name,
		String price,
		String quantity,
		String type,
	) {
		if (name.isEmpty) return false;
		double dprice, dquantity;
		dprice = price.isNotEmpty ? double.parse(price) : 0;
		dquantity = quantity.isNotEmpty ? double.parse(quantity) : 1;

		spList.update(name,
			(value) {
				spList[name].updateData(
					type: type,
					price: dprice,
					quantity: dquantity,
					insertIfAbsent: true,
				);
				return spList[name];
			},
			ifAbsent: () {
					Product product = Product(
						name: name,
					);
					product.addType(
						type: type,
						price: dprice,
						quantity: dquantity,
					);
					return product;
				}
		);
		return true;
	}
}
