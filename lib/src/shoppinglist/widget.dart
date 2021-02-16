import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Compras/Compras.dart';

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
						S.of(context).ModifiedIn(
							'female',
							DateFormat(S.of(context).dateformat
						).format(list.dateModified)),
						style: Theme.of(context).textTheme.caption,
					),
					Text(
						S.of(context).CreatedIn(
							'female',
							DateFormat(S.of(context).dateformat
						).format(list.dateCreated)),
						style: Theme.of(context).textTheme.caption,
					),
				],
			),
		);
	}
}
