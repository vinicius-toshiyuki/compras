import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  static const routeName = '/settings';
  static const brightness = 'brightness';
  static const lightTheme = 'light';
  static const darkTheme = 'dark';
  static const systemTheme = 'system';
  static const String language = 'language';
  static const languages = {'pt_BR': 'Português', 'en': 'English', 'ja': '日本語'};

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<bool> _brightness;
  final themes = [
    SettingsPage.lightTheme,
    SettingsPage.systemTheme,
    SettingsPage.darkTheme
  ];

  String _language;

  @override
  void initState() {
    _brightness = themes
        .map((theme) => theme == SettingsPage.systemTheme)
        .toList(growable: false);

    SharedPreferences.getInstance().then((prefs) {
      if (prefs.containsKey(SettingsPage.brightness)) {
        final themeMode = prefs.getString(SettingsPage.brightness);
        final lang = prefs.getString(SettingsPage.language);
        setState(() {
          _brightness =
              themes.map((theme) => theme == themeMode).toList(growable: false);
          if (prefs.containsKey(SettingsPage.language)) {
            _language = lang;
          }
        });
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    if (SettingsPage.languages.containsKey(loc.localeName)) {
      _language ??= SettingsPage.languages[loc.localeName];
    } else {
      _language ??= SettingsPage.languages['en'];
    }

    return WillPopScope(
      onWillPop: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            SettingsPage.brightness, themes[_brightness.indexOf(true)]);
        await prefs.setString(SettingsPage.language, _language);
        return true;
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            loc.settings,
            style: theme.textTheme.headline6,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ToggleButtons(
                    borderWidth: 0.5,
                    color: theme.colorScheme.secondaryVariant,
                    hoverColor: Colors.transparent,
                    constraints:
                        BoxConstraints(minWidth: 28.0, minHeight: 28.0),
                    borderRadius: BorderRadius.circular(5.0),
                    children: [
                      _OptionWidget(
                          icon: Icons.brightness_5_rounded,
                          label: loc.light,
                          theme: theme),
                      _OptionWidget(
                          icon: Icons.brightness_auto_rounded,
                          label: loc.system,
                          theme: theme),
                      _OptionWidget(
                          icon: Icons.brightness_2_rounded,
                          label: loc.dark,
                          theme: theme),
                    ],
                    isSelected: _brightness,
                    onPressed: (idx) {
                      setState(() {
                        _brightness = [false, false, false];
                        _brightness[idx] = true;
                      });
                    }),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButton(
                    value: _language,
                    icon: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(Icons.language),
                    ),
                    items: SettingsPage.languages.values
                        .map((String e) => DropdownMenuItem(
                              child: Text(e),
                              value: e,
                            ))
                        .toList(),
                    onChanged: (item) {
                      setState(() {
                        _language = item;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    style: ButtonStyle(
                      overlayColor:
                          MaterialStateProperty.all(Colors.transparent),
                    ),
                    onPressed: () {
                      showLicensePage(context: context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(loc.licenses,
                          style: theme.textTheme.subtitle2.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.4))),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionWidget extends StatelessWidget {
  const _OptionWidget({
    Key key,
    @required this.theme,
    @required this.icon,
    @required this.label,
  }) : super(key: key);

  final ThemeData theme;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Icon(
              icon,
              size: 20.0,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.caption,
          ),
        ],
      ),
    );
  }
}
