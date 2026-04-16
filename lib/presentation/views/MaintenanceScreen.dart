import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/services/AppConfigService.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final message = AppConfigService.maintenanceMessage.isNotEmpty
        ? AppConfigService.maintenanceMessage
        : 'We are under maintenance. Please try again later.';
    final estimatedEnd = AppConfigService.config.maintenance.estimatedEnd;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.construction, size: 80, color: Color(0xFFE94560)),
              ),
              const SizedBox(height: 32),
              const Text(
                'Under Maintenance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              if (estimatedEnd != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Estimated back by: ${_formatTime(estimatedEnd)}',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                ),
              ],
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Re-fetch config and check again
                    await AppConfigService.fetch();
                    if (!AppConfigService.isMaintenanceActive && context.mounted) {
                      context.pushReplacement('/dashboard');
                    }
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  label: const Text('Retry', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} $h:$m';
  }
}
