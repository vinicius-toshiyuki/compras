# Compras
[![Codemagic build status](https://api.codemagic.io/apps/60285b7d723629b11d05a8aa/60285b7d723629b11d05a8a9/status_badge.svg)](https://codemagic.io/apps/60285b7d723629b11d05a8aa/60285b7d723629b11d05a8a9/latest_build)

<img src="./res/images/logo_android.png" width="256pt" alt="Logo" />

É só para fazer lista de compras.

## Compilação

### Android

```
flutter pub run flutter_launcher_icons:main
flutter pub run gen_lang:generate --output-dir lib/src/generated
flutter build apk
```

### IOS

Nunca testado. Sem Mac, sem build.

```
flutter pub run flutter_launcher_icons:main
flutter pub run gen_lang:generate --output-dir lib/src/generated
flutter build ios
```

## Fontes

[Baloo Chettan 2](https://fonts.google.com/specimen/Baloo+Chettan+2)
[Kaushan Script](https://fonts.google.com/specimen/Kaushan+Script)

# Licença
[MIT License](./LICENSE)
