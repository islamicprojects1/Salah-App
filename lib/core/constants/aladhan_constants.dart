/// Aladhan API constants and country-to-method mapping.
///
/// Uses official calculation methods per country when available.
/// Fallback: Muslim World League (3) for unknown regions.
library;

/// Base URL for Aladhan API (no trailing slash)
const String aladhanBaseUrl = 'https://api.aladhan.com/v1';

/// الموقع الافتراضي — مكة المكرمة (الكعبة المشرفة) — يُستخدَم عند فشل GPS
const double kMeccaLatitude = 21.4225;
const double kMeccaLongitude = 39.8262;

/// Days before month end to pre-fetch next month
const int daysBeforeMonthEndToPrefetch = 5;

/// Best Aladhan calculation method per country (country name or code → method ID).
///
/// Method IDs from https://api.aladhan.com/v1/methods
/// e.g. Jordan = 23 (Ministry of Awqaf), UAE = 16 (Dubai), etc.
const Map<String, int> countryToAladhanMethod = {
  // Jordan — وزارة الأوقاف
  'jordan': 23,
  'jo': 23,
  'الأردن': 23,

  // Saudi Arabia — أم القرى
  'saudi arabia': 4,
  'sa': 4,
  'السعودية': 4,

  // Egypt
  'egypt': 5,
  'eg': 5,
  'مصر': 5,

  // UAE / Dubai
  'united arab emirates': 16,
  'uae': 16,
  'ae': 16,
  'dubai': 16,
  'الإمارات': 16,
  'دبي': 16,

  // Gulf
  'kuwait': 9,
  'kw': 9,
  'الكويت': 9,
  'qatar': 10,
  'qa': 10,
  'قطر': 10,
  'bahrain': 8,
  'bh': 8,
  'البحرين': 8,
  'oman': 8,
  'om': 8,
  'عمان': 8,

  // Pakistan
  'pakistan': 1,
  'pk': 1,
  'باكستان': 1,

  // Turkey
  'turkey': 13,
  'tr': 13,
  'تركيا': 13,

  // Southeast Asia
  'malaysia': 17,
  'my': 17,
  'ماليزيا': 17,
  'singapore': 11,
  'sg': 11,
  'سنغافورة': 11,
  'indonesia': 20,
  'id': 20,
  'إندونيسيا': 20,

  // North Africa
  'morocco': 21,
  'ma': 21,
  'المغرب': 21,
  'tunisia': 18,
  'tn': 18,
  'تونس': 18,
  'algeria': 19,
  'dz': 19,
  'الجزائر': 19,

  // Iran
  'iran': 7,
  'ir': 7,
  'إيران': 7,

  // North America
  'united states': 2,
  'us': 2,
  'usa': 2,
  'united states of america': 2,
  'canada': 2,
  'ca': 2,
  'المكسيك': 2,

  // Europe / UK — Muslim World League
  'united kingdom': 3,
  'uk': 3,
  'gb': 3,
  'france': 12,
  'fr': 12,
  'ألمانيا': 3,
  'germany': 3,
  'de': 3,
  'portugal': 22,
  'pt': 22,

  // Russia
  'russia': 14,
  'ru': 14,
  'روسيا': 14,

  // Default when country unknown
  'default': 3, // Muslim World League
};

/// Get Aladhan method ID for a country (case-insensitive).
///
/// Uses exact match first, then partial match for known countries.
/// Returns [countryToAladhanMethod['default']] (3) if not found.
int getAladhanMethodForCountry(String? country) {
  if (country == null || country.trim().isEmpty) {
    return countryToAladhanMethod['default']!;
  }
  final key = country.trim().toLowerCase();

  // Exact match first
  final exact = countryToAladhanMethod[key];
  if (exact != null) return exact;

  // Partial match for Jordan (e.g. "Hashemite Kingdom of Jordan")
  if (key.contains('jordan') || key.contains('أردن')) {
    return 23;
  }

  return countryToAladhanMethod['default']!;
}
