import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class RequestScreen extends StatefulWidget {
  @override
  _RequestScreenState createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _assetCodeController = TextEditingController();
  String _workOrderCode = "";
  String? _selectedAsset;
  String? _baseUrl;
  List<File> _images = []; // List untuk menyimpan banyak gambar
  String _accessToken = "Loading..."; // Variabel untuk token

  @override
  void initState() {
    super.initState();
    _loadBaseUrl();
    _generateWorkOrderCode();
  }

  Future<void> _loadBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _baseUrl = prefs.getString('saved_link') ?? 'http://192.168.0.197:8000';
    });
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _accessToken = prefs.getString('user_id') ?? "0"; // Ambil token
    });
  }
  Future<bool> _isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void _generateWorkOrderCode() {
    setState(() {
      // WO-2025-03-21-1626 format
      _workOrderCode = "WO-${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}-${Random().nextInt(9999).toString().padLeft(4, '0')}";
      // _workOrderCode = "WO${Random().nextInt(99999).toString().padLeft(5, '0')}";
    });
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path)); // Tambah gambar ke dalam list
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text("Ambil Foto"),
            onTap: () {
              Navigator.pop(context);
              _pickImageFromSource(ImageSource.camera);
            },
          ),
          ListTile(
            leading: Icon(Icons.image),
            title: Text("Pilih dari Galeri"),
            onTap: () {
              Navigator.pop(context);
              _pickImageFromSource(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  void _scanBarcode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerScreen(
          onScan: (String result) {
            setState(() {
              _assetCodeController.text = result;
            });
          },
        ),
      ),
    );
  }

  void _confirmDeleteImage(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Hapus Gambar?"),
        content: Text("Apakah Anda yakin ingin menghapus gambar ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _images.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _submitRequest() async {
    String description = _descriptionController.text;
    String assetCode = _assetCodeController.text;

    if (description.isEmpty || assetCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Deskripsi dan kode aset harus diisi!")),
      );
      return;
    }

    if (_baseUrl == null || _baseUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Base URL belum dikonfigurasi!")),
      );
      return;
    }

    // Konversi gambar ke Base64
    List<String> base64Images = [];
    for (var file in _images) {
      List<int> imageBytes = await File(file.path).readAsBytes();
      String base64Image = base64Encode(imageBytes);
      base64Images.add(base64Image);
    }

    // Data JSON yang akan dikirim
    Map<String, dynamic> requestData = {
      "work_order_code": _workOrderCode,
      "work_order_status": "request",
      "description": description,
      // "user_id" : _accessToken,
      // "asset_id": _selectedAsset ?? "",
      "asset_id": assetCode,
      "file": base64Images, // Kirim gambar dalam format Base64
    };

    bool online = await _isOnline();

    if (online) {
      try {

        var response = await http.post(
          Uri.parse("$_baseUrl/api/wo/store"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(requestData),
        );

        if (response.statusCode == 200) {
          String fileNames = _images.map((file) => file.path.split('/').last).join(', ');
          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(
                // content: Text("Request berhasil dikirim. File: $fileNames")),
                content: Text("Request berhasil dikirim ke server")),
          );
        } else {
          throw Exception("Gagal mengirim data: ${response.body}");
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengirim request, menyimpan offline.")),
        );
        DatabaseHelper dbHelper = DatabaseHelper();
        await dbHelper.insertRequest(requestData);
      }
    } else {
      // Simpan ke SQLite jika offline
      DatabaseHelper dbHelper = DatabaseHelper();
      await dbHelper.insertRequest(requestData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Request disimpan secara offline!")),
      );
    }

    // Reset form
    setState(() {
      _descriptionController.clear();
      _assetCodeController.clear();
      _images.clear();
      _generateWorkOrderCode();
    });
  }

  void _submitRequest2() async {
    String description = _descriptionController.text;
    String assetCode = _assetCodeController.text;

    if (description.isEmpty || assetCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Deskripsi dan kode aset harus diisi!")),
      );
      return;
    }
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Base URL belum dikonfigurasi!")),
      );
      return;
    }

    // Simpan gambar sebagai path (string) yang dipisahkan koma
    String imagePaths = _images.map((file) => file.path).join(',');

    // Data yang akan disimpan
    Map<String, dynamic> requestData = {
      "code": _workOrderCode,
      "work_order_status": "Request",
      "description": description,
      "asset": _selectedAsset ?? "",
      "asset_code": assetCode,
      "images": imagePaths,
    };

    // Simpan ke SQLite
    DatabaseHelper dbHelper = DatabaseHelper();
    await dbHelper.insertRequest(requestData);

    // Tampilkan pesan sukses
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Request disimpan secara offline!")),
    );

    // Reset form
    setState(() {
      _descriptionController.clear();
      _assetCodeController.clear();
      _images.clear();
      _generateWorkOrderCode();
    });
  }



  void _loadOfflineRequests() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> requests = await dbHelper.getRequests();

    if (requests.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Request Offline"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: requests.map((req) {
              return ListTile(
                title: Text(req['work_order_code']),
                subtitle: Text(req['description']),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Request Work Order")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Work Order Code", style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              readOnly: true,
              initialValue: _workOrderCode,
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
            SizedBox(height: 10),
            Text("Work Order Status", style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              readOnly: true,
              initialValue: "Request",
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
            SizedBox(height: 10),
            Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Masukkan deskripsi...",
              ),
            ),
            SizedBox(height: 10),
            Text("Pilih Asset", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: _selectedAsset,
              items: ["PC", "Monitor"].map((String asset) {
                return DropdownMenuItem(
                  value: asset,
                  child: Text(asset),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAsset = value!;
                });
              },
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
            SizedBox(height: 10),
            Text("Kode Aset", style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _assetCodeController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Masukkan kode aset...",
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.qr_code_scanner),
                  onPressed: _scanBarcode,
                ),
              ],
            ),
            SizedBox(height: 10),
            Text("Upload Foto", style: TextStyle(fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: _showImageSourceDialog,
              icon: Icon(Icons.camera_alt),
              label: Text("Ambil/Galeri"),
            ),
            SizedBox(height: 10),
            _images.isNotEmpty
                ? Wrap(
              spacing: 10,
              children: _images.asMap().entries.map(
                    (entry) {
                  return Stack(
                    children: [
                      Image.file(entry.value, width: 100, height: 100, fit: BoxFit.cover),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: () => _confirmDeleteImage(entry.key),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ).toList(),
            )
                : Text("Belum ada foto"),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _submitRequest,
                child: Text("Submit Request"),
              ),
            ),

            SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: _loadOfflineRequests,
                child: Text("Lihat Request Offline"),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

class BarcodeScannerScreen extends StatefulWidget {
  final Function(String) onScan;

  BarcodeScannerScreen({required this.onScan});

  @override
  _BarcodeScannerScreenState createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scan QR Code")),
      body: Column(
        children: [
          Expanded(
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      widget.onScan(scanData.code!);
      Navigator.pop(context);
    });
  }

}