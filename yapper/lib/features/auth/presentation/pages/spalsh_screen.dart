import 'package:flutter/material.dart';
import 'package:yapper/injection_container.dart' as di;
import '../../../chat/presentation/pages/chat_history.dart';
import 'login.dart'; // import your login page
import 'package:yapper/features/auth/data/datasources/auth_local_data_source.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Small delay for splash visuals
    await Future.delayed(const Duration(seconds: 2));
    try {
      final local = di.sl<AuthLocalDataSource>();
      final cached = await local.getCachedUser();
      if (!mounted) return;
      if (cached != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ChatListScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 300,
                    height: 300,
                    child: Image.asset('assets/images/Group.png'),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const Text(
                'Welcome to\nYappers',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
