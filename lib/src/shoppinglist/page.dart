import 'package:compras/compras.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'shoppinglist.dart';

class ShoppingListPage extends StatefulWidget {
  static const routeName = '/shoppingList';

  ShoppingListPage({
    Key key,
    this.loadedList,
  }) : super(key: key);

  final ShoppingList loadedList;

  @override
  ShoppingListPageState createState() => ShoppingListPageState();
}

class ShoppingListPageState extends State<ShoppingListPage>
    with WidgetsBindingObserver {
  DatabaseManager _dbManager = DatabaseManager(ShoppingListDatabase);
  TextEditingController _titleController = TextEditingController();
  ShoppingList list;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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
        baseOffset: 0, extentOffset: _titleController.text.length);
  }

  double get total {
    return list.length > 0
        ? list.values.map((e) => e.total).reduce((val, el) => val + el)
        : 0;
  }

  Future<void> _save() async {
    if (list.length > 0) await _dbManager.insertShoppingList(list);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    List<MapEntry<String, Product>> listEntries = List.from(list.entries);
    list.title ??= '${loc.newf} ${loc.list}';
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return WillPopScope(
        onWillPop: () async {
          await _save();
          scaffoldMessenger.removeCurrentSnackBar();
          return true;
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: TextButton(
              child: Text(
                list.title,
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
                    title: Text('${loc.rename} ${loc.list}'),
                    content: TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        labelText: '${loc.newm} ${loc.name}',
                      ),
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (value) =>
                          _updateTitle(_titleController.text),
                    ),
                    actions: [
                      TextButton(
                        child: Text(loc.cancel),
                        onPressed: () {
                          _titleController.addListener(_onTitleFocus);
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: Text(loc.ok),
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

              List<MapEntry<String, Product>> removed = [];
              ProductWidget product =
                  ProductWidget(listEntries[i].value, parent: this);
              return Dismissible(
                key: Key('$i${list.length}'),
                child: product,
                onDismissed: (direction) => setState(() {
                  removed.add(listEntries.removeAt(i));
                  list.remove(removed.last.key);

                  scaffoldMessenger
                      .showSnackBar(
                        SnackBar(
                          content:
                              Text('${toCapitalized(loc.item)} ${loc.removem}'),
                          action: SnackBarAction(
                              label: loc.undo,
                              onPressed: () => list.fromEntries(
                                  listEntries..insert(i, removed.first))),
                        ),
                      )
                      .closed
                      .then((reason) {
                    if (reason != SnackBarClosedReason.action) {
                      setState(() => removed.remove(0));
                    }
                  });
                }),
                background: Container(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  alignment: Alignment.centerLeft,
                  color: Theme.of(context).colorScheme.error,
                  child: Icon(
                    Icons.remove,
                    color: Theme.of(context).colorScheme.onError,
                  ),
                ),
                secondaryBackground: Container(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  alignment: Alignment.centerRight,
                  color: Theme.of(context).colorScheme.error,
                  child: Icon(
                    Icons.remove,
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
                  '${loc.newm} ${loc.product}',
                ),
                tooltip: loc.add,
                icon: Icon(Icons.add),
                label: Text('${loc.currency}${total.toStringAsFixed(2)}'),
              );
            },
          ),
        ));
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

    list.update(name, (value) {
      list[name].updateData(
        type: type,
        price: dprice,
        quantity: dquantity,
        insertIfAbsent: true,
      );
      return list[name];
    }, ifAbsent: () {
      Product product = Product(
        name: name,
      );
      product.addType(
        type: type,
        price: dprice,
        quantity: dquantity,
      );
      return product;
    });
    return true;
  }
}
