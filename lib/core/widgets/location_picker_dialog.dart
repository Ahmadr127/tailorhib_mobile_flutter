import 'package:flutter/material.dart';
import 'location_picker_map.dart';

class LocationPickerDialog extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(double latitude, double longitude) onLocationSelected;
  final bool isTailor; // Menandakan dialog untuk penjahit atau pelanggan

  const LocationPickerDialog({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
    this.isTailor = false, // Default untuk pelanggan
  });

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  late double? selectedLatitude;
  late double? selectedLongitude;

  @override
  void initState() {
    super.initState();
    selectedLatitude = widget.initialLatitude;
    selectedLongitude = widget.initialLongitude;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.isTailor
                          ? 'Pilih Lokasi Toko'
                          : 'Pilih Lokasi Anda',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2552),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Informasi tentang pentingnya lokasi
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Icon(Icons.info_outline,
                          color: Colors.blue.shade700, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.isTailor
                            ? 'Lokasi toko akan ditampilkan kepada pelanggan untuk memudahkan mereka menemukan jasa Anda'
                            : 'Lokasi Anda diperlukan untuk menemukan penjahit terdekat',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Map
            Expanded(
              child: LocationPickerMap(
                initialLatitude: widget.initialLatitude,
                initialLongitude: widget.initialLongitude,
                onLocationSelected: (lat, lng) {
                  setState(() {
                    selectedLatitude = lat;
                    selectedLongitude = lng;
                  });
                },
              ),
            ),

            // Actions
            // Info lokasi
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: selectedLatitude != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Koordinat Terpilih:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'Lat: ${selectedLatitude!.toStringAsFixed(6)}\nLng: ${selectedLongitude!.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1A2552),
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Belum ada lokasi terpilih',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: selectedLatitude != null
                        ? () {
                            widget.onLocationSelected(
                              selectedLatitude!,
                              selectedLongitude!,
                            );
                            Navigator.of(context).pop();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2552),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Simpan Lokasi'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
