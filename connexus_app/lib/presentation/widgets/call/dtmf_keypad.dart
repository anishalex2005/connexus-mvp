import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// DTMF Keypad for sending touch tones during a call.
/// Provides visual and haptic feedback for each key press.
class DtmfKeypad extends StatelessWidget {
  final void Function(String) onKeyPressed;
  final VoidCallback? onClose;
  final String? dtmfInput;

  const DtmfKeypad({
    super.key,
    required this.onKeyPressed,
    this.onClose,
    this.dtmfInput,
  });

  static const List<List<DtmfKey>> _keys = <List<DtmfKey>>[
    <DtmfKey>[
      DtmfKey('1', ''),
      DtmfKey('2', 'ABC'),
      DtmfKey('3', 'DEF'),
    ],
    <DtmfKey>[
      DtmfKey('4', 'GHI'),
      DtmfKey('5', 'JKL'),
      DtmfKey('6', 'MNO'),
    ],
    <DtmfKey>[
      DtmfKey('7', 'PQRS'),
      DtmfKey('8', 'TUV'),
      DtmfKey('9', 'WXYZ'),
    ],
    <DtmfKey>[
      DtmfKey('*', ''),
      DtmfKey('0', '+'),
      DtmfKey('#', ''),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Handle indicator
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // DTMF Input Display
          if (dtmfInput != null && dtmfInput!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                dtmfInput!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 4,
                ),
              ),
            ),
          // Keypad Grid
          ...List<Widget>.generate(_keys.length, (int rowIndex) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _keys[rowIndex].map((DtmfKey key) {
                  return _DtmfKeyButton(
                    dtmfKey: key,
                    onPressed: () => onKeyPressed(key.digit),
                  );
                }).toList(),
              ),
            );
          }),
          const SizedBox(height: 16),
          // Close Button
          if (onClose != null)
            TextButton.icon(
              onPressed: onClose,
              icon: const Icon(
                Icons.keyboard_hide,
                color: Colors.white70,
              ),
              label: const Text(
                'Hide Keypad',
                style: TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }
}

/// Data class for DTMF key.
class DtmfKey {
  final String digit;
  final String letters;

  const DtmfKey(this.digit, this.letters);
}

/// Individual DTMF key button with animations.
class _DtmfKeyButton extends StatefulWidget {
  final DtmfKey dtmfKey;
  final VoidCallback onPressed;

  const _DtmfKeyButton({
    required this.dtmfKey,
    required this.onPressed,
  });

  @override
  State<_DtmfKeyButton> createState() => _DtmfKeyButtonState();
}

class _DtmfKeyButtonState extends State<_DtmfKeyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    HapticFeedback.lightImpact();
    widget.onPressed();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (BuildContext context, Widget? child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    widget.dtmfKey.digit,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.dtmfKey.letters.isNotEmpty)
                    Text(
                      widget.dtmfKey.letters,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


