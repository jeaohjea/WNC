import 'package:flutter/material.dart';
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
      '&destination=${place.latitude},${place.longtitude}'
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

    return Scaffold (
      backgroundColor: const Color(0xFF1A0A00),
      body: CustomScrollView(
        slivers: [
          // app bar dengan foto
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF2D1200),
            leading: GestureDetector (
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12)
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18)
              )
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (place.photos != null && place.photos!.isNotEmpty)
                    Image.network(
                      '${PlacesService().getPhotoUrl(place.photos!.first)}&key=${ApiKeys.googleMapsApiKey}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, __) => _placeholderImage(),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: place.isOpen == true ? Colors.green.shade700 : Colors.red.shade700,
                        borderRadius: BorderRadius.circular(20)
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            place.isOpen == true ? Icons.check_circle : Icons.cancel,
                            color: Colors.white,
                            size: 14
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
                  )
                ],
              )
            ),
          ),

          // content
          
        ],
      )
    )
  }
}
