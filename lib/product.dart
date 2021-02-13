import 'package:flutter/material.dart';
import 'productBottomSheet.dart';
import 'database.dart';
import 'dart:collection';

class ProductData {
	String _type;
	double quantity, price;

	ProductData({
		@required String type,
		@required this.price,
		@required this.quantity,
	}): this._type = type,
		assert(price != null),
		assert(quantity != null);


	double get total {
		return quantity * price;
	}

	String get type {
		return _type;
	}

	Map<String,dynamic> toDBMap() {
		return {
			DatabaseManager.productDataType: type,
			DatabaseManager.productDataPrice: price,
			DatabaseManager.productDataQuantity: quantity,
		};
	}

	@override
	String toString() => 'Tipo $type, P: $price, Q: $quantity';
}

class _ProductDataWidget extends StatelessWidget {
	final ProductData data;
	final String type;
	final Function() onEdit;
	final Function() onDelete;

	_ProductDataWidget(
		this.data,
		this.type,
		{@required this.onEdit,
		@required this.onDelete,
	});

	@override
	Widget build(BuildContext context) {
		String quantity = data.quantity.toStringAsFixed(
			data.quantity.truncateToDouble() == data.quantity ? 0 : 2
		);
		String price = data.price.toStringAsFixed(2);

		TextStyle nameStyle = Theme.of(context).textTheme.subtitle2.copyWith(
			fontWeight: FontWeight.bold,
		);

		TextStyle dataStyle = Theme.of(context).textTheme.caption.copyWith(
			fontWeight: FontWeight.w600,
		);

		List<Widget> values = [Text('$quantity × R\$$price', style: dataStyle)];
		if(type.isNotEmpty) values.insert(0, Text('$type', style: nameStyle));

		return Row(
			children: [
				Expanded(
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: values,
					),
				),
				IconButton(
					padding: EdgeInsets.symmetric(vertical: 8),
					icon: Icon(Icons.edit), color: Theme.of(context).colorScheme.secondary,
					onPressed: onEdit,
				),
				IconButton(
					padding: EdgeInsets.symmetric(vertical: 8),
					icon: Icon(Icons.remove_circle),
					color: Theme.of(context).colorScheme.error,
					onPressed: onDelete,
				),
			],
		);
	}
}

class Product extends MapBase<String,ProductData> {
	Map<String,ProductData> data;

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

	double get total =>
		length > 0 ?
		values.map(
			(val) => val.total
		).reduce(
			(val, el) => val + el
		) : 0;

	void addType({
		@required String type,
		double price = 0,
		double quantity = 1,
	}) {
		if(containsKey(type))
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
		if(containsKey(type)) {
			data[type].price = price;
			data[type].quantity = quantity;
		} else if (insertIfAbsent)
			addType(type: type, price: price, quantity: quantity);
		else
			throw 'Type "$type" does not exist, use "addType()".';
	}

	bool renameType(
		String type,
		String newType,
	) {
		if(containsKey(type) && !containsKey(newType)) {
			data[newType] = remove(type);
			return true;
		}
		return type == newType;
	}

	void mergeType({
		@required String into,
		@required String from,
	}) {
		if(!containsKey(into) || !containsKey(from))
			throw 'Invalid values ($into, $from) in "mergeType()"';
		data[into].quantity += data[from].quantity;
		remove(from);
	}

	Map<String,dynamic> toDBMap() {
		return {
			DatabaseManager.productName: name,
			DatabaseManager.order: order,
		};
	}
	
	@override
	String toString() => 'Produto $name';
}

class ProductWidget extends StatefulWidget {
	ProductWidget(this.child, {Key key}) : assert(child != null), super(key: key);

	final Product child;

	@override
	_ProductWidget createState() => _ProductWidget();
}

class _ProductWidget extends State<ProductWidget> {
	bool _expanded = false;

	IconData get _expandIcon {
		return _expanded ? Icons.expand_less : Icons.expand_more;
	}

	void flipExtended() => setState(() => _expanded = !_expanded);

	@override
	Widget build(BuildContext context) {
		List<Widget> info = [
			TextButton(
				child: Container(
					color: Colors.transparent,
					child: Padding(
						padding: EdgeInsets.fromLTRB(10, 10, 15, 5),
						child: Row(
							children: [
								Padding(
									padding: Theme.of(context).buttonTheme.padding,
									child: Icon(
										_expandIcon,
										color: Theme.of(context).colorScheme.secondary,
									),
								),
								Expanded(child:
								Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(widget.child.name,
											style: Theme.of(context).textTheme.headline6.copyWith(
												fontWeight: FontWeight.bold,
											),
										),
										Padding(
											padding: EdgeInsets.only(top: 2),
											child: Text('R\$${widget.child.total.toStringAsFixed(2)}',
												style: Theme.of(context).textTheme.subtitle2,
											),
										),
									],
								),
								),
							],
						),
					),
				),
				onPressed: flipExtended,
			),
		];

		List data = List.from(widget.child.entries);
	
		if(_expanded) info += List.generate(
			data.length,
			(int i) {
				String type = data[i].key;
				ProductData pd = data[i].value;

				Function() onDelete = () => setState(() {
					if(widget.child.length > 1)
						widget.child.remove(type);
					else
						_expanded = false;
				});

				Function(Function()) showDeleteConfirmationDialog = (onAccept) {
					showDialog<void>(
						context: context, // talvez tenha que ficar mais detnro??
						builder: (BuildContext context) => AlertDialog(
							title: Text('Atenção'),
							content: Text(
								'Esta marca/tipo já existe.' +
								'Deseja juntar as marcas/tipos duplicados?'
							),
							actions: [
								TextButton(
									child: Text('Não'),
									onPressed: () => Navigator.of(context).pop(),
								),
								TextButton(
									child: Text('Sim'),
									onPressed: () {
										onAccept();
										Navigator.of(context).pop();
									},
								),
							],
						),
					);
				};

				Function() onEdit = () => setState(() {
					showProductBottomSheet(
						context,
						setState,
						(name, price, quantity, newType) { 
							if(name.isEmpty) return false;
							widget.child.name = name;
							double dprice, dquantity;

							if(price.isNotEmpty) dprice = double.parse(price);
							if(quantity.isNotEmpty) dquantity = double.parse(quantity);

							widget.child.updateData(
								type: type,
								price: dprice ?? 0,
								quantity: dquantity ?? 1,
								insertIfAbsent: true,
							);
							if(!widget.child.renameType(type, newType)) {
								Navigator.of(context).pop();
								showDeleteConfirmationDialog(() => setState(() =>
									widget.child.mergeType(into: newType, from: type)
								));
								return false;
							}
							return true;
						 },
						'Editar produto',
						name: widget.child.name,
						price: pd.price,
						quantity: pd.quantity,
						type: type,
					);
				});

				return Padding(
					padding: EdgeInsets.only(left: IconTheme.of(context).size + 50, top: 5),
					child: _ProductDataWidget(pd, type, onDelete: onDelete, onEdit: onEdit),
				);
			},
		);

		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: info,
		);
	}
}
