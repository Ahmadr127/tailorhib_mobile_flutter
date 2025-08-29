import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/booking_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/controllers/booking_controller.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Tambahkan import ini

class OrderDetailPage extends StatefulWidget {
  final BookingModel booking;

  const OrderDetailPage({
    super.key,
    required this.booking,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _rejectionReasonController =
      TextEditingController();
  final TextEditingController _repairNotesController = TextEditingController();
  final TextEditingController _additionalNotesController =
      TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _completionNotesController =
      TextEditingController();
  final TextEditingController _pickupDateController = TextEditingController();
  final TextEditingController _completionDateController = TextEditingController();

  // Untuk ukuran pakaian
  final Map<String, TextEditingController> _measurementControllers = {};

  // Dropdown values
  String _selectedServiceType = 'Jahit Baru';
  String _selectedCategory = 'Bawahan';

  // Loading state
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _isSaving = false;
  bool _isUpdatingPrice = false;
  bool _isCompletingOrder = false;
  bool _isCompletingPayment = false;
  String _errorMessage = '';
  BookingModel? _booking;

  // Untuk foto kerusakan
  String? _damagePhotoPath;
  File? _damagePhotoFile;
  bool _isUploadingPhoto = false;

  // Untuk foto hasil jahitan
  String? _completionPhotoPath;
  File? _completionPhotoFile;
  bool _isUploadingCompletionPhoto = false;

  // Map untuk menyimpan ukuran berdasarkan kategori
  final Map<String, List<String>> _measurementsByCategory = {
    'Bawahan': [
      'Panjang Celana',
      'Lingkar Pinggang',
      'Lingkar Pinggul',
      'Lingkar Paha',
      'Lingkar Lutut',
      'Lingkar Pergelangan Kaki',
    ],
    'Atasan': [
      'Panjang Baju',
      'Lingkar Lengan',
      'Lebar Pundak',
      'Lingkar Dada',
      'Panjang Lengan',
      'Lingkar Pinggang',
      'Kerung Lengan',
      'Lingkar Leher',
    ],
    'Terusan': [
      'Panjang Badan',
      'Lingkar Badan',
      'Lingkar Pinggang',
      'Lingkar Pinggul',
      'Panjang Rok/Dress',
      'Panjang Lengan',
      'Lebar Bahu',
      'Lingkar Lengan',
      'Lingkar Kerung',
    ],
  };

  // Map untuk menyimpan ukuran yang dipilih
  Map<String, bool> _selectedMeasurements = {};

  // Tambahkan variabel baru untuk tanggal pengambilan
  String? _selectedPickupDate;

  // Di bagian awal class _OrderDetailPageState, tambahkan fungsi formatRupiah
  String _formatRupiah(String nominal) {
    if (nominal.isEmpty) return '';
    
    print('DEBUG: _formatRupiah formatting price: "$nominal"');
    
    // Bersihkan nominal dari karakter non-angka
    String cleanNominal = nominal.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNominal.isEmpty) return '';
    
    print('DEBUG: _formatRupiah cleaned nominal: "$cleanNominal"');
    
    // Parse ke integer
    int value = int.tryParse(cleanNominal) ?? 0;
    print('DEBUG: _formatRupiah parsed integer value: "$value"');
    
    // Format dengan pemisah ribuan
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String result = value.toString().replaceAllMapped(reg, (Match match) => '${match[1]}.');
    
    print('DEBUG: _formatRupiah formatted result: "$result"');
    
    return result;
  }
  
  // Tambahkan fungsi untuk membersihkan format rupiah
  String _cleanRupiah(String nominal) {
    if (nominal.isEmpty) return '';
    
    // Tangani kasus dengan angka desimal - ambil hanya bagian sebelum titik desimal
    if (nominal.contains('.')) {
      nominal = nominal.split('.')[0];
    }
    
    // Bersihkan nominal dari karakter non-angka
    String cleanNominal = nominal.replaceAll(RegExp(r'[^0-9]'), '');
    print('DEBUG: _cleanRupiah input: $nominal, output: $cleanNominal');
    
    return cleanNominal;
  }

  @override
  void initState() {
    super.initState();
    _fetchBookingDetail();
    
    // Inisialisasi locale data untuk format tanggal Indonesia
    initializeDateFormatting('id_ID', null);

    // Inisialisasi controller untuk semua ukuran yang mungkin
    for (final category in _measurementsByCategory.keys) {
      for (final measurement in _measurementsByCategory[category]!) {
        _measurementControllers[measurement] = TextEditingController();
      }
    }
    
    // Inisialisasi tanggal penyelesaian default (7 hari dari sekarang)
    final DateTime defaultCompletionDate = DateTime.now().add(const Duration(days: 7));
    _completionDateController.text = DateFormat('yyyy-MM-dd').format(defaultCompletionDate);
  }

  Future<void> _fetchBookingDetail() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await ApiService.getBookingDetail(widget.booking.id);

      if (!mounted) return;

      if (result['success']) {
        // Simpan data booking lama untuk debugging
        final oldBooking = _booking;
        
        // Perbarui data booking dengan data terbaru
        final newBooking = BookingModel.fromJson(result['booking']);
        
        // Debug log untuk membantu debugging
        print('DEBUG: Refresh data booking berhasil');
        print('DEBUG: Harga lama: ${oldBooking?.totalPrice}, Harga baru: ${newBooking.totalPrice}');
        print('DEBUG: Tanggal selesai lama: ${oldBooking?.completionDate}, Tanggal selesai baru: ${newBooking.completionDate}');
        print('DEBUG: Foto desain: ${newBooking.designPhoto}');

      setState(() {
          _booking = newBooking;
        _isLoading = false;
          
          // Perbarui controller harga jika perlu
          if (newBooking.totalPrice != null && newBooking.totalPrice!.isNotEmpty) {
            _priceController.text = _cleanRupiah(newBooking.totalPrice!);
          }
          
          // Perbarui controller tanggal selesai jika perlu
          if (newBooking.completionDate != null && newBooking.completionDate!.isNotEmpty) {
            _completionDateController.text = newBooking.completionDate!;
          }
          
          // Inisialisasi ulang data
          _initializeData();
        });
        } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['message'];
      });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
      
      print('ERROR: Gagal mengambil detail booking: $e');
    }
  }

  void _initializeData() {
    if (_booking == null) return;

    _nameController.text = _booking!.getCustomerName();
    _selectedServiceType = _booking!.serviceType ?? 'Jahit Baru';
    _selectedCategory = _booking!.category ?? 'Bawahan';

    // Set harga jika sudah ada
    if (_booking?.totalPrice != null && _booking!.totalPrice!.isNotEmpty) {
      // Bersihkan format harga (hapus Rp, titik, koma, dsb)
      _priceController.text = _cleanRupiah(_booking!.totalPrice!);
      print('DEBUG: Harga dibersihkan: ${_priceController.text}');
    } else {
      _priceController.text = '';
    }

    // Set ukuran berdasarkan kategori yang dipilih
    if (_measurementsByCategory.containsKey(_selectedCategory)) {
      for (final measurement in _measurementsByCategory[_selectedCategory]!) {
        // Inisialisasi dengan nilai kosong atau nilai yang tersimpan jika ada
        if (_booking?.measurements != null) {
          try {
            // Cara 1: Coba parse JSON string menjadi Map
            Map<String, dynamic> measurementsMap;
            try {
              measurementsMap = jsonDecode(_booking!.measurements!);
            } catch (jsonError) {
              print('DEBUG: JSON parse error: $jsonError');
              
              // Cara 2: Format tidak standard, coba parse manual
              measurementsMap = _parseNonStandardJson(_booking!.measurements!);
            }
            
            // Ambil nilai pengukuran
            final key = measurement.toLowerCase().replaceAll(' ', '_');
            _measurementControllers[measurement]?.text =
                measurementsMap[key]?.toString() ?? '';
            
            // Debug output
            print('DEBUG: Measurement $measurement = ${_measurementControllers[measurement]?.text}');

            // Set catatan tambahan jika ada
            if (measurementsMap.containsKey('catatan_tambahan')) {
              _additionalNotesController.text =
                  measurementsMap['catatan_tambahan'] ?? '';
            }
          } catch (e) {
            // Jika parsing gagal, gunakan string kosong
            print('ERROR: Gagal parsing measurements: $e');
            _measurementControllers[measurement]?.text = '';
          }
        } else {
          _measurementControllers[measurement]?.text = '';
        }
      }
    }

    // Jika ada catatan perbaikan
    if (_booking?.repairNotes != null && _booking!.repairNotes!.isNotEmpty) {
      _repairNotesController.text = _booking!.repairNotes!;
    } else if (_booking?.notes != null && _booking!.notes!.isNotEmpty) {
      _repairNotesController.text = _booking!.notes!;
    }

    // Jika ada foto kerusakan
    if (_booking?.repairPhoto != null && _booking!.repairPhoto!.isNotEmpty) {
      _damagePhotoPath = _booking!.repairPhoto;
      _damagePhotoFile = null; // Reset _damagePhotoFile karena foto dari API
    }
  }

  // Tambahkan fungsi untuk parsing JSON non-standard
  Map<String, dynamic> _parseNonStandardJson(String input) {
    print('DEBUG: Parsing non-standard JSON: $input');
    
    // Hapus kurung kurawal pembuka dan penutup
    String content = input.trim();
    if (content.startsWith('{')) content = content.substring(1);
    if (content.endsWith('}')) content = content.substring(0, content.length - 1);
    
    Map<String, dynamic> result = {};
    
    // Split berdasarkan koma, tapi berhati-hati dengan koma dalam string
    bool inString = false;
    int lastSplit = 0;
    List<String> parts = [];
    
    for (int i = 0; i < content.length; i++) {
      if (content[i] == '"' || content[i] == "'") {
        inString = !inString;
      } else if (content[i] == ',' && !inString) {
        parts.add(content.substring(lastSplit, i).trim());
        lastSplit = i + 1;
      }
    }
    
    // Tambahkan bagian terakhir
    if (lastSplit < content.length) {
      parts.add(content.substring(lastSplit).trim());
    }
    
    // Parse setiap bagian key: value
    for (String part in parts) {
      print('DEBUG: Parsing part: $part');
      int colonIndex = part.indexOf(':');
      if (colonIndex > 0) {
        String key = part.substring(0, colonIndex).trim();
        String value = part.substring(colonIndex + 1).trim();
        
        // Bersihkan key dari tanda kutip
        if (key.startsWith('"') && key.endsWith('"')) {
          key = key.substring(1, key.length - 1);
        } else if (key.startsWith("'") && key.endsWith("'")) {
          key = key.substring(1, key.length - 1);
        }
        
        // Bersihkan value dari tanda kutip
        if (value.startsWith('"') && value.endsWith('"')) {
          value = value.substring(1, value.length - 1);
        } else if (value.startsWith("'") && value.endsWith("'")) {
          value = value.substring(1, value.length - 1);
        }
        
        result[key] = value;
        print('DEBUG: Parsed key: "$key", value: "$value"');
      }
    }
    
    print('DEBUG: Parsing result: $result');
    return result;
  }

  void _updateSelectedCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _selectedMeasurements = Map<String, bool>.fromEntries(
          (_measurementsByCategory[category] ?? [])
              .map((measurement) => MapEntry(measurement, true)));
    });
  }

  Future<void> _acceptBooking() async {
    if (!mounted || _booking == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await ApiService.acceptBooking(_booking!.id);

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        // Kembali ke halaman sebelumnya
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showRejectDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tolak Pesanan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Masukkan alasan penolakan pesanan:'),
                const SizedBox(height: 16),
                TextField(
                  controller: _rejectionReasonController,
                  decoration: const InputDecoration(
                    hintText: 'Alasan penolakan',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Tolak Pesanan'),
              onPressed: () {
                Navigator.of(context).pop();
                _rejectBooking(_rejectionReasonController.text);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _rejectBooking(String reason) async {
    if (!mounted || _booking == null) return;

    if (reason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alasan penolakan harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await ApiService.rejectBooking(_booking!.id, reason);

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        // Kembali ke halaman sebelumnya
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Tambahkan fungsi untuk mendapatkan URL foto lengkap
  String _getFullImageUrl(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) {
      return '';
    }

    // Jika sudah URL lengkap, kembalikan apa adanya
    if (photoPath.startsWith('http')) {
      return photoPath;
    }

    // Pastikan photo path memiliki format yang benar
    if (photoPath.startsWith('design_photos/')) {
      // URL untuk design_photos seharusnya menggunakan storage/
      return '${ApiService.imageBaseUrl}/storage/$photoPath';
    } else if (!photoPath.startsWith('/')) {
      return '${ApiService.imageBaseUrl}/storage/$photoPath';
    }

    // Format lainnya
    return ApiService.getFullImageUrl(photoPath);
  }

  // Modifikasi fungsi _buildImagePlaceholder untuk menampilkan foto dengan benar
  Widget _buildImagePlaceholder() {
    // Cek apakah ada design photo
    if (_booking?.designPhoto != null && _booking!.designPhoto!.isNotEmpty) {
      final String imageUrl = _getFullImageUrl(_booking!.designPhoto);
      print('DEBUG: URL Foto Desain: $imageUrl');

      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              print('ERROR: Gagal memuat gambar desain: $error');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.broken_image,
                        size: 50, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      'Gagal memuat gambar\n$error',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } else {
      // Tampilan jika tidak ada foto desain
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported,
                  size: 50, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'Tidak ada foto desain',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Fungsi untuk menyimpan data pesanan
  Future<void> _saveOrderData() async {
    if (!mounted || _booking == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Berdasarkan jenis layanan, gunakan API yang sesuai
      if (_selectedServiceType == 'Jahit Baru') {
        // Validasi data ukuran
        bool hasMeasurements = false;
        if (_measurementsByCategory.containsKey(_selectedCategory)) {
          for (final measurement
              in _measurementsByCategory[_selectedCategory]!) {
            if (_measurementControllers[measurement]?.text.trim().isNotEmpty ??
                false) {
              hasMeasurements = true;
              break;
            }
          }
        }

        if (!hasMeasurements) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mohon isi minimal satu ukuran'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() {
            _isSaving = false;
          });
          return;
        }

        await _updateMeasurements();
      } else if (_selectedServiceType == 'Perbaikan') {
        // Validasi catatan perbaikan
        if (_repairNotesController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mohon isi catatan perbaikan'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() {
            _isSaving = false;
          });
          return;
        }

        await _updateRepairDetails();
      }

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data pesanan berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload data
      _fetchBookingDetail();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Update ukuran untuk jahit baru
  Future<void> _updateMeasurements() async {
    print('DEBUG: Memperbarui ukuran untuk kategori: $_selectedCategory');
    try {
      if (!_measurementsByCategory.containsKey(_selectedCategory)) {
        return;
      }

      // Kumpulkan data ukuran
      Map<String, String> measurements = {};
      bool hasValidMeasurement = false;
      
      for (final measurement in _measurementsByCategory[_selectedCategory]!) {
        final value = _measurementControllers[measurement]?.text.trim() ?? '';
        if (value.isNotEmpty) {
          final key = measurement.toLowerCase().replaceAll(' ', '_');
          measurements[key] = value;
          hasValidMeasurement = true;
          print('DEBUG: Ukuran $key = $value');
        }
      }

      // Tambahkan catatan tambahan jika diperlukan
      final additionalNotes = _additionalNotesController.text.trim();
      if (additionalNotes.isNotEmpty) {
        measurements['catatan_tambahan'] = additionalNotes;
        print('DEBUG: Catatan tambahan: $additionalNotes');
      }

      if (!hasValidMeasurement) {
        print('DEBUG: Tidak ada ukuran yang diisi');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mohon isi minimal satu ukuran'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      print('DEBUG: Mengirim data ukuran: $measurements');
      
      // Konversi ke JSON String yang valid
      final measurementsJson = jsonEncode(measurements);
      print('DEBUG: JSON data ukuran: $measurementsJson');

      final response = await http.post(
        Uri.parse(
            '${ApiService.baseUrl}/bookings/${_booking!.id}/measurements'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'measurements': measurements,
        }),
      );

      print(
          'DEBUG: Update measurements response status: ${response.statusCode}');
      print('DEBUG: Update measurements response body: ${response.body}');

      if (response.statusCode != 200) {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Gagal memperbarui ukuran');
      }
      
      // Update UI feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ukuran berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh data dari server setelah update
      _fetchBookingDetail();
      
    } catch (e) {
      print('ERROR: Gagal update ukuran: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui ukuran: $e'),
          backgroundColor: Colors.red,
        ),
      );
      rethrow;
    }
  }

  // Update detail perbaikan untuk layanan perbaikan
  Future<void> _updateRepairDetails() async {
    print(
        'DEBUG: Memperbarui detail perbaikan. Jenis: $_selectedCategory, Ada Foto: ${_damagePhotoFile != null}');
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      // Buat request multipart untuk mengirim file
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/bookings/${_booking!.id}/repair'),
      );

      // Tambahkan headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Siapkan data perbaikan dalam format JSON string
      Map<String, String> repairDetails = {
        'jenis_perbaikan': _selectedCategory,
        'bagian': _selectedCategory,
      };

      // Tambahkan field sebagai JSON string
      request.fields['repair_details'] = jsonEncode(repairDetails);
      request.fields['repair_notes'] = _repairNotesController.text.trim();

      // Tambahkan foto jika ada
      if (_damagePhotoFile != null) {
        // Jika ada file lokal yang baru diupload
        request.files.add(
          await http.MultipartFile.fromPath(
            'repair_photo',
            _damagePhotoFile!.path,
          ),
        );
      } else if (_damagePhotoPath != null &&
          _damagePhotoPath!.isNotEmpty &&
          !_damagePhotoPath!.startsWith('http')) {
        // Jika _damagePhotoPath adalah path file lokal (bukan URL)
        request.fields['repair_photo'] = _damagePhotoPath!;
      }
      // Jika _damagePhotoPath adalah URL dan tidak ada file baru, tidak perlu mengirim foto

      // Kirim request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print(
          'DEBUG: Update repair details response status: ${response.statusCode}');
      print('DEBUG: Update repair details response body: ${response.body}');

      if (response.statusCode != 200) {
        final responseData = jsonDecode(response.body);
        throw Exception(
            responseData['message'] ?? 'Gagal memperbarui detail perbaikan');
      }
    } catch (e) {
      print('ERROR: Gagal update detail perbaikan: $e');
      rethrow;
    }
  }

  // Fungsi untuk mengunggah foto kerusakan
  Future<void> _uploadDamagePhoto() async {
    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      // Tampilkan dialog pilihan sumber foto
      final imageSource = await _showImageSourceDialog();

      if (imageSource == null) {
        setState(() {
          _isUploadingPhoto = false;
        });
        return;
      }

      // Pilih foto dari sumber yang dipilih
      final pickedFile = await _pickImage(imageSource);

      if (pickedFile != null) {
        setState(() {
          _damagePhotoFile = pickedFile;
          _damagePhotoPath = pickedFile.path;
          _isUploadingPhoto = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto kerusakan berhasil dipilih'),
              backgroundColor: Colors.green,
            ),
          );
        });
      } else {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploadingPhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Dialog untuk memilih sumber gambar (galeri atau kamera)
  Future<ImageSource?> _showImageSourceDialog() async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Sumber Foto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk memilih gambar dari galeri atau kamera
  Future<File?> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80, // Mengurangi ukuran file jika terlalu besar
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('ERROR: Gagal memilih gambar: $e');
      // Tampilkan pesan error jika diperlukan
      return null;
    }
  }

  // Fungsi untuk memilih gambar dari galeri (deprecated, digantikan oleh _pickImage)
  Future<File?> _pickImageFromGallery() async {
    return _pickImage(ImageSource.gallery);
  }

  // Fungsi untuk membangun form input ukuran
  Widget _buildMeasurementInputs() {
    if (!_measurementsByCategory.containsKey(_selectedCategory)) {
      return const SizedBox.shrink();
    }

    final measurements = _measurementsByCategory[_selectedCategory]!;
    
    // Cek apakah ada ukuran yang sudah terisi
    bool hasMeasurements = false;
    for (String measurement in measurements) {
      if (_measurementControllers[measurement]?.text.isNotEmpty ?? false) {
        hasMeasurements = true;
        break;
      }
    }
    
    // Cek apakah status sudah selesai (hanya tampilkan, tidak bisa edit)
    final bool isCompleted = _booking?.status.toLowerCase() == 'selesai';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Ukuran $_selectedCategory'),
            if (hasMeasurements)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Ukuran terisi',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (!hasMeasurements && !isCompleted)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Belum ada ukuran yang diisi. Silakan isi minimal satu ukuran.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ...measurements
            .map((measurement) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTextField(
                    measurement,
                    _measurementControllers[measurement]!,
                    enabled: !isCompleted,
                    keyboardType: TextInputType.number,
                    suffixText: 'cm',
                  ),
                ))
            ,
        const SizedBox(height: 16),
        _buildSectionTitle('Catatan Tambahan'),
        const SizedBox(height: 12),
        TextField(
          controller: _additionalNotesController,
          enabled: !isCompleted,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: isCompleted 
              ? '' 
              : 'Catatan tambahan untuk ukuran (opsional)',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1A2552)),
            ),
          ),
        ),
      ],
    );
  }

  // Fungsi untuk membangun form input perbaikan
  Widget _buildRepairInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Catatan Perbaikan'),
        const SizedBox(height: 12),
        TextField(
          controller: _repairNotesController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Masukkan detail perbaikan yang dibutuhkan',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1A2552)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('Foto Kerusakan'),
        const SizedBox(height: 12),
        _buildDamagePhotoUploader(),
      ],
    );
  }

  // Fungsi untuk membangun uploader foto kerusakan
  Widget _buildDamagePhotoUploader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_damagePhotoPath != null && _damagePhotoPath!.isNotEmpty)
          Container(
            width: double.infinity,
            height: 200,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _damagePhotoFile != null
                  ? Image.file(
                      _damagePhotoFile!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('ERROR: Gagal memuat file gambar lokal: $error');
                        return _buildBrokenImagePlaceholder();
                      },
                    )
                  : Image.network(
                      _getFullImageUrl(_damagePhotoPath),
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('ERROR: Gagal memuat gambar dari URL: $error');
                        return _buildBrokenImagePlaceholder();
                      },
                    ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isUploadingPhoto ? null : _uploadDamagePhoto,
            icon: _isUploadingPhoto
                ? Container(
                    width: 24,
                    height: 24,
                    padding: const EdgeInsets.all(2.0),
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : const Icon(Icons.camera_alt),
            label: Text(_damagePhotoPath == null
                ? 'Upload Foto Kerusakan'
                : 'Ganti Foto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A2552),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widget placeholder untuk gambar yang gagal dimuat
  Widget _buildBrokenImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image, size: 50, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            'Gagal memuat gambar',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // Modifikasi fungsi _buildTextField untuk menambahkan suffixText
  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    String? suffixText,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        prefixText: prefixText,
        suffixText: suffixText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1A2552)),
        ),
      ),
    );
  }

  // Method untuk update harga pesanan
  Future<void> _updatePrice() async {
    if (_booking == null) return;

    if (_priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon isi harga terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Tampilkan dialog untuk input harga dan tanggal penyelesaian
    // Dialog ini sudah mencakup konfirmasi, jadi tidak perlu dialog tambahan
    final bool? confirmed = await _showInputPriceAndDateDialog();
    if (confirmed != true) return;

    int price;
    String completionDate = _completionDateController.text;
    
    try {
      // Bersihkan teks harga dari karakter non-angka
      final String cleanedPriceText = _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      print('DEBUG: Cleaned price text: $cleanedPriceText');
      
      if (cleanedPriceText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harga tidak boleh kosong'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Konversi string ke int secara langsung
      price = int.parse(cleanedPriceText);
      
      print('DEBUG: Harga final yang akan diupdate: $price');
      print('DEBUG: Tanggal penyelesaian yang akan diupdate: $completionDate');
    } catch (e) {
      print('ERROR: Gagal parsing harga: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Format harga tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUpdatingPrice = true;
    });

    try {
      print('DEBUG: Mengirim update harga ke API untuk booking ID: ${_booking!.id} dengan harga: $price dan tanggal selesai: $completionDate');
      final result = await ApiService.updateBookingPrice(_booking!.id, price, completionDate);
      print('DEBUG: Hasil update harga: $result');

      if (!mounted) return;

      // Refresh data dari server untuk memastikan UI diperbarui dengan benar
      await _fetchBookingDetail();

      setState(() {
        _isUpdatingPrice = false;
      });

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Harga dan tanggal selesai berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal memperbarui harga dan tanggal selesai'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('ERROR: Gagal melakukan update harga: $e');
      if (!mounted) return;

      setState(() {
        _isUpdatingPrice = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Dialog untuk menginput harga dan tanggal penyelesaian
  Future<bool?> _showInputPriceAndDateDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Penetapan Harga dan Tanggal Selesai'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Masukkan harga dan tanggal penyelesaian pesanan:'),
                const SizedBox(height: 16),
                
                // Input harga
                TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga (Rp)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monetization_on),
                    hintText: 'Contoh: 150000',
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      // Format harga dengan pemisah ribuan saat pengguna mengetik
                      final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                      if (cleanValue.isNotEmpty) {
                        final number = int.parse(cleanValue);
                        final formatted = _formatRupiah(number.toString());
                        
                        // Hindari infinite loop dengan memeriksa apakah nilai berubah
                        if (formatted != value) {
                          _priceController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        }
                      }
                    }
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Input tanggal penyelesaian
                GestureDetector(
                  onTap: () => _selectCompletionDate(dialogContext),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _completionDateController,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Penyelesaian',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                        hintText: 'YYYY-MM-DD',
                  ),
                ),
              ),
            ),
                const SizedBox(height: 8),
                const Text(
                  'Pilih tanggal ketika pesanan diperkirakan selesai',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2552),
              ),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  // Method untuk upload foto hasil jahitan
  Future<void> _uploadCompletionPhoto() async {
    setState(() {
      _isUploadingCompletionPhoto = true;
    });

    try {
      // Tampilkan dialog pilihan sumber foto
      final imageSource = await _showImageSourceDialog();

      if (imageSource == null) {
        setState(() {
          _isUploadingCompletionPhoto = false;
        });
        return;
      }

      // Pilih foto dari sumber yang dipilih
      final pickedFile = await _pickImage(imageSource);

      if (pickedFile != null) {
        setState(() {
          _completionPhotoFile = pickedFile;
          _completionPhotoPath = pickedFile.path;
          _isUploadingCompletionPhoto = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto hasil jahitan berhasil dipilih'),
              backgroundColor: Colors.green,
            ),
          );
        });
      } else {
        setState(() {
          _isUploadingCompletionPhoto = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploadingCompletionPhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method untuk menyelesaikan pesanan
  Future<void> _completeBooking() async {
    if (!mounted || _booking == null) return;

    if (_completionNotesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon isi catatan penyelesaian'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_completionPhotoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon pilih foto hasil jahitan'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isCompletingOrder = true);

    try {
      final result = await context.read<BookingController>().completeBooking(
            widget.booking.id,
            _completionNotesController.text.trim(),
            _completionPhotoFile!.path,
            _selectedPickupDate,
          );

      if (!mounted) return;

      setState(() {
        _isCompletingOrder = false;
      });

      if (result['success']) {
        // Update data booking jika ada data terbaru
        if (result['booking'] != null) {
          setState(() {
            _booking = BookingModel.fromJson(result['booking']);
            _fetchBookingDetail(); // Refresh data
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Pesanan berhasil diselesaikan'),
            backgroundColor: Colors.green,
          ),
        );

        // Kembali ke halaman sebelumnya setelah berhasil
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal menyelesaikan pesanan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCompletingOrder = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Tambahkan method untuk memilih tanggal
  Future<void> _selectPickupDate(BuildContext context) async {
    try {
      final DateTime now = DateTime.now();
      DateTime initialDate = now.add(const Duration(days: 1));

      if (_selectedPickupDate != null && _selectedPickupDate!.isNotEmpty) {
        try {
          initialDate = DateTime.parse(_selectedPickupDate!);
        } catch (e) {
          print('ERROR: Gagal parsing tanggal: $e');
        }
      }

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: now,
        lastDate: now.add(const Duration(days: 90)),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF1A2552),
                onPrimary: Colors.white,
                onSurface: Color(0xFF1A2552),
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        setState(() {
          _selectedPickupDate = picked.toIso8601String();
          _pickupDateController.text =
              "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
        });
      }
    } catch (e) {
      print('ERROR: Gagal memilih tanggal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat memilih tanggal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method untuk menyelesaikan pembayaran
  Future<void> _completePayment() async {
    if (!mounted || _booking == null) return;

    // Validasi input tanggal
    if (_pickupDateController.text.trim().isEmpty ||
        _selectedPickupDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon pilih tanggal pengambilan terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isCompletingPayment = true;
    });

    try {
      final result = await ApiService.completePayment(
        _booking!.id,
        _selectedPickupDate!,
      );

      if (!mounted) return;

      setState(() {
        _isCompletingPayment = false;
      });

      if (result['success']) {
        // Update data booking jika ada data terbaru
        if (result['booking'] != null) {
          setState(() {
            _booking = BookingModel.fromJson(result['booking']);
            _fetchBookingDetail(); // Refresh data
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(result['message'] ?? 'Pembayaran berhasil dikonfirmasi'),
            backgroundColor: Colors.green,
          ),
        );

        // Kembali ke halaman sebelumnya setelah berhasil
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(result['message'] ?? 'Gagal mengkonfirmasi pembayaran'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCompletingPayment = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // UI untuk form penyelesaian pesanan
  Widget _buildCompletionForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Penyelesaian Pesanan'),
        const SizedBox(height: 12),

        // Form input catatan penyelesaian
        TextField(
          controller: _completionNotesController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Catatan Penyelesaian',
            hintText: 'Tulis catatan penyelesaian pesanan...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1A2552)),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Upload foto hasil jahitan
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Foto Hasil Jahitan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),

            // Preview foto jika sudah dipilih
            if (_completionPhotoFile != null)
              Container(
                width: double.infinity,
                height: 200,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _completionPhotoFile!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('ERROR: Gagal memuat gambar: $error');
                      return _buildBrokenImagePlaceholder();
                    },
                  ),
                ),
              ),

            // Tombol upload foto
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed:
                    _isUploadingCompletionPhoto ? null : _uploadCompletionPhoto,
                icon: _isUploadingCompletionPhoto
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(Icons.camera_alt),
                label: Text(_completionPhotoFile == null
                    ? 'Upload Foto Hasil Jahitan'
                    : 'Ganti Foto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A2552),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Tombol selesaikan pesanan
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isCompletingOrder ? null : _completeBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isCompletingOrder
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : const Text(
                    'Selesaikan Pesanan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // UI untuk form konfirmasi pembayaran
  Widget _buildPaymentConfirmationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Konfirmasi Pembayaran'),
        const SizedBox(height: 12),

        // Deskripsi form
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Konfirmasi Pembayaran COD',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Dengan mengonfirmasi pembayaran, Anda menyatakan bahwa pelanggan telah melunasi pembayaran Cash on Delivery (COD) dan mengatur tanggal pengambilan.',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Form input tanggal pengambilan
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tanggal Pengambilan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectPickupDate(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _pickupDateController.text.isEmpty
                            ? 'Pilih tanggal pengambilan'
                            : _pickupDateController.text,
                        style: TextStyle(
                          color: _pickupDateController.text.isEmpty
                              ? Colors.grey.shade500
                              : Colors.black,
                        ),
                      ),
                    ),
                    Icon(Icons.calendar_month, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Tombol konfirmasi pembayaran
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isCompletingPayment ? null : _completePayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isCompletingPayment
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : const Text(
                    'Konfirmasi Pembayaran COD',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // Di dalam class _OrderDetailPageState, tambahkan helper function untuk mendapatkan status teks pembayaran
  String _getPaymentStatusText() {
    if (_booking == null) return '-';

    // Periksa properti payment_status (pastikan model memiliki properti ini)
    final String paymentStatus = (_booking!.paymentStatus ?? '').toLowerCase();

    switch (paymentStatus) {
      case 'paid':
        return 'Lunas';
      case 'partial':
        return 'Sebagian';
      case 'unpaid':
        return 'Belum Bayar';
      default:
        return paymentStatus.isNotEmpty ? paymentStatus : 'Belum Bayar';
    }
  }

  // Tambahkan method untuk membangun badge status pembayaran
  Widget _buildPaymentStatusBadge() {
    if (_booking == null) return const SizedBox.shrink();

    final String paymentStatus = (_booking!.paymentStatus ?? '').toLowerCase();
    Color badgeColor;
    IconData badgeIcon;

    switch (paymentStatus) {
      case 'paid':
        badgeColor =
            const Color(0xFF34A853); // Hijau Google yang lebih profesional
        badgeIcon = Icons.check_circle;
        break;
      case 'partial':
        badgeColor = const Color(0xFFFBBC05); // Kuning Google
        badgeIcon = Icons.monetization_on;
        break;
      default:
        badgeColor = const Color(0xFF9AA0A6); // Abu-abu Google
        badgeIcon = Icons.money_off;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, color: badgeColor, size: 14),
          const SizedBox(width: 4),
          Text(
            _getPaymentStatusText(),
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Revisi tampilan info pembayaran untuk gaya yang lebih modern
  Widget _buildPaymentInfoCard() {
    if (_booking == null) return const SizedBox.shrink();

    final String paymentStatus = (_booking!.paymentStatus ?? '').toLowerCase();
    final bool isPaid = paymentStatus == 'paid';
    final Color themeColor =
        isPaid ? const Color(0xFF34A853) : const Color(0xFF1A2552);

    // Format harga dengan benar
    String formattedPrice = 'Belum ditetapkan';
    int basePrice = 0;
    
    if (_booking!.totalPrice != null && _booking!.totalPrice!.isNotEmpty) {
      // Log untuk debugging
      print('DEBUG: Original totalPrice dari booking: "${_booking!.totalPrice}"');
      
      // Untuk menghindari masalah dengan titik desimal, pastikan kita mengambil nilai yang benar
      String priceToFormat = _booking!.totalPrice!;
      
      // Jika berformat desimal (mis. 50000.00), hanya ambil bagian integer
      if (priceToFormat.contains('.')) {
        priceToFormat = priceToFormat.split('.')[0];
        print('DEBUG: Mengambil bagian integer saja: "$priceToFormat"');
      }
      
      String cleanPrice = _cleanRupiah(priceToFormat);
      print('DEBUG: totalPrice setelah dibersihkan: "$cleanPrice"');
      
      // Parse ke integer
      basePrice = int.tryParse(cleanPrice) ?? 0;
      
      // Pastikan nilai dalam format yang benar (hindari pembersihan ganda)
      formattedPrice = _formatRupiah(cleanPrice);
      print('DEBUG: Harga final yang ditampilkan: "$formattedPrice"');
    }
    
    // Cek metode pembayaran
    final bool isCod = (_booking!.paymentMethod?.toLowerCase() == 'cod' ||
                        _booking!.paymentMethod?.toLowerCase() == 'cash_on_delivery');
    
    // Biaya tambahan - 0 jika COD
    final int paymentServiceFee = isCod ? 0 : 4000; 
    // final int tailorServiceFee = isCod ? 0 : 1000;
    final int totalPrice = basePrice + paymentServiceFee;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan status pembayaran yang lebih modern
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isPaid ? const Color(0xFFEDF7ED) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color:
                      isPaid ? const Color(0xFFCEEDCE) : Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Informasi Pembayaran',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isPaid
                        ? const Color(0xFF1E8E3E)
                        : const Color(0xFF1A2552),
                  ),
                ),
                if (isPaid)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34A853),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF34A853).withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Lunas',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Tampilkan badge COD jika metode pembayaran COD
                if (isCod)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.monetization_on, size: 14, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'COD',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Isi dengan informasi pembayaran detail
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rincian biaya
                if (basePrice > 0) ...[
                  // Biaya Jahit
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'Biaya Jahit',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                          fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                        'Rp $formattedPrice',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Hanya tampilkan biaya layanan jika bukan COD
                  if (!isCod) ...[
                    // Biaya Layanan Payment
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Biaya Layanan Payment',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Rp ${_formatRupiah(paymentServiceFee.toString())}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Biaya Layanan Tailor
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     Text(
                    //       'Biaya Layanan Tailor',
                    //       style: TextStyle(
                    //         color: Colors.grey.shade700,
                    //         fontSize: 14,
                    //       ),
                    //     ),
                    //     Text(
                    //       'Rp ${_formatRupiah(tailorServiceFee.toString())}',
                    //       style: const TextStyle(
                    //         fontSize: 14,
                    //         color: Colors.black,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ] else ...[
                    // Pesan penjelasan biaya COD
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, top: 4),
                      child: Text(
                        "Tidak ada biaya layanan tambahan untuk metode COD",
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  
                  // Total Pembayaran
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Pembayaran',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1A2552),
                        ),
                      ),
                      Text(
                        'Rp ${_formatRupiah(totalPrice.toString())}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                ] else ...[
                  // Jika tidak ada harga (belum ditetapkan)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Harga belum ditetapkan',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Tampilkan tanggal pengambilan dengan ikon kalender
                if (_booking?.pickupDate != null &&
                    _booking!.pickupDate!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event_available,
                            color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tanggal Pengambilan',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatPickupDate(_booking!.pickupDate!),
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper untuk memformat tanggal pengambilan
  String _formatPickupDate(String isoDate) {
    try {
      // Parse tanggal dari format ISO
      final DateTime date = DateTime.parse(isoDate);
      // Format menjadi dd/MM/yyyy
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      print('ERROR: Gagal memformat tanggal: $e');
      return isoDate; // Kembalikan format asli jika gagal parsing
    }
  }

  // Add this new widget to build rating and review card
  Widget _buildRatingAndReviewCard() {
    if (_booking == null || _booking?.status.toLowerCase() != 'selesai' || _booking?.rating == null) {
      print('DEBUG: Rating card not shown because:');
      print('DEBUG: - Booking is null: ${_booking == null}');
      print('DEBUG: - Status is not selesai: ${_booking?.status.toLowerCase() != 'selesai'}');
      print('DEBUG: - Rating is null: ${_booking?.rating == null}');
      return const SizedBox.shrink();
    }

    // Debug print the rating data structure
    print('DEBUG: Rating data: ${_booking!.rating}');
    print('DEBUG: Rating data type: ${_booking!.rating.runtimeType}');

    // Safely access rating data
    final ratingData = _booking!.rating as Map<String, dynamic>;
    final ratingValue = ratingData['rating']?.toString() ?? '0.0';
    final reviewText = ratingData['review']?.toString();
    final createdAt = ratingData['created_at']?.toString();

    print('DEBUG: Rating value: $ratingValue');
    print('DEBUG: Review text: $reviewText');
    print('DEBUG: Created at: $createdAt');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Rating & Ulasan'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rating section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            ratingValue,
                            style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'dari pelanggan',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Divider(height: 1, color: Colors.grey.shade200),

              // Review section
              if (reviewText != null && reviewText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ulasan:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reviewText,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

              // Review date
              if (createdAt != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    'Diberikan pada ${_formatDate(createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Add helper method to format date
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      print('ERROR: Gagal memformat tanggal: $e');
      return dateStr;
    }
  }

  // Widget untuk input harga dan tanggal penyelesaian yang lebih user friendly
  Widget _buildPriceInput() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white, // Mengubah warna background menjadi putih
      margin: EdgeInsets.zero, // Menghilangkan margin default dari Card
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Mengatur ukuran kolom agar tidak memakan ruang berlebih
          children: [
            // Header dengan ikon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2552).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.price_check,
                    color: Color(0xFF1A2552),
                    size: 20, // Mengurangi ukuran ikon
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Informasi Harga & Penyelesaian',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2552),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16), // Mengurangi jarak
            
            // Input harga dengan format yang lebih baik
            const Text(
              'Harga Pesanan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A2552),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  // Prefiks Rp
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(9),
                        bottomLeft: Radius.circular(9),
                      ),
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: const Text(
                      'Rp',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2552),
                      ),
                    ),
                  ),
                  
                  // Input field
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Masukkan harga pesanan',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                          if (cleanValue.isNotEmpty) {
                            final number = int.parse(cleanValue);
                            final formatted = _formatRupiah(number.toString());
                            
                            // Hindari infinite loop dengan memeriksa apakah nilai berubah
                            if (formatted != value) {
                              _priceController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(offset: formatted.length),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16), // Mengurangi jarak
            
            // Input tanggal penyelesaian dengan tampilan yang lebih baik
            const Text(
              'Tanggal Penyelesaian',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A2552),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectCompletionDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Mengurangi padding vertikal
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.blue.shade700, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        // Format tanggal ke format yang lebih mudah dibaca oleh user
                        _getFormattedCompletionDate(),
                        style: const TextStyle(
                          fontSize: 15, // Mengurangi ukuran font
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 10), // Mengurangi jarak
            
            // Info box tentang tanggal penyelesaian
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // Mengurangi padding
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start, // Memastikan ikon sejajar dengan teks di atas
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2), // Sesuaikan posisi ikon
                    child: Icon(Icons.info_outline, color: Colors.blue.shade700, size: 14), // Mengurangi ukuran ikon
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tanggal ini akan ditampilkan ke pelanggan sebagai estimasi waktu penyelesaian pesanan',
                      style: TextStyle(
                        fontSize: 11, // Mengurangi ukuran font
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16), // Mengurangi jarak
            
            // Tombol update yang lebih menarik
            SizedBox(
              width: double.infinity,
              height: 48, // Menetapkan tinggi tombol secara eksplisit
              child: ElevatedButton.icon(
                onPressed: _isUpdatingPrice ? null : _updatePrice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A2552),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 0), // Mengurangi padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0, // Mengurangi shadow
                ),
                icon: _isUpdatingPrice
                    ? Container(
                        width: 18,
                        height: 18,
                        padding: const EdgeInsets.all(0),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline, size: 18), // Mengurangi ukuran ikon
                label: Text(
                  _isUpdatingPrice ? 'Menyimpan...' : 'Simpan Harga & Tanggal',
                  style: const TextStyle(
                    fontSize: 15, // Mengurangi ukuran font
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Method untuk mendapatkan format tanggal yang lebih user-friendly
  String _getFormattedCompletionDate() {
    try {
      final date = DateTime.parse(_completionDateController.text);
      
      // Format default untuk semua tanggal (tanpa logic relatif)
      return DateFormat('d MMMM yyyy').format(date);
    } catch (e) {
      // Jika gagal parsing, kembalikan text yang ada di controller
      print('ERROR: Gagal parsing tanggal penyelesaian: $e');
      return _completionDateController.text;
    }
  }

  // Widget untuk menampilkan foto hasil dan catatan penyelesaian pada pesanan dengan status selesai
  Widget _buildCompletionDetails() {
    if (_booking?.completionPhoto == null || _booking!.completionPhoto!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Detail Penyelesaian Pesanan'),
        const SizedBox(height: 12),

        // Tampilkan foto hasil jahitan
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Foto Hasil Jahitan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _getFullImageUrl(_booking!.completionPhoto),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('ERROR: Gagal memuat gambar dari URL: $error');
                    return _buildBrokenImagePlaceholder();
                  },
                ),
              ),
            ),
          ],
        ),

        // Tampilkan catatan penyelesaian jika ada
        if (_booking?.completionNotes != null && _booking!.completionNotes!.isNotEmpty) ...[
          Text(
            'Catatan Penyelesaian',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              _booking!.completionNotes!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Detail Booking',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF1A2552),
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A2552)),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Detail Booking',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF1A2552),
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A2552)),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchBookingDetail,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final isOrderInProcess = _booking?.status.toLowerCase() == 'diproses';
    final isNewTailoring = _selectedServiceType == 'Jahit Baru';
    final isRepair = _selectedServiceType == 'Perbaikan';
    final isCompleted = _booking?.status.toLowerCase() == 'selesai';

    // Cek apakah pesanan sudah memiliki data lengkap untuk ditentuken harganya
    final bool canSetPrice = isOrderInProcess &&
        ((isNewTailoring &&
                _booking?.measurements != null &&
                _booking!.measurements!.isNotEmpty) ||
            (isRepair &&
                _booking?.repairDetails != null &&
                _booking!.repairDetails!.isNotEmpty));

    // Cek apakah pesanan sudah memiliki harga (untuk menyelesaikan pesanan)
    final bool canComplete = isOrderInProcess &&
        _booking?.totalPrice != null &&
        _booking!.totalPrice!.isNotEmpty;

    // Cek apakah status selesai dan belum ada pickup date
    final bool canConfirmPayment =
        _booking?.status.toLowerCase() == 'selesai' &&
        (_booking?.pickupDate == null || _booking!.pickupDate!.isEmpty) &&
        (_booking?.paymentMethod != null && 
         (_booking!.paymentMethod!.toLowerCase() == 'cod' || 
          _booking!.paymentMethod!.toLowerCase() == 'cash_on_delivery'));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Detail Booking',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF1A2552),
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A2552)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _isProcessing ||
              _isSaving ||
              _isCompletingOrder ||
              _isCompletingPayment
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bagian Detail Pesanan
                  _buildSectionTitle('Detail Pesanan'),
                  const SizedBox(height: 8),
                  _buildInfoCard([
                    _buildInfoRow(
                        'Tanggal', _booking?.getFormattedDate() ?? '-'),
                    _buildInfoRow('Waktu', _booking?.appointmentTime ?? '-'),
                    _buildInfoRow(
                        'Status Pesanan', _booking?.getStatusText() ?? '-'),
                  ]),

                  const SizedBox(height: 20),

                  // Tampilkan info pembayaran jika pesanan sudah memiliki harga
                  if (_booking?.totalPrice != null &&
                      _booking!.totalPrice!.isNotEmpty)
                    _buildPaymentInfoCard(),

                  // Jenis Layanan dan Kategori
                  _buildSectionTitle('Jenis Layanan'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    'Jenis',
                    TextEditingController(text: _booking?.serviceType ?? '-'),
                    enabled: false,
                  ),

                  const SizedBox(height: 16),

                  _buildSectionTitle('Kategori'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    'Kategori',
                    TextEditingController(text: _booking?.category ?? '-'),
                    enabled: false,
                  ),

                  const SizedBox(height: 16),

                  // Detail penyelesaian untuk pesanan dengan status selesai
                  if (isCompleted) ...[
                    _buildCompletionDetails(),
                    const SizedBox(height: 20),
                  ],

                  // Jika status diproses atau selesai dan jenis layanan Jahit Baru, tampilkan input ukuran
                  if ((isOrderInProcess || _booking?.status.toLowerCase() == 'selesai') && isNewTailoring) ...[
                    _buildMeasurementInputs(),
                    const SizedBox(height: 20),
                  ],

                  // Jika status diproses dan jenis layanan Perbaikan, tampilkan input catatan dan foto kerusakan
                  if (isOrderInProcess && isRepair) ...[
                    _buildRepairInputs(),
                    const SizedBox(height: 20),
                  ],

                  // Tambahkan input harga jika pesanan sudah memiliki data lengkap
                  if (canSetPrice) ...[
                    _buildPriceInput(),
                    const SizedBox(height: 20),
                  ],

                  // Tambahkan form penyelesaian jika pesanan sudah memiliki harga
                  if (canComplete) ...[
                    _buildCompletionForm(),
                    const SizedBox(height: 20),
                  ],

                  // Tambahkan form konfirmasi pembayaran jika status selesai, belum ada pickup date dan belum paid
                  if (canConfirmPayment &&
                      (_booking?.paymentStatus == null ||
                          _booking!.paymentStatus!.toLowerCase() !=
                              'paid')) ...[
                    _buildPaymentConfirmationForm(),
                    const SizedBox(height: 20),
                  ],

                  _buildSectionTitle('Foto Pesanan Desain'),
                  const SizedBox(height: 8),
                  _buildImagePlaceholder(),

                  const SizedBox(height: 24),

                  // Tombol Simpan untuk status diproses
                  if (isOrderInProcess)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveOrderData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A2552),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Simpan Data',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                  // Action Buttons for Reservasi status
                  if (_booking?.status.toLowerCase() == 'reservasi')
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _acceptBooking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A2552),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Terima Booking',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _showRejectDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                            child: const Text(
                              'Tolak Booking',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Rating and review card moved to the bottom
                  if (_booking?.totalPrice != null &&
                      _booking!.totalPrice!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildRatingAndReviewCard(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A2552),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...children,
          
          // Tambahkan kode transaksi jika tersedia
          if (_booking?.transactionCode != null && _booking!.transactionCode!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_long, color: Colors.blue.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kode Transaksi',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _booking!.transactionCode!,
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Tampilkan metode pembayaran jika tersedia
          if (_booking?.paymentMethod != null && _booking!.paymentMethod!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    _getPaymentMethodIcon(_booking!.paymentMethod!),
                    color: Colors.green.shade700, 
                    size: 16
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Metode Pembayaran',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getPaymentMethodText(_booking!.paymentMethod!),
                          style: TextStyle(
                            color: Colors.green.shade900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Tambahkan notes jika ada
          if (_booking?.notes != null && _booking!.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.note, color: Colors.blue.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catatan Pesanan',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _booking!.notes ?? '',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Tambahkan alasan penolakan jika status dibatalkan
          if (_booking?.status.toLowerCase() == 'dibatalkan' &&
              _booking?.rejectionReason != null &&
              _booking!.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.cancel, color: Colors.red.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alasan Penolakan',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _booking!.rejectionReason!,
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper untuk mendapatkan ikon metode pembayaran
  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'transfer_bank':
        return Icons.account_balance;
      case 'cod':
      case 'cash_on_delivery':
        return Icons.monetization_on;
      default:
        return Icons.payment;
    }
  }
  
  // Helper untuk mendapatkan teks metode pembayaran
  String _getPaymentMethodText(String method) {
    switch (method.toLowerCase()) {
      case 'transfer_bank':
        return 'Transfer Bank';
      case 'cod':
      case 'cash_on_delivery':
        return 'Cash on Delivery (COD)';
      default:
        return method;
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const Text(':'),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _rejectionReasonController.dispose();
    _repairNotesController.dispose();
    _additionalNotesController.dispose();
    _priceController.dispose();
    _completionNotesController.dispose();
    _pickupDateController.dispose();
    _completionDateController.dispose(); // Tambahkan dispose untuk controller baru

    // Dispose semua measurement controllers
    for (final controller in _measurementControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  // Method untuk konfirmasi harga yang sangat besar
  Future<bool> _showPriceConfirmationDialog(int price) async {
    // Format harga dengan pemisah ribuan
    final formatter = NumberFormat('#,###', 'id_ID');
    final formattedPrice = formatter.format(price);
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Harga'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Anda akan menetapkan harga Rp $formattedPrice'),
                const SizedBox(height: 16),
                const Text('Apakah harga ini sudah benar?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: const Text('Benar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;
  }

  // Method untuk memilih tanggal penyelesaian
  Future<void> _selectCompletionDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_completionDateController.text) ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A2552),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ), dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _completionDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // Dialog konfirmasi harga dan tanggal penyelesaian
  Future<bool> _showPriceAndDateConfirmationDialog(String price, String completionDate) async {
    // Format harga dengan pemisah ribuan
    final cleanedPrice = price.replaceAll(RegExp(r'[^0-9]'), '');
    final formattedPrice = _formatRupiah(cleanedPrice);
    
    // Format tanggal
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(completionDate);
    } catch (e) {
      parsedDate = DateTime.now();
    }
    final formattedDate = DateFormat('d MMMM yyyy').format(parsedDate);
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Simpan perubahan berikut?'),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  const Text('Harga: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Rp $formattedPrice'),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  const Text('Tanggal Selesai: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(formattedDate),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2552),
              ),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;
  }
}
