# Compras

[![Codemagic build status](https://api.codemagic.io/apps/60285b7d723629b11d05a8aa/60285b7d723629b11d05a8a9/status_badge.svg)](https://codemagic.io/apps/60285b7d723629b11d05a8aa/60285b7d723629b11d05a8a9/latest_build)
[![compras](https://snapcraft.io/compras/badge.svg)](https://snapcraft.io/compras)

[![Disponível na Snap Store](
https://snapcraft.io/static/images/badges/pt/snap-store-white.svg)](https://snapcraft.io/compras)

<img src="img/logo_android.png" width=196px></img>

Just a shopping list app.

## Build

### Preparation

```bash
flutter pub run flutter_launcher_icons:main
flutter gen-i10n
```

- Android

```bash
flutter build apk
```

- Linux

> Needs `sqlite3` installed

```bash
flutter build linux
```

- IOS, Web, Windows e MacOS

> Never tested. No Mac, no build.

```bash
cd compras
flutter create --platforms=ios,web,windows,macos .
flutter build [ios|web|windows|macos]
```

## Fonts

- [Source Sans Pro](https://fonts.google.com/specimen/Source+Sans+Pro)
- [Kaushan Script](https://fonts.google.com/specimen/Kaushan+Script)
<!--
### TODO

- [x] Mudar o *buildDefaultDragHandles* da *ReorderableList*
- [ ] Pegar as listas já ordenadas
- [x] Tirar *currency* da *i10n*
- [ ] Colocar o gráfico separado
-->
## License

[MIT License](./LICENSE)
