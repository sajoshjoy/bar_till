// lib/login_screen.dart
import 'package:flutter/material.dart';
import 'database.dart';
import 'auth_service.dart';
import 'till_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String pin = '';
  String error = '';

  Future<void> _submit() async {
    if (pin.length < 4) return;
    final staff = await AppDatabase.findStaffByPin(pin);
    if (staff == null) {
      setState(() {
        error = 'Invalid PIN';
        pin = '';
      });
      return;
    }
    AuthService.login(staff);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TillScreen()),
    );
  }

  void _tap(String d) {
    if (pin.length >= 4) return;
    setState(() {
      pin += d;
      error = '';
    });
    if (pin.length == 4) _submit();
  }

  void _backspace() {
    if (pin.isEmpty) return;
    setState(() => pin = pin.substring(0, pin.length - 1));
  }

  void _clear() {
    setState(() {
      pin = '';
      error = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC), Color(0xFF00C9FF)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 520,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.lock_outline,
                        color: Colors.white, size: 42),
                  ),
                  const SizedBox(height: 20),
                  const Text('Staff Login',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B2B4A))),
                  const SizedBox(height: 6),
                  const Text('Enter your 4-digit PIN',
                      style: TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final filled = i < pin.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: filled
                              ? const LinearGradient(colors: [
                                  Color(0xFF6A11CB),
                                  Color(0xFF2575FC),
                                ])
                              : null,
                          color: filled ? null : const Color(0xFFEDEFF6),
                          border: Border.all(
                            color: filled
                                ? Colors.transparent
                                : const Color(0xFFD7DCEA),
                            width: 1.5,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  if (error.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Color(0xFFC62828), size: 18),
                          const SizedBox(width: 6),
                          Text(error,
                              style:
                                  const TextStyle(color: Color(0xFFC62828))),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  _Keypad(
                    onDigit: _tap,
                    onBackspace: _backspace,
                    onClear: _clear,
                    onEnter: _submit,
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6FB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Manager: 1234   •   Cashier: 1111',
                      style: TextStyle(
                          color: Color(0xFF2B2B4A),
                          fontWeight: FontWeight.w500),
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

class _Keypad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onEnter;

  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
    required this.onEnter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row(['1', '2', '3']),
        const SizedBox(height: 12),
        _row(['4', '5', '6']),
        const SizedBox(height: 12),
        _row(['7', '8', '9']),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _digitKey('⌫', onTap: onBackspace, color: const Color(0xFF9E9E9E)),
            const SizedBox(width: 12),
            _digitKey('0', onTap: () => onDigit('0')),
            const SizedBox(width: 12),
            _digitKey('C', onTap: onClear, color: const Color(0xFFE94B4B)),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF43C97A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: onEnter,
            child: const Text('Login',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _row(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < digits.length; i++) ...[
          _digitKey(digits[i], onTap: () => onDigit(digits[i])),
          if (i < digits.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _digitKey(String label,
      {required VoidCallback onTap, Color? color}) {
    final isDigit = int.tryParse(label) != null;
    return SizedBox(
      width: 92,
      height: 68,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? const Color(0xFF3F6FE0),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: TextStyle(
            fontSize: isDigit ? 26 : 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}