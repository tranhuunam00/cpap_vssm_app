import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/ble_cubit.dart';
import 'connection_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  StreamSubscription<int>? rssiSubscription;
  // =====================================================
  // BLE
  // =====================================================

  @override
  void initState() {
    super.initState();

    final bleService = context.read<BleCubit>().bleService;

    rssiSubscription = bleService.rssiStream.listen((rssi) {
      if (!mounted) return;

      setState(() {
        currentRssi = rssi;
      });
    });
  }

  Timer? _timeoutTimer;

  bool isDisconnected = false;

  int packetCount = 0;

  int latency = 0;

  int currentRssi = 0;

  DateTime? lastPacketTime;

  // =====================================================
  // BLOWER
  // =====================================================

  double currentPwm = 55;
  double pendingPwm = 55;
  bool pwmChanged = false;

  bool blowerRunning = false;

  // =====================================================
  // RUNTIME
  // =====================================================

  DateTime? startTime;

  Duration runningDuration = Duration.zero;

  Duration totalRuntime = Duration.zero;

  Timer? runtimeTimer;

  // =====================================================
  // RESET TIMEOUT
  // =====================================================

  void resetTimeout() {
    _timeoutTimer?.cancel();

    _timeoutTimer = Timer(
      const Duration(seconds: 2),
      () {
        if (mounted) {
          setState(() {
            isDisconnected = true;
          });
        }
      },
    );
  }

  // =====================================================
  // START RUNTIME
  // =====================================================

  void startRuntime() {
    if (startTime != null) {
      return;
    }

    startTime = DateTime.now();

    runtimeTimer?.cancel();

    runtimeTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted || startTime == null) {
          return;
        }

        setState(() {
          runningDuration = DateTime.now().difference(
            startTime!,
          );
        });
      },
    );
  }

  // =====================================================
  // STOP RUNTIME
  // =====================================================

  void stopRuntime() {
    runtimeTimer?.cancel();

    if (startTime != null) {
      totalRuntime += DateTime.now().difference(
        startTime!,
      );
    }

    startTime = null;

    runningDuration = Duration.zero;
  }

  // =====================================================
  // FORMAT TIME
  // =====================================================

  String formatDuration(Duration duration) {
    String two(int n) => n.toString().padLeft(2, '0');

    return "${two(duration.inHours)}:"
        "${two(duration.inMinutes.remainder(60))}:"
        "${two(duration.inSeconds.remainder(60))}";
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    rssiSubscription?.cancel();
    runtimeTimer?.cancel();

    super.dispose();
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final bleService = context.read<BleCubit>().bleService;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),

      // =================================================
      // APPBAR
      // =================================================

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "SiPAP",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              right: 14,
            ),
            child: Row(
              children: [
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              22,
                            ),
                          ),
                          title: const Text(
                            "Ngắt kết nối",
                          ),
                          content: const Text(
                            "Bạn có chắc muốn ngắt BLE?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(
                                  context,
                                  false,
                                );
                              },
                              child: const Text(
                                "Hủy",
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () {
                                Navigator.pop(
                                  context,
                                  true,
                                );
                              },
                              child: const Text(
                                "Ngắt",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirm != true) {
                      return;
                    }

                    await bleService.disconnect();

                    if (!context.mounted) {
                      return;
                    }

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConnectionPage(),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(
                    Icons.power_settings_new,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // =================================================
      // BODY
      // =================================================

      body: StreamBuilder<Map<String, dynamic>>(
        stream: bleService.sensorStream,
        builder: (context, snapshot) {
          // =============================================
          // DISCONNECTED
          // =============================================

          if (!snapshot.hasData || isDisconnected) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bluetooth_disabled,
                      size: 110,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Mất kết nối SiPAP",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Không nhận được dữ liệu từ thiết bị",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            16,
                          ),
                        ),
                      ),
                      onPressed: () async {
                        await bleService.disconnect();

                        if (!context.mounted) {
                          return;
                        }

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ConnectionPage(),
                          ),
                          (route) => false,
                        );
                      },
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Kết nối lại",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // =============================================
          // SENSOR DATA
          // =============================================

          final data = snapshot.data!;

          resetTimeout();

          isDisconnected = false;

          packetCount++;

          final now = DateTime.now();

          if (lastPacketTime != null) {
            latency = now.difference(lastPacketTime!).inMilliseconds;
          }

          lastPacketTime = now;

          final flow = (data["flow"] ?? 0).toDouble();

          final rpm = data["rpm"] ?? 0;

          final pwm = data["pwm"] ?? 0;

          currentPwm = pwm.toDouble();

          if (!pwmChanged) {
            pendingPwm = currentPwm;
          }

          blowerRunning = pwm > 0;

          // =============================================
          // RUNTIME
          // =============================================

          if (blowerRunning) {
            startRuntime();
          } else {
            stopRuntime();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // =========================================
                // STATUS CARD
                // =========================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade700,
                        Colors.blue.shade400,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      28,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          const Text(
                            "ĐÃ KẾT NỐI",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 26,
                      ),
                      Wrap(
                        spacing: 30,
                        runSpacing: 18,
                        children: [
                          _statusItem(
                            "Trạng thái bơm",
                            blowerRunning ? "ĐANG CHẠY" : "ĐÃ DỪNG",
                          ),
                          _statusItem(
                            "Tổng TG",
                            formatDuration(
                              totalRuntime + runningDuration,
                            ),
                          ),
                          _statusItem(
                            "RSSI",
                            "$currentRssi dBm",
                          ),
                          _statusItem(
                            "Packet",
                            "$packetCount",
                          ),
                          _statusItem(
                            "Delay",
                            "${latency}ms",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // =========================================
                // SENSOR GRID
                // =========================================

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.9,
                  children: [
                    _sensorCard(
                      title: "LƯU LƯỢNG",
                      value: flow.toStringAsFixed(1),
                      unit: "slm",
                      icon: Icons.air,
                      color: Colors.blue,
                      subtitle: "Dòng khí hiện tại",
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // =========================================
                // CONTROL PANEL
                // =========================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      28,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.settings,
                            color: Colors.blue,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          const Text(
                            "Điều khiển blower",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "PWM ${currentPwm.toInt()}",
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      // =====================================
                      // BUTTONS
                      // =====================================

                      Row(
                        children: [
                          Expanded(
                            child: AnimatedOpacity(
                              duration: const Duration(
                                milliseconds: 200,
                              ),
                              opacity: blowerRunning ? 0.6 : 1,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  disabledBackgroundColor:
                                      Colors.green.shade300,
                                  elevation: blowerRunning ? 0 : 8,
                                  shadowColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      18,
                                    ),
                                  ),
                                ),
                                onPressed: blowerRunning
                                    ? null
                                    : () async {
                                        await bleService.sendAction(
                                          "START",
                                        );
                                      },
                                icon: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Bật",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: AnimatedOpacity(
                              duration: const Duration(
                                milliseconds: 200,
                              ),
                              opacity: !blowerRunning ? 0.6 : 1,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  disabledBackgroundColor: Colors.red.shade300,
                                  elevation: !blowerRunning ? 0 : 8,
                                  shadowColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      18,
                                    ),
                                  ),
                                ),
                                onPressed: !blowerRunning
                                    ? null
                                    : () async {
                                        await bleService.sendAction(
                                          "STOP",
                                        );
                                      },
                                icon: const Icon(
                                  Icons.stop,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Tắt",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 26,
                      ),

                      // =====================================
                      // SLIDER
                      // =====================================

                      // =====================================
// SLIDER
// =====================================

                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Tốc độ blower",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${pendingPwm.toInt()}",
                                style: TextStyle(
                                  color:
                                      pwmChanged ? Colors.orange : Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: pendingPwm,
                            min: 0,
                            max: 255,
                            divisions: 255,
                            activeColor: Colors.blue,
                            inactiveColor: Colors.grey.shade300,
                            onChanged: (v) {
                              setState(() {
                                pendingPwm = v;
                                pwmChanged =
                                    pendingPwm.toInt() != currentPwm.toInt();
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: pwmChanged
                                    ? Colors.orange
                                    : Colors.grey.shade400,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: pwmChanged
                                  ? () async {
                                      final pwmValue = pendingPwm.toInt();

                                      await bleService.sendAction(
                                        "PWM:$pwmValue",
                                      );

                                      setState(() {
                                        currentPwm = pendingPwm;
                                        pwmChanged = false;
                                      });
                                    }
                                  : null,
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "Áp dụng tốc độ",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
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

  // =====================================================
  // STATUS ITEM
  // =====================================================

  Widget _statusItem(
    String title,
    String value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // =====================================================
  // SENSOR CARD
  // =====================================================

  Widget _sensorCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.05,
            ),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "$value $unit",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
