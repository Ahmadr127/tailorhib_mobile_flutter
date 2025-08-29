import '../models/order_model.dart';

class OrderController {
  // Sample data, in real app would come from API
  final List<OrderModel> orders = [
    OrderModel(
      id: '001',
      item: 'Kemeja Batik',
      date: '12 Agustus 2023',
      status: 'Selesai',
      tailorName: 'Penjahit ABC',
      price: 150000,
    ),
    OrderModel(
      id: '002',
      item: 'Celana Panjang',
      date: '20 Agustus 2023',
      status: 'Diproses',
      tailorName: 'Penjahit XYZ',
      price: 120000,
    ),
    OrderModel(
      id: '003',
      item: 'Jas Formal',
      date: '1 September 2023',
      status: 'Menunggu',
      tailorName: 'Penjahit XYZ',
      price: 450000,
    ),
  ];

  // Method untuk mendapatkan pesanan berdasarkan status
  List<OrderModel> getOrdersByStatus(String status) {
    if (status == 'Semua') {      return orders;
    }
    return orders.where((order) => order.status == status).toList();
  }
}
