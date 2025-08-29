import 'package:flutter/material.dart';

class GalleryGridWidget extends StatelessWidget {
  final List<String>? galleryItems;
  final Function(String) onTapItem;
  final Function(String) onLongPressItem;
  final VoidCallback onAddItem;
  final bool isLoading;
  final bool isRefreshing;
  final int crossAxisCount;
  final double spacing;

  const GalleryGridWidget({
    super.key,
    required this.galleryItems,
    required this.onTapItem,
    required this.onLongPressItem,
    required this.onAddItem,
    this.isLoading = false,
    this.isRefreshing = false,
    this.crossAxisCount = 3,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Memuat galeri...',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: (galleryItems?.length ?? 0) + 1, // +1 untuk tombol tambah
          itemBuilder: (context, index) {
            // Jika ini adalah item terakhir (tombol tambah)
            if (index == (galleryItems?.length ?? 0)) {
              return GestureDetector(
                onTap: isRefreshing ? null : onAddItem,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 32,
                      color: isRefreshing ? Colors.grey.shade300 : Colors.grey,
                    ),
                  ),
                ),
              );
            }

            // Tampilkan gambar galeri yang ada
            final galleryItem = galleryItems![index];
            return GestureDetector(
              onTap: isRefreshing ? null : () => onTapItem(galleryItem),
              onLongPress:
                  isRefreshing ? null : () => onLongPressItem(galleryItem),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        galleryItem,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
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
                          print('Error loading image: $galleryItem - $error');
                          return Container(
                            color: Colors.grey.shade200,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.grey,
                                  size: 32,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Gagal memuat',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // Overlay for refreshing state
                    if (isRefreshing)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        // Overlay refresh indicator
        if (isRefreshing)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Memperbarui...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// Versi yang lebih sederhana untuk penggunaan cepat
class SimpleGalleryGrid extends StatelessWidget {
  final List<String>? galleryItems;
  final VoidCallback onAddTap;
  final Function(String) onImageTap;

  const SimpleGalleryGrid({
    super.key,
    required this.galleryItems,
    required this.onAddTap,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return GalleryGridWidget(
      galleryItems: galleryItems,
      onTapItem: onImageTap,
      onLongPressItem: onImageTap, // Sama dengan onTap untuk versi sederhana
      onAddItem: onAddTap,
    );
  }
}
