import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:testing/detail_wo_screen.dart';
import 'package:testing/database_helper.dart';

class ListWoScreen extends StatefulWidget {
  @override
  _ListWoScreenState createState() => _ListWoScreenState();
}

class _ListWoScreenState extends State<ListWoScreen> {
  List<Map<String, dynamic>> workOrders = [];
  bool isOnline = false;

  @override
  void initState() {
    super.initState();
    _loadWorkOrders();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    ConnectivityResult result = await Connectivity().checkConnectivity();
    setState(() {
      isOnline = (result != ConnectivityResult.none);
    });

    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        isOnline = (result != ConnectivityResult.none);
      });
    });
  }

  Future<void> _loadWorkOrders() async {
    final data = await DatabaseHelper().getRequests();
    setState(() {
      workOrders = data;
    });
  }

  Future<void> _deleteWorkOrder(int id) async {
    await DatabaseHelper().deleteRequest(id);
    _loadWorkOrders();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Data berhasil dihapus")),
    );
  }

  Future<void> _sendWorkOrder(Map<String, dynamic> wo) async {
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tidak ada koneksi internet!")),
      );
      return;
    }

    try {
      var response = await http.post(
        Uri.parse("https://your-api.com/send-workorder"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(wo),
      );

      if (response.statusCode == 200) {
        await DatabaseHelper().deleteRequest(wo['id']);
        _loadWorkOrders();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Data ${wo['work_order_code']} berhasil dikirim")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengirim data: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error mengirim data: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("List WO")),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Status: ${isOnline ? "Online" : "Offline"}"),
              ],
            ),
            Expanded(
              child: workOrders.isEmpty
                  ? Center(child: Text("Tidak ada data"))
                  : ListView.builder(
                itemCount: workOrders.length,
                itemBuilder: (context, index) {
                  var wo = workOrders[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(10.0),
                      title: Text(
                        wo["work_order_code"] ?? "-",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(wo["description"] ?? "-"),
                          SizedBox(height: 5),
                          Text(
                            "Status: ${wo["work_order_status"] ?? "Unknown"}",
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.send, color: Colors.blue),
                            onPressed: isOnline ? () => _sendWorkOrder(wo) : null,
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteWorkOrder(wo['id']),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailWoScreen(workOrder: wo),
                          ),
                        ).then((shouldRefresh) {
                          if (shouldRefresh == true) {
                            _loadWorkOrders();
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
