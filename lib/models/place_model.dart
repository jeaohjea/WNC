class PlaceModel {
  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longtitude;
  final double? rating;
  final int? userRatingTotal;
  final bool? isOpen;
  final List<OpeningHours>? openingHours;
  final String? phoneNumber;
  final String? website;
  final List<String>? photos;
  final double? distanceKm;
  final List<String> types;
  final String? priceLevel;

  PlaceModel({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longtitude,
    this.rating,
    this.userRatingTotal,
    this.isOpen,
    this.openingHours,
    this.phoneNumber,
    this.website,
    this.photos,
    this.distanceKm,
    this.types = const [],
    this.priceLevel,
});

  factory PlaceModel.fromNearbyJson(Map<String, dynamic> json) {
    final geometry = json['geometry']['location'];
    final openingHoursData = json['opening_hours'];

    return PlaceModel(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      address: json['vicinity'] ?? '',
      latitude: (geometry['lat'] as num).toDouble(),
      longtitude: (geometry['lng'] as num).toDouble(),
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      userRatingTotal: json['user_ratings_total'],
      isOpen: openingHoursData != null ? openingHoursData['open_now'] : null,
      types: List<String>.from(json['types'] ?? []),
      priceLevel: _parsePriceLevel(json['price_level']),
    );
  }

  factory PlaceModel.fromDetailJson(Map<String, dynamic> json) {
    final geometry = json['geometry']['location'];
    final openingHoursData = json['opening_hours'];
    List<OpeningHours>? hours;

    if (openingHoursData != null && openingHoursData['weekday_text'] != null) {
      hours = (openingHoursData['weekday_text'] as List)
          .map((h) => OpeningHours.fromText(h.toString()))
          .toList();
    }

    List<String>? photoRefs;
    if (json['photos'] != null) {
      photoRefs = (json['photos'] as List)
          .take(3)
          .map((p) => p['photo_reference'].toString())
          .toList();
    }

    return PlaceModel(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      address: json['formatted_address'] ?? json['vicinity'] ?? '',
      latitude: (geometry['lat'] as num).toDouble(),
      longtitude: (geometry['lng'] as num).toDouble(),
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      userRatingTotal: json['user_rating_total'],
      isOpen: openingHoursData != null ? openingHoursData['open_now'] : null,
      openingHours: hours,
      phoneNumber: json['formatted_phone_number'],
      website: json['website'],
      photos: photoRefs,
      types: List<String>.from(json['types'] ?? []),
      priceLevel: _parsePriceLevel(json['price_level']),
    );
  }

  static String? _parsePriceLevel(dynamic level) {
    if (level == null) return null;
    final Map<int, String> levels = {
      0: 'Gratis',
      1: 'Murah',
      2: 'Sedang',
      3: 'Mahal',
      4: 'Sangat Mahal',
    };
    return levels[level as int];
  }

  String get photoUrl {
    if (photos != null && photos!.isNotEmpty) {
      return 'https://maps.googleapis.com/maps/api/place/photo'
          '?maxwidth=400&photo_reference=${photos!.first}';
    }
    return '';
  }

  String get statusText {
    if (isOpen == null) return 'Status tidak diketahui';
    return isOpen! ? 'Buka Sekarang' : 'Tutup Sekarang';
  }
}

class OpeningHours {
  final String dayText;

  OpeningHours({required this.dayText});

  factory OpeningHours.fromText(String text) {
    return OpeningHours(dayText: text);
  }
}