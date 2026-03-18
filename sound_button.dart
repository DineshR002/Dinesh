import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
class SoundButton extends StatelessWidget {
  final bool isOn;
  final VoidCallback onTap;

  const SoundButton({
    super.key,
    required this.isOn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isOn
                ? [Colors.greenAccent, Colors.green]
                : [Colors.redAccent, Colors.red],
          ),
          boxShadow: [
            BoxShadow(
              color: isOn
                  ? Colors.green.withOpacity(0.5)
                  : Colors.red.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          isOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}
