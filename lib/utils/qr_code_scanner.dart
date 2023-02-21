import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:to_do_app/models/task.dart';
import 'dart:convert';

import '../tasks_view_model.dart';

class QRScannerWidget extends StatefulWidget {
  const QRScannerWidget({super.key});
  @override
  _QRScannerWidgetState createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  String qrCodeData = '';

  void _onQRCodeScanned(String qrCodeScanData) {
    setState(() {
      try {
        Map<String, dynamic> data = jsonDecode(qrCodeScanData);
        if (data.containsKey('taskTitle') &&
            data.containsKey('description') &&
            data.containsKey('ownerId') &&
            data.containsKey('status') &&
            data.containsKey('lastUpdate')) {
          if (data['taskTitle'] != "" &&
              data['description'] != "" &&
              data['status'] != "" &&
              data['ownerId'] != "" &&
              data['ownerId'] is int &&
              data['lastUpdate'] != "") {
            context.read<Tasks>().addTask(
                Task(
                    ownerId: data['ownerId'],
                    taskTitle: data['taskTitle'],
                    description: data['description'],
                    status: data['status'],
                    lastUpdate: data['lastUpdate']),
                []);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'TaskId with title "${data['taskTitle']}" successfully inserted via QR Code scan')));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Invalid JSON, please try valid QR Code')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Error in decoding JSON. Please pass valid JSON')));
      }
      context.push('/tasks');
    });
  }

  Future<void> _scanQRCode() async {
    String data = await FlutterBarcodeScanner.scanBarcode(
      "#ff6666",
      "Cancel",
      true,
      ScanMode.QR,
    );

    _onQRCodeScanned(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                _scanQRCode();
              },
              child: const Text('Scan QR Code'),
            ),
            const SizedBox(height: 20),
            Text(qrCodeData),
          ],
        ),
      ),
    );
  }
}
