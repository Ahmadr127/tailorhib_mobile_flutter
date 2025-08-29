import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tailorhub/core/services/api_service.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Data pesanan dari API
  List<Map<String, dynamic>> _scheduledOrders = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadCalendarData();
  }

  // Fungsi untuk memformat angka bulan menjadi format dengan leading zero
  String _formatMonth(int month) {
    return month.toString().padLeft(2, '0');
  }

  // Fungsi untuk memuat data kalender dari API
  Future<void> _loadCalendarData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      // Format bulan dan tahun sesuai kebutuhan API
      final month = _formatMonth(_focusedDay.month);
      final year = _focusedDay.year.toString();

      print('DEBUG: Memuat data kalender untuk bulan $month tahun $year');
      final result = await ApiService.getTailorCalendar(month, year);

      if (mounted) {
        setState(() {
          _isLoading = false;

          if (result['success']) {
            // Parse data dari API ke format yang dibutuhkan
            // Data dari API berbentuk: {"month":4, "year":2025, "month_name":"April", "calendar":[...]}
            final apiData = result['data'] as Map<String, dynamic>;
            print(
                'DEBUG: Data kalender berhasil dimuat untuk ${apiData['month_name']} ${apiData['year']}');

            final calendarData = apiData['calendar'] as List<dynamic>? ?? [];
            print('DEBUG: Jumlah hari dalam kalender: ${calendarData.length}');

            _scheduledOrders = [];

            // Proses setiap tanggal dalam kalender
            for (var dayData in calendarData) {
              final String dateString = dayData['date'] ?? '';
              final bookings = dayData['bookings'] as List<dynamic>? ?? [];

              // Jika ada booking pada tanggal tersebut
              if (bookings.isNotEmpty) {
                print(
                    'DEBUG: Terdapat ${bookings.length} booking pada tanggal $dateString');
              }

              for (var booking in bookings) {
                final DateTime bookingDate = DateTime.parse(dateString);

                _scheduledOrders.add({
                  'date': bookingDate,
                  'orderCode': booking['id']?.toString() ?? '',
                  'customerName': booking['customer_name'] ?? '',
                  'service': booking['service_type'] ?? '',
                  'status': booking['status'] ?? '',
                  'id': booking['id']?.toString() ?? '',
                });
              }
            }

            print(
                'DEBUG: Total booking yang ditampilkan: ${_scheduledOrders.length}');
            _errorMessage = '';
          } else {
            _scheduledOrders = [];
            _errorMessage = result['message'] ?? 'Gagal memuat data kalender';
            print('DEBUG: Gagal memuat data kalender: $_errorMessage');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Terjadi kesalahan: $e';
          _scheduledOrders = [];
        });
      }
      print('ERROR: Gagal memuat data kalender: $e');
    }
  }

  // Helper untuk menampilkan marker pada kalender
  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _scheduledOrders.where((order) {
      return isSameDay(order['date'] as DateTime, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A2552)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kalender',
          style: TextStyle(
            color: Color(0xFF1A2552),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1A2552)),
            onPressed: _loadCalendarData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCalendar(),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Memuat data kalender...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_errorMessage.isNotEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCalendarData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A2552),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: _buildScheduleList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          leftChevronIcon:
              Icon(Icons.chevron_left, color: Color(0xFF1A2552)),
          rightChevronIcon:
              Icon(Icons.chevron_right, color: Color(0xFF1A2552)),
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2552),
          ),
          headerPadding: EdgeInsets.symmetric(vertical: 12),
          headerMargin: EdgeInsets.only(bottom: 8),
        ),
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: TextStyle(color: Colors.black87),
          weekendTextStyle: TextStyle(color: Colors.black87),
          todayDecoration: BoxDecoration(
            color: Color(0xFF1A2552),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Color(0xFF1A2552),
            shape: BoxShape.circle,
          ),
          cellMargin: EdgeInsets.all(4),
          markersMaxCount: 3,
          markerDecoration: BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          markerSize: 6.0,
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.black87, fontSize: 12),
          weekendStyle: TextStyle(color: Colors.black87, fontSize: 12),
        ),
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });

          // Muat data baru jika bulan berubah
          if (_focusedDay.month != _selectedDay?.month ||
              _focusedDay.year != _selectedDay?.year) {
            _loadCalendarData();
          }
        },
        eventLoader: (day) {
          // Menandai hari yang memiliki pesanan
          final events = _getEventsForDay(day);
          return events.isNotEmpty
              ? [1]
              : []; // Cukup mengembalikan list dengan 1 item jika ada event
        },
      ),
    );
  }

  Widget _buildScheduleList() {
    if (_selectedDay == null) return Container();

    // Filter pesanan berdasarkan tanggal yang dipilih
    final ordersForSelectedDay = _scheduledOrders.where((order) {
      return isSameDay(order['date'], _selectedDay);
    }).toList();

    if (ordersForSelectedDay.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada jadwal untuk tanggal ini',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih tanggal lain atau tambahkan pesanan baru',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ordersForSelectedDay.length,
      itemBuilder: (context, index) {
        final order = ordersForSelectedDay[index];
        return _buildScheduleItem(order);
      },
    );
  }

  Widget _buildScheduleItem(Map<String, dynamic> order) {
    final formattedDate = DateFormat('d MMM yyyy').format(order['date']);

    // Tentukan warna berdasarkan status
    Color statusColor = Colors.orange;
    String statusText = order['status'].toString().toUpperCase();

    if (order['status'] == 'diterima') {
      statusColor = Colors.blue;
    } else if (order['status'] == 'diproses') {
      statusColor = Colors.orange;
    } else if (order['status'] == 'selesai') {
      statusColor = Colors.green;
    } else if (order['status'] == 'dibatalkan') {
      statusColor = Colors.red;
    } else if (order['status'] == 'reservasi') {
      statusColor = Colors.purple;
      statusText = 'RESERVASI';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event, size: 16, color: Color(0xFF1A2552)),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2552),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                const Text(
                  'Kode Pesanan: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '#${order['orderCode']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              order['customerName'],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.design_services_outlined,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              order['service'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Color(0xFF1A2552)),
                  onPressed: () {
                    // Navigasi ke detail pesanan
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => OrderDetailPage(orderId: order['id']),
                    //   ),
                    // ).then((_) => _loadCalendarData());
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
