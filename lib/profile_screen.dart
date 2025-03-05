import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey _globalKey = GlobalKey();

  final Map<String, String> profileData = {
    "Full Name": "Testing5",
    "Email": "panjidenisgiantoroo5@gmail.com",
    "Company": "PT Pertamina",
    "Department": "Production B",
    "Division": "HR",
    "Role": "Operator",
    "Description Division": "HR Resource Human"
  };

  // Fungsi untuk meminta izin penyimpanan
  Future<void> _requestPermission() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      print("Izin penyimpanan diberikan.");
    } else {
      print("Izin penyimpanan ditolak.");
    }
  }

  @override
  void initState() {
    super.initState();
    _requestPermission(); // Minta izin saat aplikasi dijalankan
  }

  // Fungsi untuk menangkap gambar
  Future<File?> _captureCard() async {
    try {
      await Future.delayed(Duration(milliseconds: 500));
      RenderRepaintBoundary? boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      Uint8List pngBytes = byteData.buffer.asUint8List();
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/profile_card.png';
      File file = File(filePath);
      await file.writeAsBytes(pngBytes);
      return file;
    } catch (e) {
      print("Error capturing card: $e");
      return null;
    }
  }

  // Fungsi untuk berbagi gambar
  void _shareCard() async {
    File? capturedImage = await _captureCard();
    if (capturedImage != null) {
      await Share.shareXFiles([XFile(capturedImage.path)], text: "Profil Karyawan");
    } else {
      print("Gagal menyimpan gambar");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: Center(
        child: RepaintBoundary(
          key: _globalKey,
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              width: 350,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [Colors.grey[300]!, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 0.15,
                    child: Image.asset(
                      'assets/logo.png',
                      width: 180,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: profileData.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                "${entry.key}: ${entry.value}",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: AssetImage('assets/profile.jpg'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _shareCard,
        heroTag: "btnShare",
        child: Icon(Icons.share),
      ),
    );
  }
}