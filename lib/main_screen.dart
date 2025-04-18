    import 'package:flutter/material.dart';
    import 'package:shared_preferences/shared_preferences.dart';
    import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
    import 'login_screen.dart'; // Import halaman login

    class MainScreen extends StatefulWidget {
      @override
      _MainScreenState createState() => _MainScreenState();
    }

    class _MainScreenState extends State<MainScreen> {
      final TextEditingController _linkController = TextEditingController(); // Controller input
      String? _savedLink; // Link yang tersimpan di local storage
      final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
      QRViewController? _qrController;

      @override
      void initState() {
        super.initState();
        _loadSavedLink(); // Load link saat app dibuka
      }

      Future<void> _loadSavedLink() async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        setState(() {
          _savedLink = prefs.getString('saved_link') ?? ''; // Load link
          _linkController.text = _savedLink!; // Tampilkan di input field
        });
      }

      Future<void> _saveLink(String link) async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_link', link);
      }

      void _submitLink() {
        String link = _linkController.text.trim();

        if (link.isNotEmpty) {
          _saveLink(link); // Simpan link ke lokal
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Silakan masukkan link terlebih dahulu."),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      void _scanQRCode() async {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QRView(
              key: _qrKey,
              onQRViewCreated: (QRViewController controller) {
                _qrController = controller;
                controller.scannedDataStream.listen((scanData) {
                  setState(() {
                    _linkController.text = scanData.code ?? ''; // Ambil hasil scan
                  });
                  _saveLink(scanData.code ?? ''); // Simpan ke SharedPreferences
                  controller.dispose(); // Tutup scanner setelah berhasil
                  Navigator.pop(context); // Kembali ke halaman utama
                });
              },
            ),
          ),
        );
      }

      @override
      void dispose() {
        _qrController?.dispose();
        super.dispose();
      }

      @override
      Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(title: Text("Halaman Utama")),
          body: Stack(
            children: [
              /// Circular di kiri atas
              Positioned(
                top: -100,
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(150),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: _linkController,
                      decoration: InputDecoration(
                        labelText: "Masukkan Link",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitLink,
                      child: Text("Submit"),
                    ),
                  ],
                ),
              ),

              /// Avatar di tengah atas
              Positioned(
                top: 20,
                left: MediaQuery.of(context).size.width / 2 - 40,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, color: Colors.white, size: 40),
                ),
              ),

              /// Floating Action Button di kanan bawah
              Positioned(
                bottom: 50,
                right: 20,
                child: FloatingActionButton(
                  onPressed: _scanQRCode,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.qr_code, size: 30),
                ),
              ),
            ],
          ),
        );
      }
    }
