import 'dart:io' show Platform;
import 'dart:math' as Math;
import 'dart:ui';

import 'package:compras/compras.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    final kaushanScriptlicense =
        await rootBundle.loadString('fonts/KaushanScript-OFL.txt');
    final balooChettanlicense =
        await rootBundle.loadString('fonts/SourceSansPro-OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], kaushanScriptlicense);
    yield LicenseEntryWithLineBreaks(['google_fonts'], balooChettanlicense);
  });

  runApp(ComprasApp());
}

class ComprasApp extends StatefulWidget {
  @override
  _ComprasAppState createState() => _ComprasAppState();
}

class _ComprasAppState extends State<ComprasApp> {
  final _windowSize = Size(350, 450);

  ThemeMode _brightness = ThemeMode.system;

  void updateTheme() {
    SharedPreferences.getInstance().then((prefs) async {
      setState(() {
        final brightnessStr = prefs.getString(SettingsPage.brightness);
        switch (brightnessStr) {
          case SettingsPage.lightTheme:
            _brightness = ThemeMode.light;
            break;
          case SettingsPage.darkTheme:
            _brightness = ThemeMode.dark;
            break;
          case SettingsPage.systemTheme:
          default:
            _brightness = ThemeMode.system;
            break;
        }
      });
    });
  }

  @override
  void initState() {
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      DesktopWindow.setMinWindowSize(_windowSize);
      DesktopWindow.setWindowSize(_windowSize.flipped * 2);
    }
    updateTheme();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appFont = 'Source Sans Pro';
    return MaterialApp(
      restorationScopeId: 'app',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: [
        const Locale('en'),
        const Locale('ja'),
        const Locale('pt'),
        const Locale('pt', 'BR'),
      ],
      theme: ThemeData(
        primarySwatch: Colors.cyan,
        textTheme: Typography.blackCupertino.apply(fontFamily: appFont),
        floatingActionButtonTheme: theme.floatingActionButtonTheme,
      ),
      darkTheme: ThemeData.dark().copyWith(
        textTheme: Typography.whiteCupertino.apply(
          fontFamily: appFont,
          displayColor: ThemeData.dark().textTheme.headline1.color,
          bodyColor: ThemeData.dark().textTheme.bodyText1.color,
        ),
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: Colors.cyan.shade600,
        ),
        floatingActionButtonTheme: ThemeData.dark().floatingActionButtonTheme,
      ),
      themeMode: _brightness,
      home: DividerTheme(
        child: ComprasHomePage(app: this),
        data: theme.dividerTheme.copyWith(
          indent: 15,
          endIndent: 15,
          space: 0,
        ),
      ),
      onGenerateRoute: (settings) {
        var pageRoute;
        if (settings.name == ShoppingListPage.routeName) {
          pageRoute = PageRouteBuilder(
            barrierColor: Colors.black26,
            opaque: true,
            pageBuilder: (context, animation, secondaryAnimation) {
              final Map<String, dynamic> args = settings.arguments ?? Map();
              return ShoppingListPage(
                loadedList: args.putIfAbsent('loadedList', () => null),
              );
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child);
            },
          );
        } else {
          pageRoute = PageRouteBuilder(
              barrierColor: Colors.black26,
              opaque: true,
              pageBuilder: (context, animation, secondaryAnimation) {
                return SettingsPage();
              },
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child);
              });
        }
        return pageRoute;
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class ComprasHomePage extends StatefulWidget {
  final _ComprasAppState app;
  ComprasHomePage({@required this.app});
  _ComprasHomePageState createState() => _ComprasHomePageState();
}

class _ComprasHomePageState extends State<ComprasHomePage> {
  List<ShoppingList> shoppingLists;
  DatabaseManager _dbManager = DatabaseManager(ShoppingListDatabase);

  final titleFont = TextStyle(fontFamily: 'Kaushan Script');

