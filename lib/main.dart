import 'dart:math' as Math;
import 'dart:ui';
import 'dart:io' show Platform;

import 'package:compras/compras.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:desktop_window/desktop_window.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    final kaushanScriptlicense =
        await rootBundle.loadString('fonts/KaushanScript_OFL.txt');
    final balooChettanlicense =
        await rootBundle.loadString('fonts/BalooChettan_OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], kaushanScriptlicense);
    yield LicenseEntryWithLineBreaks(['google_fonts'], balooChettanlicense);
  });

  runApp(ComprasApp());
}

class ComprasApp extends StatelessWidget {
  final _windowSize = Size(350, 450);

  @override
  Widget build(BuildContext context) {
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      DesktopWindow.setMinWindowSize(_windowSize);
      DesktopWindow.setWindowSize(_windowSize.flipped * 2);
    }
    final theme = Theme.of(context);
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: [
        const Locale('en'),
        const Locale('ja'),
        const Locale('pt'),
        const Locale('pt', 'BR'),
      ],
      theme: ThemeData(
        primarySwatch: Colors.cyan,
        textTheme: GoogleFonts.sourceSansProTextTheme(),
        floatingActionButtonTheme: theme.floatingActionButtonTheme,
      ),
      darkTheme: ThemeData.dark().copyWith(
        textTheme: GoogleFonts.sourceSansProTextTheme().apply(
          displayColor: ThemeData.dark().textTheme.headline1.color,
          bodyColor: ThemeData.dark().textTheme.bodyText1.color,
        ),
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: Colors.cyan.shade600,
        ),
        floatingActionButtonTheme: ThemeData.dark().floatingActionButtonTheme,
      ),
      home: DividerTheme(
        child: ComprasHomePage(),
        data: theme.dividerTheme.copyWith(
          indent: 15,
          endIndent: 15,
          space: 0,
        ),
      ),
      onGenerateRoute: (settings) {
        // if (settings.name == ShoppingListPage.routeName);
        return PageRouteBuilder(
          barrierColor: Colors.black26,
          opaque: true,
          pageBuilder: (context, animation, secondaryAnimation) {
            final Map<String, dynamic> args = settings.arguments ?? Map();
            return ShoppingListPage(
              loadedList: args.putIfAbsent('loadedList', () => null),
            );
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child);
          },
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class ComprasHomePage extends StatefulWidget {
  _ComprasHomePageState createState() => _ComprasHomePageState();
}

class _ComprasHomePageState extends State<ComprasHomePage> {
  List<ShoppingList> shoppingLists;
  DatabaseManager _dbManager = DatabaseManager(ShoppingListDatabase);

  final titleFont = GoogleFonts.kaushanScript();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget title = Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 12,
          right: 0,
          height: 40.0,
          width: 40.0,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Transform.rotate(
              angle: Math.pi / 180 * 25,
              alignment: Alignment.center,
              child: Image.asset(
                'img/logo_android.png',
                color: theme.colorScheme.surface.withOpacity(0.75),
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 0,
          height: 40.0,
          width: 40.0,
          child: Transform.rotate(
            angle: Math.pi / 180 * 25,
            alignment: Alignment.center,
            child: Image.asset('img/logo_android.png'),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                text: loc.title[0],
                style: titleFont.copyWith(
                  fontSize: 40.0,
                ),
                children: [
                  TextSpan(
                    text: loc.title.substring(1),
                    style: titleFont.copyWith(
                      letterSpacing: -2.5,
                      fontSize: 28.0,
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(width: 20.0),
          ],
        ),
      ],
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        title: title,
      ),
      body: FutureBuilder(
          future: _dbManager.getShoppingLists(),
          builder: (BuildContext context,
              AsyncSnapshot<List<ShoppingList>> snapshot) {
            Widget child;
            if (snapshot.hasData && snapshot.data.length > 0) {
              int i = 0;
              shoppingLists = snapshot.data
                ..sort((list1, list2) =>
                    list1.order?.compareTo(list2.order ?? double.infinity) ??
                    -1)
                ..forEach((list) {
                  while (snapshot.data.any((list) => list.order == i)) i++;
                  list.order ??= i++;
                })
                ..sort((list1, list2) => list1.order.compareTo(list2.order));
              child = ReorderableListView.builder(
                proxyDecorator: (child, index, animation) {
                  return Container(
                      child: child,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                        boxShadow: [
                          BoxShadow(
                              blurRadius: animation.value * 6.0,
                              color: Colors.black26,
                              offset: Offset.fromDirection(90, 4)),
                        ],
                      ));
                },
                header: Container(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      loc.lists_title,
                      style: theme.textTheme.headline5,
                    ),
                  ),
                ),
                padding: EdgeInsets.all(8.0),
                onReorder: (oldIndex, newIndex) {
                  final moved = shoppingLists.removeAt(oldIndex);
                  if (newIndex > shoppingLists.length)
                    newIndex = shoppingLists.length;
                  shoppingLists.insert(newIndex, moved);

                  List<int> idxs = [oldIndex, newIndex]..sort();

                  int i = idxs.first;
                  List<Future<void>> insertions = [];
                  for (final list in shoppingLists
                    ..getRange(idxs.first, idxs.last + 1)
                    ..forEach((list) => list.order = i++)
                    ..getRange(idxs.first, idxs.last + 1))
                    insertions.add(_dbManager.insertShoppingList(list));
                  Future.wait(insertions).then((val) => setState(() {}));
                },
                itemCount: shoppingLists?.length ?? 0,
                itemBuilder: (BuildContext context, int i) {
                  return Column(
                    key: Key('Coluna${i}Lista${shoppingLists[i].id}'),
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                          Dismissible(
                            key: Key('Lista${shoppingLists[i].id}'),
                            child: TextButton(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child:
                                    ShoppingListWidget(list: shoppingLists[i]),
                              ),
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                    ShoppingListPage.routeName,
                                    arguments: {
                                      'loadedList': shoppingLists[i],
                                    }).then((val) {
                                  if (shoppingLists[i].length == 0)
                                    _dbManager
                                        .deleteShoppingList(shoppingLists[i].id)
                                        .then((val) => setState(() {}));
                                  else
                                    setState(() {});
                                });
                              },
                            ),
                            onDismissed: (direction) {
                              _dbManager
                                  .deleteShoppingList(
                                      shoppingLists.removeAt(i).id)
                                  .then((val) => setState(() {}));
                            },
                            background: Container(
                              height: 50,
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              alignment: Alignment.centerLeft,
                              color: theme.colorScheme.error,
                              child: Icon(
                                Icons.remove,
                                color: theme.colorScheme.onError,
                              ),
                            ),
                            secondaryBackground: Container(
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              alignment: Alignment.centerRight,
                              color: theme.colorScheme.error,
                              child: Icon(
                                Icons.remove,
                                color: theme.colorScheme.onError,
                              ),
                            ),
                          ),
                        ] +
                        (i == shoppingLists.length - 1 ? [] : [Divider()]),
                  );
                },
              );
            } else {
              child = Container(
                alignment: Alignment.center,
                child: Opacity(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(width: 140),
                          Positioned(
                            bottom: 0,
                            height: 30,
                            width: 140,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                    theme.colorScheme.onSurface
                                        .withOpacity(0.0),
                                  ],
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  topRight: Radius.circular(15),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: 10.0),
                            child: Image.asset(
                              'img/blob.png',
                              width: 100,
                              alignment: Alignment.center,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.0),
                      Text(
                        loc.nothing_to_see,
                        style: theme.textTheme.headline6,
                      ),
                    ],
                  ),
                  opacity: 0.2,
                ),
              );
            }
            return child;
          }),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        tooltip: '${loc.newf} ${loc.shoppinglist}',
        onPressed: () {
          Navigator.of(context)
              .pushNamed(ShoppingListPage.routeName)
              .then((val) => setState(() {}));
        },
      ),
    );
  }
}
