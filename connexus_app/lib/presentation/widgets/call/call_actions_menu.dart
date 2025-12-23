import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bottom sheet menu for additional call actions.
/// Used for less common actions that don't fit in the main UI.
class CallActionsMenu extends StatelessWidget {
  final bool isRecording;
  final bool isBluetoothAvailable;
  final bool isBluetoothConnected;
  final VoidCallback? onToggleRecording;
  final VoidCallback? onToggleBluetooth;
  final VoidCallback? onSendSms;
  final VoidCallback? onAddNote;
  final VoidCallback? onViewContact;

  const CallActionsMenu({
    super.key,
    this.isRecording = false,
    this.isBluetoothAvailable = false,
    this.isBluetoothConnected = false,
    this.onToggleRecording,
    this.onToggleBluetooth,
    this.onSendSms,
    this.onAddNote,
    this.onViewContact,
  });

  static Future<void> show(
    BuildContext context,
    CallActionsMenu menu,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => menu,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A3E),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Text(
            'Call Actions',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          // Action items
          _ActionItem(
            icon:
                isRecording ? Icons.stop : Icons.fiber_manual_record,
            iconColor: isRecording ? Colors.red : null,
            label:
                isRecording ? 'Stop Recording' : 'Start Recording',
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              onToggleRecording?.call();
            },
          ),
          if (isBluetoothAvailable)
            _ActionItem(
              icon: Icons.bluetooth_audio,
              iconColor:
                  isBluetoothConnected ? Colors.blue : null,
              label: isBluetoothConnected
                  ? 'Disconnect Bluetooth'
                  : 'Connect Bluetooth',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                onToggleBluetooth?.call();
              },
            ),
          _ActionItem(
            icon: Icons.sms,
            label: 'Send SMS',
            subtitle: 'Send text message to caller',
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              onSendSms?.call();
            },
          ),
          _ActionItem(
            icon: Icons.note_add,
            label: 'Add Note',
            subtitle: 'Add note about this call',
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              onAddNote?.call();
            },
          ),
          _ActionItem(
            icon: Icons.person,
            label: 'View Contact',
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              onViewContact?.call();
            },
          ),
          const SizedBox(height: 16),
          // Cancel button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  const _ActionItem({
    required this.icon,
    this.iconColor,
    required this.label,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 8,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (iconColor ?? Colors.white)
                    .withOpacity(0.1),
              ),
              child: Icon(
                icon,
                color: iconColor ??
                    Colors.white.withOpacity(0.9),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.white
                            .withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}


