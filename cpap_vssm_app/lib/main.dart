import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/ble/ble_service.dart';
import 'features/cpap/presentation/bloc/ble_cubit.dart';
import 'features/cpap/presentation/pages/connection_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BleCubit(BleService()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const ConnectionPage(),
      ),
    );
  }
}