  @override
  Widget build(BuildContext context) {
    Intl.defaultLocale = Localizations.localeOf(context).toLanguageTag();
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
                tooltip: loc.share,
                icon: Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed(
                    SettingsPage.routeName,
                  )
                      .then((val) {
                    widget.app.updateTheme();
                  });
                }),
          ),
        ],
      ),
      body: FutureBuilder(
          future: _dbManager.getShoppingLists(),
          builder: (BuildContext context,
              AsyncSnapshot<List<ShoppingList>> snapshot) {
            Widget child;
            if (snapshot.hasData && snapshot.data.length > 0) {
              int i = 0;
              // TODO: arrumar essa palhaçada aqui
              shoppingLists = snapshot.data
                ..sort((list1, list2) =>
                    list1.order?.compareTo(list2.order ?? double.infinity) ??
                    -1)
                ..forEach((list) {
                  while (snapshot.data.any((list) => list.order == i)) i++;
                  list.order ??= i++;
                })
                ..sort((list1, list2) => list1.order.compareTo(list2.order));
              final lists = shoppingLists.toList();
              lists.sort((list1, list2) => list1.total.compareTo(list2.total));
              final miny = lists.first.total * 0.8;
              final maxy = lists.last.total * 1.2;
              lists.sort((list1, list2) =>
                  list1.dateCreated.isBefore(list2.dateCreated) ? 0 : 1);
              final interval = 0.1;
              final minx = 1 - interval;
              final maxx = lists.length + interval;
              final currencyFormatter =
                  NumberFormat.simpleCurrency(decimalDigits: 0);
              var chartData = _getGraphData(theme, currencyFormatter, minx,
                  miny, maxx, maxy, interval, lists);
              var listsHeader = Container(
                alignment: Alignment.center,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8.0, top: 16.0),
                  child: Text(
                    loc.lists_title,
                    style: theme.textTheme.headline5,
                  ),
                ),
              );
              child = ReorderableListView.builder(
                restorationId: 'MainPage',
                buildDefaultDragHandles: false,
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
                header: shoppingLists.length > 3
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.only(top: 16.0),
                            child: Text(
                              loc.graph,
                              style: theme.textTheme.headline5,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15.0)),
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary.withOpacity(0.04),
                                  theme.colorScheme.primaryVariant
                                      .withOpacity(0.07),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            width: MediaQuery.of(context).size.width * 0.6,
                            margin: EdgeInsets.only(top: 8.0),
                            padding: EdgeInsets.all(8.0),
                            child: AspectRatio(
                              aspectRatio: 4 / 3,
                              child: LineChart(chartData),
                            ),
                          ),
                          listsHeader,
                        ],
                      )
                    : listsHeader,
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
                  return ReorderableDelayedDragStartListener(
                    key: Key('Item${i}Lista${shoppingLists[i].id}dragHandle'),
                    index: i,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                            Dismissible(
                              key: Key('Lista${shoppingLists[i].id}'),
                              child: TextButton(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: ShoppingListWidget(
                                      list: shoppingLists[i]),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                      ShoppingListPage.routeName,
                                      arguments: {
                                        'loadedList': shoppingLists[i],
                                      }).then((val) {
                                    if (shoppingLists[i].length == 0)
                                      _dbManager
                                          .deleteShoppingList(
                                              shoppingLists[i].id)
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
                    ),
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

  LineChartData _getGraphData(
      ThemeData theme,
      NumberFormat currencyFormatter,
      double minx,
      double miny,
      double maxx,
      double maxy,
      double interval,
      List<ShoppingList> lists) {
    return LineChartData(
        lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: theme.colorScheme.onSurface,
                getTooltipItems: (spots) {
                  return [
                    for (final spot in spots)
                      LineTooltipItem(
                          currencyFormatter.format(spot.y),
                          theme.textTheme.subtitle2
                              .copyWith(color: theme.colorScheme.surface)),
                  ];
                })),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              width: 4,
            ),
            left: BorderSide(
              color: Colors.transparent,
            ),
            right: BorderSide(
              color: Colors.transparent,
            ),
            top: BorderSide(
              color: Colors.transparent,
            ),
          ),
        ),
        gridData: FlGridData(
          show: false,
        ),
        minX: minx,
        minY: miny,
        maxX: maxx,
        maxY: maxy,
        titlesData: FlTitlesData(
          bottomTitles: SideTitles(
              reservedSize: 40.0,
              margin: 8.0,
              showTitles: true,
              getTextStyles: (value) {
                return theme.textTheme.caption;
              },
              interval: interval,
              checkToShowTitle: (min, max, _, interval, value) {
                final isIndexValid = value.toStringAsFixed(1) ==
                    value.truncate().toStringAsFixed(1);
                return isIndexValid;
              },
              getTitles: (value) {
                final index = value.truncate() - 1;
                if (index >= 0 && index < lists.length) {
                  var data = lists[index].dateCreated;
                  final formatter = DateFormat('d\nMMM\nyy');
                  return formatter.format(data);
                }
                return '';
              }),
          leftTitles: SideTitles(
            interval: maxy == 0 ? 1 : maxy / 5,
            reservedSize: currencyFormatter.format(maxy).length * 5.0,
            margin: 8.0,
            showTitles: true,
            getTextStyles: (value) {
              return theme.textTheme.caption;
            },
            getTitles: (value) {
              return currencyFormatter.format(value);
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            preventCurveOverShooting: true,
            spots: [
              for (var i = 0; i < lists.length; i++)
                FlSpot(i + 1.0, lists[i].total),
            ],
            isCurved: true,
            colors: [
              theme.colorScheme.primary.withOpacity(0.4),
            ],
            barWidth: 8,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
            ),
            belowBarData: BarAreaData(
              show: true,
              colors: [
                theme.colorScheme.primary.withOpacity(0.3),
                theme.colorScheme.primaryVariant.withOpacity(0.1),
              ],
              gradientFrom: Offset.fromDirection(0.78, 1.2),
              gradientTo: Offset.fromDirection(3.92),
            ),
          )
        ]);
  }
}
