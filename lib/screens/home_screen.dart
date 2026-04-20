import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wnc_finder/models/place_model.dart';
import 'package:wnc_finder/screens/detail_screen.dart';
import 'package:wnc_finder/services/location_service.dart';
import 'package:wnc_finder/services/place_services.dart';
import 'package:wnc_finder/widgets/filter_chip_row.dart';
import 'package:wnc_finder/widgets/place_card.dart';
import 'package:wnc_finder/widgets/search_bar_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final PlacesService _placesService = PlacesService();
  final LocationService _locationService = LocationService();
  final Completer<GoogleMapController> _mapController = Completer();

  List<PlaceModel> _places = [];
  Set<Marker> _markers = {};
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isSearching = false;
  String _errorMessage = '';
  String _selectedFilter = 'Semua';
  int _selectedRadius = 2000;
  PlaceModel? _selectedPlace;

  late AnimationController _panelController;
  late Animation<double> _panelAnimation;
  bool _isPanelExpanded = false;

  final List<String> _filters = [
    'Semua',
    'Warkop',
    'Cafe',
    'Kopi Susu',
    'Buka Sekarang',
  ];
  final List<int> _radiusOptions = [500, 1000, 2000, 5000];

  static const LatLng _defaultLocation = LatLng(-7.2575, 112.7521); //surabaya

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _panelAnimation = CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeInOut,
    );
    _initLocation();
  }

  @override
  void dispose() {
    _panelController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      setState(() => _currentPosition = position);
      await _loadNearbyPlaces();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadNearbyPlaces({String? keyword}) async {
    if (_currentPosition == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      String searchKeyword = keyword ?? _getKeywordForFilter();
      final places = await _placesService.searchNearby(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radius: _selectedRadius,
        keyword: searchKeyword,
      );

      final filtered = _filteredPlaces(places);
      _updateMarkerAndList(filtered);

      //animasi kamera ke lokasi user
      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          14.5,
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Gagal memuat data; ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getKeywordForFilter() {
    switch (_selectedFilter) {
      case 'Warkop':
        return 'warung kopi warkop';
      case 'Cafe':
        return 'cafe coffee shop';
      case 'Kopi Susu':
        return 'kopi susu kekinian';
      case 'Buka Sekarang':
        return 'warkop cafe kopi';
      default:
        return 'warkop cafe kopi warung kopi';
    }
  }

  List<PlaceModel> _filteredPlaces(List<PlaceModel> places) {
    if (_selectedFilter == 'Buka Sekarang') {
      return places.where((p) => p.isOpen == true).toList();
    }
    return places;
  }

  void _updateMarkerAndList(List<PlaceModel> places) {
    final markers = <Marker>{};

    // mark lokasi user
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Lokasi Anda'),
        ),
      );
    }

    for (int i = 0; i < places.length; i++) {
      final place = places[i];
      markers.add(
        Marker(
          markerId: MarkerId(place.placeId),
          position: LatLng(place.latitude, place.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            place.isOpen == true
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: place.name,
            snippet:
                '⭐ ${place.rating?.toStringAsFixed(1) ?? 'N/A'} • ${place.statusText}',
          ),
          onTap: () => _onMarkerTapped(place),
        ),
      );
    }

    setState(() {
      _places = places;
      _markers = markers;
    });

    // expand jika berhasil
    if (places.isNotEmpty && !_isPanelExpanded) {
      _togglePanel();
    }
  }

  void _onMarkerTapped(PlaceModel place) {
    setState() => _selectedPlace = (place);
    if (!_isPanelExpanded) _togglePanel();
  }

  void _togglePanel() {
    setState(() => _isPanelExpanded = !_isPanelExpanded);
    if (_isPanelExpanded) {
      _panelController.forward();
    } else {
      _panelController.reverse();
    }
  }

  Future<void> _onSearchSubmit(String query) async {
    if (query.isEmpty) return;
    setState(() => _isSearching = true);

    try {
      final places = await _placesService.textSearch(
        query: query,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
      );
      _updateMarkerAndList(places);

      if (places.isNotEmpty) {
        final controller = await _mapController.future;
        controller.animateCamera(
          CameraUpdate.newLatLngBounds(_getBounds(places), 80),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Pencarian gagal: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  LatLngBounds _getBounds(List<PlaceModel> places) {
    double minLat = places.first.latitude, maxLat = places.first.latitude;
    double minLng = places.first.longitude, maxLng = places.first.longitude;

    for (var p in places) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat - 0.01, minLng - 0.01),
      northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
    );
  }

  void _goToMyLocation() async {
    if (_currentPosition == null) return;
    final controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        15,
      ),
    );
  }

  void _onPlaceTapped(PlaceModel place) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(place: place)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0A00),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    )
                  : _defaultLocation,
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController.complete(controller),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            style: _mapStyle,
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4722A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('☕', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 6),
                            Text(
                              'WarkopFinder',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.place,
                              color: Color(0xFFD4722A),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_places.length} tempat',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                //search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SearchBarWidget(
                    onSearch: _onSearchSubmit,
                    isLoading: _isSearching,
                  ),
                ),

                const SizedBox(height: 10),

                //filter chips
                FilterChipRow(
                  filters: _filters,
                  selected: _selectedFilter,
                  onSelected: (filter) {
                    setState(() => _selectedFilter = filter);
                    _loadNearbyPlaces();
                  },
                ),

                //radius selector
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _radiusOptions.map((r) {
                        final isSelected = _selectedRadius == r;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedRadius = r);
                            _loadNearbyPlaces();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFD4722A)
                                  : Colors.black45,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xffd4722a)
                                    : Colors.white24,
                              ),
                            ),
                            child: Text(
                              r >= 1000 ? '${r ~/ 1000} km' : '${r}m',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white60,
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          //fab lokasi
          Positioned(
            right: 16,
            bottom: _isPanelExpanded ? 340 : 100,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'refresh',
                  backgroundColor: const Color(0xffd4722a),
                  onPressed: _loadNearbyPlaces,
                  child: const Icon(Icons.refresh, color: Colors.white),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'location',
                  backgroundColor: Colors.white,
                  onPressed: _goToMyLocation,
                  child: const Icon(
                    Icons.my_location,
                    color: Color(0xffd4722a),
                  ),
                ),
              ],
            ),
          ),

          //loading overlay
          if (_isLoading)
            Container(
              color: Colors.black38,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xffd4722a)),
                  SizedBox(height: 12),
                  Text(
                    'Mencari warkop dan cafe...',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),

          //error snackbar
          if (_errorMessage.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),

          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomPanel()),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isPanelExpanded ? 360 : 60,
      decoration: const BoxDecoration(
        color: Color(0xff1a0a00),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          //handle
          GestureDetector(
            onTap: _togglePanel,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  if (!_isPanelExpanded) ...[
                    const SizedBox(height: 6),
                    Text(
                      _places.isEmpty
                          ? 'Tidak ada tempat yang bisa ditemukan'
                          : '${_places.length} warkop & cafe ditemukan - Tap untuk melihat',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isPanelExpanded)
            Expanded(
              child: _places.isEmpty
                  ? const Center(
                      child: Text(
                        'tidak ada tempat yang ditemukan\nCoba perbesar radius pencarian',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: _places.length,
                      itemBuilder: (context, index) {
                        return PlaceCard(
                          place: _places[index],
                          onTap: () => _onPlaceTapped(_places[index]),
                          apiKey: _placesService.getPhotoUrl(''),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }

  // Custom Map Style (dark theme dengan aksen hangat)
  static const String _mapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#1d2c4d"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8ec3b9"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#1a3646"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#304a7d"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#98a5be"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0e1626"}]},
  {"featureType": "poi.park", "elementType": "geometry.fill", "stylers": [{"color": "#023e58"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]}
]
''';
}
