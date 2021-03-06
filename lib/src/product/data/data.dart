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
  String toString() => 'Tipo $type, P: $price, Q: $quantity';
}
