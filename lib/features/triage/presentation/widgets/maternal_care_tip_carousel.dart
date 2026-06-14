import 'dart:async';

import 'package:flutter/material.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/localization/app_localizations.dart';

class MaternalCareTipCarousel extends StatefulWidget {
  const MaternalCareTipCarousel({super.key, this.compact = false});

  final bool compact;

  @override
  State<MaternalCareTipCarousel> createState() =>
      _MaternalCareTipCarouselState();
}

class _MaternalCareTipCarouselState extends State<MaternalCareTipCarousel> {
  Timer? _timer;
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!reduceMotion) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) {
          setState(() => _index = (_index + 1) % _tips(context).length);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tips = _tips(context);
    final tip = tips[_index % tips.length];
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return AnimatedSwitcher(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 450),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0.03),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(tip.title),
        padding: EdgeInsets.all(widget.compact ? 14 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              tip.color.withValues(alpha: 0.16),
              AppTheme.primary.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: tip.color.withValues(alpha: 0.22)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: widget.compact ? 38 : 42,
              height: widget.compact ? 38 : 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tip.color.withValues(alpha: 0.14),
              ),
              child: Icon(tip.icon, color: tip.color, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tip.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tip.body,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: widget.compact ? 12.5 : 13,
                      height: 1.35,
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

  List<_MaternalCareTip> _tips(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sw = l10n.locale == 'sw';
    if (sw) {
      return const [
        _MaternalCareTip(
          Icons.warning_amber_rounded,
          'Dalili za hatari',
          'Kutokwa damu, kichwa kuuma sana, uvimbe wa uso/mikono, homa, kifafa, au mtoto kusonga kidogo kunahitaji huduma haraka.',
          AppTheme.error,
        ),
        _MaternalCareTip(
          Icons.event_available_outlined,
          'Hudhuria ANC',
          'ANC husaidia kupima shinikizo la damu, upungufu wa damu, ukuaji wa ujauzito, na kupanga hatua inayofuata ya huduma.',
          AppTheme.primary,
        ),
        _MaternalCareTip(
          Icons.medication_outlined,
          'Virutubisho na damu',
          'Muulize mhudumu wako kuhusu chuma/folate na vipimo vya Hb kama unachoka haraka au kupumua kwa shida.',
          AppTheme.warning,
        ),
        _MaternalCareTip(
          Icons.bug_report_outlined,
          'Kinga ya malaria',
          'Katika maeneo yenye malaria, ANC inaweza kusaidia neti, IPTp, na matibabu ya haraka ya homa.',
          AppTheme.success,
        ),
        _MaternalCareTip(
          Icons.privacy_tip_outlined,
          'Vipimo vya siri',
          'Huduma za ANC zinaweza kutoa vipimo vya HIV na kaswende kwa faragha ili kulinda mama na mtoto.',
          AppTheme.accent,
        ),
      ];
    }
    return const [
      _MaternalCareTip(
        Icons.warning_amber_rounded,
        'Know danger signs',
        'Bleeding, severe headache, face or hand swelling, fever, convulsions, or reduced baby movement need care quickly.',
        AppTheme.error,
      ),
      _MaternalCareTip(
        Icons.event_available_outlined,
        'Keep ANC close',
        'ANC checks can review blood pressure, anaemia, pregnancy progress, and the next safe care step.',
        AppTheme.primary,
      ),
      _MaternalCareTip(
        Icons.medication_outlined,
        'Ask about iron and folate',
        'If you feel very tired or short of breath, ask your care team about Hb checks and supplements.',
        AppTheme.warning,
      ),
      _MaternalCareTip(
        Icons.bug_report_outlined,
        'Prevent malaria early',
        'In malaria-risk areas, ANC can help with nets, IPTp, and fast care when fever appears.',
        AppTheme.success,
      ),
      _MaternalCareTip(
        Icons.privacy_tip_outlined,
        'Private screening matters',
        'ANC can offer confidential HIV and syphilis screening to protect both mother and baby.',
        AppTheme.accent,
      ),
    ];
  }
}

class _MaternalCareTip {
  const _MaternalCareTip(this.icon, this.title, this.body, this.color);

  final IconData icon;
  final String title;
  final String body;
  final Color color;
}
