import 'dart:io';
import 'package:flutter/material.dart';
import '../models/gallery_item_model.dart';
import '../services/api_service.dart';

class GalleryController {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

  List<GalleryItem> galleryItems = [];
  bool isLoading = false;

  // Dispose metode
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
  }

  // Reset input fields
  void resetFields() {
    titleController.clear();
    descriptionController.clear();
    categoryController.clear();
  }

  // Mengambil daftar galeri
  Future<bool> fetchGalleryItems(BuildContext context) async {
    isLoading = true;

    try {
      final result = await ApiService.getTailorGallery();

      isLoading = false;

      if (result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        galleryItems = data.map((item) => GalleryItem.fromJson(item)).toList();
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      isLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  // Menambahkan item galeri
  Future<bool> addGalleryItem(BuildContext context, File photo) async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        categoryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua field harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    isLoading = true;

    try {
      final result = await ApiService.addTailorGalleryItem(
        photo: photo,
        title: titleController.text,
        description: descriptionController.text,
        category: categoryController.text,
      );

      isLoading = false;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        resetFields();
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      isLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  // Mengupdate item galeri
  Future<bool> updateGalleryItem(BuildContext context, int id) async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        categoryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua field harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    isLoading = true;

    try {
      final result = await ApiService.updateTailorGalleryItem(
        id: id,
        title: titleController.text,
        description: descriptionController.text,
        category: categoryController.text,
      );

      isLoading = false;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        resetFields();
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      isLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  // Menghapus item galeri
  Future<bool> deleteGalleryItem(BuildContext context, int id) async {
    isLoading = true;

    try {
      final result = await ApiService.deleteTailorGalleryItem(id);

      isLoading = false;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      isLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  // Load data ke form untuk edit
  void setFormDataForEdit(GalleryItem item) {
    titleController.text = item.title;
    descriptionController.text = item.description;
    categoryController.text = item.category;
  }
}
