import 'dart:collection';

import 'package:compras/compras.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Product extends MapBase<String, ProductData> {
  Map<String, ProductData> data;

  ProductData operator [](Object key) => data[key];
  void clear() => data.clear();
  void operator []=(Object key, ProductData val) => data[key] = val;
  ProductData remove(Object key) => data.remove(key);
  get keys => data.keys;

  String name;
  int order;

  Product({
    @required this.name,
    this.order,
  }) {
    data = Map();
  }

  double get total => length > 0
      ? values.map((val) => val.total).reduce((val, el) => val + el)
      : 0;

  void addType({
    @required String type,
    double price = 0,
    double quantity = 1,
  }) {
    if (containsKey(type))
      throw 'Type "$type" already exists, use "updateData()".';
    data[type] = ProductData(
      type: type,
      price: price,
      quantity: quantity,
    );
  }

  void updateData({
    @required String type,
    double price = 0,
    double quantity = 1,
    bool insertIfAbsent = false,
  }) {
    if (containsKey(type)) {
      this[type].price = price;
      this[type].quantity = quantity;
    } else if (insertIfAbsent)
      addType(type: type, price: price, quantity: quantity);
    else
      throw 'Type "$type" does not exist, use "addType()".';
  }

  bool renameType(
    String type,
    String newType,
  ) {
    if (containsKey(type) && !containsKey(newType)) {
      this[newType] = remove(type);
      return true;
    }
    return type == newType;
  }

  void mergeType({
    @required String into,
    @required String from,
  }) {
    if (!containsKey(into) || !containsKey(from))
      throw 'Invalid values ($into, $from) in "mergeType()"';
    this[into].quantity += this[from].quantity;
    remove(from);
  }

  Map<String, dynamic> toDBMap() {
    return {
      DatabaseManager.productName: name,
      DatabaseManager.order: order,
    };
  }

  @override
  String toString() => 'Produto $name';

  static Future<void> showAddBottomSheet(
    context,
    Function(
      VoidCallback fn,
    )
        setState,
    bool Function(
      String name,
      String price,
      String quantity,
      String type,
    )
        submit,
    String title, {
    String name = '',
    double price = 0,
    double quantity = 1,
    String type = '',
  }) {
    TextEditingController nameController = TextEditingController();
    TextEditingController priceController = TextEditingController();
    TextEditingController quantityController = TextEditingController();
    TextEditingController typeController = TextEditingController();

    nameController.text = name;
    quantityController.text = quantity == 1
        ? '1'
        : quantity
            .toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 2);
    priceController.text = price == 0 ? '' : price.toString();
    typeController.text = type;

    void selectNameCallback() {
      nameController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: nameController.text.length,
      );
      nameController.removeListener(selectNameCallback);
    }

    nameController.addListener(selectNameCallback);
    void selectPriceCallback() {
      priceController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: priceController.text.length,
      );
      priceController.removeListener(selectPriceCallback);
    }

    priceController.addListener(selectPriceCallback);
    void selectQuantityCallback() {
      quantityController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: quantityController.text.length,
      );
      quantityController.removeListener(selectQuantityCallback);
    }

    quantityController.addListener(selectQuantityCallback);
    void selectTypeCallback() {
      typeController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: typeController.text.length,
      );
      typeController.removeListener(selectTypeCallback);
    }

    typeController.addListener(selectTypeCallback);

    final Icon checkIcon = Icon(
      Icons.check,
      color: Colors.green,
    );
    final Icon errorIcon = Icon(
      Icons.error,
      color: Theme.of(context).errorColor,
    );

    bool validNumbers() {
      bool validPrice =
          priceController.text.replaceAll(',', '.').split('.').length <= 2;
      bool validQuantity =
          quantityController.text.replaceAll(',', '.').split('.').length <= 2;
      return validPrice && validQuantity;
    }

    bool expanded = false;
    bool valid = true;

    Icon confirmIcon() => valid ? checkIcon : errorIcon;

    return showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          final loc = AppLocalizations.of(context);
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setSheetState) {
            bool _submit() {
              priceController.text = priceController.text.replaceAll(',', '.');
              quantityController.text =
                  quantityController.text.replaceAll(',', '.');
              bool passed = submit(
                nameController.text,
                priceController.text,
                quantityController.text,
                typeController.text,
              );
              valid = passed;
              return passed;
            }

            /* = Create and set up text fields ====== */
            TextField nameField = TextField(
              controller: nameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                labelText: toCapitalized(loc.name),
              ),
              autofocus: true,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              onChanged: (value) => setSheetState(
                  () => valid = value.isNotEmpty && validNumbers()),
            );

            TextField priceField = TextField(
              controller: priceController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                labelText: toCapitalized(loc.price),
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onChanged: (value) => setSheetState(() =>
                  valid = nameController.text.isNotEmpty && validNumbers()),
            );

            TextField quantityField = TextField(
              controller: quantityController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                labelText: toCapitalized(loc.quanity),
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onChanged: (value) => setSheetState(() =>
                  valid = nameController.text.isNotEmpty && validNumbers()),
              onSubmitted: (value) => setState(() {
                if (valid && _submit()) Navigator.of(context).pop();
              }),
            );

            TextField typeField = TextField(
              controller: typeController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                labelText: toCapitalized(loc.type),
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (value) => setState(() {
                if (valid && _submit()) Navigator.of(context).pop();
              }),
            );
            /* ===================================== */

            return Padding(
              padding: EdgeInsets.all(15.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                      Container(
                        alignment: Alignment.topRight,
                        child: TextButton.icon(
                          onPressed: () => setState(() {
                            if (valid && _submit()) Navigator.of(context).pop();
                          }),
                          label: Text(loc.confirm),
                          icon: confirmIcon(),
                        ),
                      ),
                      Text(
                        '$title',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(0, 15, 0, 5),
                        child: nameField,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                                padding: EdgeInsets.only(right: 5),
                                child: priceField),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: 5),
                              child: quantityField,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          expanded ? Icons.expand_more : Icons.expand_less,
                          color: Theme.of(context)
                              .iconTheme
                              .color
                              .withOpacity(0.54),
                        ),
                        onPressed: () => setSheetState(() {
                          FocusScope.of(context)
                              .requestFocus(nameField.focusNode);
                          expanded = !expanded;
                        }),
                        splashRadius: 20,
                      ),
                    ] +
                    (expanded
                        ? <Widget>[
                            Padding(
                              padding: EdgeInsets.fromLTRB(5, 5, 5, 0),
                              child: typeField,
                            ),
                          ]
                        : <Widget>[]),
              ),
            );
          });
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(15),
          ),
        ),
        isScrollControlled: true,
        backgroundColor: Theme.of(context).colorScheme.surface);
  }
}
