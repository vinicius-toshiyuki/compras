String toCapitalized(String text) {
  return '${text[0].toUpperCase()}${text.substring(1)}';
}

String toTitle(String text) {
  return text.split(RegExp(r'\s')).map((word) => toCapitalized(word)).join(' ');
}
