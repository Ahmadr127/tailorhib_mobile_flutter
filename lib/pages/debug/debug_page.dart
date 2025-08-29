import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/shared_prefs_helper.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  bool _isLoading = false;
  Map<String, dynamic> _tokenStatus = {};
  final TextEditingController _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkTokenStatus();
  }

  Future<void> _checkTokenStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await ApiService.checkTokenStatus();
      setState(() {
        _tokenStatus = status;
      });
    } catch (e) {
      print('Error checking token status: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testSharedPrefs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await SharedPrefsHelper.checkIfWorking();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'SharedPreferences ${result ? "berfungsi dengan baik" : "bermasalah"}'),
          backgroundColor: result ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      _checkTokenStatus();
    }
  }

  Future<void> _fixSharedPrefs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await SharedPrefsHelper.tryToFix();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Memperbaiki SharedPreferences ${result ? "berhasil" : "gagal"}'),
          backgroundColor: result ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      _checkTokenStatus();
    }
  }

  Future<void> _saveTokenManually() async {
    if (_tokenController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.saveToken(_tokenController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );
      _tokenController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      _checkTokenStatus();
    }
  }

  Future<void> _removeTokenManually() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.removeToken();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      _checkTokenStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Shared Preferences'),
        backgroundColor: const Color(0xFF1A2552),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    title: 'Status Token',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusItem(
                          'SharedPreferences Status',
                          _tokenStatus['sharedPrefsWorking'] == true
                              ? 'Berfungsi'
                              : 'Bermasalah',
                          _tokenStatus['sharedPrefsWorking'] == true
                              ? Colors.green
                              : Colors.red,
                        ),
                        _buildStatusItem(
                          'Token di SharedPreferences',
                          _tokenStatus['tokenInSharedPrefs'] == true
                              ? 'Ada'
                              : 'Tidak Ada',
                          _tokenStatus['tokenInSharedPrefs'] == true
                              ? Colors.green
                              : Colors.orange,
                        ),
                        if (_tokenStatus['tokenValue'] != null)
                          _buildStatusItem(
                            'Nilai Token',
                            '${_tokenStatus['tokenValue']}',
                            Colors.blue,
                          ),
                        _buildStatusItem(
                          'Token di Memory',
                          _tokenStatus['tokenInMemory'] == true
                              ? 'Ada'
                              : 'Tidak Ada',
                          _tokenStatus['tokenInMemory'] == true
                              ? Colors.green
                              : Colors.orange,
                        ),
                        if (_tokenStatus['memoryTokenValue'] != null)
                          _buildStatusItem(
                            'Nilai Token Memory',
                            '${_tokenStatus['memoryTokenValue']}',
                            Colors.blue,
                          ),
                        if (_tokenStatus['error'] != null)
                          _buildStatusItem(
                            'Error',
                            '${_tokenStatus['error']}',
                            Colors.red,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Aksi',
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: _testSharedPrefs,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 45),
                          ),
                          child: const Text('Test SharedPreferences'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _fixSharedPrefs,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 45),
                          ),
                          child: const Text('Perbaiki SharedPreferences'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _removeTokenManually,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 45),
                          ),
                          child: const Text('Hapus Token'),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _tokenController,
                          decoration: const InputDecoration(
                            labelText: 'Token',
                            border: OutlineInputBorder(),
                            hintText: 'Masukkan token manual',
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _saveTokenManually,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 45),
                          ),
                          child: const Text('Simpan Token Manual'),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _checkTokenStatus,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A2552),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 45),
                          ),
                          child: const Text('Refresh Status'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2552),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }
}
