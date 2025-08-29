class OrderModel {
  final String id;
  final String item;
  final String date;
  final String status;
  final String tailorName;
  final double price;

  OrderModel({
    required this.id,
    required this.item,
    required this.date,
    required this.status,
    required this.tailorName,
    required this.price,
  });
}
