import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart' as connectivity;
import 'package:testing/list_part_screen.dart';
import 'package:testing/list_wo_screen.dart';
import 'package:testing/profile_screen.dart';
import 'package:testing/request_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0; // Menyimpan indeks menu yang dipilih
  bool _isOnline = true; // Status koneksi internet
  StreamSubscription<connectivity.ConnectivityResult>? _connectivitySubscription;

  // Daftar widget untuk setiap menu
  final List<Widget> _pages = [
    RequestScreen(), // Halaman Request
    ListWoScreen(), // Halaman List WO
ListPartScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkConnectivity(); // Mengecek status koneksi saat aplikasi dimulai

    // Memonitor perubahan status koneksi secara real-time
    _connectivitySubscription =
        connectivity.Connectivity().onConnectivityChanged.listen((connectivity.ConnectivityResult result) {
          setState(() {
            _isOnline = (result != connectivity.ConnectivityResult.none);
          });
        });
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await connectivity.Connectivity().checkConnectivity();
    setState(() {
      _isOnline = (connectivityResult != connectivity.ConnectivityResult.none);
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update indeks saat menu ditekan
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel(); // Hindari memory leak
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),
        actions: [
          Icon(
            _isOnline ? Icons.wifi : Icons.wifi_off,
            color: _isOnline ? Colors.green : Colors.red,
          ),
          SizedBox(width: 16),
        ],
      ),
      body: _pages[_selectedIndex], // Menampilkan halaman sesuai menu yang dipilih
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue, // Warna ikon aktif
        unselectedItemColor: Colors.grey, // Warna ikon tidak aktif
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.send), // Ikon Request
            label: "Request",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment), // Ikon List WO
            label: "List WO",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build), // Ikon List Part
            label: "List Part",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person), // Ikon Profile
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
