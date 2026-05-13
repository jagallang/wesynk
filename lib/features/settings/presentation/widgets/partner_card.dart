import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../home/presentation/providers/home_providers.dart';

class PartnerCard extends ConsumerStatefulWidget {
  const PartnerCard({super.key});

  @override
  ConsumerState<PartnerCard> createState() => _PartnerCardState();
}

class _PartnerCardState extends ConsumerState<PartnerCard> {
  final _myEmailCtrl = TextEditingController();
  final _partnerEmailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  bool _registered = false;
  String? _codeError;

  @override
  void dispose() {
    _myEmailCtrl.dispose();
    _partnerEmailCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w+$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.2),
                  child:
                      Icon(Icons.favorite, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.partner,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      Text(S.partnerPlaceholder,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(S.pairingDesc,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 16),

            if (!_registered) ...[
              TextField(
                controller: _myEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: S.myEmail,
                  hintText: 'me@gmail.com',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email_outlined),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _partnerEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: S.partnerEmail,
                  hintText: S.partnerEmailHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person_add_outlined),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codeCtrl,
                decoration: InputDecoration(
                  labelText: S.isKo ? '페어링 코드' : 'Pairing Code',
                  hintText: S.isKo ? '파트너와 약속한 코드' : 'Shared secret code',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  isDense: true,
                  errorText: _codeError,
                ),
                onChanged: (_) => setState(() => _codeError = null),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ||
                          !_isValidEmail(_myEmailCtrl.text.trim()) ||
                          !_isValidEmail(_partnerEmailCtrl.text.trim()) ||
                          _codeCtrl.text.trim().isEmpty
                      ? null
                      : _register,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.link),
                  label: Text(S.requestPairing),
                ),
              ),
            ] else ...[
              _PairingStatusView(
                myEmail: _myEmailCtrl.text.trim().toLowerCase(),
                partnerEmail: _partnerEmailCtrl.text.trim().toLowerCase(),
                onMatched: (coupleId) {
                  ref.read(coupleIdProvider.notifier).state = coupleId;
                  PreferencesService().setCoupleId(coupleId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(S.pairingSuccess)),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _register() async {
    setState(() => _loading = true);
    try {
      final coupleId = ref.read(coupleIdProvider);
      final service = ref.read(firestoreServiceProvider);
      final code = _codeCtrl.text.trim();
      if (code.isEmpty) {
        setState(() => _codeError = S.isKo ? '코드를 입력하세요' : 'Enter a code');
        return;
      }

      final matchedId = await service.registerForPairing(
        myEmail: _myEmailCtrl.text.trim(),
        partnerEmail: _partnerEmailCtrl.text.trim(),
        coupleId: coupleId,
        pairingCode: code,
      );

      setState(() => _registered = true);

      if (matchedId != null && mounted) {
        ref.read(coupleIdProvider.notifier).state = matchedId;
        PreferencesService().setCoupleId(matchedId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.pairingSuccess)),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.isKo
                ? '파트너의 등록을 기다리는 중...'
                : 'Waiting for partner...'),
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }
}

/// 페어링 상태 실시간 감시 (등록 후 매칭 대기/완료)
class _PairingStatusView extends ConsumerWidget {
  final String myEmail;
  final String partnerEmail;
  final ValueChanged<String> onMatched;

  const _PairingStatusView({
    required this.myEmail,
    required this.partnerEmail,
    required this.onMatched,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(firestoreServiceProvider);
    final theme = Theme.of(context);

    return StreamBuilder<Map<String, dynamic>?>(
      stream: service.pairingStatusStream(myEmail),
      builder: (context, snap) {
        final data = snap.data;
        final matched = data?['matched'] == true;
        final matchedCoupleId = data?['matchedCoupleId'] as String?;

        if (matched && matchedCoupleId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onMatched(matchedCoupleId);
          });

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle, size: 40, color: Colors.green),
                const SizedBox(height: 8),
                Text(S.partnerConnected,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 4),
                Text(partnerEmail,
                    style: TextStyle(color: theme.colorScheme.primary)),
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Icon(Icons.hourglass_top, size: 32),
              const SizedBox(height: 8),
              Text(S.pairingPending,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text(partnerEmail,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary)),
              const SizedBox(height: 8),
              Text(
                S.isKo
                    ? '파트너도 같은 방법으로 이메일을 등록하면 자동 연결됩니다'
                    : 'Your partner also needs to register emails the same way',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        );
      },
    );
  }
}
