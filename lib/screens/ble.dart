// ignore_for_file: unused_field

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/session_data_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

class _BleRow {
  final int timeMs;
  final double biteForce;
  final double mouthOpening;

  _BleRow({
    required this.timeMs,
    required this.biteForce,
    required this.mouthOpening,
  });
}

class BLEdata extends StatefulWidget {
  const BLEdata({super.key});
  @override
  State<BLEdata> createState() => _BLEdataState();
}

class _BLEdataState extends State<BLEdata> {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;
  StreamSubscription<List<int>>? _dataSubscription;
  final List<_BleRow> _sessionData = [];
  final Guid serviceUuid =
      Guid("4fafc201-1fb5-459e-8acb-c74c965c4013");
  final Guid characteristicUuid =
      Guid("beb5483e-36e1-4688-b7f5-ea07361b26a8");
  final SessionDataService _session = SessionDataService();
  final Box _box = Hive.box('appBox');

  @override
  void initState() {
    super.initState();
    _listenToSessionChanges();
  }

  void _listenToSessionChanges() {
    _box.listenable(keys: ['clock_tick']).addListener(() {
      if (_session.isRunning && _dataSubscription == null) {
        _attachToConnectedDevice();
      }
      if (!_session.isRunning && _dataSubscription != null) {
        _stopListening();
      }
    });
  }

  Future<void> _attachToConnectedDevice() async {
    final devices = FlutterBluePlus.connectedDevices;
    if (devices.isEmpty) return;

    _device = devices.first;
    final services = await _device!.discoverServices();

    for (final service in services) {
      if (service.uuid == serviceUuid) {
        for (final char in service.characteristics) {
          if (char.uuid == characteristicUuid) {
            _characteristic = char;
            await char.setNotifyValue(true);
            // Also attach the characteristic to the central session service
            // so it can write the incoming values into Hive for the UI meters.
            _session.attachBleCharacteristic(char);

            _dataSubscription = char.lastValueStream.listen((value) {
              if (value.isNotEmpty && _session.isRunning) {
                final received = utf8.decode(value).trim();
                _addData(received);
              }
            });
            return;
          }
        }
      }
    }
  }

  void _stopListening() {
    _dataSubscription?.cancel();
    _dataSubscription = null;
    _characteristic = null;
  }

  void _addData(String raw) {
    final timeMs = _session.elapsedMs;
    final biteForce = double.tryParse(raw) ?? 0.0;
    final mouthOpening = double.tryParse(raw) ?? 0.0;

    setState(() {
      _sessionData.add(
        _BleRow(
          timeMs: timeMs,
          biteForce: biteForce,
          mouthOpening: mouthOpening,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Time (ms)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Bite Force',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Mouth Opening',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView.builder(
              itemCount: _sessionData.length,
              itemBuilder: (_, index) {
                final row = _sessionData[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(flex:2, child:Text(row.timeMs.toString())),
                      Expanded(flex:2, child:Text(row.biteForce.toStringAsFixed(2))),
                      Expanded(flex:3, child:Text(row.mouthOpening.toStringAsFixed(2))),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ); 
  }
}