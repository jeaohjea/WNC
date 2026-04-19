import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wnc_finder/config/api_keys.dart';
import 'package:wnc_finder/models/place_model.dart';
import 'package:wnc_finder/services/place_services.dart';

class DetailScreen extends StatefulWidget {
  final PlaceModel place;

  const DetailScreen({super.key, required this.place});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final PlacesService _placesService = PlacesService();
  PlaceModel? _detailPlace;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await _placesService.getPlaceDetail(widget.place.placeId);
      setState(() {
        _detailPlace = detail ?? widget.place;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _detailPlace = widget.place;
        _isLoading = false;
      });
    }
  }

  Future<void> _openMapsNavigation() async {
    final place = _detailPlace ?? widget.place;
    final url = Uri.parse(
      'https:// www.google.com/maps/dir/?api-1'
      '&destination=${place.latitude},${place.longitude}'
      '&destination_place_id=${place.placeId}',
    );
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _callPhone() async {
    final phone = _detailPlace?.phoneNumber;
    if (phone == null) return;
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _openWebsite() async {
    final website = _detailPlace?.website;
    if (website == null) return;
    final url = Uri.parse(website);
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final place = _detailPlace ?? widget.place;

    return Scaffold(
      backgroundColor: const Color(0xFF1A0A00),
      body: CustomScrollView(
        slivers: [
          // app bar dengan foto
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF2D1200),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (place.photos != null && place.photos!.isNotEmpty)
                    Image.network(
                      '${PlacesService().getPhotoUrl(place.photos!.first)}&key=${ApiKeys.googleMapsApiKey}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderImage(),
                    )
                  else
                    _placeholderImage(),

                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC1A0A00)],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),

                  //status buka/tutup
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: place.isOpen == true
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            place.isOpen == true
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            place.statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // content
          SliverToBoxAdapter(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xffd4722a),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),

                        //rating
                        if (place.rating != null) ...[
                          Row(
                            children: [
                              RatingBarIndicator(
                                rating: place.rating!,
                                itemBuilder: (context, _) => const Icon(
                                  Icons.star,
                                  color: Color(0xffffc107),
                                ),
                                itemCount: 5,
                                itemSize: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${place.rating!.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  color: Color(0xffffc107),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (place.userRatingTotal != null) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(${_formatCount(place.userRatingTotal!)} ulasan)',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        //harga dan tipe
                        if (place.priceLevel != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xffd4722a).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xffd4722a).withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              'Kisaran harga: ${place.priceLevel}',
                              style: const TextStyle(
                                color: Color(0xffd4722a),
                                fontSize: 12,
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),
                        _divider(),

                        //alamat
                        _infoRow(Icons.location_on, 'Alamat', place.address),

                        //telepon
                        if (place.phoneNumber != null)
                          _infoRow(
                            Icons.phone,
                            'Telepon',
                            place.phoneNumber!,
                            onTap: _callPhone,
                            isLink: true,
                          ),

                        //web
                        if (place.website != null)
                          _infoRow(
                            Icons.language,
                            'Website',
                            place.website!,
                            onTap: _openWebsite,
                            isLink: true,
                          ),

                        _divider(),

                        //jam operasional
                        if (place.openingHours != null &&
                            place.openingHours!.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Jam Operasional',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          ...place.openingHours!.map(
                            (h) => _hourRow(h.dayText),
                          ),
                          _divider(),
                        ],

                        //mini map
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Lokasi',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: 180,
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(place.latitude, place.longitude),
                                zoom: 16,
                              ),
                              markers: {
                                Marker(
                                  markerId: MarkerId(place.placeId),
                                  position: LatLng(
                                    place.latitude,
                                    place.longitude,
                                  ),
                                  infoWindow: InfoWindow(title: place.name),
                                ),
                              },
                              zoomControlsEnabled: false,
                              myLocationButtonEnabled: false,
                              scrollGesturesEnabled: false,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        //tombol navigasi
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _openMapsNavigation,
                            icon: const Icon(Icons.directions, size: 20),
                            label: const Text(
                              'Buka Navigasi di Google Maps',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffd4722a),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadiusGeometry.circular(14),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: const Color(0xff2d1200),
      child: const Center(child: Text('☕', style: TextStyle(fontSize: 64))),
    );
  }

  Widget _divider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      height: 1,
      color: Colors.white12,
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
    bool isLink = false,
  }) {
    return Padding(
      padding: const EdgeInsetsGeometry.only(bottom: 14),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xffd4722a), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: isLink ? const Color(0xff7ec8e3) : Colors.white,
                      fontSize: 14,
                      decoration: isLink ? TextDecoration.underline : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hourRow(String text) {
    //memisahkan hari dan jam :(
    final parts = text.split(': ');
    final day = parts.isNotEmpty ? parts[0] : text;
    final hours = parts.length > 1 ? parts[1] : '';

    //highlight hari ini
    final now = DateTime.now();
    final days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final today = days[now.weekday - 1];
    final isToday = day.contains(today);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isToday
            ? const Color(0xffd4722a).withOpacity(0.15)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: isToday
            ? Border.all(color: const Color(0xffd4722a).withOpacity(0.3))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: TextStyle(
              color: isToday ? const Color(0xffd4722a) : Colors.white60,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
          Text(
            hours,
            style: TextStyle(
              color: isToday ? Colors.white : Colors.white60,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}rb';
    return count.toString();
  }
}
