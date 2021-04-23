import 'dart:io' show Platform;
import 'package:compras/compras.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

import 'shoppinglist.dart';

class _RestorableShoppingList extends RestorableValue<ShoppingList> {
  final ShoppingList defaultValue;
  final ShoppingListPageState pageState;
  List<ProductWidget> products;
  List<MapEntry<String, Product>> _entries;
  List<MapEntry<String, Product>> _hidden = [];

  _RestorableShoppingList(this.defaultValue, this.pageState);

  @override
  ShoppingList createDefaultValue() {
    _entries = List.from(defaultValue.entries);
    products = List.generate(_entries.length, (int i) {
      return ProductWidget(_entries[i].value, parent: pageState);
    });
    return defaultValue;
  }

  @override
  void didUpdateValue(ShoppingList oldValue) {
    if (oldValue == null || oldValue != value) {
      notifyListeners();
    }
  }

  @override
  ShoppingList fromPrimitives(Object data) {
    _entries = (data as List<Object>)[0];
    products = (data as List<Object>)[1];
    return (data as List<Object>)[2];
  }

  @override
  Object toPrimitives() {
    return [_entries, products, value];
  }

  void swap(int oldIndex, int newIndex) {
    final moved = _entries.removeAt(oldIndex);
    final movedWidget = products.removeAt(oldIndex);
    if (newIndex > oldIndex) newIndex--;
    _entries.insert(newIndex, moved);
    products.insert(newIndex, movedWidget);
    for (var i = 0; i < products.length; i++) {
      products[i].child.order = i;
    }
  }

  void hide(int i) {
    _hidden.add(_entries.removeAt(i));
    value.remove(_hidden.last.key);
    products.removeAt(i);
  }

  void unhide(int i) {
    // TODO: Colocando no penúltimo se voltar o último quando esconde mais de um
    i = i > _entries.length ? _entries.length : i;
    _entries.insert(i, _hidden.removeAt(0));
    value.addEntries([_entries[i]]);
    products.insert(i, ProductWidget(_entries[i].value, parent: pageState));
  }

