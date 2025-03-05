import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'dart:math';
import 'database_helper.dart';


class RequestScreen extends StatefulWidget {
  @override
  _RequestScreenState createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _assetCodeController = TextEditingController();
  String _workOrderCode = "";
  String? _selectedAsset;
  List<File> _images = []; // List untuk menyimpan banyak gambar

  @override
  void initState() {
    super.initState();
    _generateWorkOrderCode();
  }

  void _generateWorkOrderCode() {
    setState(() {
      _workOrderCode = "WO${Random().nextInt(99999).toString().padLeft(5, '0')}";
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

    // Simpan gambar sebagai path (string) yang dipisahkan koma
    String imagePaths = _images.map((file) => file.path).join(',');

    // Data yang akan disimpan
    Map<String, dynamic> requestData = {
      "work_order_code": _workOrderCode,
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