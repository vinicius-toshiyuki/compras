// DO NOT EDIT. This is code generated via package:gen_lang/generate.dart

import 'dart:async';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import 'messages_all.dart';

class S {
 
  static const GeneratedLocalizationsDelegate delegate = GeneratedLocalizationsDelegate();

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }
  
  static Future<S> load(Locale locale) {
    final String name = locale.countryCode == null ? locale.languageCode : locale.toString();

    final String localeName = Intl.canonicalizedLocale(name);

    return initializeMessages(localeName).then((bool _) {
      Intl.defaultLocale = localeName;
      return new S();
    });
  }
  
  String get title {
    return Intl.message("Compras", name: 'title');
  }

  String New(targetGender, thing) {
    return Intl.gender(targetGender,
        male: "New ${thing}",
        female: "New ${thing}",
        other: "New ${thing}",
        name: 'New',
        args: [targetGender, thing]);
  }

  String Rename(thing) {
    return Intl.message("Rename ${thing}", name: 'Rename', args: [thing]);
  }

  String Remove(targetGender, thing) {
    return Intl.gender(targetGender,
        male: "${thing} removed",
        female: "${thing} removed",
        other: "${thing} removed",
        name: 'Remove',
        args: [targetGender, thing]);
  }

  String Edit(thing) {
    return Intl.message("Edit ${thing}", name: 'Edit', args: [thing]);
  }

  String ModifiedIn(targetGender, date) {
    return Intl.gender(targetGender,
        male: "Modified in ${date}",
        female: "Modified in ${date}",
        other: "Modified in ${date}",
        name: 'ModifiedIn',
        args: [targetGender, date]);
  }

  String CreatedIn(targetGender, date) {
    return Intl.gender(targetGender,
        male: "Created in ${date}",
        female: "Created in ${date}",
        other: "Created in ${date}",
        name: 'CreatedIn',
        args: [targetGender, date]);
  }

  String get dateformat {
    return Intl.message("MM/dd/yyyy HH:mm", name: 'dateformat');
  }

  String get confirm {
    return Intl.message("Confirm", name: 'confirm');
  }

  String get OK {
    return Intl.message("OK", name: 'OK');
  }

  String get cancel {
    return Intl.message("Cancel", name: 'cancel');
  }

  String get yes {
    return Intl.message("Yes", name: 'yes');
  }

  String get no {
    return Intl.message("No", name: 'no');
  }

  String get undo {
    return Intl.message("Undo", name: 'undo');
  }

  String get add {
    return Intl.message("Add", name: 'add');
  }

  String get warning {
    return Intl.message("Warning", name: 'warning');
  }

  String get name {
    return Intl.message("name", name: 'name');
  }

  String get list {
    return Intl.message("list", name: 'list');
  }

  String get item {
    return Intl.message("item", name: 'item');
  }

  String get product {
    return Intl.message("product", name: 'product');
  }

  String get shoppinglist {
    return Intl.message("shopping list", name: 'shoppinglist');
  }

  String get price {
    return Intl.message("price", name: 'price');
  }

  String get quanity {
    return Intl.message("quantity", name: 'quanity');
  }

  String get type {
    return Intl.message("Brand/type", name: 'type');
  }

  String currency(value) {
    return Intl.message("\$${value}", name: 'currency', args: [value]);
  }

  String get mergeTypesText {
    return Intl.message("This brand/type already exists. Merge duplicated brands/types?", name: 'mergeTypesText');
  }


}

class GeneratedLocalizationsDelegate extends LocalizationsDelegate<S> {
  const GeneratedLocalizationsDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
			Locale("en", "US"),
			Locale("ja", ""),
			Locale("pt", ""),

    ];
  }

  LocaleListResolutionCallback listResolution({Locale fallback}) {
    return (List<Locale> locales, Iterable<Locale> supported) {
      if (locales == null || locales.isEmpty) {
        return fallback ?? supported.first;
      } else {
        return _resolve(locales.first, fallback, supported);
      }
    };
  }

  LocaleResolutionCallback resolution({Locale fallback}) {
    return (Locale locale, Iterable<Locale> supported) {
      return _resolve(locale, fallback, supported);
    };
  }

  Locale _resolve(Locale locale, Locale fallback, Iterable<Locale> supported) {
    if (locale == null || !isSupported(locale)) {
      return fallback ?? supported.first;
    }

    final Locale languageLocale = Locale(locale.languageCode, "");
    if (supported.contains(locale)) {
      return locale;
    } else if (supported.contains(languageLocale)) {
      return languageLocale;
    } else {
      final Locale fallbackLocale = fallback ?? supported.first;
      return fallbackLocale;
    }
  }

  @override
  Future<S> load(Locale locale) {
    return S.load(locale);
  }

  @override
  bool isSupported(Locale locale) =>
    locale != null && supportedLocales.contains(locale);

  @override
  bool shouldReload(GeneratedLocalizationsDelegate old) => false;
}

// ignore_for_file: unnecessary_brace_in_string_interps
