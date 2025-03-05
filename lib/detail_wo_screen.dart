import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:testing/database_helper.dart';

class DetailWoScreen extends StatelessWidget {
  final Map<String, dynamic> workOrder;

  DetailWoScreen({required this.workOrder});

  Future<void> _deleteWorkOrder(BuildContext context, int id) async {
    await DatabaseHelper().deleteRequest(id);
    Navigator.pop(context, true); // Kembali ke layar sebelumnya dengan status refresh
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Work Order berhasil dihapus")),
    );
  }

  Future<void> _sendWorkOrder(BuildContext context, Map<String, dynamic> wo) async {
    try {
      var response = await http.post(
        Uri.parse("https://your-api.com/send-workorder"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(wo),
      );

      if (response.statusCode == 200) {
        await DatabaseHelper().deleteRequest(wo['id']); // Hapus jika sukses dikirim
        Navigator.pop(context, true); // Kembali dan refresh
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Work Order ${wo['work_order_code']} berhasil dikirim")),
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
      appBar: AppBar(title: Text("Detail WO")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Kode WO: ${workOrder["work_order_code"]}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Deskripsi: ${workOrder["description"]}"),
            SizedBox(height: 10),
            Text("Status: ${workOrder["work_order_status"]}"),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _sendWorkOrder(context, workOrder),
                  icon: Icon(Icons.send),
                  label: Text("Kirim"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                ElevatedButton.icon(
                  onPressed: () => _deleteWorkOrder(context, workOrder['id']),
                  icon: Icon(Icons.delete),
                  label: Text("Hapus"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
