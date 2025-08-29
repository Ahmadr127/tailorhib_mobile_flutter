import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerMap extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(double latitude, double longitude) onLocationSelected;

  const LocationPickerMap({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  late MapController _mapController;
  LatLng _selectedLocation = const LatLng(-6.2088, 106.8456); // Default Jakarta
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Gunakan initial location jika ada
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation =
          LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }

    // Jika tidak ada lokasi awal, coba dapatkan lokasi saat ini
    if (widget.initialLatitude == null && widget.initialLongitude == null) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Cek izin lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Izin ditolak, gunakan lokasi default
          setState(() {
            _hasError = true;
            _errorMessage = 'Izin lokasi ditolak. Menggunakan lokasi default.';
            _isLoading = false;
          });
          _showSnackBar('Izin lokasi ditolak. Menggunakan lokasi default.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Izin ditolak permanen, gunakan lokasi default
        setState(() {
          _hasError = true;
          _errorMessage = 'Izin lokasi ditolak permanen. Silakan ubah di pengaturan perangkat.';
          _isLoading = false;
        });
        _showSnackBar(
            'Izin lokasi ditolak permanen. Silakan ubah di pengaturan perangkat.');
        return;
      }

      // Gunakan akurasi rendah untuk menghindari kebutuhan ACCESS_FINE_LOCATION
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _hasError = false;
      });

      // Gerakkan peta ke lokasi saat ini
      _mapController.move(_selectedLocation, 15);

      // Set lokasi yang dipilih
      widget.onLocationSelected(
          _selectedLocation.latitude, _selectedLocation.longitude);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Gagal mendapatkan lokasi saat ini: $e';
      });
      _showSnackBar('Gagal mendapatkan lokasi saat ini: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isLoading)
          const LinearProgressIndicator()
        else if (_hasError)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.red.shade50,
            width: double.infinity,
            child: Text(
              _errorMessage,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          )
        else
          const SizedBox(height: 4),
        Expanded(
          child: Stack(
            children: [
              // Peta
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedLocation,
                  initialZoom: 15.0,
                  minZoom: 5.0,
                  maxZoom: 18.0,
                  onTap: (tapPosition, latLng) {
                    setState(() {
                      _selectedLocation = latLng;
                    });
                    widget.onLocationSelected(
                        latLng.latitude, latLng.longitude);
                  },
                ),
                children: [
                  // Layer peta
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.tailorhub',
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  // Marker
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 40.0,
                        height: 40.0,
                        point: _selectedLocation,
                        child: const Icon(
                          Icons.location_pin,
                          color: Color(0xFF1A2552),
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Tombol lokasi saat ini
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  heroTag: 'GetLocationBtn',
                  mini: true,
                  backgroundColor: const Color(0xFF1A2552),
                  onPressed: _getCurrentLocation,
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),
              ),
              // Info koordinat
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.white.withOpacity(0.8),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Text(
                    'Latitude: ${_selectedLocation.latitude.toStringAsFixed(6)}\nLongitude: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Instruksi
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey[200],
          width: double.infinity,
          child: const Text(
            'Ketuk pada peta untuk memilih lokasi atau gunakan tombol lokasi saat ini',
            style: TextStyle(fontSize: 12, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
