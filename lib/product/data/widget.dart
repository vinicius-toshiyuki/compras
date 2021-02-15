import 'package:flutter/material.dart';
import 'data.dart';

class ProductDataWidget extends StatelessWidget {
	final ProductData data;
	final String type;
	final Function() onEdit;
	final Function() onDelete;

	ProductDataWidget(
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
