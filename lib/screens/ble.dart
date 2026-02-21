// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class BLEdata extends StatefulWidget {
  const BLEdata({super.key});

  @override
  State<BLEdata> createState() => _BLEdataState();
}

class _BLEdataState extends State<BLEdata> {
  final Box _box = Hive.box('appBox');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ───────────────────────── Header ─────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
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

          // ───────────────────────── Live table ─────────────────────────
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _box.listenable(keys: ['session']),
              builder: (context, Box box, _) {
                final List session =
                    box.get('session', defaultValue: []);

                if (session.isEmpty) {
                  return const Center(
                    child: Text("No session data"),
                  );
                }

                return ListView.builder(
                  itemCount: session.length,
                  itemBuilder: (_, index) {
                    final row = session[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(row['time_ms'].toString()),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              (row['bite_force'] as num)
                                  .toDouble()
                                  .toStringAsFixed(2),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              (row['mouth_opening'] as num)
                                  .toDouble()
                                  .toStringAsFixed(2),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}