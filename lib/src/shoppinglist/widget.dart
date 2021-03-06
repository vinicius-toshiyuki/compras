import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:compras/compras.dart';

class ShoppingListWidget extends StatelessWidget {
  final ShoppingList list;

  ShoppingListWidget({
    @required this.list,
  }) : assert(list != null);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(15, 10, 15, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(list.title,
                    style: Theme.of(context)
                        .textTheme
                        .headline6
                        .copyWith(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Container(
            height: 5,
          ),
          Text('${loc.modifiedInf} ${DateFormat(loc.dateformat).format(list.dateModified)}',
            style: Theme.of(context).textTheme.caption,
          ),
          Text('${loc.createdInf} ${DateFormat(loc.dateformat).format(list.dateCreated)}',
            style: Theme.of(context).textTheme.caption,
          ),
        ],
      ),
    );
  }
}
