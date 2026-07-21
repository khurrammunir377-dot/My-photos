import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyOption {
  final String code; // e.g. "USD"
  final String symbol; // e.g. "$"
  final String name;
  const CurrencyOption(this.code, this.symbol, this.name);
}

/// NOTE: Google Play Billing already shows each user their real, localized
/// price automatically based on their Play Store country - once the products
/// are set up in Play Console, that part needs no extra work from us.
/// This helper only powers an in-app "preview your price in ___" selector,
/// using approximate rates, so users get a sense of cost before checkout.
class CurrencyHelper {
  static const String _prefKey = 'preferred_currency';

  static const List<CurrencyOption> supported = [
    CurrencyOption('USD', '\$', 'US Dollar'),
    CurrencyOption('AED', 'د.إ', 'UAE Dirham'),
    CurrencyOption('EUR', '€', 'Euro'),
    CurrencyOption('GBP', '£', 'British Pound'),
    CurrencyOption('INR', '₹', 'Indian Rupee'),
    CurrencyOption('PKR', '₨', 'Pakistani Rupee'),
    CurrencyOption('SAR', '﷼', 'Saudi Riyal'),
    CurrencyOption('CAD', 'CA\$', 'Canadian Dollar'),
    CurrencyOption('AUD', 'A\$', 'Australian Dollar'),
  ];

  // Fallback approximate rates (relative to 1 USD), used if the live rate fetch fails
  // or the device is offline. Good enough for an estimate label, not for billing.
  static const Map<String, double> _fallbackRates = {
    'USD': 1.0,
    'AED': 3.67,
    'EUR': 0.92,
    'GBP': 0.79,
    'INR': 83.5,
    'PKR': 278.0,
    'SAR': 3.75,
    'CAD': 1.36,
    'AUD': 1.51,
  };

  static Future<String> getPreferredCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey) ?? 'USD';
  }

  static Future<void> setPreferredCurrency(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
  }

  /// Attempts a live rate fetch; falls back to static approximate rates on any failure
  /// (no internet, API down, etc.) so the UI never breaks.
  static Future<double> getRate(String currencyCode) async {
    if (currencyCode == 'USD') return 1.0;
    try {
      final response = await http
          .get(Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rate = data['rates']?[currencyCode];
        if (rate != null) return (rate as num).toDouble();
      }
    } catch (_) {
      // fall through to static rate
    }
    return _fallbackRates[currencyCode] ?? 1.0;
  }

  static CurrencyOption optionFor(String code) {
    return supported.firstWhere((c) => c.code == code, orElse: () => supported.first);
  }

  static String formatPrice(double usdPrice, String currencyCode, double rate) {
    final option = optionFor(currencyCode);
    final converted = usdPrice * rate;
    // Whole-number currencies read oddly with decimals (e.g. PKR 278) - round those.
    final display = converted >= 20 ? converted.round().toString() : converted.toStringAsFixed(2);
    return '${option.symbol}$display';
  }
}
