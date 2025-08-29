import 'package:flutter/material.dart';
import '../../../core/models/tailor_model.dart';
import '../../../core/models/gallery_model.dart';
import '../../../core/services/api_service.dart';
import 'booking_page.dart';
import 'review_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DescriptionPage extends StatefulWidget {
  final TailorModel tailor;

  const DescriptionPage({
    super.key,
    required this.tailor,
  });

  @override
  State<DescriptionPage> createState() => _DescriptionPageState();
}

class _DescriptionPageState extends State<DescriptionPage> {
  bool _isLoading = false;
  late TailorModel _tailorDetail;
  List<GalleryModel> _galleryItems = [];

  @override
  void initState() {
    super.initState();
    _tailorDetail = widget.tailor;
    _loadTailorGallery();
  }

  Future<void> _loadTailorGallery() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load tailor gallery saja, tidak fetch ulang detail tailor
      final galleryResult =
          await ApiService.getTailorGalleryById(_tailorDetail.id);

      if (galleryResult['success']) {
        setState(() {
          _galleryItems = galleryResult['gallery'] as List<GalleryModel>;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Detail Penjahit',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF1A2552),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF1A2552),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF1A2552),
              size: 18,
            ),
            onPressed: () => Navigator.of(context).pop(),
            splashRadius: 24,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                return false;
              },
              child: RefreshIndicator(
                onRefresh: _loadTailorGallery,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header dengan foto dan info penjahit
                        Row(
                          children: [
                            // Foto penjahit
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 50,
                                height: 50,
                                child: _tailorDetail.profilePhoto != null
                                    ? Image.network(
                                        ApiService.getFullImageUrl(
                                            _tailorDetail.profilePhoto!),
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Image.asset(
                                            'assets/images/tailor_default.png',
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      )
                                    : Image.asset(
                                        'assets/images/tailor_default.png',
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Nama dan rating
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _tailorDetail.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (_tailorDetail.average_rating ?? 0.0).toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '(${_tailorDetail.completed_orders ?? 0} ulasan)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Info Pemesanan
                        const Text(
                          'Info Pemesanan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _tailorDetail.shopDescription ??
                              'Jahit bisa dilakukan dimana saja sesuai dengan lokasi penjahit. Penemuan ukuran juga dapat dilakukan dilokasi penjahit.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Alamat
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              width: 100,
                              child: Text(
                                'Alamat',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _tailorDetail.address ?? 'Alamat tidak tersedia',
                                    style: const TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  if (_tailorDetail.address.isNotEmpty == true)
                                    GestureDetector(
                                      onTap: () => _launchMaps(_tailorDetail.latitude, _tailorDetail.longitude),
                                      child: const Icon(
                                        Icons.location_on,
                                        size: 18,
                                        color: Color(0xFF1A2552),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Jam Kerja
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              width: 100,
                              child: Text(
                                'Nomor HP',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    _tailorDetail.phoneNumber,
                                    style: const TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => _launchWhatsApp(_tailorDetail.phoneNumber),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF25D366),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const FaIcon(
                                        FontAwesomeIcons.whatsapp,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Galeri Hasil Jahit
                        const Text(
                          'Galeri Hasil Jahit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _galleryItems.isEmpty
                            ? Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Belum ada foto di galeri',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : SizedBox(
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _galleryItems.length,
                                  itemBuilder: (context, index) {
                                    final gallery = _galleryItems[index];
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: GestureDetector(
                                          onTap: () => _showFullImage(
                                            context,
                                            ApiService.getFullImageUrl(
                                                gallery.photo),
                                            gallery.title,
                                            gallery.description,
                                          ),
                                          child: Image.network(
                                            ApiService.getFullImageUrl(
                                                gallery.photo),
                                            width: 100,
                                            height: 120,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                width: 100,
                                                height: 120,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                    Icons.image_not_supported),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                        const SizedBox(height: 24),

                        // Spesialisasinya
                        const Text(
                          'Spesialisasinya:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _tailorDetail.specializations.isNotEmpty
                            ? Column(
                                children: _tailorDetail.specializations
                                    .map((spec) => _buildSpecialityItem(
                                        spec is Map ? spec['name'] ?? 'Jahit' : 'Jahit'))
                                    .toList(),
                              )
                            : Column(
                                children: [
                                  _buildSpecialityItem('Jahit'),
                                  _buildSpecialityItem('Kelim'),
                                  _buildSpecialityItem('Merubah Model Pakaian'),
                                ],
                              ),

                        const SizedBox(height: 20),

                        // Tombol Booking
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookingPage(
                                    tailorId: _tailorDetail.id,
                                    tailorName: _tailorDetail.name,
                                    tailorImage: _tailorDetail.profilePhoto,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A2552),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Booking',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        // ===== TAMBAHAN: ULASAN PENGGUNA =====
                        const SizedBox(height: 32),
                        const Text(
                          'Ulasan Pengguna',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_tailorDetail.ratings.isNotEmpty)
                          Column(
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _tailorDetail.ratings.length > 2 ? 2 : _tailorDetail.ratings.length,
                                itemBuilder: (context, index) {
                                  final review = _tailorDetail.ratings[index];
                                  final customer = review.customer;
                                  final customerName = customer?.name ?? '-';
                                  final customerPhoto = customer?.profilePhoto;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              if (customerPhoto != null && customerPhoto.isNotEmpty)
                                                CircleAvatar(
                                                  radius: 20,
                                                  backgroundImage: NetworkImage(
                                                    ApiService.getFullImageUrl(customerPhoto),
                                                  ),
                                                  backgroundColor: Colors.grey[200],
                                                )
                                              else
                                                const CircleAvatar(
                                                  radius: 20,
                                                  backgroundColor: Colors.grey,
                                                  child: Icon(Icons.person, color: Colors.white, size: 20),
                                                ),
                                              const SizedBox(width: 12),
                                              Text(
                                                customerName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  color: Color(0xFF1A2552),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              const Icon(Icons.star, color: Colors.amber, size: 20),
                                              const SizedBox(width: 2),
                                              Text(
                                                review.rating,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                _formatDate(review.createdAt),
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            review.review,
                                            style: const TextStyle(fontSize: 15),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (_tailorDetail.ratings.length > 2)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ReviewPage(
                                            reviews: _tailorDetail.ratings,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('Lihat Semua Ulasan'),
                                  ),
                                ),
                            ],
                          )
                        else
                          const Text(
                            'Belum ada ulasan dari pengguna.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        // ===== END TAMBAHAN =====
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  void _showFullImage(
      BuildContext context, String imageUrl, String title, String description) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 300,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 300,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 50),
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialityItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
            ),
            child: const Center(
              child: Icon(
                Icons.check,
                size: 14,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _launchMaps(String? latitude, String? longitude) async {
  if (latitude == null || longitude == null || latitude.isEmpty || longitude.isEmpty) return;
  
  final mapUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  
  if (await canLaunch(mapUrl)) {
    await launch(mapUrl);
  } else {
    print('Could not launch $mapUrl');
  }
}

Future<void> _launchWhatsApp(String phoneNumber) async {
  // Remove any non-numeric characters from the phone number
  String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
  
  // If the number doesn't start with '+62' or '62', add it
  if (!cleanNumber.startsWith('62')) {
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '62${cleanNumber.substring(1)}';
    } else {
      cleanNumber = '62$cleanNumber';
    }
  }
  
  final whatsappUrl = 'https://wa.me/$cleanNumber';
  
  if (await canLaunch(whatsappUrl)) {
    await launch(whatsappUrl);
  } else {
    print('Could not launch WhatsApp');
  }
}

String _formatDate(String? dateString) {
  if (dateString == null || dateString.isEmpty) return '-';
  try {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year}';
  } catch (e) {
    return dateString ?? '-';
  }
}
