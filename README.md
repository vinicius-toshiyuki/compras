# Compras
[![Codemagic build status](https://api.codemagic.io/apps/60285b7d723629b11d05a8aa/60285b7d723629b11d05a8a9/status_badge.svg)](https://codemagic.io/apps/60285b7d723629b11d05a8aa/60285b7d723629b11d05a8a9/latest_build)

<img src="img/logo_android.png" width="256pt" alt="Logo" />

É só para fazer lista de compras.

## Compilação

### Preparo

```
flutter pub run flutter_launcher_icons:main
```

- Android
```
flutter build apk
```
- Linux
> Precisa do `sqlite3` instalado
```
flutter build linux
```
- IOS, Web, Windows e MacOS
> Nunca testado. Sem Mac, sem build.
```
cd compras
flutter create --platforms=ios,web,windows,macos .
flutter build [ios|web|windows|macos]
```

## Fontes

[Baloo Chettan 2](https://fonts.google.com/specimen/Baloo+Chettan+2)
[Kaushan Script](https://fonts.google.com/specimen/Kaushan+Script)

### TODO

- [ ] Mudar a fonte e a licença
- [ ] Salvar as fontes padrão localmente
- [ ] Checar o texto na *addProductBottomSheet*
- [ ] Mudar o *buildDefaultDragHanldes* da *ReorderableList*
- [ ] Mudar a [página](lib/src/shoppinglist/page.dart) para usar *ReorderableList*
- [ ] Arrumar o título da janela no desktop
- [ ] Colocar o ícone no aplicativo de desktop

# Licença
[MIT License](./LICENSE)