  void update(String name, Product Function(Product) update,
      {Product Function() ifAbsent}) {
    value.update(name, update, ifAbsent: () {
      final product = ifAbsent();
      _entries.add(MapEntry(name, product));
      products.add(ProductWidget(_entries.last.value, parent: pageState));
      return product;
    });
  }
}

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
    with WidgetsBindingObserver, RestorationMixin {
  DatabaseManager _dbManager = DatabaseManager(ShoppingListDatabase);
  TextEditingController _titleController = TextEditingController();
  _RestorableShoppingList list;

  @override
  String get restorationId => ShoppingListPage.routeName;

  @override
  void restoreState(RestorationBucket oldBucket, bool initialRestore) {
    registerForRestoration(list, 'shopping list');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _save();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    list = _RestorableShoppingList(widget.loadedList ?? ShoppingList(), this);

    _titleController.addListener(_onTitleFocus);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    list.dispose();
    super.dispose();
  }

  void _onTitleFocus() {
    _titleController.removeListener(_onTitleFocus);
    _titleController.text = list.value.title;
    _titleController.selection = TextSelection(
        baseOffset: 0, extentOffset: _titleController.text.length);
  }

  double get total {
    return list.value.length > 0
        ? list.value.values.map((e) => e.total).reduce((val, el) => val + el)
        : 0;
  }

  Future<void> _save() async {
    if (list.value.length > 0) await _dbManager.insertShoppingList(list.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    list.value.title ??= '${loc.newf} ${loc.list}';
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    var listTitle = TextButton(
      child: Text(
        list.value.title,
        style: theme.textTheme.headline6,
        overflow: TextOverflow.ellipsis,
      ),
      onPressed: () {
        void _updateTitle(String newTitle) {
          if (newTitle.isNotEmpty) {
            setState(() => list.value.title = newTitle);
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
              onSubmitted: (value) => _updateTitle(_titleController.text),
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
    );
    return WillPopScope(
        onWillPop: () async {
          await _save();
          scaffoldMessenger.removeCurrentSnackBar();
          return true;
        },
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            title: listTitle,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                    tooltip: loc.share,
                    icon: Icon(Icons.share),
                    onPressed: () {
                      final textData = _getListTextData();
                      if (Platform.isIOS || Platform.isAndroid) {
                        Share.share(textData, subject: list.value.title);
                      } else {
                        showDialog(
                                context: context,
                                builder: (context) {
                                  return Dialog(
                                      child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(loc.shareText),
                                        Container(
                                          height: 200,
                                          padding: const EdgeInsets.all(8.0),
                                          child: Align(
                                            alignment: Alignment.topLeft,
                                            child: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SelectableText.rich(
                                                    TextSpan(
                                                      text: list.value.title +
                                                          '\n',
                                                      style: theme
                                                          .textTheme.headline6,
                                                      children: [
                                                        TextSpan(
                                                            text: textData,
                                                            style: theme
                                                                .textTheme
                                                                .bodyText2),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        // TODO: Os métodos não funcionam no desktop ainda
                                        // ElevatedButton(
                                        //     style: ButtonStyle(
                                        //       backgroundColor:
                                        //           MaterialStateProperty.all(
                                        //               theme.colorScheme.secondary),
                                        //     ),
                                        //     onPressed: () {
                                        //       Navigator.of(context).pop(true);
                                        //     },
                                        //     child: Text(loc.share,
                                        //         style: theme.textTheme.button
                                        //             .copyWith(
                                        //                 color: theme.colorScheme
                                        //                     .onSecondary)))
                                      ],
                                    ),
                                  ));
                                })
                            // .then((value) {
                            //   if (value == true) {
                            //     // Share.share(textData, subject: list.value.title);
                            //     var uri = Uri(scheme: 'mailto', queryParameters: {
                            //       'subject': list.value.title,
                            //       'body': textData,
                            //     });
                            //     print(uri.toString());
                            //     launch(uri.toString());
                            //   }
                            // })
                            ;
                      }
                    }),
              )
            ],
          ),
          body: ReorderableListView.builder(
            restorationId: 'ShoppingListPage${list.value.id}',
            padding: const EdgeInsets.only(bottom: 60),
            onReorder: (oldIndex, newIndex) {
              list.swap(oldIndex, newIndex);
            },
            buildDefaultDragHandles: false,
            itemCount: list.value.length,
            itemBuilder: (BuildContext context, int i) {
              return ReorderableDelayedDragStartListener(
                key: Key(
                    '$i${list.value.id}${list.products[i].child.name}dragHandle'),
                index: i,
                child: Dismissible(
                  key: Key('$i${list.value.id}${list.products[i].child.name}'),
                  child: list.products[i],
                  onDismissed: (direction) => setState(() {
                    list.hide(i);
                    scaffoldMessenger.showSnackBar(SnackBar(
                      content:
                          Text('${toCapitalized(loc.item)} ${loc.removem}'),
                      action: SnackBarAction(
                        label: loc.undo,
                        onPressed: () => setState(() {
                          list.unhide(i);
                          scaffoldMessenger.hideCurrentSnackBar();
                        }),
                      ),
                    ));
                  }),
                  background: Container(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    alignment: Alignment.centerLeft,
                    color: theme.colorScheme.error,
                    child: Icon(
                      Icons.remove,
                      color: theme.colorScheme.onError,
                    ),
                  ),
                  secondaryBackground: Container(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    alignment: Alignment.centerRight,
                    color: theme.colorScheme.error,
                    child: Icon(
                      Icons.remove,
                      color: theme.colorScheme.onError,
                    ),
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
                ).then((val) => setState(() {})),
                tooltip: loc.add,
                icon: Icon(Icons.add),
                label: Text(NumberFormat.simpleCurrency(decimalDigits: 2)
                    .format(total)),
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
      list.value[name].updateData(
        type: type,
        price: dprice,
        quantity: dquantity,
        insertIfAbsent: true,
      );
      int idx = list.products
          .indexWhere((ProductWidget widget) => widget.child.name == name);
      list.products
        ..removeAt(idx)
        ..insert(idx, ProductWidget(list.value[name], parent: list.pageState));
      return list.value[name];
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

  String _getListTextData() {
    var products = [];
    for (var prdt in list.products) {
      var prdtText = [prdt.child.name];
      for (var data in prdt.child.values) {
        prdtText.add(data.toString());
      }
      products.add(prdtText.join(', '));
    }
    return products.join('\n');
  }
}
