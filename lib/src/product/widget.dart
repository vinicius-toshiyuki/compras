import 'package:compras/compras.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class ProductWidget extends StatefulWidget {
  ProductWidget(this.child, {@required this.parent, Key key})
      : assert(child != null),
        assert(parent != null),
        super(key: key);

  final Product child;
  final ShoppingListPageState parent;

  @override
  _ProductWidgetState createState() => _ProductWidgetState();
}

class _ProductWidgetState extends State<ProductWidget> with RestorationMixin {
  @override
  String get restorationId => 'ProductWidget${widget.child.name}';

  @override
  void restoreState(RestorationBucket oldBucket, bool initialRestore) {
    registerForRestoration(_expanded, 'expansion state${widget.child.name}');
  }

  RestorableBool _expanded = RestorableBool(false);

  IconData get _expandIcon {
    return _expanded.value ? Icons.expand_less : Icons.expand_more;
  }

  void flipExtended() => setState(() => _expanded.value = !_expanded.value);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    List<Widget> info = [
      TextButton(
        child: Container(
          color: Colors.transparent,
          child: Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 15, 5),
            child: Row(
              children: [
                Padding(
                  padding: theme.buttonTheme.padding,
                  child: Icon(
                    _expandIcon,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.child.name,
                        style: theme.textTheme.headline6.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          NumberFormat.simpleCurrency(decimalDigits: 2)
                              .format(widget.child.total),
                          style: theme.textTheme.subtitle2,
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

    if (_expanded.value)
      info += List.generate(
        data.length,
        (int i) {
          String type = data[i].key;
          ProductData pd = data[i].value;

          Function() onDelete = () => widget.parent.setState(() {
                setState(() {});
                if (widget.child.length > 1)
                  widget.child.remove(type);
                else
                  _expanded.value = false;
              });

          Function(Function()) showDeleteConfirmationDialog = (onAccept) {
            showDialog<void>(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: Text(loc.warning),
                content: Text(loc.mergeTypesText),
                actions: [
                  TextButton(
                    child: Text(loc.no),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  TextButton(
                    child: Text(loc.yes),
                    onPressed: () {
                      onAccept();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          };

          Function() onEdit = () {
            Product.showAddBottomSheet(
              context,
              setState,
              (name, price, quantity, newType) {
                widget.child.name = name;

                double dprice = double.tryParse(price) ?? 0;
                double dquantity = double.tryParse(quantity) ?? 1;

                widget.child.updateData(
                  type: type,
                  price: dprice,
                  quantity: dquantity,
                  insertIfAbsent: true,
                );
                if (!widget.child.renameType(type, newType)) {
                  Navigator.of(context).pop();
                  showDeleteConfirmationDialog(() => setState(
                      () => widget.child.mergeType(into: newType, from: type)));
                  return false;
                }
                return true;
              },
              '${loc.edit} ${loc.product}',
              name: widget.child.name,
              price: pd.price,
              quantity: pd.quantity,
              type: type,
            ).then((val) => widget.parent.setState(() => setState(() {})));
          };

          return Padding(
            padding:
                EdgeInsets.only(left: IconTheme.of(context).size + 50, top: 5),
            child:
                ProductDataWidget(pd, type, onDelete: onDelete, onEdit: onEdit),
          );
        },
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: info,
    );
  }
}
