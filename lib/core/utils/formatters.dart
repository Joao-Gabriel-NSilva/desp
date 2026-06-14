class Formatters {
  static String currency(double value) {
    // Retorna formatado em BRL: R$ X.XXX,XX
    final String sign = value < 0 ? '-' : '';
    final double absoluteValue = value.abs();
    final String fixed = absoluteValue.toStringAsFixed(2);
    final List<String> parts = fixed.split('.');
    final String integerPart = parts[0];
    final String decimalPart = parts[1];

    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String formattedInteger = integerPart.replaceAllMapped(reg, (Match match) => '${match[1]}.');

    return '${sign}R\$ $formattedInteger,$decimalPart';
  }

  static String date(DateTime date) {
    // Retorna no formato DD/MM/AAAA
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$day/$month/$year';
  }
}
