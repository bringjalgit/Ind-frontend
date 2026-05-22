import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/Components/CutomAppBar.dart';
import 'package:classifieds/theme/app_colors.dart';
import 'package:classifieds/widgets/CommonLoader.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/cubit/ContactInfo/ContactInfoCubit.dart';
import '../../data/cubit/ContactInfo/ContactInfoStates.dart';
import '../../model/ContactInfoModel.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({Key? key}) : super(key: key);

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ContactInfoCubit>().getContactInfo();
  }

  // Helper to extract dynamic value by key name
  String? _getValue(List<Data>? data, String key) {
    return data
        ?.firstWhere(
          (item) => item.name?.toLowerCase() == key.toLowerCase(),
          orElse: () => Data(value: null),
        )
        .value;
  }

  // --- Launch functions ---
  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Support Request for IND Classifieds',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.textColor(context);
    final backgroundColor = ThemeHelper.backgroundColor(context);

    return Scaffold(
      appBar: CustomAppBar1(title: 'Contact Support', actions: []),
      body: SafeArea(
        child: BlocBuilder<ContactInfoCubit, ContactInfoStates>(
          builder: (context, state) {
            if (state is ContactInfoLoading) {
              return const Center(child: DottedProgressWithLogo());
            } else if (state is ContactInfoFailure) {
              return Center(child: Text("Error: ${state.error}"));
            } else if (state is ContactInfoLoaded) {
              final data = state.contactInfoModel.data;

              final email =
                  _getValue(data, "Mail") ?? "support@indclassifieds.in";
              final phone =
                  _getValue(data, "Admin Mobile") ?? "+91 83091 63721";

              return Container(
                color: backgroundColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Lottie.asset(
                        'assets/lottie/Support.json',
                        width: 200,
                        height: 200,
                        repeat: true,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'We’re Here to Help!',
                        style: AppTextStyles.headlineMedium(textColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Reach out to us via Email or Phone. Our team responds within 24 hours.',
                        style: AppTextStyles.bodyMedium(textColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Email
                      _buildContactOption(
                        context,
                        icon: Icons.email_rounded,
                        title: 'Email Us',
                        subtitle: email,
                        onTap: () => _launchEmail(email),
                      ),
                      const SizedBox(height: 16),

                      // Phone
                      _buildContactOption(
                        context,
                        icon: Icons.phone_rounded,
                        title: 'Call Us',
                        subtitle: phone,
                        onTap: () => _launchPhone(phone),
                      ),

                      // const SizedBox(height: 16),
                      //
                      // // WhatsApp
                      // _buildContactOption(
                      //   context,
                      //   icon: Icons.chat_bubble_rounded,
                      //   title: 'WhatsApp Us',
                      //   subtitle: 'Chat with us instantly',
                      //   onTap: () => _launchWhatsApp(whatsapp),
                      // ),
                      const Spacer(),
                      Text(
                        'IND Classifieds - Buy, Sell, Connect!',
                        style: AppTextStyles.bodySmall(textColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  // Reusable card widget
  Widget _buildContactOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final textColor = ThemeHelper.textColor(context);
    return Card(
      elevation: 4,
      color: ThemeHelper.cardColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Icon(icon, size: 28, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleMedium(textColor)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTextStyles.bodySmall(textColor)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: textColor),
            ],
          ),
        ),
      ),
    );
  }
}
