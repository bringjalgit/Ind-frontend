import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/referral_share.dart';
import '../../theme/ThemeHelper.dart';
import '../../theme/AppTextStyles.dart';
import '../../model/ReferralModels.dart';
import '../../data/cubit/Referral/referral_cubit.dart';
import '../../data/cubit/Referral/referral_state.dart';

const Color _primary = Color(0xFF1677FF);
const Color _secondary = Color(0xFF4682B4);
const Color _accent = Color(0xFFFFD600);
const Color _okBg = Color(0xFFDCFCE7);
const Color _ok = Color(0xFF16A34A);
const Color _warnBg = Color(0xFFFEF3C7);
const Color _warn = Color(0xFFB45309);

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReferralCubit()..load(),
      child: const _ReferralView(),
    );
  }
}

class _ReferralView extends StatelessWidget {
  const _ReferralView();

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeHelper.isDarkMode(context);
    final bg = ThemeHelper.backgroundColor(context);
    final textColor = ThemeHelper.textColor(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text('Refer & Earn', style: AppTextStyles.headlineSmall(textColor)),
      ),
      body: BlocBuilder<ReferralCubit, ReferralState>(
        builder: (context, state) {
          if (state is ReferralLoading || state is ReferralInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ReferralDisabled) {
            return _centered(textColor, Icons.card_giftcard_outlined,
                'Refer & Earn is coming soon', 'This feature isn\'t available on your account yet.');
          }
          if (state is ReferralError) {
            return RefreshIndicator(
              onRefresh: () => context.read<ReferralCubit>().load(),
              child: ListView(children: [
                const SizedBox(height: 140),
                _centered(textColor, Icons.wifi_off_rounded, 'Something went wrong', state.message),
              ]),
            );
          }
          final s = state as ReferralLoaded;
          return RefreshIndicator(
            onRefresh: () => context.read<ReferralCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _hero(s.info),
                const SizedBox(height: 14),
                _redeemCard(context, isDark, textColor, s.info),
                const SizedBox(height: 14),
                _ruleCallout(isDark, textColor, s.info),
                const SizedBox(height: 14),
                _codeCard(context, isDark, textColor, s.info),
                const SizedBox(height: 14),
                _stats(isDark, textColor, s.info),
                const SizedBox(height: 18),
                Text('Friends you referred', style: AppTextStyles.titleSmall(textColor).copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                if (s.friends.isEmpty)
                  _emptyFriends(textColor)
                else
                  ...s.friends.map((f) => _friendRow(isDark, textColor, f)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---- HERO ----
  Widget _hero(ReferralInfo info) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, Color(0xFF2F7BF6), _secondary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withOpacity(0.16),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
              ),
              child: const Icon(Icons.card_giftcard, color: _accent, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Invite friends, earn rewards',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Reward points for boosts & spins',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12.5)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${info.rewardPoints}',
                style: const TextStyle(color: Colors.white, fontSize: 33, fontWeight: FontWeight.w800, height: 1)),
            const SizedBox(width: 6),
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text('points', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('YOUR BALANCE',
                  style: TextStyle(color: Colors.white.withOpacity(0.82), fontSize: 10.5, letterSpacing: 1.3, fontWeight: FontWeight.w700)),
            ),
          ]),
        ],
      ),
    );
  }

  // ---- REDEEM (points → free listing) ----
  Widget _redeemCard(BuildContext context, bool isDark, Color textColor, ReferralInfo info) {
    final cost = info.redeemFreeListingCost;
    final bal = info.rewardPoints;
    final canRedeem = info.canRedeemFreeListing;
    final credits = info.freeListingCredits;
    final pct = cost <= 0 ? 1.0 : (bal / cost).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDeco(isDark),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('REDEEM YOUR POINTS',
            style: AppTextStyles.labelSmall(textColor.withOpacity(0.6))
                .copyWith(letterSpacing: 1.4, fontWeight: FontWeight.w700)),
        if (credits > 0) ...[
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: _okBg,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: _ok.withOpacity(0.28)),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle_rounded, color: _ok, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  credits == 1
                      ? '1 free listing ready — applied automatically on your next ad'
                      : '$credits free listings ready — used automatically when you post',
                  style: const TextStyle(color: _ok, fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.35),
                ),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Container(
            width: 44, height: 44, alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFFFFE87A), _accent],
              ),
            ),
            child: const Icon(Icons.confirmation_num_rounded, color: Color(0xFF222222), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Free listing', style: AppTextStyles.bodyMedium(textColor).copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 1),
              Text('Post an ad free — no plan needed', style: AppTextStyles.labelMedium(textColor.withOpacity(0.6))),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$cost', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w800)),
            Text('points', style: AppTextStyles.labelSmall(textColor.withOpacity(0.6))),
          ]),
        ]),
        const SizedBox(height: 13),
        if (canRedeem)
          SizedBox(
            width: double.infinity, height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
              ),
              onPressed: () => _doRedeem(context),
              icon: const Icon(Icons.card_giftcard_rounded, size: 18),
              label: const Text('Redeem for a free listing', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
            ),
          )
        else ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: pct, minHeight: 8,
              backgroundColor: isDark ? Colors.white10 : const Color(0xFFF0F1F4),
              color: _primary,
            ),
          ),
          const SizedBox(height: 7),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('$bal / $cost', style: AppTextStyles.labelMedium(textColor.withOpacity(0.65))),
            Text('Earn ${cost - bal} more to unlock', style: AppTextStyles.labelMedium(textColor.withOpacity(0.65))),
          ]),
        ],
      ]),
    );
  }

  Future<void> _doRedeem(BuildContext context) async {
    final cubit = context.read<ReferralCubit>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final result = await cubit.redeemFreeListing();
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.success
          ? 'Free listing unlocked! Use it on your next ad.'
          : result.message),
      duration: const Duration(seconds: 2),
    ));
  }

  // ---- RULE CALLOUT ----
  Widget _ruleCallout(bool isDark, Color textColor, ReferralInfo info) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: _accent.withOpacity(isDark ? 0.14 : 0.13),
        border: Border.all(color: const Color(0xFFD6A000).withOpacity(0.40)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: _accent),
          child: const Icon(Icons.verified_rounded, color: Color(0xFF222222), size: 19),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('How you both earn',
                style: AppTextStyles.titleSmall(textColor).copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(
              'Points are paid only after your friend posts their first listing successfully. '
              'Then you get ${info.referrerPoints} and they get ${info.refereePoints} — automatically.',
              style: AppTextStyles.bodySmall(textColor).copyWith(height: 1.5),
            ),
          ]),
        ),
      ]),
    );
  }

  // ---- CODE CARD ----
  Widget _codeCard(BuildContext context, bool isDark, Color textColor, ReferralInfo info) {
    final code = info.code ?? '—';
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDeco(isDark),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('YOUR REFERRAL CODE',
            style: AppTextStyles.labelSmall(textColor.withOpacity(0.6)).copyWith(letterSpacing: 1.4, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: Text(code,
                style: TextStyle(color: textColor, fontSize: 23, fontWeight: FontWeight.w800, letterSpacing: 5)),
          ),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied'), duration: Duration(seconds: 1)),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isDark ? Colors.white10 : const Color(0xFFF4F6F8),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFDFDFDF)),
              ),
              child: const Icon(Icons.copy_rounded, color: _primary, size: 18),
            ),
          ),
        ]),
        const SizedBox(height: 13),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
            ),
            onPressed: () => shareReferralInvite(context: context, info: info),
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('Share invite', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  // ---- STATS ----
  Widget _stats(bool isDark, Color textColor, ReferralInfo info) {
    return Row(children: [
      _stat(isDark, textColor, '${info.totalReferred}', 'Referred', null),
      const SizedBox(width: 10),
      _stat(isDark, textColor, '${info.totalPending}', 'Pending', info.totalPending > 0 ? _primary : null),
      const SizedBox(width: 10),
      _stat(isDark, textColor, '${info.totalEarned}', 'Points earned', const Color(0xFFC79A00)),
    ]);
  }

  Widget _stat(bool isDark, Color textColor, String n, String k, Color? nColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
        decoration: _cardDeco(isDark),
        child: Column(children: [
          Text(n, style: TextStyle(color: nColor ?? textColor, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(k, textAlign: TextAlign.center, style: AppTextStyles.labelMedium(textColor.withOpacity(0.65))),
        ]),
      ),
    );
  }

  // ---- FRIEND ROW ----
  Widget _friendRow(bool isDark, Color textColor, ReferredFriend f) {
    final initial = f.name.isNotEmpty ? f.name[0].toUpperCase() : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 13),
      decoration: _cardDeco(isDark),
      child: Row(children: [
        Container(
          width: 38, height: 38, alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_primary, _secondary]),
          ),
          child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(f.name, style: AppTextStyles.bodyMedium(textColor).copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 1),
            Text(
              f.isRewarded ? 'Posted first listing · you were paid' : 'Hasn\'t posted a listing yet · no points yet',
              style: AppTextStyles.labelMedium(textColor.withOpacity(0.6)),
            ),
          ]),
        ),
        _statusPill(f),
        if (f.isRewarded) ...[
          const SizedBox(width: 8),
          Text('+${f.points}', style: const TextStyle(color: _ok, fontWeight: FontWeight.w800, fontSize: 12.5)),
        ],
      ]),
    );
  }

  Widget _statusPill(ReferredFriend f) {
    final ok = f.isRewarded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: ok ? _okBg : _warnBg, borderRadius: BorderRadius.circular(999)),
      child: Text(ok ? 'Rewarded' : 'Pending',
          style: TextStyle(color: ok ? _ok : _warn, fontSize: 10.5, fontWeight: FontWeight.w700)),
    );
  }

  Widget _emptyFriends(Color textColor) => Container(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
        alignment: Alignment.center,
        child: Column(children: [
          Icon(Icons.group_add_outlined, color: textColor.withOpacity(0.35), size: 34),
          const SizedBox(height: 8),
          Text('No referrals yet', style: AppTextStyles.bodyMedium(textColor.withOpacity(0.7))),
          const SizedBox(height: 3),
          Text('Share your code to start earning', style: AppTextStyles.bodySmall(textColor.withOpacity(0.5))),
        ]),
      );

  BoxDecoration _cardDeco(bool isDark) => BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1B1B1E), const Color(0xFF141416)]
              : [const Color(0xFFF9FAFB), const Color(0xFFFFFFFF)],
        ),
        border: Border.all(color: isDark ? const Color(0xFF2B2B2E) : const Color(0xFFDFDFDF)),
      );

  Widget _centered(Color textColor, IconData icon, String title, String sub) => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 44, color: textColor.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: AppTextStyles.titleMedium(textColor).copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text(sub, textAlign: TextAlign.center, style: AppTextStyles.bodySmall(textColor.withOpacity(0.6))),
          ]),
        ),
      );
}
