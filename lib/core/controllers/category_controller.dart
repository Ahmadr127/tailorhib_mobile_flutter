
class CategoryController {
  // Pilihan kategori yang dipilih
  final List<bool> selectedCategories = List.generate(8, (index) => false);

  // Nama kategori sesuai gambar yang diberikan
  final List<String> categories = [
    'Celana',
    'Gamis',
    'Gaun',
    'Jas Blazer',
    'Kebaya',
    'Kemeja',
    'Rok',
    'Seragam',
  ];

  // Nama file gambar kategori
  final List<String> categoryImages = [
    'model_jahit/celana.png',
    'model_jahit/gamis.png',
    'model_jahit/gaun.png',
    'model_jahit/jasblezer.png',
    'model_jahit/kebaya.png',
    'model_jahit/kemeja.png',
    'model_jahit/rok.png',
    'model_jahit/seragam.png',
  ];

  // Map untuk menyimpan data dari API, dikelompokkan berdasarkan kategori
  final Map<String, List<Map<String, dynamic>>> apiCategories = {};

  // List untuk menyimpan semua kategori yang tersedia
  List<String> categoryGroups = [];

  // Menyimpan data spesialisasi untuk penggunaan nanti
  List<Map<String, dynamic>> allSpecializations = [];

  // Inisialisasi data kategori dari API
  void initializeFromApi(List<Map<String, dynamic>> specializations) {
    allSpecializations = specializations;
    apiCategories.clear();

    // Kelompokkan spesialisasi berdasarkan kategori
    for (var spec in specializations) {
      String category = spec['category'] as String;

      if (!apiCategories.containsKey(category)) {
        apiCategories[category] = [];
      }

      apiCategories[category]!.add(spec);
    }

    // Perbarui list kategori
    categoryGroups = apiCategories.keys.toList();

    print('Initialized ${categoryGroups.length} categories from API');
    print('Categories: $categoryGroups');
  }

  void toggleCategory(int index) {
    selectedCategories[index] = !selectedCategories[index];
  }

  List<String> getSelectedCategories() {
    List<String> selected = [];
    for (int i = 0; i < selectedCategories.length; i++) {
      if (selectedCategories[i]) {
        selected.add(categories[i]);
      }
    }
    return selected;
  }
}
