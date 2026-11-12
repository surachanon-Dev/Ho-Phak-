import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../widgets/common.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HoPhakLogo(size: 88, light: true),
            SizedBox(height: 12),
            Text('ค้นหาหอพักที่ใช่ ใกล้ที่คุณต้องการ', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 32),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
