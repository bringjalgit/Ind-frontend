import 'package:flutter/material.dart';

import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeHelper.isDarkMode(context);
    final bgColor = ThemeHelper.backgroundColor(context);
    final textColor = ThemeHelper.textColor(context);

    final notifications = [
      {
        'color': Colors.grey,
        'text':
            'You purchased iPhone 13 Pro for ₹58,000.\nThe seller will ship it shortly',
      },
      {
        'color': Colors.red,
        'text':
            'Your Samsung Smart TV 55” listing has been sold! Get ready to ship it',
      },
      {
        'color': Colors.yellow[800],
        'text':
            'Offer received: ₹6,000 for Sony Soundbar HT-S20R. Accept or counter?',
      },
      {
        'color': Colors.green,
        'text': 'Your product Honda Activa 6G has 15 new views today',
      },
      {
        'color': Colors.blue,
        'text':
            'Reminder: Dispatch your sold product iPhone 13 Pro by tomorrow',
      },
      {
        'color': Colors.grey,
        'text':
            'You purchased iPhone 13 Pro for ₹58,000.\nThe seller will ship it shortly',
      },
      {
        'color': Colors.red,
        'text':
            'Your Samsung Smart TV 55” listing has been sold! Get ready to ship it',
      },
      {
        'color': Colors.yellow[800],
        'text':
            'Offer received: ₹6,000 for Sony Soundbar HT-S20R. Accept or counter?',
      },
      {
        'color': Colors.green,
        'text': 'Your product Honda Activa 6G has 15 new views today',
      },
      {
        'color': Colors.blue,
        'text':
            'Reminder: Dispatch your sold product iPhone 13 Pro by tomorrow',
      },
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Notification',
          style: AppTextStyles.headlineSmall(textColor),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = notifications[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: (item['color'] as Color).withOpacity(0.3),
                  child: Icon(Icons.person, color: item['color'] as Color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['text'].toString(),
                    style: AppTextStyles.bodyMedium(textColor),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
