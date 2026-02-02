import 'package:get/get.dart';
import 'ar_translations.dart';
import 'en_translations.dart';

/// App translations combining all supported languages
/// 
/// Used with GetX internationalization system
class Languages extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'ar': arTranslations,
    'en': enTranslations,
  };
}
