import 'package:latlong2/latlong.dart';

class UaePlace {
  final String nameArabic;
  final String nameEnglish;
  final String category; // 'highway', 'landmark', 'fuel', 'mosque'
  final LatLng location;

  const UaePlace({
    required this.nameArabic,
    required this.nameEnglish,
    required this.category,
    required this.location,
  });
}

/**
 * 100% Offline Database of essential UAE locations, highways, and landmarks.
 * Covers Ajman, Sharjah, Dubai, and primary transit corridors.
 */
class UaePlacesService {
  static const List<UaePlace> offlinePlaces = [
    // Ajman
    UaePlace(
      nameArabic: 'كورنيش عجمان',
      nameEnglish: 'Ajman Corniche',
      category: 'landmark',
      location: LatLng(25.4140, 55.4380),
    ),
    UaePlace(
      nameArabic: 'سيتي سنتر عجمان',
      nameEnglish: 'City Centre Ajman',
      category: 'landmark',
      location: LatLng(25.3995, 55.4795),
    ),
    UaePlace(
      nameArabic: 'مسجد الشيخ زايد - عجمان',
      nameEnglish: 'Sheikh Zayed Mosque Ajman',
      category: 'mosque',
      location: LatLng(25.3850, 55.4650),
    ),

    // Sharjah
    UaePlace(
      nameArabic: 'واجهة المجاز المائية - الشارقة',
      nameEnglish: 'Al Majaz Waterfront Sharjah',
      category: 'landmark',
      location: LatLng(25.3312, 55.3888),
    ),
    UaePlace(
      nameArabic: 'جامع الشارقة الكبير',
      nameEnglish: 'Sharjah Grand Mosque',
      category: 'mosque',
      location: LatLng(25.2769, 55.5972),
    ),
    UaePlace(
      nameArabic: 'مطار الشارقة الدولي',
      nameEnglish: 'Sharjah International Airport',
      category: 'landmark',
      location: LatLng(25.3286, 55.5172),
    ),

    // Dubai
    UaePlace(
      nameArabic: 'دبي مول وبرج خليفة',
      nameEnglish: 'Dubai Mall & Burj Khalifa',
      category: 'landmark',
      location: LatLng(25.1972, 55.2744),
    ),
    UaePlace(
      nameArabic: 'مطار دبي الدولي (DXB)',
      nameEnglish: 'Dubai International Airport',
      category: 'landmark',
      location: LatLng(25.2532, 55.3657),
    ),
    UaePlace(
      nameArabic: 'دبي مارينا',
      nameEnglish: 'Dubai Marina',
      category: 'landmark',
      location: LatLng(25.0805, 55.1403),
    ),

    // Key Highways
    UaePlace(
      nameArabic: 'شارع الشيخ زايد (E11)',
      nameEnglish: 'Sheikh Zayed Road (E11)',
      category: 'highway',
      location: LatLng(25.1500, 55.2300),
    ),
    UaePlace(
      nameArabic: 'شارع الشيخ محمد بن زايد (E311)',
      nameEnglish: 'Sheikh Mohammed Bin Zayed Rd (E311)',
      category: 'highway',
      location: LatLng(25.3100, 55.4500),
    ),
    UaePlace(
      nameArabic: 'شارع الإمارات العابر (E611)',
      nameEnglish: 'Emirates Road (E611)',
      category: 'highway',
      location: LatLng(25.2500, 55.5400),
    ),
    UaePlace(
      nameArabic: 'شارع الاتحاد (عجمان - الشارقة)',
      nameEnglish: 'Al Ittihad Street (Ajman-Sharjah)',
      category: 'highway',
      location: LatLng(25.3600, 55.4100),
    ),

    // Petrol Stations
    UaePlace(
      nameArabic: 'محطة أدنوك - شارع الاتحاد',
      nameEnglish: 'ADNOC Service Station - Al Ittihad',
      category: 'fuel',
      location: LatLng(25.3900, 55.4400),
    ),
    UaePlace(
      nameArabic: 'محطة إينوك - E311',
      nameEnglish: 'ENOC Petrol Station - E311',
      category: 'fuel',
      location: LatLng(25.3200, 55.4600),
    ),
  ];

  static List<UaePlace> search(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase().trim();
    return offlinePlaces.where((place) {
      return place.nameArabic.toLowerCase().contains(q) ||
          place.nameEnglish.toLowerCase().contains(q) ||
          place.category.toLowerCase().contains(q);
    }).toList();
  }
}
