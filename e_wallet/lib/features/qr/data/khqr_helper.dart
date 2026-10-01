/// Helper class for generating standard KHQR (EMVCo) QR payloads for Cambodia.
/// Compatible with Bakong, ABA Mobile, ACLEDA, and camera QR scanners.
class KhqrHelper {
  KhqrHelper._();

  /// Formats an EMVCo tag (tag + 2-digit length + value).
  static String formatTag(String tag, String value) {
    final len = value.length.toString().padLeft(2, '0');
    return '$tag$len$value';
  }

  /// Calculates CRC-16/CCITT-FALSE checksum (polynomial 0x1021, init 0xFFFF).
  static String calculateCrc16(String input) {
    int crc = 0xFFFF;
    final bytes = input.codeUnits;
    for (final b in bytes) {
      crc ^= (b << 8);
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  /// Generates a compliant EMVCo / KHQR payload string.
  ///
  /// [accountId]: Bakong / Wallet identifier, e.g. "sokha_chan@ewallet" or "WAL-01493803"
  /// [merchantName]: Display name of payee, e.g. "Sokha Chan"
  /// [amount]: Transaction amount in USD/KHR (optional for static QR)
  /// [currency]: "USD" (code 840) or "KHR" (code 116)
  /// [billNumber]: Optional invoice or reference code
  /// [city]: City name, defaults to "Phnom Penh"
  static String generateKhqrPayload({
    required String accountId,
    required String merchantName,
    double? amount,
    String currency = 'USD',
    String? billNumber,
    String city = 'Phnom Penh',
  }) {
    final cleanName = merchantName.trim().replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '');
    final displayName = cleanName.isEmpty ? 'E-WALLET PAYEE' : cleanName.toUpperCase();
    final isDynamic = amount != null && amount > 0;

    // Tag 00: Payload Format Indicator (Fixed "01")
    String payload = formatTag('00', '01');

    // Tag 01: Point of Initiation Method ("11" = Static, "12" = Dynamic)
    payload += formatTag('01', isDynamic ? '12' : '11');

    // Tag 29: Merchant Account Information (Bakong format)
    // Sub-tag 00: Globally Unique ID ("bakong@nbc")
    // Sub-tag 01: Bakong / Wallet Account ID
    final subTag00 = formatTag('00', 'bakong@nbc');
    final subTag01 = formatTag('01', accountId.trim());
    final tag29Value = '$subTag00$subTag01';
    payload += formatTag('29', tag29Value);

    // Tag 52: Merchant Category Code (5999 = Miscellaneous/General)
    payload += formatTag('52', '5999');

    // Tag 53: Transaction Currency (840 = USD, 116 = KHR)
    final currCode = currency.toUpperCase() == 'KHR' ? '116' : '840';
    payload += formatTag('53', currCode);

    // Tag 54: Transaction Amount (if dynamic)
    if (isDynamic) {
      payload += formatTag('54', amount.toStringAsFixed(2));
    }

    // Tag 58: Country Code ("KH")
    payload += formatTag('58', 'KH');

    // Tag 59: Merchant / Payee Name (max 25 chars)
    final truncatedName = displayName.length > 25 ? displayName.substring(0, 25) : displayName;
    payload += formatTag('59', truncatedName);

    // Tag 60: Merchant City (max 15 chars)
    final cleanCity = city.length > 15 ? city.substring(0, 15) : city;
    payload += formatTag('60', cleanCity);

    // Tag 62: Additional Data Field (optional bill number)
    if (billNumber != null && billNumber.trim().isNotEmpty) {
      final subTagBill = formatTag('01', billNumber.trim());
      payload += formatTag('62', subTagBill);
    }

    // Tag 63: CRC (Checksum over everything up to and including "6304")
    final beforeCrc = '${payload}6304';
    final crc = calculateCrc16(beforeCrc);
    return '$beforeCrc$crc';
  }
}
