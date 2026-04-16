import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wnc_finder/models/place_model.dart';
import '../models/place_model.dart';
import '../config/api_keys.dart';

class PlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';
  final String _apiKey = ApiKeys.googleMapsApiKey;

  // cari warkop di sekitar
  Future<List<PlaceModel>> searchNearby({
    required double latitude,
    required double longtitude,
    int radius = 2000,
    String keyword = 'warkop cafe',
  }) async {
    final url = Uri.parse (
      '$_baseUrl/place/nearbysearch/json'
      '?location=$latitude,$longtitude'
      '&radius=$radius'
      '&type=cafe'
      '&keyword=${Uri.encodeComponent(keyword)}'
      '&language=id'
      '&key=$_apiKey'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          final results = data['results'] as List;
          final places = results
              .map((r) => PlaceModel.fromNearbyJson(r))
              .toList();

          for (var place in places) {
            place = _addDistance(place, latitude, longtitude);
          }
          return places;
        }
      }
      return [];
    } catch (e) {
      throw Exception('Gagal mangambil data tempat: $e');
    }
  }

  // cari berdasarkan teks
  Future<List<PlaceModel>> textSearch ({
    required String query,
    double? latitude,
    double? longtitude,
  }) async {
    String url = '$_baseUrl/place/textsearch/json'
        '?query=${Uri.encodeComponent(query)}'
        '&type=cafe'
        '&language=id'
        '&key=$_apiKey';

    if (latitude != null && longtitude != null) {
      url += '&location=$latitude,$longtitude&radius=5000';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          final results = data['results'] as List;
          return results.map((r) => PlaceModel.fromNearbyJson(r)).toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Gagal mencari tempat: $e');
    }
  }

  // ambil data lengkap dari gmaps seperti jam buka, nomor telp, dll
  Future<PlaceModel?> getPlaceDetail(String placeId) async {
    final url = Uri.parse(
      '$_baseUrl/place/details/json'
      '?place_id=$placeId'
      '&fields=name,formatted_address,geometry,rating,user_ratings_total'
      'opening_hours,formatted_phone_number,website,photos,types,price_level,vicinity'
      '&language=id'
      '&key=$_apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return PlaceModel.fromDetailJson(data['result']);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil detail tempat: $e');
    }
  }

  // url foto dari places API
  String getPhotoUrl(String photoReference, {int maxWidth = 400}) {
    return '$_baseUrl/place/photo'
        'maxwidth=$maxWidth'
        '&photo_reference=$photoReference'
        '&key=$_apiKey';
  }

  PlaceModel _addDistance(PlaceModel place, double userLat, double userLng) {
    // haversine formula sederhana
    const double earthRadius = 6371; //km
    final double dLat = _toRad(place.latitude - userLat);
    final double dLng = _toRad(place.longtitude - userLng);
    final double a = (dLat / 2) * (dLat / 2) + _toRad(userLat) * _toRad(place.latitude) * (dLng / 2) * (dLng / 2);
    final double c = 2 * (a < 1 ? a : 1);
    final double distance = earthRadius * c;

    return PlaceModel(
      placeId: place.placeId,
      name: place.name,
      address: place.address,
      latitude: place.latitude,
      longtitude: place.longtitude,
      rating: place.rating,
      userRatingTotal: place.userRatingTotal,
      isOpen: place.isOpen,
      openingHours: place.openingHours,
      phoneNumber: place.phoneNumber,
      website: place.website,
      photos: place.photos,
      distanceKm: distance,
      types: place.types,
      priceLevel: place.priceLevel,
    );
  }

  double _toRad (double deg) => deg * 3.14159265358979323846 / 180;
}