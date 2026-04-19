import 'package:flutter/material.dart';
import 'package:wnc_finder/config/api_keys.dart';
import 'package:wnc_finder/models/place_model.dart';
import 'package:wnc_finder/services/place_services.dart';

class PlaceCard extends StatelessWidget {
  final PlaceModel place;
  final VoidCallback onTap;
  final String apiKey;

  const PlaceCard({
    super.key,
    required this.place,
    required this.onTap,
    required this.apiKey,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xff2d1200),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            //foto
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: SizedBox(
                width: 90,
                height: 90,
                child: place.photos != null && place.photos!.isNotEmpty
                    ? Image.network(
                        '${PlacesService().getPhotoUrl(place.photos!.first)}&key=${ApiKeys.googleMapsApiKey}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _photoPlaceholder(),
                      )
                    : _photoPlaceholder(),
              ),
            ),

            //info
            Expanded(
              child: Padding(
                padding: const EdgeInsetsGeometry.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //nama
                    Text(
                      place.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    //alamat
                    Text(
                      place.address,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    //rating, status, dan jarak
                    Row(
                      children: [
                        if (place.rating != null) ...[
                          const Icon(
                            Icons.star,
                            color: Color(0xffffc107),
                            size: 13,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            place.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Color(0xffffc107),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        _statusBadge(),
                        const Spacer(),
                        if (place.distanceKm != null)
                          Text(
                            place.distanceKm! < 1
                                ? '${(place.distanceKm! * 1000).toInt()}m'
                                : '${place.distanceKm!.toStringAsFixed(1)}km',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            //chevron
            const Padding(
              padding: EdgeInsetsGeometry.only(right: 12),
              child: Icon(Icons.chevron_right, color: Colors.white24, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge() {
    final isOpen = place.isOpen;
    if (isOpen == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isOpen
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isOpen ? 'Buka' : 'Tutup',
        style: TextStyle(
          color: isOpen ? Colors.green.shade400 : Colors.red.shade400,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: const Color(0xff3d1a00),
      child: const Center(child: Text('☕', style: TextStyle(fontSize: 28))),
    );
  }
}
