import 'package:flutter/material.dart';
import 'shoppinglist/shoppinglist.dart';
import 'shoppinglist/page.dart';
import 'shoppinglist/widget.dart';
import 'database.dart';

void main() => runApp(ComprasApp());

class ComprasApp extends StatelessWidget {
	final String title = 'Compras';

	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			title: title,
			theme: ThemeData(
				primarySwatch: Colors.blue,
			),
			darkTheme: ThemeData.dark(),
			home: DividerTheme(
				child: ComprasHomePage(title: title),
				data: DividerTheme.of(context).copyWith(
					indent: 15,
					endIndent: 15,
					space: 0,
				),
			),
			routes: <String, WidgetBuilder> {
				ShoppingListPage.routeName: (BuildContext context) {
					final Map<String,dynamic> args = ModalRoute.of(context).settings.arguments ?? Map();
					return ShoppingListPage(
						loadedList: args.putIfAbsent('loadedList', () => null),
					);
				},
			},
			debugShowCheckedModeBanner: false,
		);
	}
}

class ComprasHomePage extends StatefulWidget {
	final String title;

	ComprasHomePage({
		@required this.title,
	});

	_ComprasHomePageState createState() => _ComprasHomePageState();
}

class _ComprasHomePageState extends State<ComprasHomePage> {
	List<ShoppingList> shoppingLists;
	DatabaseManager _dbManager = DatabaseManager(ShoppingListDatabase);

	@override
	void initState() {
		_updateLists();
		super.initState();
	}

	void _updateLists() {
		_dbManager.getShoppingLists().then((val) => setState((){
			int i = 0;
			shoppingLists = val
				..sort((list1, list2) => list1.order?.compareTo(list2.order ?? double.infinity) ?? -1)
				..forEach((list) {
					while(val.any((list) => list.order == i)) i++;
					list.order ??= i++;
				})
				..sort((list1, list2) => list1.order.compareTo(list2.order));
		}));
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				leading: Icon(Icons.local_grocery_store),
				title: Text(widget.title,
					overflow: TextOverflow.ellipsis,
				),
				// actions: [
				// 	IconButton(
				// 		icon: Icon(Icons.delete),
				// 		onPressed: () => _dbManager.delete(),
				// 	),
				// ],
			),
			body: ReorderableListView(
				onReorder: (oldIndex, newIndex) => setState(() {
					final moved = shoppingLists.removeAt(oldIndex);
					if(newIndex > shoppingLists.length)
						newIndex = shoppingLists.length;
					shoppingLists.insert(newIndex, moved);

					List<int> idxs = [oldIndex, newIndex]..sort();

					int i = idxs.first;
					for(final list in shoppingLists
						..getRange(idxs.first, idxs.last + 1)
						..forEach((list) => list.order = i++)
						..getRange(idxs.first, idxs.last + 1))
						_dbManager.insertShoppingList(list);
				}),
				children: List<Widget>.generate(
					shoppingLists?.length ?? 0,
					(int i) {
						return Column(
							key: Key('Coluna${i}Lista${shoppingLists[i].id}'),
							mainAxisSize: MainAxisSize.min,
							children: <Widget>[
								Dismissible(
									key: Key('Lista${shoppingLists[i].id}'),
									child: TextButton(
										child: ShoppingListWidget(
											list: shoppingLists[i]
										),
										onPressed: () {
											Navigator.of(context).pushNamed(
												ShoppingListPage.routeName,
												arguments: {
													'loadedList': shoppingLists[i],
												}
											).then((val) {
												if(shoppingLists[i].length == 0)
													_dbManager.deleteShoppingList(shoppingLists[i].id);
												_updateLists();
											});
										},
									),
									onDismissed: (direction) {
										_dbManager.deleteShoppingList(shoppingLists.removeAt(i).id).then(
											(val) => setState(() {})
										);
									},
									background: Container(
										height: 50,
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
								),
							] + (i == shoppingLists.length - 1 ? [] : [Divider()]),
						);
					},
				),
			),
			floatingActionButton: FloatingActionButton(
				child: Icon(Icons.add),
				tooltip: 'Criar nova lista de compras',
				onPressed: () {
					Navigator.of(context)
						.pushNamed(ShoppingListPage.routeName)
						.then((val) => _updateLists());
				},
			),
		);
	}
}
