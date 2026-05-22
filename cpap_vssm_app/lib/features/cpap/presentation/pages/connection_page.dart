import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/ble_cubit.dart';
import 'dashboard_page.dart';

class ConnectionPage extends StatefulWidget {
  const ConnectionPage({super.key});

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  bool isConnecting = false;

  /// =========================
  /// CONNECT DEVICE
  /// =========================
  Future<void> connectDevice() async {
    setState(() {
      isConnecting = true;
    });

    await context.read<BleCubit>().autoConnect();

    setState(() {
      isConnecting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: BlocListener<BleCubit, BleState>(
          listener: (context, state) async {
            /// =========================
            /// CONNECTED
            /// =========================
            if (state is BleConnected) {
              await context.read<BleCubit>().bleService.startListeningSensor();

              if (!mounted) return;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const DashboardPage(),
                ),
              );
            }

            /// =========================
            /// NOT FOUND
            /// =========================
            if (state is BleNotFound) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.red,
                  content: const Text(
                    "Không tìm thấy thiết bị CPAP ",
                  ),
                ),
              );
            }
          },
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// =========================
                  /// ICON
                  /// =========================
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Image.asset(
                        "assets/icons/mainIcon.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// =========================
                  /// TITLE
                  /// =========================
                  const Text(
                    "Kết nối thiết bị \n CPAP VSSM",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 14),

                  /// =========================
                  /// SUBTITLE
                  /// =========================
                  const Text(
                    "Đảm bảo thiết bị CPAP VSSM kết nối nguồn và ở khoảng cách tối đa 5m",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 50),

                  /// =========================
                  /// CONNECT BUTTON
                  /// =========================
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: isConnecting ? null : connectDevice,
                      child: isConnecting
                          ? const SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bluetooth_connected,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Kết nối thiết bị",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// =========================
                  /// STATUS
                  /// =========================
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Sẵn sàng kết nối",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
