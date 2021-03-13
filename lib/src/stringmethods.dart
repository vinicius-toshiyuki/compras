String toCapitalized(String text) {
  return '${text[0].toUpperCase()}${text.substring(1)}';
}

String toTitle(String text) {
  return text.split(RegExp(r'\s')).map((word) => toCapitalized(word)).join(' ');
}

extension on String {
  String capitalize() {
    return this[0].toUpperCase() + this.substring(1);
  }

  String title() {
    return this.split(RegExp(r'\s')).map((word) => word.capitalize()).join(' ');
  }
}
