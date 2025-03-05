import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
    home: ListPartScreen(),
  ));
}

class ListPartScreen extends StatefulWidget {
  @override
  _ListPartScreenState createState() => _ListPartScreenState();
}

class _ListPartScreenState extends State<ListPartScreen> {
  List<dynamic> _parts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchParts();
  }

  Future<void> _fetchParts() async {
    final url = Uri.parse('http://192.168.5.227:8000/api/list_part');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _parts = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('List Part'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: EdgeInsets.all(8.0),
        itemCount: _parts.length,
        itemBuilder: (context, index) {
          final part = _parts[index];
          return Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              title: Text(
                part['nameParts'] ?? 'No Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(part['descriptionParts'] ?? 'No Description'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Category: ${part['category']}'),
                  SizedBox(height: 4),
                  Text(
                    'Updated: ${part['updated_at'].substring(0, 10)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
