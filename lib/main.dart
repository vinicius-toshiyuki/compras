import 'dart:math' as Math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Compras/Compras.dart';

void main() => runApp(ComprasApp());

class ComprasApp extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			localizationsDelegates: [
				S.delegate,
				GlobalMaterialLocalizations.delegate,
				GlobalWidgetsLocalizations.delegate,
			],
			supportedLocales: S.delegate.supportedLocales,
			theme: ThemeData(
				primarySwatch: Colors.cyan,
				textTheme: GoogleFonts.balooChettanTextTheme(),
			),
			darkTheme: ThemeData.dark().copyWith(
				textTheme: GoogleFonts.balooChettanTextTheme().apply(
					displayColor: ThemeData.dark().textTheme.headline1.color,
					bodyColor: ThemeData.dark().textTheme.bodyText1.color,
				),
			),
			home: DividerTheme(
				child: ComprasHomePage(),
				data: DividerTheme.of(context).copyWith(
					indent: 15,
					endIndent: 15,
					space: 0,
				),
			),
			onGenerateRoute: (settings) {
				// if (settings.name == ShoppingListPage.routeName);
				return PageRouteBuilder(
					barrierColor: Colors.black26,
					opaque: true,
					pageBuilder: (context, animation, secondaryAnimation) {
						final Map<String,dynamic> args = ModalRoute.of(context).settings.arguments ?? Map();
						return ShoppingListPage(
							loadedList: args.putIfAbsent('loadedList', () => null),
						);
					},
					transitionsBuilder: (context, animation, secondaryAnimation, child) {
						return SlideTransition(
							position: Tween<Offset>(
								begin: Offset(1, 0),
								end: Offset.zero,
							).animate(animation),
							child: child
						);
					},
				);
			},
			debugShowCheckedModeBanner: false,
		);
	}
}

class ComprasHomePage extends StatefulWidget {
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
		Widget title = Stack(
			alignment: Alignment.center,
			children: [
				Positioned(
					top: 12,
					right: 0,
					height: 40.0,
					width: 40.0,
					child: ImageFiltered(
						imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
						child: Transform.rotate(
							angle: Math.pi / 180 * 25,
							alignment: Alignment.center,
							child: Image.asset('res/images/logo_android.png',
								color: Theme.of(context).colorScheme.surface.withOpacity(0.75),
							),
						),
					),
				),
				Positioned(
					top: 12,
					right: 0,
					height: 40.0,
					width: 40.0,
					child: Transform.rotate(
						angle: Math.pi / 180 * 25,
						alignment: Alignment.center,
						child: Image.asset('res/images/logo_android.png'),
					),
				),
				Row(
					mainAxisSize: MainAxisSize.min,
					children: [
						RichText(
							text: TextSpan(
								text: S.of(context).title[0],
								style: Theme.of(context).textTheme.headline6.copyWith(
									fontFamily: 'Rosanna',
									fontSize: 64,
								),
								children: [
									TextSpan(
										text: S.of(context).title.substring(1),
										style: Theme.of(context).textTheme.headline6.copyWith(
											fontFamily: 'Rosanna',
											fontSize: 48,
										),
									),
								],
							),
							overflow: TextOverflow.ellipsis,
						),
						SizedBox(width: 15.0),
					],
				),
			],
		);

		return Scaffold(
			backgroundColor: Theme.of(context).colorScheme.surface,
			appBar: AppBar(
				// leading: Padding(
				// 	padding: EdgeInsets.all(8.0),
				// 	child: Container(
				// 		padding: EdgeInsets.all(4),
				// 		child: Image.asset('res/images/logo_android.png'),
				// 		decoration: BoxDecoration(
				// 			color: Colors.white,
				// 			borderRadius: BorderRadius.all(Radius.circular(25)),
				// 		),
				// 	),
				// ),
				centerTitle: true,
				title: title,
				// actions: [
				// 	IconButton(
				// 		icon: Icon(Icons.delete),
				// 		onPressed: () => _dbManager.delete(),
				// 	),
				// ],
			),
			body: (shoppingLists?.length ?? 0) > 0 ? ReorderableListView(
				header: Container(
					alignment: Alignment.center,
					child: Padding(
						padding: EdgeInsets.all(8.0),
						child: Text(S.of(context).lists_title,
							style: Theme.of(context).textTheme.headline5,
						),
					),
				),
				padding: EdgeInsets.all(8.0),
				onReorder: (oldIndex, newIndex) => setState(() {
					final moved = shoppingLists.removeAt(oldIndex);
					if (newIndex > shoppingLists.length)
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
												if (shoppingLists[i].length == 0) _dbManager.deleteShoppingList(shoppingLists[i].id);
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
			) : Container(
				alignment: Alignment.center,
				child: Opacity(
					child: Column(
						mainAxisAlignment: MainAxisAlignment.center,
						children: [
							Stack(
								alignment: Alignment.center,
								children: [
									SizedBox(width: 140),
									Positioned(
										bottom: 0,
										height: 30,
										width: 140,
										child: Container(
											decoration: BoxDecoration(
												gradient: LinearGradient(
													begin: Alignment.topCenter,
													end: Alignment.bottomCenter,
													colors: [
														Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
														Theme.of(context).colorScheme.onSurface.withOpacity(0.0),
													],
												),
												borderRadius: BorderRadius.only(
													topLeft: Radius.circular(15),
													topRight: Radius.circular(15),
												),
											),
										),
									),
									Padding(
										padding: EdgeInsets.only(bottom: 10.0),
										child: Image.asset('res/images/blob.png',
											width: 100,
											alignment: Alignment.center,
										),
									),
								],
							),
							SizedBox(height: 16.0),
							Text(S.of(context).nothing_to_see,
								style: Theme.of(context).textTheme.headline6,
							),
						],
					),
					opacity: 0.2,
				),
			),
			floatingActionButton: FloatingActionButton(
				child: Icon(Icons.add),
				tooltip: S.of(context).New('female', S.of(context).shoppinglist),
				onPressed: () {
					Navigator.of(context)
						.pushNamed(ShoppingListPage.routeName)
						.then((val) => _updateLists());
				},
				backgroundColor: Theme.of(context).colorScheme.secondary,
			),
		);
	}
}
