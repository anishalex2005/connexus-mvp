import 'package:flutter/material.dart';
import '../base_screen.dart';

class HomeScreen extends BaseScreen {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends BaseScreenState<HomeScreen> {
  // Simple mock data for recent AI calls
  final List<_MockCall> _recentCalls = const [
    _MockCall(
      contactName: 'Acme Support Line',
      direction: CallDirection.outbound,
      durationMinutes: 7,
      outcome: 'Issue resolved',
      startedAt: 'Today · 10:24 AM',
    ),
    _MockCall(
      contactName: 'Onboarding – New User',
      direction: CallDirection.outbound,
      durationMinutes: 15,
      outcome: 'Left voicemail with summary',
      startedAt: 'Yesterday · 3:12 PM',
    ),
    _MockCall(
      contactName: 'VIP Customer Check‑in',
      direction: CallDirection.inbound,
      durationMinutes: 4,
      outcome: 'Escalated to human agent',
      startedAt: 'Mon · 5:47 PM',
    ),
  ];

  @override
  String get appBarTitle => 'ConnexUS';

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Call Overview',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This is a demo view showing recent AI-assisted calls using mock data.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: null, // Stubbed for now
                  icon: const Icon(Icons.smart_toy_outlined),
                  label: const Text('Start AI Call'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: null, // Stubbed for now
                  icon: const Icon(Icons.sms_outlined),
                  label: const Text('Send AI SMS'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Recent AI Calls',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: _recentCalls.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final call = _recentCalls[index];
                return _RecentCallCard(call: call);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentCallCard extends StatelessWidget {
  const _RecentCallCard({required this.call});

  final _MockCall call;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = call.direction == CallDirection.outbound
        ? Icons.north_east
        : Icons.south_west;
    final iconColor =
        call.direction == CallDirection.outbound ? Colors.green : Colors.blue;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    call.contactName,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    call.outcome,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${call.startedAt} · ${call.durationMinutes} min',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockCall {
  const _MockCall({
    required this.contactName,
    required this.direction,
    required this.durationMinutes,
    required this.outcome,
    required this.startedAt,
  });

  final String contactName;
  final CallDirection direction;
  final int durationMinutes;
  final String outcome;
  final String startedAt;
}

enum CallDirection { inbound, outbound }
