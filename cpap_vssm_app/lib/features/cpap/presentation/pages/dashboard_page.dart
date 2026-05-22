import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/ble_cubit.dart';
import 'connection_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bleService = context.read<BleCubit>().bleService;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "CPAP VSSM",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              onPressed: () async {
                /// =========================
                /// CONFIRM DIALOG
                /// =========================
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Row(
                        children: [
                          Icon(
                            Icons.bluetooth_disabled,
                            color: Colors.red,
                          ),
                          SizedBox(width: 10),
                          Text("Ngắt kết nối"),
                        ],
                      ),
                      content: const Text(
                        "Bạn có chắc muốn ngắt kết nối với thiết bị CPAP không?",
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      actions: [
                        /// HỦY
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                          child: const Text(
                            "Hủy",
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ),

                        /// ĐỒNG Ý
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                          child: const Text(
                            "Ngắt kết nối",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );

                /// user cancel
                if (confirm != true) return;

                /// disconnect
                await bleService.disconnect();

                /// back connection screen
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ConnectionPage(),
                  ),
                  (route) => false,
                );
              },
              icon: const Icon(
                Icons.bluetooth_disabled,
                color: Colors.red,
              ),
              label: const Text(
                "Ngắt kết nối",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: bleService.sensorStream,
        builder: (context, snapshot) {
          /// waiting sensor
          if (!snapshot.hasData) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    "Waiting sensor data...",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;

          final temperature = data["temperature"];
          final spo2 = data["spo2"];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                /// ========================
                /// STATUS CARD
                /// ========================

                const SizedBox(height: 28),

                /// ========================
                /// SENSOR GRID
                /// ========================
                Row(
                  children: [
                    Expanded(
                      child: _sensorCard(
                        title: "Temperature",
                        value: "$temperature °C",
                        icon: Icons.thermostat,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _sensorCard(
                        title: "SpO2",
                        value: "$spo2 %",
                        icon: Icons.favorite,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                /// ========================
                /// EXTRA INFO
                /// ========================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Thông tin thiết bị",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _infoRow(
                        "Tín hiệu truyền",
                        "Excellent",
                        Colors.green,
                      ),
                      const SizedBox(height: 14),
                      _infoRow(
                        "Trạng thái cảm biến",
                        "Receiving Data",
                        Colors.blue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// ========================
  /// SENSOR CARD
  /// ========================
  Widget _sensorCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 28,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// ========================
  /// INFO ROW
  /// ========================
  Widget _infoRow(
    String title,
    String value,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
