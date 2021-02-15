import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'shoppinglist.dart';

class ShoppingListWidget extends StatelessWidget {
	final ShoppingList list;

	ShoppingListWidget({
		@required this.list,
	}): assert(list != null);

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: EdgeInsets.fromLTRB(15, 10, 15, 0),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				mainAxisSize: MainAxisSize.min,
				children: [
					Row(
						children: [
							Expanded(
								child: Text(
									list.title,
									style: Theme.of(context)
										.textTheme
										.headline6
										.copyWith(fontWeight: FontWeight.bold)
								),
							),
						],
					),
					Container(
						height: 5,
					),
					Text(
						'Modificada em ${DateFormat("dd/MM/yyyy HH:mm").format(list.dateModified)}',
						style: Theme.of(context).textTheme.caption,
					),
					Text(
						'Criada em ${DateFormat("dd/MM/yyyy HH:mm").format(list.dateCreated)}',
						style: Theme.of(context).textTheme.caption,
					),
				],
			),
		);
	}
}
