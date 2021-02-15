import 'package:flutter/material.dart';
import 'shoppinglist.dart';
import '../database.dart';
import '../product/product.dart';
import '../product/widget.dart';

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
	TextEditingController _controller = TextEditingController();

	void _onTitleFocus() {
		_controller.selection = TextSelection(
			baseOffset: 0,
			extentOffset: _controller.text.length
		);
		_controller.removeListener(_onTitleFocus);
	}

	@override
	void initState() {
		super.initState();
		spList = widget.loadedList ?? ShoppingList();
		spList.title ??= 'Nova lista';
		WidgetsBinding.instance.addObserver(this);
		_controller.text = spList.title;

		_controller.addListener(_onTitleFocus);
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
							showDialog(
								context: context,
								builder: (context) => AlertDialog(
									title: Text('Renomear lista'),
									content: TextField(
										controller: _controller,
										decoration: InputDecoration(
											border: OutlineInputBorder(),
											isDense: true,
											labelText: 'Novo nome',
										),
										autofocus: true,
										textCapitalization: TextCapitalization.words,
										textInputAction: TextInputAction.done,
										onSubmitted: (value) => _updateTitle(_controller.text),
									),
									actions: [
										TextButton(
											child: Text('Cancelar'),
											onPressed: Navigator.of(context).pop,
										),
										TextButton(
											child: Text('OK'),
											onPressed: () => _updateTitle(_controller.text),
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

						List<MapEntry<String,Product>> removed = [];
						ProductWidget product = ProductWidget(spListEntries[i].value);
						return Dismissible(
							key: Key('$i${spList.length}'),
							child: product,
							onDismissed: (direction) => setState(() {
								removed.add(spListEntries.removeAt(i));
								spList.remove(removed.last.key);

								Scaffold.of(context).showSnackBar(SnackBar(
									content: Text('Item removido'),
									action: SnackBarAction(
										label: 'Desfazer',
										onPressed: () => setState(() =>
											spList.fromEntries(spListEntries..insert(i, removed.first))
										),
									),
								)).closed.then((reason) {
									if(reason != SnackBarClosedReason.action)
										removed.remove(0);
								});
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
							onPressed: () => Product.showAddBottomSheet(
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
		dprice = double.tryParse(price) ?? 0;
		dquantity = double.tryParse(quantity) ?? 1;

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
