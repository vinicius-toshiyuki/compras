import 'package:flutter/material.dart';
import 'package:compras/compras.dart';

class ProductData {
  String _type;
  double quantity, price;

  ProductData({
    @required String type,
    @required this.price,
    @required this.quantity,
  })  : this._type = type,
        assert(price != null),
        assert(quantity != null);

  double get total {
    return quantity * price;
  }

  String get type {
    return _type;
  }

  Map<String, dynamic> toDBMap() {
    return {
      DatabaseManager.productDataType: type,
      DatabaseManager.productDataPrice: price,
      DatabaseManager.productDataQuantity: quantity,
    };
  }

  @override
  String toString() =>
      '${type.isEmpty ? '' : '($type)'} ' +
      '${quantity == quantity.toInt() ? quantity.toInt() : quantity.toStringAsFixed(2)} ' +
      '\u00d7 ${price.toStringAsFixed(2)}';
}
