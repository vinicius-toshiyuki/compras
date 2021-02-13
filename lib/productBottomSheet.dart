import 'package:flutter/material.dart';

final Icon _checkIcon = Icon(
	Icons.check,
	color: Colors.green,
);
final Icon _errorIcon = Icon(
	Icons.error,
	color: Colors.red,
);

void showProductBottomSheet(
	context,
	Function(
		VoidCallback fn,
	) setState,
	bool Function(
		String name,
		String price,
		String quantity,
		String type,
	) submit,
	String title,
	{String name = '',
	double price = 0,
	double quantity = 1,
	String type = '',
	}) {

	TextEditingController nameController = TextEditingController();
	TextEditingController priceController = TextEditingController();
	TextEditingController quantityController = TextEditingController();
	TextEditingController typeController = TextEditingController();

	nameController.text = name;
	quantityController.text = quantity == 1 ? '1' : quantity
		.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 2);
	priceController.text = price == 0 ? '' : price.toString();
	typeController.text = type;

	Icon confirmIcon = _checkIcon;

	bool expanded = false;

	showModalBottomSheet<void>(
		context: context,
		builder: (BuildContext context) {
			return StatefulBuilder(
				builder: (BuildContext context, StateSetter setSheetState) {
					bool _submit() {
						bool passed = submit(
							nameController.text,
							priceController.text,
							quantityController.text,
							typeController.text,
						);
						confirmIcon = passed ? _checkIcon : _errorIcon;
						return passed;
					}

					TextField nameField = TextField(
						controller: nameController,
						decoration: InputDecoration(
							border: OutlineInputBorder(),
							isDense: true,
							labelText: 'Nome',
						),
						textInputAction: TextInputAction.next,
						textCapitalization: TextCapitalization.words,
						onChanged: (value) => setSheetState(() =>
							confirmIcon = value.isEmpty ? _errorIcon : _checkIcon
						),
					);

					TextField priceField = TextField(
							controller: priceController,
							decoration: InputDecoration(
								border: OutlineInputBorder(),
								isDense: true,
								labelText: 'Preço',
							),
							keyboardType: TextInputType.number,
							textInputAction: TextInputAction.next,
						);

					TextField quantityField = TextField(
						controller: quantityController,
						decoration: InputDecoration(
							border: OutlineInputBorder(),
							isDense: true,
							labelText: 'Quantidade',
						),
						keyboardType: TextInputType.number,
						textInputAction: TextInputAction.done,
						onSubmitted: (value) => setState(() =>
							_submit() ? Navigator.of(context).pop() : null
						),
					);

					TextField typeField = TextField(
						controller: typeController,
						decoration: InputDecoration(
							border: OutlineInputBorder(),
							isDense: true,
							labelText: 'Marca/tipo',
						),
						textCapitalization: TextCapitalization.words,
						textInputAction: TextInputAction.done,
						onSubmitted: (value) => setState(() =>
							_submit() ? Navigator.of(context).pop() : null
						),
					);

					return Padding(
						padding: EdgeInsets.all(15.0),
						child: Column(
							mainAxisAlignment: MainAxisAlignment.start,
							mainAxisSize: MainAxisSize.min,
							children: [
								Container(
									alignment: Alignment.topRight,
									child: TextButton.icon(
										onPressed: () => setState(() =>
											_submit() ? Navigator.of(context).pop() : null
										),
										label: Text('Confirmar'),
										icon: confirmIcon,
									),
								),
								Text('$title',
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
												child: priceField
											),
										),
										Expanded(
											child: Padding(
												padding: EdgeInsets.only(left: 5),
												child: quantityField,
											),
										),
									],
								),
								Padding(
									padding: EdgeInsets.only(bottom: expanded ? 0 : MediaQuery.of(context).viewInsets.bottom),
									child: IconButton(
										icon: Icon(
											expanded ? Icons.expand_more : Icons.expand_less,
											color: Theme.of(context).iconTheme.color.withOpacity(0.54),
										),
										onPressed: () => setSheetState(() {
											FocusScope.of(context).requestFocus(nameField.focusNode);
											expanded = !expanded;
										}),
										splashRadius: 20,
									),
								),
							] + (expanded ? <Widget>[
								Padding(
									padding: EdgeInsets.fromLTRB(5, 5, 5, MediaQuery.of(context).viewInsets.bottom),
									child: typeField,
								),
							] : <Widget>[]),
						),
					);
				}
			);
		},
		shape: RoundedRectangleBorder(
			borderRadius: BorderRadius.vertical(
				top: Radius.circular(15),
			),
		),
		isScrollControlled: true,
	).then((value) {
		// nameController.dispose();
		// priceController.dispose();
		// quantityController.dispose();
		// typeController.dispose();
	});
}

