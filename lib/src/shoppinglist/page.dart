import 'package:flutter/material.dart';
import 'shoppinglist.dart';
import 'package:Compras/Compras.dart';

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
	DatabaseManager _dbManager = DatabaseManager(ShoppingListDatabase);
	TextEditingController _titleController = TextEditingController();
	ShoppingList list;

	@override
	void didChangeAppLifecycleState(
		AppLifecycleState state
	) {
		if (state == AppLifecycleState.paused) _save();
	}

	@override
	void initState() {
		super.initState();
		WidgetsBinding.instance.addObserver(this);

		list = widget.loadedList ?? ShoppingList();

		_titleController.addListener(_onTitleFocus);
	}

	@override
	void dispose() {
		WidgetsBinding.instance.removeObserver(this);
		super.dispose();
	}

	void _onTitleFocus() {
		_titleController.removeListener(_onTitleFocus);
		_titleController.text = list.title;
		_titleController.selection = TextSelection(
			baseOffset: 0,
			extentOffset: _titleController.text.length
		);
	}

	double get total {
		return list.length > 0 ?
			list.values
				.map((e) => e.total)
				.reduce((val, el) => val + el) : 0;
	}

	void _save() {
		if (list.length > 0)
			_dbManager.insertShoppingList(list);
	}

	@override
	Widget build(BuildContext context) {
		List<MapEntry<String,Product>> listEntries = List.from(list.entries);
		list.title ??= S.of(context).New('female', S.of(context).list);

		return WillPopScope(
			onWillPop: () async {
				_save();
				return true;
			},
			child: Scaffold(
				backgroundColor: Theme.of(context).colorScheme.surface,
				appBar: AppBar(
					title: TextButton(
						child: Text(list.title,
							style: Theme.of(context).textTheme.headline6,
							overflow: TextOverflow.ellipsis,
						),
						onPressed: () {
							void _updateTitle(String newTitle) {
								if (newTitle.isNotEmpty) {
									setState(() => list.title = newTitle);
									Navigator.of(context).pop();
									_titleController.addListener(_onTitleFocus);
								}
							}
							showDialog(
								context: context,
								builder: (context) => AlertDialog(
									title: Text(S.of(context).Rename(S.of(context).list)),
									content: TextField(
										controller: _titleController,
										decoration: InputDecoration(
											border: OutlineInputBorder(),
											isDense: true,
											labelText: S.of(context).New('male', S.of(context).name),
										),
										autofocus: true,
										textCapitalization: TextCapitalization.words,
										textInputAction: TextInputAction.done,
										onSubmitted: (value) => _updateTitle(_titleController.text),
									),
									actions: [
										TextButton(
											child: Text(S.of(context).cancel),
											onPressed: () {
												_titleController.addListener(_onTitleFocus);
												Navigator.of(context).pop();
											},
										),
										TextButton(
											child: Text(S.of(context).OK),
											onPressed: () => _updateTitle(_titleController.text),
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
					itemCount: list.length + 1,
					itemBuilder: (BuildContext context, int i) {
						if (i == list.length) return Container(height: 60);

						List<MapEntry<String,Product>> removed = [];
						ProductWidget product = ProductWidget(listEntries[i].value);
						return Dismissible(
							key: Key('$i${list.length}'),
							child: product,
							onDismissed: (direction) => setState(() {
								removed.add(listEntries.removeAt(i));
								list.remove(removed.last.key);

								Scaffold.of(context).showSnackBar(SnackBar(
									content: Text(S.of(context).Remove('male', toCapitalized(S.of(context).item))),
									action: SnackBarAction(
										label: S.of(context).undo,
										onPressed: () => setState(() =>
											list.fromEntries(listEntries..insert(i, removed.first))
										),
									),
								)).closed.then((reason) {
									if (reason != SnackBarClosedReason.action)
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
								S.of(context).New('male', S.of(context).product),
							),
							tooltip: S.of(context).add,
							icon: Icon(Icons.add),
							label: Text(S.of(context).currency(total.toStringAsFixed(2))),
							backgroundColor: Theme.of(context).colorScheme.secondary,
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

		list.update(name,
			(value) {
				list[name].updateData(
					type: type,
					price: dprice,
					quantity: dquantity,
					insertIfAbsent: true,
				);
				return list[name];
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
