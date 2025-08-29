import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';

class MidtransWebView extends StatefulWidget {
  final String url;
  final Function(String)? onUrlChanged;
  final Function()? onWebViewClosed;

  const MidtransWebView({
    super.key, 
    required this.url,
    this.onUrlChanged,
    this.onWebViewClosed,
  });

  @override
  State<MidtransWebView> createState() => _MidtransWebViewState();
}

class _MidtransWebViewState extends State<MidtransWebView> {
  late WebViewController _controller;
  bool _isLoading = true;
  Timer? _checkTimer;
  
  @override
  void initState() {
    super.initState();
    _setupWebView();
    // Mulai pengecekan URL secara berkala
    _startUrlCheckTimer();
  }

  @override
  void dispose() {
    // Hentikan timer terlebih dahulu
    _checkTimer?.cancel();
    
    // Panggil callback menggunakan scheduleMicrotask untuk memastikan
    // callback dipanggil setelah dispose selesai secara aman
    if (widget.onWebViewClosed != null) {
      // Simpan reference callback untuk digunakan setelah dispose
      final callback = widget.onWebViewClosed;
      // Jalankan callback setelah frame ini selesai
      WidgetsBinding.instance.addPostFrameCallback((_) {
        callback!();
      });
    }
    
    super.dispose();
  }
  
  void _startUrlCheckTimer() {
    // Cek URL setiap 2 detik
    _checkTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final currentUrl = await _controller.currentUrl();
        if (currentUrl != null) {
          print('URL saat ini (timer check): $currentUrl');
          
          // Panggil callback onUrlChanged jika ada
          if (widget.onUrlChanged != null) {
            widget.onUrlChanged!(currentUrl);
          }
          
          // Auto-close untuk URL dengan indikator spesifik
          _checkForAutoCloseUrl(currentUrl);
        }
      } catch (e) {
        print('Error checking URL: $e');
      }
    });
  }
  
  void _checkForAutoCloseUrl(String url) {
    // URL yang mengindikasikan transaksi selesai dan WebView harus ditutup
    final autoCloseIndicators = [
      'transaction_status=settlement',
      'transaction_status=capture',
      'transaction_status=paid',
      'status_code=200&transaction_status=settlement',
      'example.com/?order_id=', // Domain yang tidak diharapkan tapi mungkin muncul
      '/snap/v2/finish'
    ];
    
    for (var indicator in autoCloseIndicators) {
      if (url.contains(indicator)) {
        print('URL menunjukkan transaksi selesai: $url');
        _closeWebView(true);
        return;
      }
    }
  }
  
  void _closeWebView(bool success) {
    // Tunggu sebentar sebelum menutup (memungkinkan URL untuk diproses)
    // Hentikan timer terlebih dahulu untuk mencegah callback tak terduga
    _checkTimer?.cancel();
    
    // Tunda penutupan WebView untuk memastikan state tree tidak terkunci
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.of(context).pop(success);
      }
    });
  }

  void _setupWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('Halaman mulai dimuat: $url');
            setState(() {
              _isLoading = true;
            });
            
            // Panggil callback onUrlChanged
            if (widget.onUrlChanged != null) {
              widget.onUrlChanged!(url);
            }
          },
          onPageFinished: (String url) {
            print('Halaman selesai dimuat: $url');
            setState(() {
              _isLoading = false;
            });
            
            // Panggil callback onUrlChanged
            if (widget.onUrlChanged != null) {
              widget.onUrlChanged!(url);
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('Error saat memuat halaman: ${error.description}');
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Navigasi ke: ${request.url}');
            
            // Panggil callback onUrlChanged
            if (widget.onUrlChanged != null) {
              widget.onUrlChanged!(request.url);
            }
            
            // Cek domain example.com (URL redirect yang mungkin menandakan transaksi selesai)
            if (request.url.contains('example.com') && request.url.contains('order_id=')) {
              print('Terdeteksi URL example.com dengan order_id, kemungkinan transaksi selesai');
              // Tunggu sedikit sebelum menutup WebView
              Future.delayed(const Duration(milliseconds: 500), () {
                _closeWebView(true);
              });
              return NavigationDecision.prevent;
            }
            
            // Navigasi seperti biasa untuk URL lainnya
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Konfirmasi sebelum keluar
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Konfirmasi'),
            content: const Text('Apakah Anda yakin ingin membatalkan pembayaran?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Tidak'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ya'),
              ),
            ],
          ),
        );
        if (shouldPop == true) {
          // Pastikan callback dipanggil saat user menutup WebView
          if (widget.onWebViewClosed != null) {
            widget.onWebViewClosed!();
          }
          return true;
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pembayaran'),
          backgroundColor: Theme.of(context).primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final shouldClose = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Konfirmasi'),
                  content: const Text('Apakah Anda yakin ingin membatalkan pembayaran?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Tidak'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Ya'),
                    ),
                  ],
                ),
              );
              if (shouldClose == true) {
                Navigator.of(context).pop(false);
              }
            },
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
} 